SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************/
CREATE       proc [dbo].[bspHQPRStateUITotals]
/*************************************
* Created By:	GF 05/21/2002
* Modified By:	GF 10/24/2003	- issue #22807 - only employees with SUI wages greater than zero
*				GF 01/21/2005	- issue #26901 - for NY last quarter (12) show employees w/SUI Wages = zero
*				GF 03/15/2005	- issue #27361 - for 'MN' use Gross Wages, not SUI Wages
*				GF 07/14/2005	- issue #29280 - for 'MN' put back using SUI wages.
*				GF 05/04/2006	- issue #120994 - added total withholding and month counts for 'NM' changes
*				GF 05/08/2007	- issue #124526 - form 'ME' accumlate wages for all employees
*				MH 06/17/2010	- issue #139331 - Get total out of state eligible wages.
*				EN 10/29/2010	- issue #141722 - Get total workers comp for New Mexico reporting
*				CHS	01/20/2010	- issue #142618 - for 'ME' get total employees subject to withholding
*				CHS 10/21/2011	- issue B-02847	- for 'PA' get total sui to be paid 
*									by employer (@TotalSuiDue) and by employees (@TotalEmplSuiDue). 
*				CHS 11/16/2011	- D-03279 for 'OH' added @OutofStateSUIWagesYN
*				CHS 06/22/2012	- issue B-02847	- for 'PA' reworked @TotalEmplSuiDue
*				CHS 01/23/2012	- issue D-06540 - for 'PA' reworked @TotalEmplSuiDue & @TotalSUIDue
*				EN	01/28/2013	- TFS-73305	Return OutofStateSUIWages value for reporting in Michigan's 'E' record
*
* Returns Total Employees, Total Gross, Total SUIWages, Total ExcessWages, Total EligWages
*
***********************************/
 (@prco bCompany, @state bState, @quarter bDate, @totalempl int output, @totalgross bDollar output,
  @totalsui bDollar output, @totalexcess bDollar output, @totalelig bDollar output,
  @totalwithhd bDollar output, @mth1count integer output, @mth2count integer output, @mth3count integer output,
  @totaloselig bDollar output, @totalnmworkcomp bDollar output, @totalMEemplWH int output, 
  @TotalSuiDue bDollar output, @TotalEmplSuiDue bDollar output, @OutofStateSUIWagesYN bYN output,
  @OutofStateSUIWages bDollar output, @errmsg varchar(255) output)
 as
 set nocount on
  
 declare @rcode int, @taxrate bRate
  
 select @rcode = 0, @mth1count = 0, @mth2count = 0, @mth3count = 0
 
 select @OutofStateSUIWages = 0, @OutofStateSUIWagesYN = 'N'
 
 ---- B-02847	- for 'PA' get total sui to be paid by employer. 
 --select @taxrate = TaxRate from bPRUH
 --where PRCo=@prco and State=@state and Quarter=@quarter 
 
DECLARE @EmployerUILiabilityCode bEDLCode, @EmployeeUIDeductionCode bEDLCode, @firstmonth bMonth 

IF @state in ('PA','VT')
	BEGIN

	-- set variable for beginning month in quarter
	SET @firstmonth = dateadd(mm, -2, @quarter)
	
	-- get employee SUI deduction code
	SELECT @EmployeeUIDeductionCode = MIN(sd.DLCode)
	FROM bPRSD sd
	WHERE sd.PRCo = @prco 
		AND sd.State = @state 
		AND sd.BasedOn = 'U'		
	
	-- get employee SUI deduction amount due
	SELECT @TotalEmplSuiDue = ISNULL(SUM(a.Amount), 0)
	FROM dbo.bPREA a WITH (NOLOCK)
	WHERE	a.PRCo = @prco 
			AND a.Mth >= @firstmonth AND a.Mth <= @quarter -- @quarter is last month in the quarter
			AND a.EDLType = 'D' AND a.EDLCode = @EmployeeUIDeductionCode
			
	-- get employer SUI liability code
	SELECT @EmployerUILiabilityCode = si.SUTALiab
	FROM bPRSI si
	WHERE si.PRCo = @prco AND si.State = @state				

	-- get employer SUI liability amount due			
	SELECT @TotalSuiDue = ISNULL(SUM(a.Amount), 0)
	FROM dbo.bPREA a WITH (NOLOCK)
	WHERE	a.PRCo = @prco 
			AND a.Mth >= @firstmonth AND a.Mth <= @quarter
			AND a.EDLType = 'L' AND a.EDLCode = @EmployerUILiabilityCode
	
	END
 
if @state = 'ME' 
	begin
 	select @totalempl = count(1), @totalgross = isnull(sum(bPRUE.GrossWages),0),
 		   @totalsui = isnull(sum(bPRUE.SUIWages),0), @totalexcess = isnull(sum(bPRUE.ExcessWages),0),
 		   @totalelig = isnull(sum(bPRUE.EligWages),0), @totalwithhd = isnull(sum(bPRUE.StateTax),0),
		@mth1count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
				and Quarter>=@quarter and Quarter<=@quarter and Mth1 <> 0),
		@mth2count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
				and Quarter>=@quarter and Quarter<=@quarter and Mth2 <> 0),
		@mth3count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
				and Quarter>=@quarter and Quarter<=@quarter and Mth3 <> 0),
		@totaloselig = isnull(sum(p2.YTDOutofStateEligWages),0)
		
 	from bPRUE with (nolock) 
 		--This code is borrowed from bspHQPRStateUnemployment.  Can be expanded as needed to pull other amounts.
 	   	Left Join (
		----get year to date   	
		select b.PRCo, b.Employee, sum(b.EligWages) 'YTDOutofStateEligWages'
		from bPRUE b
		where b.PRCo = @prco and b.Quarter = @quarter and b.State <> @state
		group by b.PRCo, b.Employee) as p2
		on bPRUE.PRCo = p2.PRCo and bPRUE.Employee = p2.Employee  
		 	
 	where bPRUE.PRCo=@prco and bPRUE.State=@state and bPRUE.Quarter>=@quarter and bPRUE.Quarter<=@quarter
 	and bPRUE.SUIWages >= 0

	
	select @totalMEemplWH = count(1) -- #142618 - get total employees subject to withholding
	from bPRUE with (nolock)
 		
 	   	Left Join (
		----get year to date   	
		select b.PRCo, b.Employee, sum(b.EligWages) 'YTDOutofStateEligWages'
		from bPRUE b
		where b.PRCo = @prco and b.Quarter = @quarter and b.State <> @state
		group by b.PRCo, b.Employee) as p2
		on bPRUE.PRCo = p2.PRCo and bPRUE.Employee = p2.Employee  
		 	
 	where bPRUE.PRCo=@prco and bPRUE.State=@state and bPRUE.Quarter>=@quarter and bPRUE.Quarter<=@quarter
 	and bPRUE.StateTax > 0
 	
	goto bspexit
	end

 -- -- -- #27361 for 'MN' use gross - #29280 'MN' back to using SUI
 if @state = 'MN'
 	begin
 	select @totalempl = count(1), @totalgross = isnull(sum(bPRUE.GrossWages),0),
 			@totalsui = isnull(sum(bPRUE.SUIWages),0), @totalexcess = isnull(sum(bPRUE.ExcessWages),0),
 			@totalelig = isnull(sum(bPRUE.EligWages),0), @totalwithhd = isnull(sum(bPRUE.StateTax),0),
		@mth1count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
				and Quarter>=@quarter and Quarter<=@quarter and Mth1 <> 0),
		@mth2count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
				and Quarter>=@quarter and Quarter<=@quarter and Mth2 <> 0),
		@mth3count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
				and Quarter>=@quarter and Quarter<=@quarter and Mth3 <> 0),
		@totaloselig = isnull(sum(p2.YTDOutofStateEligWages),0)
				
 	from bPRUE with (nolock) 
 	 	--This code is borrowed from bspHQPRStateUnemployment.  Can be expanded as needed to pull other amounts.
 	   	Left Join (
		----get year to date   	
		select b.PRCo, b.Employee, sum(b.EligWages) 'YTDOutofStateEligWages'
		from bPRUE b
		where b.PRCo = @prco and b.Quarter = @quarter and b.State <> @state
		group by b.PRCo, b.Employee) as p2
		on bPRUE.PRCo = p2.PRCo and bPRUE.Employee = p2.Employee  
 	
 	where bPRUE.PRCo=@prco and bPRUE.State=@state and bPRUE.Quarter>=@quarter and bPRUE.Quarter<=@quarter
 	and bPRUE.SUIWages > 0
 	end
 else
 	begin
 	select @totalempl = count(1), @totalgross = isnull(sum(bPRUE.GrossWages),0),
 			@totalsui = isnull(sum(bPRUE.SUIWages),0), @totalexcess = isnull(sum(bPRUE.ExcessWages),0),
 			@totalelig = isnull(sum(bPRUE.EligWages),0), @totalwithhd = isnull(sum(bPRUE.StateTax),0),
			@totalnmworkcomp = isnull(sum(bPRUE.DLCode1Amt),0) + isnull(sum(bPRUE.DLCode2Amt),0), --#141722 get total workers comp for New Mexico
			@mth1count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
					and Quarter>=@quarter and Quarter<=@quarter and Mth1 <> 0),
			@mth2count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
					and Quarter>=@quarter and Quarter<=@quarter and Mth2 <> 0),
			@mth3count = (select count(1) from bPRUE with (nolock) where PRCo=@prco and State=@state 
					and Quarter>=@quarter and Quarter<=@quarter and Mth3 <> 0),
			@totaloselig = isnull(sum(p2.YTDOutofStateEligWages),0),
			--@TotalSuiDue = isnull(@taxrate, 0) * isnull(sum(bPRUE.EligWages),0), --B-02847 CHS
			--@TotalEmplSuiDue = isnull(sum(p3.TotalUCIPaidByEployees),0),			--B-02847 CHS
			@OutofStateSUIWages = sum(p2.OutofStateSUIWages) -- D-03279 CHS
				
 	from bPRUE with (nolock)
 		--This code is borrowed from bspHQPRStateUnemployment.  Can be expanded as needed to pull other amounts.
 	   	Left Join (
			----get year to date   	
			select b.PRCo, b.Employee, sum(b.EligWages) 'YTDOutofStateEligWages', sum(b.SUIWages) 'OutofStateSUIWages' --D-03279 
			from bPRUE b
			where b.PRCo = @prco and b.Quarter = @quarter and b.State <> @state
			group by b.PRCo, b.Employee) 
				as p2 on bPRUE.PRCo = p2.PRCo and bPRUE.Employee = p2.Employee  
				
		--Left Join (
		--			-- get total amounts paid by employees for UCI for PA
		--			select e.PRCo, sum(e.GrossWages) * l.RateAmt1 'TotalUCIPaidByEployees', e.Employee
		--			from bPRUE e
		--				join bPRSI i on i.PRCo = e.PRCo and i.State = e.State
		--				join bPRDL l on l.PRCo = i.PRCo and l.DLCode = i.DLCode1
		--			where e.PRCo = @prco
		--				and e.State = @state
		--				and e.Quarter = @quarter 
		--			group by e.PRCo, e.GrossWages, l.RateAmt1, e.Employee
		--			) as p3 on bPRUE.PRCo = p3.PRCo and bPRUE.Employee = p3.Employee  --B-02847 CHS
			
		
 	where bPRUE.PRCo=@prco and bPRUE.State=@state and bPRUE.Quarter>=@quarter and bPRUE.Quarter<=@quarter
 	-- -- -- issue #26901
 	and ((bPRUE.State <> 'NY' and bPRUE.SUIWages > 0)
 	or (bPRUE.State = 'NY' and month(@quarter) <> 12 and bPRUE.SUIWages > 0)
 	or (bPRUE.State = 'NY' and month(@quarter) = 12 and bPRUE.SUIWages >= 0))
 	
 	--D-03279 
 	select @OutofStateSUIWagesYN = case when (@totalsui > 0 and @OutofStateSUIWages > 0) then 'Y' else 'N' end
 	
 	end


bspexit:
 	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspHQPRStateUITotals] TO [public]
GO
