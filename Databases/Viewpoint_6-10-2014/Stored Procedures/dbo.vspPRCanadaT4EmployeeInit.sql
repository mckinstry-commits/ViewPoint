SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRCanadaT4EmployeeInit]
	/******************************************************
	* CREATED BY:  Mark H 
	* MODIFIED By: Liz S  08/25/10	RPP Number comes from Employee Craft, use Employer's RPP when NULL #140354
	*			   Liz S  09/01/10	Add missing PRCo to joins, and taxyear #140692
	*				EN 12/14/2010 #142472 pension plan as negative earnings cancelled out by employer contribution
	*				EN 2/10/2012 TK-12432/#145769 T-4 does not recognise (-) number is the Amount column, treats as (+)
	*				EN 2/10/2012 TK-12436/#145795 Box 26 (CPP Pensionable Earnings) is incorrect on T4
	*				EN 10/17/2013 TFS-53351/Task 64546 when Box 14 is set up to use earn codes, set bPRCAItems_AmtType to 'A' ... else set it to 'S'			
	*				EN 10/29/2013 TFS-59545/65305 fixed to correct handling of prorating and limit for Box 26
	*				CHS 11/18/2013	TFS 65883 added PREA validation.
	*
	* Usage:	Initialization procedure for Canadian T4.  Creates
	*			list of Employees having PREA (Employee Accumulations)
	*			corresponding to T4Box mappings in PRCAEmployerItems. 
	*	
	*
	* Input params:
	*
	*	@prco - Payroll Company
	*	@taxyear - Tax Year
	*	
	*
	* Output params:
	*	@msg		Error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @taxyear char(4), @reinit bYN, @msg varchar(255) output)

	as 
	set nocount on
	declare @rcode int, @firstdayinyear varchar(10), @lastdayinyear varchar(10), @t4Box int,
	@t4Code int
   	
	select @rcode = 0
	select @firstdayinyear = '01/01/' + @taxyear
	select @lastdayinyear = '12/31/' + @taxyear
	
	if @reinit = 'N'
	begin
		if exists(select 1 from PRCAEmployees where PRCo = @prco and TaxYear = @taxyear)
		begin
			select @msg = 'Employees were previously initialized.  Overwrite?', @rcode = 7
			goto vspexit
		end
	end

	--------------------------------------------------------------------------------------------------------
	-- SET VALUE OF BOX 14 AmtType IN bPRCAItems DEPENDING ON BOX 14 SETUP IN bPRCAEmployerItems          --
	-- BOX 14 WILL BE SET UP TO ONLY USE EITHER ALL EARN CODES OR ALL DEDUCTION CODES                     --
	-- IF DEDUCTION CODES, THEN EMPLOYEE ACCUMS SUBJECT AMOUNTS WILL BE ACCESSED SO AmtType SHOULD BE 'S' --
	-- IF EARN CODES, THEN AmtType SHOULD BE 'A'                                                          --
	--------------------------------------------------------------------------------------------------------

	-- CONFIRM THAT BOX 14 IS SETUP IS CORRECT - MUST REFERENCE EITHER EARNINGS OR DEDUCTIONS, NOT A MIX --
	DECLARE @Box14EDLType char(1)

	SELECT TOP 1 @Box14EDLType = EDLType FROM dbo.bPRCAEmployerItems
	WHERE PRCo = @prco AND TaxYear = @taxyear AND T4BoxNumber = 14

	IF	(SELECT COUNT(*) FROM dbo.bPRCAEmployerItems
		 WHERE PRCo = @prco AND TaxYear = @taxyear AND T4BoxNumber = 14)
		<> 
		(SELECT COUNT(*) FROM dbo.bPRCAEmployerItems
		 WHERE PRCo = @prco AND TaxYear = @taxyear AND T4BoxNumber = 14 AND EDLType = @Box14EDLType)
	BEGIN
			SELECT @msg = 'Box 14 setup is incorrect. Must be set to either use only earnings codes or only deduction codes.', @rcode = 1
			goto vspexit
	END

	-- CONFIRM THAT BOX 14 IS NOT SETUP TO REFERENCE LIABILITIES --
	IF @Box14EDLType = 'L'
	BEGIN
			SELECT @msg = 'Box 14 setup is incorrect. Must not be set to use liability code(s).', @rcode = 1
			goto vspexit
	END

	-- Confirm that there is at least one EDL code in PREA which matches an EDL code in PRCAEmployerItems
	-- otherwise you'll get a trigger error from btPRCAEmployeeProvincei
	IF NOT EXISTS (SELECT TOP 1 1 FROM PREA a 
						JOIN PRCAEmployerItems c on c.PRCo = a.PRCo 
							AND c.TaxYear = @taxyear and c.EDLType = a.EDLType
							AND c.EDLCode = a.EDLCode	
					WHERE a.PRCo = @prco AND a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear)
	BEGIN
			SELECT @msg = 'There were no employee accumulations to initialize Employee T4s.', @rcode = 1
			goto vspexit	
	END	

	-- SET BOX 14 AmtType IN bPRCAItems
	UPDATE dbo.bPRCAItems
	SET AmtType = CASE WHEN @Box14EDLType = 'E' THEN 'A' ELSE 'S' END
	WHERE PRCo = @prco AND TaxYear = @taxyear AND T4BoxNumber = 14

	-------------------------------------------------
	-- CLEAR CONTENTS OF CANADA T4 EMPLOYEE TABLES --
	-------------------------------------------------
	delete PRCAEmployeeProvince where PRCo = @prco and TaxYear = @taxyear
	delete PRCAEmployeeItems where PRCo = @prco and TaxYear = @taxyear	
	delete PRCAEmployeeCodes where PRCo = @prco and TaxYear = @taxyear
	delete PRCAEmployees where PRCo = @prco and TaxYear = @taxyear

	--Create PRCAEmployees
	insert PRCAEmployees (PRCo, TaxYear, Employee, FirstName, MidName, LastName, Suffix, [SIN], 
	AddressLine1, City, Province, Country, PostalCode, ProvinceEmployed, CPPQPPExempt, EIExempt,
	PPIPExempt, RPPNumber) 
	select distinct h.PRCo, @taxyear, h.Employee, h.FirstName, h.MidName, h.LastName, h.Suffix, 
	/*substring(h.SSN, 1, 3) + substring(h.SSN, 5,3) + substring(h.SSN, 9,11)*/
	REPLACE(SSN,'-', ''), 
	substring(h.Address, 1, 30), substring(h.City, 1, 25), h.State, 
	h.Country, h.Zip, h.TaxState, h.CPPQPPExempt, h.EIExempt, h.PPIPExempt, 
	CASE WHEN cm.PensionNumber IS NOT NULL THEN cm.PensionNumber ELSE r.RPPNumber END AS 'RPPNumber'
	from PREH h
	join PREA a on a.PRCo = h.PRCo and a.Employee = h.Employee
	join PRCAEmployerItems c on c.PRCo = h.PRCo and c.TaxYear = @taxyear and c.EDLType = a.EDLType
			and c.EDLCode = a.EDLCode
	join PRCAEmployer r on c.PRCo = r.PRCo and c.TaxYear = r.TaxYear 
	LEFT JOIN PRCM cm ON cm.Craft = h.Craft AND cm.PRCo = h.PRCo 
	where h.PRCo = @prco and c.TaxYear = @taxyear and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear

	--Create PRCAEmployeeItems
	declare a cursor local fast_forward
	for
	select T4BoxNumber from PRCAItems where PRCo = @prco and TaxYear = @taxyear

	open a

	fetch next from a into @t4Box

	while @@fetch_status = 0
	begin
		----------------------------------------------------------
		-- CREATE PRCAEmployeeItems FOR BOXES OTHER THAN BOX 26 --
		----------------------------------------------------------
		IF @t4Box <> 26
		BEGIN
			--TK-12432 / #145769 modified search for employee accums to limit ABS() conversion 
			--					 of earnings amounts to non-true earnings only
			INSERT	PRCAEmployeeItems (PRCo, TaxYear, Employee, T4BoxNumber, Amount)
			SELECT	a.PRCo, @taxyear, h.Employee, c.T4BoxNumber, 
					Amount = 
						SUM(CASE i.AmtType 
								WHEN 'S' THEN a.SubjectAmt 
								WHEN 'E' THEN a.EligibleAmt 
								ELSE
									CASE WHEN a.EDLType = 'E' AND e.TrueEarns = 'N' THEN ABS(a.Amount)
										ELSE a.Amount
									END
							END)

			FROM PRCAEmployees h
			JOIN PREA a ON	a.PRCo = h.PRCo AND 
							a.Employee = h.Employee
			LEFT JOIN PREC e ON a.PRCo = e.PRCo AND 
								a.EDLCode = e.EarnCode
			JOIN PRCAEmployerItems c ON c.PRCo = h.PRCo AND 
										c.TaxYear = @taxyear AND 
										c.EDLType = a.EDLType AND 
										c.EDLCode = a.EDLCode
			JOIN PRCAItems i ON i.PRCo = c.PRCo AND 
								i.TaxYear = c.TaxYear AND 
								i.T4BoxNumber = c.T4BoxNumber
			WHERE	h.PRCo = @prco AND 
					a.Mth >= @firstdayinyear AND 
					a.Mth <= @lastdayinyear AND 
					c.T4BoxNumber = @t4Box AND 
					h.TaxYear = @taxyear
			GROUP BY a.PRCo, h.Employee, c.T4BoxNumber
		END

		------------------------------------------------------------------------------
		-- CREATE PRCAEmployeeItems FOR BOX 26										--
		--																			--
		-- #145795 Box 26 (CPP Pensionable Earnings) should show subject amount		--
		--	with maximum pensionable earnings limit applied							--
		-- TFS-59545/65305 additional correction to how pensionable amount limit	--
		--	is applied ... with prorating											--
		------------------------------------------------------------------------------
		IF @t4Box = 26
		BEGIN
			-- find Maximum annual pensionable earnings amount
			DECLARE @CPPDednMaxPensionEarnAmt	bDollar

			SELECT TOP 1						--Use latest effective date within tax year
					@CPPDednMaxPensionEarnAmt	= CPPDednMaxPensionEarnAmt
			FROM	dbo.PRCALimitsAndRates
			WHERE	YEAR(EffectiveDate) = @taxyear
			ORDER BY EffectiveDate DESC

			-- CTE to determine employee stats needed for computing Box 26 with potential age-based prorating and annual limit
			;WITH EmplsAndProrateTypes (Employee,
										BirthDate,
										ProrateType)
			
			AS -- establish employees for TaxYear and age-based Prorate Type for each employee
			(	 
			 SELECT [Employee]		= t4empl.Employee, 
			 
					[BirthDate]		= eh.BirthDate,
					
					[ProrateType]	= (CASE	WHEN 
												(
												 (eh.BirthDate IS NULL)
												 OR
												 ((@taxyear - YEAR(eh.BirthDate) >= 19) AND (@taxyear - YEAR(eh.BirthDate) <=69))
												)
												THEN 2 -- Employee is 18 (or older) AND 69 (or younger) throughout entire tax year so all months are pensionable
											WHEN 
												(@taxyear - YEAR(eh.BirthDate) = 18)
												THEN 3 -- Employee turns 18 during the tax year so some (or no) months are pensionable
											WHEN 
												(@taxyear - YEAR(eh.BirthDate) = 70)
												THEN 4 -- Employee truns 70 during the tax year so some (or all) months are pensionable
											ELSE 
												1 -- No months are pensionable
											END)
			 FROM	dbo.PRCAEmployees t4empl
			 JOIN	dbo.PREH eh ON eh.PRCo = t4empl.PRCo AND eh.Employee = t4empl.Employee
			 WHERE	t4empl.PRCo = @prco  
					AND t4empl.TaxYear = @taxyear
			),
			
			PensionableMthsAndRanges (Employee,
									  PensionableMths,
									  FirstPensionableMth,
									  LastPensionableMth)
			AS -- establish pensionable number of months and month ranges
			(
			 SELECT [Employee]				= Employee,
			 
					[PensionableMths]		= (CASE ProrateType	WHEN 2 THEN 12											-- empl between 18 and 70 all year so all months pensionable
																WHEN 3 THEN MONTH(@lastdayinyear) - MONTH(BirthDate)	-- empl turned 18 this year so only months after birth month pensionable
																WHEN 4 THEN MONTH(BirthDate)							-- empl turned 70 this year so only months through birth month pensionable
																ELSE		0											-- empl is too young or too old to have any pensionable months
																END), 
																		
					[FirstPensionableMth]	= (CASE ProrateType	WHEN 2 THEN @firstdayinyear
																WHEN 3 THEN	(CASE MONTH(BirthDate)	WHEN 12 THEN NULL
																									ELSE DATEADD(month, MONTH(BirthDate), @firstdayinyear)
																									END)
																WHEN 4 THEN @firstdayinyear
																ELSE		NULL
																END),
																		
					[LastPensionableMth]	= (CASE ProrateType	WHEN 2 THEN DATEADD(day, -30, @lastdayinyear)
																WHEN 3 THEN (CASE MONTH(BirthDate)	WHEN 12 THEN NULL
																									ELSE DATEADD(day, -30, @lastdayinyear)
																									END)
																WHEN 4 THEN DATEADD(month, -1, DATEADD(month, MONTH(BirthDate), @firstdayinyear))
																ELSE		NULL
																END)
			 FROM EmplsAndProrateTypes 
			)

			-- insert PRCAEmployeeItems for Box 26 with prorated pension limit
			INSERT	PRCAEmployeeItems (PRCo, TaxYear, Employee, T4BoxNumber, Amount)
			SELECT	ea.PRCo, 
					@taxyear, 
					ea.Employee, 
					@t4Box,
					Amount = (CASE WHEN SUM(ea.SubjectAmt) > ROUND(@CPPDednMaxPensionEarnAmt * (CAST(cte.PensionableMths AS numeric(16,5)) / 12), 2)
										THEN ROUND(@CPPDednMaxPensionEarnAmt * (CAST(cte.PensionableMths AS numeric(16,5)) / 12), 2)
								   ELSE SUM(ea.SubjectAmt)
								   END)
			FROM	dbo.PREA ea 
			JOIN	PensionableMthsAndRanges cte	ON cte.Employee = ea.Employee
			JOIN	dbo.PRCAEmployerItems items		ON items.PRCo = ea.PRCo 
													   AND items.EDLType = ea.EDLType 
													   AND items.EDLCode = ea.EDLCode
			WHERE	ea.PRCo = @prco
					AND ea.Mth BETWEEN cte.FirstPensionableMth AND cte.LastPensionableMth 
					AND ea.EDLType = 'D'
					AND items.TaxYear = @taxyear 
					AND items.T4BoxNumber = @t4Box 
			GROUP BY ea.PRCo, ea.Employee, cte.PensionableMths
		END
			
		

		fetch next from a into @t4Box

	end

	close a
	deallocate a

	--Create PRCAEmployeeCodes
--	insert PRCAEmployeeCodes (PRCo, TaxYear, Employee, T4CodeNumber, Amount)
--	select a.PRCo, @taxyear, a.Employee, e.T4CodeNumber, case i.AmtType when 'S' then Sum(a.SubjectAmt) 
--	when 'E' then Sum(a.EligibleAmt) else Sum(a.Amount) end as 'Amount'
--	from PREA a
--	join PRCAEmployerCodes e on a.PRCo = e.PRCo and a.EDLType = e.EDLType and a.EDLCode = e.EDLCode 
--	join PRCACodes i on e.PRCo = i.PRCo and e.TaxYear = i.TaxYear and i.T4CodeNumber = e.T4CodeNumber
--	where a.PRCo = @prco and e.TaxYear = @taxyear and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear 
--	group by a.PRCo, a.Employee, e.T4CodeNumber, i.AmtType, a.EDLType, a.EDLCode

	declare b cursor local fast_forward
	for
	select T4CodeNumber from PRCACodes where PRCo = @prco and TaxYear = @taxyear

	open b

	fetch next from b into @t4Code

	while @@fetch_status = 0
	begin

		insert PRCAEmployeeCodes (PRCo, TaxYear, Employee, T4CodeNumber, Amount)
		select a.PRCo, @taxyear, h.Employee, c.T4CodeNumber, 
		Amount = abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END))
		from PRCAEmployees h
		join PREA a on a.PRCo = h.PRCo and a.Employee = h.Employee
		join PRCAEmployerCodes c on c.PRCo = h.PRCo and c.TaxYear = @taxyear and c.EDLType = a.EDLType
				and c.EDLCode = a.EDLCode
		JOIN PRCACodes i ON i.PRCo = c.PRCo AND i.TaxYear = c.TaxYear AND i.T4CodeNumber = c.T4CodeNumber
		where h.PRCo = @prco and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear and c.T4CodeNumber = @t4Code-- c.Item >=1 and c.Item <=6
				AND h.TaxYear = @taxyear -- #140692
		group by a.PRCo, h.Employee, c.T4CodeNumber

		fetch next from b into @t4Code

	end

	close b
	deallocate b

	--Create Employee Province
	insert PRCAEmployeeProvince (PRCo, TaxYear, Employee, Province, Wages, Tax, Country)
	select a.PRCo, @taxyear, a.Employee, p.Province,
	abs(Sum(a.SubjectAmt)) 'Wages',  abs(Sum(a.Amount)) 'Tax', p.Country
	from PREA a
	join PRCAEmployerProvince p on a.PRCo = p.PRCo and a.EDLCode = p.DednCode
	where a.PRCo = @prco and p.TaxYear = @taxyear and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear and p.Initialize = 'Y' and a.EDLType = 'D'
	group by a.PRCo, a.Employee, p.Province, p.Country

	vspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4EmployeeInit] TO [public]
GO
