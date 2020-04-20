SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[vspPRCanadaT4SlipGenerate]
/******************************************************
* CREATED BY:  Mark H   09/03/09
*
* MODIFIED BY: Mark H   12/17/09	Need to include employees that do not have a Province (no Provincial wages recorded).
*			   Mark H   12/22/09	Added code to reinitialize variables prior to fetching next into @employee.
*			   Mark H   12/23/09	Kept above change. However, if Employee does not have any provincial wages/deductions
*									then the insert into the temp table can be the values from @t4boxes table variable which
*									are the raw values from PRCAEmployeeItems.
*									Also added a Sorting parameter '@sort'. 
*			   Liz S    08/25/10	RPP Number comes from Employee (PREH) now instead of Employer. #140354
*			   Liz S    10/25/10	Change Country and Province to ZZ to Follow T4 & T619 Electronic File specs. #141666
*			   Mark H   02/14/11	Country needs to be three alpha characters. #143352.
*			   Czeslaw	05/05/11	CL-143226 Per new requirement, entire Federal Box 46 amount is now assigned to employee's 
*									home province; if employee did not work in home province, then entire amount is assigned 
*									to first province printed on T4. In other words: there is no longer a proportional distribution 
*									of Federal Box 46 value across multiple provinces.
*			   CHS		05/16/11	141794 Added five new Code fields and changed Other Codes ordering
*			   Czeslaw	05/18/11	143355 Corrected typo at Insert into @t4boxes.Box19.
*			   Czeslaw	05/23/11	141794 Added column e.MidName to final select statement. Changed column alias for e.ProvinceEmployed
*									from 'Province' (not unique) to 'ProvinceEmployed' (unique); column is not actually being used
*									by any reports or by the XML generator. Added cursor to set corrected final #temptable.Seq values
*									(for T4 slip output order). Deleted 'Box10' from Order By clause in final select statement, 
*									since corrected final sequence values now control slip output order, as originally intended.
*			   Czeslaw	02/10/12	145801 / D-04501 Boxes 44, 55, and 56 had been omitted erroneously from the part of the procedure
*									that checks for differences and rounding errors, and corrects them. I added the necessary code to 
*									resolve differences for these three boxes.
*			   CHS		11/27/12	B-11847 TK-19654 Add contact email address.
*			   MV		11/27/12	D-047171/TK-19476 Restrict employees by ReturnType: "O" = Original, "A" = Amended, "C" = Cancelled.
*              Czeslaw	12/06/12	147613 / D-06269 Implemented rounding to nearest whole dollar amount for Box 52 by rounding first
*									the federal Box 52 amount, then each provincial portion of the federal amount; differences due to
*									rounding are resolved in same manner as previously (unchanged).
*
* Usage:  Returns dataset from PR Canada T4 tables to generate T4 Slips.
*
*	This procedure returns all elements required to generate an XML T4 Slip. All calculations and accumulations for
*	Boxes and Codes are done within this procedure. Calling program code takes the values returned from this
*	procedure and places them in the XML Elements. While the calling program will do no calculations or value 
*	manipulation, it does expect the field names returned in the final query. In other words, you can change the value
*	of a field but you cannot change the field name without changing the calling program.
*
*	A couple of things to note with Canadian T4s:
*
*	1.  A T4 comprises Boxes and Codes.
*	2.  A Box may hold numeric dollar data or alphanumeric data, such as an SIN or Registration Number. A Code holds numeric dollar data only.
*	3.	Boxes and Codes do not share the same number. In other words, there will be no "Box14" and "Code14" (only one or the other).
*	4.  An Employee may be issued more than one T4 slip:
*
*		a.  Employee works out of more than one office in more than one Province. Federal amounts must be reported
*			proportionately for each Province. For example, an Employee reports to an office in BC 60% of the time 
*			and AB 40% of the time. In this case they would get one T4 slip showing 60% of their federal amounts reported 
*			to BC, and a second T4 slip reporting the remaining 40% to AB. (Box 46 is an exception; see notes in revision history above.)
*
*		b.	More than 6 "Code" amounts. Codes represent taxable allowances and benefits, deductible amounts, employment
*			commissions, and other entries. If an employee has more than 6 of these, the subsequent "overflow" Codes must be reported
*			on another T4, again, reporting no more than 6 Codes. Subsequent "overflow" T4s only need to show the Code amounts. 
*			Federal and Provincial amounts do not need to be reported again.
*
*	5.	Everything is returned as one dataset: all header, detail and summary fields. A T4 XML file contains the following
*		parts:
*		
*		Submission
*		T619 - Header information about the transmitter or sender.
*		T4 - The T4 itself.
*		
*		The T4 is subdivided into:
*			T4 Slips - The individual slips;
*			T4 Summary - The sum of the slips plus some employer contribution data.
*	
*
* Input params:
*	
*	@prco - Payroll Company
*	@taxyear - Tax Year for T4 filing
*	@remit - Amount previously remitted to Canada Revenue Agency
*	@amtenclosed - Amount enclosed with T4 filing
*	@sort - variable specifying how recordset being returned should be sorted.
*			'N' = By Employee Number
*			'A' = By Employee Sort Name
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*
*******************************************************/
   
   	(@prco bCompany, @taxyear char(4), @remit bDollar, @amtenclosed bDollar, @sort char(1), @msg varchar(100) output)

	as 
	set nocount on

	declare @rcode int, @seq int, @cntr int, @sql varchar(8000), @employee bEmployee, @provinceemployed varchar(4), @t4boxnumber smallint, 
	@amount bDollar, @province varchar(4) 

	--Federal Variables...hold initial values.
	declare @fedBox14Wages bDollar, @fedBox16CPPCont bDollar, @fedBox18EIPrem bDollar, @fedBox20RPPCont bDollar, @fedBox22IncTax bDollar, 
	@fedBox24EIEarn bDollar, @fedBox26CPPEarn bDollar, @fedBox44UnionDues bDollar, @fedBox46CharDon bDollar, @fedBox52PenAdj bDollar,
	@fedBox55PPIPPrem bDollar, @fedBox56PPIPEarn bDollar
 
	--Provincial Variables...hold proportional amounts of Federal Variables.
	declare @provBox14Wages bDollar, @provfedBox14Wages bDollar, @provBox16CPPCont bDollar, @provBox18EIPrem bDollar, @provBox20RPPCont bDollar, 
	@provBox22IncTax bDollar, @provfedBox22IncTax bDollar, @provBox24EIEarn bDollar,  @provBox26CPPEarn bDollar, 
	@provBox44UnionDues bDollar, @provBox46CharDon bDollar, @provBox52PenAdj bDollar, @provBox55PPIPPrem bDollar, 
	@provBox56PPIPEarn bDollar

	--Provincial accumulators.  After processing an employee these should equal the corresponding Federal Variable.  
	--Differences due to rounding to be updated into the last provincial record.
	declare @totalfedBox14Wages bDollar, @totalBox16CPPCont bDollar, @totalBox18EIPrem bDollar, @totalBox20RPPCont bDollar, @totalfedBox22IncTax bDollar, 
	@totalBox24EIEarn bDollar, @totalBox26CPPEarn bDollar, @totalBox44UnionDues bDollar, @totalBox46CharDon bDollar, 
	@totalBox52PenAdj bDollar, @totalBox55PPIPPrem bDollar, @totalBox56PPIPEarn bDollar

	--T4Summary Variables
	declare @totalBox14 bDollar, @totalBox16 bDollar, @totalBox18 bDollar, @totalBox19 bDollar, @totalBox20 bDollar, @totalBox22 bDollar, 
	@totalBox27 bDollar, @totalBox52 bDollar, @totalDeductions bDollar, @totalslips int 
	   	
	select @rcode = 0, @seq = 0, @cntr = 0, @sql = ''

	if @prco is null
	begin
		select @msg = 'Missing PR Company.', @rcode = 1
		goto vspexit
	end

	if @taxyear is null
	begin
		select @msg = 'Missing Tax Year.', @rcode = 1
		goto vspexit
	end
	
	--#temptable temporary table.  This will be used to create the dataset that will be returned to the calling
	--procedure to create the T4 slips.
	Create table #temptable (PRCo tinyint, TaxYear char(4), Employee integer, Seq integer, FedBox14Wages numeric(12,2), FedBox22IncTax numeric(12,2), 
	Province varchar(4), ProvBox14Wages numeric(12,2), ProvBox22IncomeTax numeric(12,2), ProvFedBox22IncTax numeric (12,2),
	Box14 numeric(12,2), Box16 numeric(12,2), Box17 numeric(12,2), Box18 numeric(12,2), Box19 numeric(12,2), Box20 numeric(12,2),
	Box22 numeric(12,2), Box24 numeric(12,2), Box26 numeric(12,2), Box27 numeric(12,2), Box44 numeric(12,2), Box46 numeric(12,2),
	Box52 numeric(12,2), Box55 numeric(12,2), Box56 numeric(12,2), Code30 numeric(12,2), Code31 numeric(12,2), Code32 numeric(12,2),
	Code33 numeric(12,2), Code34 numeric(12,2), Code35 numeric(12,2), Code36 numeric(12,2), Code37 numeric(12,2), Code38 numeric(12,2),
	Code39 numeric(12,2), Code40 numeric(12,2), Code41 numeric(12,2), Code42 numeric(12,2), Code43 numeric(12,2), Code53 numeric(12,2),
	Code66 numeric(12,2), Code67 numeric(12,2), Code68 numeric(12,2), Code69 numeric(12,2), --141794
	Code70 numeric(12,2), Code71 numeric(12,2), Code72 numeric(12,2), Code73 numeric(12,2), Code74 numeric(12,2), Code75 numeric(12,2),
	Code77 numeric(12,2), Code78 numeric(12,2), Code79 numeric(12,2), Code80 numeric(12,2), Code81 numeric(12,2), Code82 numeric(12,2),
	Code83 numeric(12,2), Code84 numeric(12,2), Code85 numeric(12,2), 
	Code86 numeric(12,2), --141794
	Code97 numeric(12,2), Code98 numeric(12,2), Code99 numeric(12,2),
    RptBox1Cd smallint, RptBox2Cd smallint, RptBox3Cd smallint, RptBox4Cd smallint, RptBox5Cd smallint, RptBox6Cd smallint,
    RptBox1Amt numeric(12,2), RptBox2Amt numeric(12,2), RptBox3Amt numeric(12,2), RptBox4Amt numeric(12,2), RptBox5Amt numeric(12,2),
    RptBox6Amt numeric(12,2))

	--@t4boxes table variable used to turn PRCAEmployeeItems on its side
	declare @t4boxes table(PRCo smallint, TaxYear char(4), Employee int, 
	Box14 numeric (12,2), Box16 numeric (12,2), Box17 numeric (12,2), Box18 numeric (12,2), Box19 numeric (12,2), Box20 numeric (12,2),
	Box22 numeric (12,2), Box24 numeric (12,2), Box26 numeric (12,2), Box27 numeric (12,2), Box44 numeric (12,2), Box46 numeric (12,2),
	Box52 numeric (12,2), Box55 numeric (12,2), Box56 numeric (12,2))

	INSERT @t4boxes(PRCo, TaxYear, Employee, Box14,Box16,Box17,Box18,Box19,Box20,Box22,Box24,Box26,Box27,
	Box44,Box46,Box52,Box55,Box56)
	SELECT p.PRCo, p.TaxYear, p.Employee, 
	Box14 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 14 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box16 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 16 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box17 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 17 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box18 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 18 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box19 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 19 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0), --143355
	Box20 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 20 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box22 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 22 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box24 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 24 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box26 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 26 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box27 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 27 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box44 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 44 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box46 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 46 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box52 = round(isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 52 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),0), --147613
	Box55 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 55 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0),
	Box56 = isnull((select Amount from PRCAEmployeeItems where T4BoxNumber = 56 and PRCo = p.PRCo and TaxYear = p.TaxYear and Employee = p.Employee),0)
	FROM dbo.PRCAEmployeeItems p (NOLOCK) --TK-19476 restrict employees by ReturnType
	JOIN dbo.PRCAEmployees e (NOLOCK) ON p.PRCo=e.PRCo AND p.TaxYear=e.TaxYear AND p.Employee = e.Employee
	JOIN dbo.PRCAEmployer r (NOLOCK) ON e.PRCo=r.PRCo AND e.TaxYear=r.TaxYear
	WHERE	p.PRCo = @prco
	AND		p.TaxYear = @taxyear
	AND		(
				(r.ReturnType = 'O' AND e.ReturnType = 'O') OR 
				(r.ReturnType = 'A' AND e.ReturnType IN ('A','C'))
			)
	GROUP BY p.PRCo, p.TaxYear, p.Employee


	--Work the BOXES.
	--Loop through Employees and work the Boxes.
	
	--CL-143226 Czeslaw 05/05/11 - ProvinceEmployed represents the employee's home province - TK19476 limit cursor to employees in @t4boxes temp table
	DECLARE employeecurs cursor local fast_forward for
	SELECT e.Employee, e.ProvinceEmployed 
	FROM PRCAEmployees e (NOLOCK)
	JOIN @t4boxes t4 ON e.PRCo = t4.PRCo AND e.TaxYear = t4.TaxYear AND e.Employee = t4.Employee 
	WHERE e.PRCo = @prco and e.TaxYear = @taxyear

	open employeecurs
	fetch next from employeecurs into @employee, @provinceemployed

	while @@fetch_status = 0
	begin
	
		select @fedBox14Wages = Box14, @fedBox16CPPCont = Box16, @fedBox18EIPrem = Box18, @fedBox20RPPCont = Box20, 
		@fedBox22IncTax = Box22, @fedBox24EIEarn = Box24, @fedBox26CPPEarn = Box26, @fedBox44UnionDues = Box44, 
		@fedBox46CharDon = Box46, @fedBox52PenAdj = Box52, @fedBox55PPIPPrem = Box55, @fedBox56PPIPEarn = Box56
		from @t4boxes
		where PRCo = @prco and TaxYear = @taxyear and Employee = @employee

		if exists(select 1 from PRCAEmployeeProvince where PRCo = @prco and TaxYear = @taxyear and Employee = @employee)
		begin
						
		--Create cursor of Provinces
			declare provcurs cursor local fast_forward for
			select Province, Wages, Tax from PRCAEmployeeProvince 
			where PRCo = @prco and TaxYear = @taxyear and Employee = @employee
			order by Province

			open provcurs
			fetch next from provcurs into @province, @provBox14Wages, @provBox22IncTax

			--Initialize accumulators
			select @totalfedBox14Wages = 0, @totalBox16CPPCont = 0, @totalBox18EIPrem = 0, @totalBox20RPPCont = 0, @totalfedBox22IncTax = 0, @totalBox24EIEarn = 0,
			@totalBox26CPPEarn = 0, @totalBox44UnionDues = 0, @totalBox46CharDon = 0, @totalBox52PenAdj = 0, @totalBox55PPIPPrem = 0,
			@totalBox56PPIPEarn = 0

			select @seq = 1
		
			while @@fetch_status = 0
			begin
				
				--Determine ratio of Provincial wages to Federal Wages.  This ratio will be used to determine which portion of the 
				--Federal earnings/deductions/liabilities to allocate to the province.
				
				--Calculate portion
				select @provfedBox14Wages = (@fedBox14Wages * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provBox16CPPCont = (@fedBox16CPPCont * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provBox18EIPrem = (@fedBox18EIPrem * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provBox20RPPCont = (@fedBox20RPPCont * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provfedBox22IncTax = (@fedBox22IncTax * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provBox24EIEarn = (@fedBox24EIEarn * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provBox26CPPEarn = (@fedBox26CPPEarn * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provBox44UnionDues = (@fedBox44UnionDues * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provBox52PenAdj = (round((@fedBox52PenAdj * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end)),0)) --147613
				select @provBox55PPIPPrem = (@fedBox55PPIPPrem * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				select @provBox56PPIPEarn = (@fedBox56PPIPEarn * (case when @fedBox14Wages > 0 then @provBox14Wages/@fedBox14Wages else 1 end))
				
				--CL-143226 Czeslaw 05/05/11
				--Box 46 requires special treatment: if employee worked in home province, then assign entire Federal amount to employee's home province; 
				--if employee did not work in home province, then assign entire Federal amount to first province printed on T4.

				--IF EMPLOYEE DID work in his home province during the tax year...
				IF EXISTS(SELECT 1 FROM PRCAEmployeeProvince WHERE PRCo = @prco AND TaxYear = @taxyear AND Employee = @employee AND Province = @provinceemployed)
					BEGIN
						--Assign full Federal Box 46 value to home province
						IF @province = @provinceemployed
							BEGIN SELECT @provBox46CharDon = @fedBox46CharDon END
						ELSE
							BEGIN SELECT @provBox46CharDon = 0 END
					END
				--IF EMPLOYEE DID NOT work in his home province during the tax year...
				ELSE
					BEGIN
						--Assign full Federal Box 46 value to first province printed on T4
						IF @seq = 1
							BEGIN SELECT @provBox46CharDon = @fedBox46CharDon END
						ELSE
							BEGIN SELECT @provBox46CharDon = 0 END
					END


				--Accumulate proportions into "total" variables. Each total will be compared against original Federal value.
				--Corrections to be made to the last Provincial record for rounding errors.
				select @totalfedBox14Wages = @totalfedBox14Wages + @provfedBox14Wages
				select @totalBox16CPPCont = @totalBox16CPPCont + @provBox16CPPCont
				select @totalBox18EIPrem = @totalBox18EIPrem + @provBox18EIPrem
				select @totalBox20RPPCont = @totalBox20RPPCont + @provBox20RPPCont
				select @totalfedBox22IncTax = @totalfedBox22IncTax + @provfedBox22IncTax
				select @totalBox24EIEarn = @totalBox24EIEarn + @provBox24EIEarn
				select @totalBox26CPPEarn = @totalBox26CPPEarn + @provBox26CPPEarn
				select @totalBox44UnionDues = @totalBox44UnionDues + @provBox44UnionDues
				select @totalBox46CharDon = @totalBox46CharDon + @provBox46CharDon
				select @totalBox52PenAdj = @totalBox52PenAdj + @provBox52PenAdj
				select @totalBox55PPIPPrem = @totalBox55PPIPPrem + @provBox55PPIPPrem
				select @totalBox56PPIPEarn = @totalBox56PPIPEarn + @provBox56PPIPEarn

				--Insert into TEMP table
				insert #temptable(PRCo, TaxYear, Employee, Seq, FedBox14Wages, FedBox22IncTax, Province, ProvBox14Wages, 
				ProvBox22IncomeTax, ProvFedBox22IncTax, Box14, Box16, Box18, Box22, Box24, Box26, Box44, Box46, Box52, Box55, Box56)
				values (@prco, @taxyear, @employee, @seq, @fedBox14Wages, @fedBox22IncTax, @province, @provBox14Wages,
				@provBox22IncTax, @provfedBox22IncTax, (isnull(@provBox14Wages,0) /*+ isnull(@provfedBox14Wages,0)*/), isnull(@provBox16CPPCont,0), 
				isnull(@provBox18EIPrem,0), (isnull(@provfedBox22IncTax,0) + isnull(@provBox22IncTax,0)), isnull(@provBox24EIEarn,0), 
				isnull(@provBox26CPPEarn,0), isnull(@provBox44UnionDues,0), isnull(@provBox46CharDon,0), isnull(@provBox52PenAdj,0), 
				isnull(@provBox55PPIPPrem,0), isnull(@provBox56PPIPEarn,0))
		 
				fetch next from provcurs into @province, @provBox14Wages, @provBox22IncTax
				select @seq = @seq + 1

			end

			--Check for differences/rounding errors and update #temptable if needed.

			--Federal Wage Diff Box 14
			if @fedBox14Wages <> @totalfedBox14Wages
			begin
				update #temptable set Box14 = Box14 + (@fedBox14Wages - @totalfedBox14Wages)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end

			--CPP Diff Box 16
			if @fedBox16CPPCont <> @totalBox16CPPCont
			begin
				update #temptable set Box16 = Box16 + (@fedBox16CPPCont - @totalBox16CPPCont)
				where PRCo = @prco and TaxYear = @taxyear and  Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end

			--EI Diff Box 18
			if @fedBox18EIPrem <> @totalBox18EIPrem
			begin
				update #temptable set Box18 = Box18 + (@fedBox18EIPrem - @totalBox18EIPrem)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end
			
			--RPP Contributions Diff Box 20
			--Not needed because entire federal Box 20 amount is assigned exceptionally to last provincial slip in sequence

			--Fed Income Tax Diff Box 22
			if @fedBox22IncTax <> @totalfedBox22IncTax
			begin
				update #temptable set Box22 = Box22 + (@fedBox22IncTax - @totalfedBox22IncTax)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end

			--EI Earn Diff Box 24
			if @fedBox24EIEarn <> @totalBox24EIEarn
			begin
				update #temptable set Box24 = Box24 + (@fedBox24EIEarn - @totalBox24EIEarn)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end

			--CPP Earn Diff Box 26
			if @fedBox26CPPEarn <> @totalBox26CPPEarn
			begin
				update #temptable set Box26 = Box26 + (@fedBox26CPPEarn - @totalBox26CPPEarn)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end
			
			--Union Dues Diff Box 44 -- Issue 145801
			if @fedBox44UnionDues <> @totalBox44UnionDues
			begin
				update #temptable set Box44 = Box44 + (@fedBox44UnionDues - @totalBox44UnionDues)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end
			
			--Charitable Donations Diff Box 46
			--Not needed because entire federal Box 46 amount is assigned exceptionally to slip for home province or first provincial slip in sequence			

			--Pension Adjustment Diff Box 52
			if @fedBox52PenAdj <> @totalBox52PenAdj
			begin
				update #temptable set Box52 = Box52 + (@fedBox52PenAdj - @totalBox52PenAdj)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end

			--Employee's PPIP Premiums Diff Box 55 -- Issue 145801
			if @fedBox55PPIPPrem <> @totalBox55PPIPPrem
			begin
				update #temptable set Box55 = Box55 + (@fedBox55PPIPPrem - @totalBox55PPIPPrem)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end

			--PPIP Insurable Earnings Diff Box 56 -- Issue 145801
			if @fedBox56PPIPEarn <> @totalBox56PPIPEarn
			begin
				update #temptable set Box56 = Box56 + (@fedBox56PPIPEarn - @totalBox56PPIPEarn)
				where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)
			end
			
			--Enter the remaining Boxes into the last provincial T4 
			--Do not include Box16 in this update.  
			update #temptable set /*Box16 = t.Box16,*/ Box17 = t.Box17, Box19 = t.Box19, Box20 = t.Box20, Box27 = t.Box27 
			from #temptable a join @t4boxes t on a.PRCo = t.PRCo and a.TaxYear = t.TaxYear and a.Employee = t.Employee 
			where a.PRCo = @prco and a.TaxYear = @taxyear and a.Employee = @employee and a.Province = 
					(select top 1 Province from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @employee 
					order by Province Desc)

			--Reset Accumulators
			select @totalfedBox14Wages = 0, @totalBox16CPPCont = 0, @totalBox18EIPrem = 0, @totalBox20RPPCont = 0, @totalfedBox22IncTax = 0, @totalBox24EIEarn = 0,
			@totalBox26CPPEarn = 0, @totalBox44UnionDues = 0, @totalBox46CharDon = 0, @totalBox52PenAdj = 0, @totalBox55PPIPPrem = 0,
			@totalBox56PPIPEarn = 0

			close provcurs
			deallocate provcurs
		end
		else
		begin
			--In this case FedBox14 wages are going to be the same as ProvincialBox14 wages 
			--so t.Box14 can go in both places.
			select @seq = 1
			
			insert #temptable(PRCo, TaxYear, Employee, Seq, FedBox14Wages, FedBox22IncTax, 
			Box14, Box16, Box18, Box22, Box24, Box26, Box44, Box46, Box52, 
			Box55, Box56, Box17, Box19, Box20, Box27)
			Select @prco, @taxyear, @employee, @seq, t.Box14, t.Box22,
			t.Box14, t.Box16, t.Box18, t.Box22, t.Box24, t.Box26, t.Box44, t.Box46, t.Box52, 
			t.Box55, t.Box56, t.Box17, t.Box19, t.Box20, t.Box27
			from @t4boxes t
			where t.PRCo = @prco and t.TaxYear = @taxyear and t.Employee = @employee
			
		end

		select @fedBox14Wages = null, @fedBox16CPPCont = null, @fedBox18EIPrem = null, @fedBox20RPPCont = null, 
		@fedBox22IncTax = null, @fedBox24EIEarn = null, @fedBox26CPPEarn = null, @fedBox44UnionDues = null, 
		@fedBox46CharDon = null, @fedBox52PenAdj = null, @fedBox55PPIPPrem = null, @fedBox56PPIPEarn = null,
		@provfedBox22IncTax = null, @provBox16CPPCont = null, @provBox18EIPrem = null, @provfedBox22IncTax = null,
		@provBox22IncTax = null, @provBox14Wages = null, @provBox24EIEarn = null,@provBox26CPPEarn = null, 
		@provBox44UnionDues = null,@provBox46CharDon = null, @provBox52PenAdj = null,@provBox55PPIPPrem = null,
		@provBox56PPIPEarn = null
		
		fetch next from employeecurs into @employee, @provinceemployed
	end
		
	close employeecurs
	deallocate employeecurs


	--Work the CODES.
	--If an employee has more than 6 codes with amounts > 0 then another T4 must be generated.
	declare @t4codes table(PRCo int, TaxYear char(4), Employee int, T4CodeNumber smallint, Amount numeric(12,2))

	--We want only Codes that have an amount greater than zero.
	INSERT @t4codes (PRCo, TaxYear, Employee, T4CodeNumber, Amount)
	SELECT c.PRCo, c.TaxYear, c.Employee, c.T4CodeNumber, c.Amount
	FROM PRCAEmployeeCodes c
	JOIN @t4boxes t4 ON c.PRCo = t4.PRCo AND c.TaxYear = t4.TaxYear AND c.Employee = t4.Employee  --TK-19476
	WHERE c.PRCo = @prco and c.TaxYear = @taxyear and c.Amount > 0

	declare @t4codeempl bEmployee, @t4codenumber smallint, @t4codeamt bDollar, @box10province varchar(4)
	
	DECLARE emplcurs cursor local fast_forward for 
	SELECT DISTINCT (c.Employee)
	FROM PRCAEmployeeCodes c
	JOIN @t4boxes t4 ON c.PRCo = t4.PRCo AND c.TaxYear = t4.TaxYear AND c.Employee = t4.Employee --TK-19476
	WHERE c.PRCo = @prco and c.TaxYear = @taxyear

	open emplcurs
	fetch next from emplcurs into @t4codeempl

	--work the employees
	while @@fetch_status = 0
	begin --outer loop
		if exists(select 1 from @t4codes where PRCo = @prco and TaxYear = @taxyear and Employee = @t4codeempl)
		begin --1
			
			--#141794
			--if province employed ("home province") exists in temp table then update it - otherwise grab the first province in sequence on T4
			
			--Determine employee's home province
			select @provinceemployed = ProvinceEmployed from PRCAEmployees (nolock) where PRCo = @prco and TaxYear = @taxyear and Employee = @t4codeempl
			
			--Determine Seq value of first T4 slip
			select @seq = min(Seq) 
			from #temptable 
			where PRCo = @prco and TaxYear = @taxyear and Employee = @t4codeempl
			
			--Use Seq value for slip for home province instead, if it exists
			select @seq = isnull(Seq, @seq)
			from #temptable
			where PRCo = @prco and TaxYear = @taxyear and Employee = @t4codeempl and Province = @provinceemployed

			--Determine province that is first in sequence (by alphanumeric order) on T4, if any provincial wages recorded
			select top 1 @box10province = Province 
			from PRCAEmployeeProvince 
			where PRCo = @prco and TaxYear = @taxyear and Employee = @t4codeempl
			order by Province
			
			--Use employee's home province instead, if it exists
			select @box10province = isnull(Province, @box10province)
			from PRCAEmployeeProvince 
			where PRCo = @prco and TaxYear = @taxyear and Employee = @t4codeempl and Province = @provinceemployed


			----This will be the employee record to update
			--#141794
			
			declare empcodecurs cursor local fast_forward for 
			select Employee, T4CodeNumber, Amount from @t4codes
			where PRCo = @prco and TaxYear = @taxyear and Employee = @t4codeempl

			open empcodecurs

			fetch next from empcodecurs into @employee, @t4codenumber, @t4codeamt
				
			select @cntr = 1

			while @@fetch_status = 0
			begin --inner loop
				
				if @cntr <=6 
                        begin
                              select @sql = 'Update #temptable set Code' + convert(varchar(4), @t4codenumber) + ' = ' + convert(varchar(16), @t4codeamt)
															+',RptBox'+ convert(varchar(4), @cntr)+'Cd'+ ' = '+ convert(varchar(4), @t4codenumber) 
											                +',RptBox' + convert(varchar(4), @cntr)+'Amt' + ' = ' + convert(varchar(16), @t4codeamt)
															+' where Employee = ' + convert(varchar(10), @employee) + ' and Seq = ' + convert(varchar(10), @seq)
                        end
                        
                 else
                        begin
							select @cntr = 1
							--#141794
							select @seq = 1 + max(Seq) from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @t4codeempl
							
							select @sql = 'Insert #temptable(PRCo, TaxYear, Employee, Seq, Code' + convert(varchar(4), @t4codenumber) 
											+',RptBox1Amt'+','+'RptBox1Cd' + ',Province'
											+ ' ) '
											+' values (' + convert(varchar(4), @prco) + ',''' + @taxyear + ''',' +  convert(varchar(10), @employee) + 
											',' + convert(varchar(10), @seq) + ',' + convert(varchar(16), @t4codeamt) +','+ convert(varchar(16), @t4codeamt)
											+',' + convert(varchar(4), @t4codenumber) 
											+','
											+ case when @box10province is null then 'null'
												else + '''' + convert(varchar(4), @box10province) + '''' end
											+ ')'                                 
                        end
                                                                     
				execute(@sql)

				delete @t4codes where PRCo = @prco and TaxYear = @taxyear and Employee = @employee and T4CodeNumber = @t4codenumber

				fetch next from empcodecurs into @employee, @t4codenumber, @t4codeamt
				select @cntr = @cntr + 1

			end --inner loop
			
			close empcodecurs
			deallocate empcodecurs

		end --1

		fetch next from emplcurs into @t4codeempl
	end --outer loop

	close emplcurs
	deallocate emplcurs
	
	
	--Set final SEQUENCE values for T4 slip output order 141794
	declare @sliporderempl integer, @sliporderprov varchar(4), @sliporderseq integer
	
	declare sliporderemplcurs cursor local fast_forward for 
	select distinct(Employee) from #temptable 
	where PRCo = @prco and TaxYear = @taxyear
	order by Employee

	open sliporderemplcurs
	fetch next from sliporderemplcurs into @sliporderempl
	
	while @@fetch_status = 0
	begin --outer loop

		--We need to modify sequence values only if employee has some Provincial wages (i.e., not Federal wages only)
		if exists(select 1 from #temptable where PRCo = @prco and TaxYear = @taxyear and Employee = @sliporderempl and Province is not NULL)
		begin --1
			
			--Multiply existing Seq values by 100 to prevent collisions
			update #temptable
			set Seq = Seq * 100
			where PRCo = @prco and TaxYear = @taxyear and Employee = @sliporderempl
			
			declare sliporderprovcurs cursor local fast_forward for 
			select Province, Seq from #temptable 
			where PRCo = @prco and TaxYear = @taxyear and Employee = @sliporderempl
			order by Province, Seq
			
			open sliporderprovcurs
			fetch next from sliporderprovcurs into @sliporderprov, @sliporderseq
			
			select @cntr = 0
			
			while @@fetch_status = 0
			begin --inner loop
			
				select @cntr = @cntr + 1

				--Set final sequence value here
				update #temptable
				set Seq = @cntr
				where PRCo = @prco and TaxYear = @taxyear and Employee = @sliporderempl and Province = @sliporderprov and Seq = @sliporderseq
				
				fetch next from sliporderprovcurs into @sliporderprov, @sliporderseq
				
			end --inner loop
			
			close sliporderprovcurs
			deallocate sliporderprovcurs
						
		end --1
		
		fetch next from sliporderemplcurs into @sliporderempl
		
	end --outer loop
	
	close sliporderemplcurs
	deallocate sliporderemplcurs	
	

	--Get the totals that will be used for the T4Summary
	select @totalBox14 = sum(isnull(t.Box14,0)), @totalBox16 = sum(isnull(t.Box16,0)), @totalBox18 = sum(isnull(t.Box18,0)), 
	@totalBox19 = sum(isnull(t.Box19,0)), @totalBox20 = sum(isnull(t.Box20,0)), @totalBox22 = sum(isnull(t.Box22,0)), 
	@totalBox27 = sum(isnull(t.Box27,0)), @totalBox52 = sum(isnull(t.Box52,0)), @totalslips = count(1)
	from PRCAEmployer r
	join PRCAEmployees e on r.PRCo = e.PRCo and r.TaxYear = e.TaxYear
	join #temptable t on e.PRCo = t.PRCo and e.Employee = t.Employee
	where r.PRCo = @prco and r.TaxYear = @taxyear

	select @totalDeductions = @totalBox16 + @totalBox27 + @totalBox18 + @totalBox19 + @totalBox22

	--THIS is the select statement for the FINAL RESULT SET that is returned by the stored procedure
	select r.TaxYear, e.Employee, h.SortName, t.Seq, r.BusinessNumber, '1' 'SubmitRefID', 'MM' + r.TransmitterNumber 'TransmitterNumber', '1' 'TransmitterType', '1' 'SummaryCount', 
	'E' 'LanguageCode', r.CompanyName, r.AddressLine1, r.AddressLine2, r.City, 
	CASE r.Country WHEN 'US' THEN r.Province WHEN 'CA' THEN r.Province ELSE 'ZZ' END AS 'Province', --141666
	case r.Country when 'US' then 'USA' WHEN 'CA' THEN 'CAN' else 'ZZZ' end as 'Country', 
	r.PostalCode, r.ContactName, 
	substring(replace(r.ContactPhone,'-',''), 1, 3) 'ContactAreaCode', 
	substring(replace(replace(replace(r.ContactPhone,'(',''),')',''), '-', ''),4,3) + '-' + 
	substring(replace(replace(replace(r.ContactPhone,'(',''),')',''), '-', ''), 7, len(r.ContactPhone)) 'ContactPhone',
	r.ContactPhoneExt, r.ContactEmail, r.ReturnType 'ReturnTypeCode', r.OwnerSIN 'OwnerSIN', r.CoOwnerSIN 'CoOwnerSIN', e.[SIN] 'EmployeeSIN', 
	e.FirstName, e.MidName, e.LastName, e.Suffix, e.AddressLine1 'EmployeeAddress1', e.AddressLine2 'EmployeeAddress2', e.City 'EmployeeCity', --141794
	CASE WHEN e.Province in ('AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU','ON', 'PE', 'QC', 'SK', 'YT', 'US') THEN e.Province else 'ZZ' end as 'EmployeeProv', --141666
	case e.Country when 'US' then 'USA' WHEN 'CA' THEN 'CAN' ELSE 'ZZZ' end as 'EmployeeCountry', e.PostalCode 'EmployeePostalCode', 
	case when e.ProvinceEmployed in ('AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU','ON', 'PE', 'QC', 'SK', 'YT', 'US') then e.ProvinceEmployed else 'ZZ' end as 'ProvinceEmployed', --141794
	case e.CPPQPPExempt when 'Y' then 1 else 0 end as 'CPPQPPExempt', case e.EIExempt when 'Y' then 1 else 0 end 'EIExempt', 
	case e.PPIPExempt when 'Y' then 1 else 0 end as 'PPIPExempt', e.RPPNumber, e.ReturnType 'EmpReturnType', t.FedBox14Wages,
	
	/*t.Province is the Province wages were posted to. e.ProvinceEmployed is the employee's "home province". */
	isnull(t.Province, e.ProvinceEmployed) as 'Box10', 
		
	t.ProvBox22IncomeTax, 
	t.ProvFedBox22IncTax, t.FedBox22IncTax, isnull(t.Box14,0) 'Box14',isnull(t.Box16,0) 'Box16',isnull(t.Box17,0) 'Box17', 
	isnull(t.Box18,0) 'Box18', isnull(t.Box19,0) 'Box19',isnull(t.Box20,0) 'Box20', isnull(Box22,0) 'Box22', isnull(t.Box24,0) 'Box24', 
	isnull(t.Box26,0) 'Box26', isnull(t.Code30,0) 'Code30', isnull(t.Code31,0) 'Code31', isnull(t.Code32,0) 'Code32', 
	isnull(t.Code33,0) 'Code33', isnull(t.Code34,0) 'Code34', isnull(t.Code35,0) 'Code35', isnull(t.Code36,0) 'Code36', 
	isnull(t.Code37,0) 'Code37', isnull(t.Code38,0) 'Code38', isnull(t.Code39,0) 'Code39', isnull(t.Code40,0) 'Code40', 
	isnull(t.Code41,0) 'Code41', isnull(t.Code42,0) 'Code42', isnull(t.Code43,0) 'Code43', isnull(t.Box44,0) 'Box44', 
	isnull(t.Box46,0) 'Box46', isnull(t.Box52,0) 'Box52', isnull(t.Code53,0) 'Code53', isnull(t.Box55,0) 'Box55', 
	isnull(t.Box56,0) 'Box56', 
	isnull(t.Code66,0) 'Code66', isnull(t.Code67,0) 'Code67', isnull(t.Code68,0) 'Code68', isnull(t.Code69,0) 'Code69', --141794
	isnull(t.Code70,0) 'Code70', isnull(t.Code71,0) 'Code71', isnull(t.Code72,0) 'Code72', 
	isnull(t.Code73,0) 'Code73', isnull(t.Code74,0) 'Code74', isnull(t.Code75,0) 'Code75', isnull(t.Code77,0) 'Code77', 
	isnull(t.Code78,0) 'Code78', isnull(t.Code79,0) 'Code79', isnull(t.Code80,0) 'Code80', isnull(t.Code81,0) 'Code81', 
	isnull(t.Code82,0) 'Code82', isnull(t.Code83,0) 'Code83', isnull(t.Code84,0) 'Code84', isnull(t.Code85,0) 'Code85',
	isnull(t.Code86,0) 'Code86', --141794
	isnull(t.Code97,0) 'Code97', isnull(t.Code98,0) 'Code98', isnull(t.Code99,0) 'Code99', @totalBox14 'T4SummaryTotalBox14', 
	@totalBox16 'T4SummaryTotalBox16', @totalBox18 'T4SummaryTotalBox18', @totalBox19 'T4SummaryTotalBox19', @totalBox20 
	'T4SummaryTotalBox20', @totalBox22 'T4SummaryTotalBox22', @totalBox27 'T4SummaryTotalBox27', @totalBox52 'T4SummaryTotalBox52', 
	@totalDeductions 'T4SummaryTotalDeductions', @totalslips 'T4SummaryTotalSlips', @remit 'T4SummaryRemittance', @amtenclosed 'T4SummaryAmountEnclosed',
	t.RptBox1Cd, t.RptBox2Cd, t.RptBox3Cd, t.RptBox4Cd, t.RptBox5Cd, t.RptBox6Cd,
	t.RptBox1Amt, t.RptBox2Amt, t.RptBox3Amt, t.RptBox4Amt, t.RptBox5Amt, t.RptBox6Amt, @sort 'Sort'
	from PRCAEmployer r
	join PRCAEmployees e on r.PRCo = e.PRCo and r.TaxYear = e.TaxYear
	join #temptable t on e.PRCo = t.PRCo and e.Employee = t.Employee
	join PREH h on e.PRCo = h.PRCo and e.Employee = h.Employee
	where r.PRCo = @prco and r.TaxYear = @taxyear
	Order By r.TaxYear, e.Employee, t.Seq --141794

		
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4SlipGenerate] TO [public]
GO
