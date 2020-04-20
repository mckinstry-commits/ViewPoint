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
		
		--#145795 Box 26 (CPP Pensionable Earnings) should show subject amount with maximum pensionable earnings limit applied
		IF @t4Box = 26
		BEGIN
			DECLARE @MaxPensionableEarnLimit bDollar
			SELECT @MaxPensionableEarnLimit = (CASE WHEN @taxyear >= '2012' THEN 50100
													ELSE 48300
											   END)
			UPDATE PRCAEmployeeItems
			SET Amount = @MaxPensionableEarnLimit
			WHERE	PRCo = @prco AND
					TaxYear = @taxyear AND
					T4BoxNumber = @t4Box AND
					Amount > @MaxPensionableEarnLimit
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
