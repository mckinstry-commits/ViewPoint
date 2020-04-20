SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUnemplWageInit    Script Date: 8/28/99 9:35:40 AM ******/
  CREATE        procedure [dbo].[bspPRUnemplWageInit]
   /************************************************************
    * CREATED BY: 	 EN 2/23/99
    * MODIFIED By : EN 3/30/99
    *          By : DANF 01/06/00
    *          By : JC  4/19/00	--added ISNULL's to @phone and @unempid
    *          By : Danf added Message for missing Federal ID.
    *          By : GF 09/12/2000 additional columns for NY electronic filing
    *          By : GF 01/11/2001 additional columns for MMREF-1 electronic filing
    *          By : EN 1/18/01  added list of fields to PRUH insert and 2nd PRUE insert and updated PRUE insert list to include new ReportUnit and Industry fields
    *               GF 02/13/2001 - issue #  for NY, need to include all employees with YTD wages.
    *               GF 08/20/2001 - pull plant, branch from PRSI into PRUH
    *               GF 08/28/2001 - pull Local Code Amounts into PRUE buckets
    *				  GF 04/03/2002 - added suffix to intitialize for PRUE
    *				  GF 04/17/2002 - Fix for 'PA'. Do not strip dash out of @unemplid.
    *				  EN 10/09/2002 - issue 18877 change double quotes to single
    *				  GF 11/04/2003 - issue #22900 - annual wages and tax including future months
    *				  GF 11/06/2003 - issue #22884 - changed description to electronic filing
    *				  GF 05/09/2006 - issue #120994 - pull in PRUE.DLCode1 and PRUE.DLCode2 information from PRSI.
    *				  GF 10/31/2006 - issue #122925 - one more column for 'NM', PRUH.Penalty2
    *				  GF 01/29/2007 - issue #123715 - need to use NY state tax when initalizing 12/?? for new york. Need all employees in state with state tax amount.
    *				  mh 4/4/07 - issue 28007 - need to include PRSI.WagePlan
    *				  mh 4/12/07 - issue 28009 - Initializing MultiCountry, MultiLocation, MultiIndicator, and EFTIndicator as 0
	*											as opposed to null.
	*				  mh 4/13/07 - issue 28010 - Only initializing states that have employees to initialize.  
    *				  mh 9/20/07 - Issue 124225 - EMail added to PRSI.  Need to copy over to PRUH
    *				GF 10/29/2007 - issue #125648 changed to accumulate hours and weeks for Rhode Island (RI) 
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
	*				MH 09/09/2008 - issue #128713 - Add NACIS codes for WY
	*				mh 09/16/2008 - issue #128713 - Added calculation for AnnualGrossWage (YTDWages) 
	*				mh 01/21/2009 - issue #131924 - Correct 28010 change.  Need to include employees that have 
	*						have no suta but have state tax deductions.
	*				mh 04/15/2010 - Issue 139086 - Include State Taxable Wages in State Tax Dedudn update to PRUE.
	*				mh 05/18/2010 - Issue 139559 - more problems with MA.  Need to include employees that do not have
	*					SUTA liabilty but have income tax deduction.
	*				GF 09/10/2010 - issue #141031 changed to use vfDateOnly
	*				LS 02/24/2011 - #142860 Remove local code amounts for NY included in AnnualStateTax
    *				EN 11/13/2012 - D-04315/#143616/TK-19201 NY needs to report quarterly for 1st 3 qtrs and annual on 4 qtr
    *				CHS	10/11/2013	- Clientele 145752, TFS 38990 for NY 4th qtr only, Annual Gross Wages needs to include all states
    *
    
		While working a 5.x update I ran across something that could be a problem.  See the "potental problem" tag below.
		We insert entries into PRUE.  GrossWages is one of them.  That is the Subject Wages for the unemployment liability
		code specified in the PRSI.  Later on we update this field, PRUE.GrossWages, to the sum of the subject wages for
		the deduction code specified for income tax in PRSI.  My concern is what if a state that does not have income tax 
		(AK, FL, NV, NH, TN, TX, WA, WY) adopts a change to show GrossWages?  So far no complaints so no change.  Just
		making a note of this.
		
    
    *
    * USAGE:
    * Initializes Quarterly Unemployment/Wage reporting data in bPRUH and bPRUE.
    *
    * INPUT PARAMETERS
    *   @prco      PR Co#
    *   @state	state to initialize, null to initialzie all states
    *   @quarter   quarter ending month
    *   @reinit	'Y' = reinitialize existing information, 'N' = skip if already exists
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    *
    * RETURN VALUE
    *   0   	success
    *   1   	fail
    ************************************************************/
  @prco bCompany, @state varchar(4), @quarter bMonth, @reinit char(1), @reccount int output, @errmsg varchar(255) output
  as
  set nocount on
  
declare @rcode int, @firstmonth bMonth, @marker int, @EIN varchar(11), @uistate varchar(4),
  		@opencursor tinyint, @sutaliab bEDLCode, @phone varchar(15), @unempid varchar(20), 
  		@rateamt1 Decimal(16,5), @firstofyear bMonth, @year varchar(4),
		@month integer, @qtr_begindate bDate, @qtr_enddate bDate, @openrionly tinyint,
		@employee bEmployee, @hrsworked smallint, @wksworked int

select @rcode = 0, @opencursor = 0, @reccount = 0, @openrionly = 0

---- set date values
set @year = convert(varchar(4),year(convert(smalldatetime,@quarter)))
set @month = convert(integer,month(convert(smalldatetime,@quarter)))
set @firstofyear = '01/01/' + @year

---- set quarter dates
if @month = 3
	begin
	select @qtr_begindate = '01/01/' + @year, @qtr_enddate = '03/31/' + @year
	end
if @month = 6
	begin
	select @qtr_begindate = '04/01/' + @year, @qtr_enddate = '06/30/' + @year
	end
if @month = 9
	begin
	select @qtr_begindate = '07/01/' + @year, @qtr_enddate = '09/30/' + @year
	end
if @month = 12
	begin
	select @qtr_begindate = '10/01/' + @year, @qtr_enddate = '12/31/' + @year
	end

---- validate State
	if @state is not null
	begin
		select @uistate = State, @sutaliab = SUTALiab 
		from bPRSI with (nolock) where PRCo = @prco and State = @state

		if @@rowcount = 0
		begin
			select @errmsg = @state + ' is not setup in PR State Information table.', @rcode = 1
			goto bspexit
		end

		if @sutaliab is null
		begin
			select @errmsg = @state + ' is missing SUTA liability setup information.', @rcode = 1
			goto bspexit
		end
	end
   
	-- verify Quarter
	if datepart(mm,@quarter) not in (3,6,9,12)
   	begin
   		select @errmsg = 'Quarter ending month must be 3/yy, 6/yy, 9/yy or 12/yy.', @rcode = 1
   		goto bspexit
   	end
   
	-- Initialize Unemployment Reporting Information
   
	-- set variable for beginning month in quarter
	set @firstmonth = dateadd(mm, -2, @quarter)
   
	-- get EIN - strip hyphens from Federal Tax ID */
	select @EIN = ltrim(rtrim(FedTaxId)) from bHQCO with (nolock) where HQCo = @prco
	select @marker = charindex('-', @EIN)

	If @marker is null
	begin
		select @errmsg = 'Missing Federal Tax Id from Head Quarters.', @rcode = 1
		goto bspexit
	end
	else
  	
	while @marker <> 0
  	begin
  		select @EIN = substring(@EIN, 1, @marker-1) + substring(@EIN, @marker+1, 11-@marker)
  		select @marker = charindex('-', @EIN)
  	end


---- if initializing for all States use a cursor
if @state is null
	begin
	declare bcState cursor FAST_FORWARD
	for select State 
   	from bPRSI where PRCo = @prco and SUTALiab is not null
   
	open bcState
	select @opencursor = 1
    
	fetch next from bcState into @uistate
	if @@fetch_status <> 0 goto State_End
	end
   
   
init_State:	-- initialize State header and Employee detail Unemployment info
   	-- based on 'reinit' option, clear existing Employee and State info, or skip

   	if @reinit = 'Y'
	begin
   		delete FROM bPRUE where PRCo = @prco and State = @uistate and Quarter = @quarter
   		delete FROM bPRUH where PRCo = @prco and State = @uistate and Quarter = @quarter
	end
   	else
   		if exists(select 1 from bPRUH with (nolock) where PRCo = @prco and State = @uistate and Quarter = @quarter) 
			goto next_State

	--mh #131924 - corrected query
	--mh 28010 If there are no employees then do not initialize state.
--	if (select count(h.PRCo)
--  		from bPREH h with (nolock)
--   		join bPRSI s with (nolock) on s.PRCo = h.PRCo
--   		join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
--   		where h.PRCo = @prco and s.State = @uistate and a.Mth >= @firstmonth and a.Mth <= @quarter
--   		and a.EDLType = 'L' and a.EDLCode = s.SUTALiab) = 0
--	begin
--		goto next_State
--	end
   
	if (select count(a.PRCo)
	from bPREA a
	join bPRSI s on a.PRCo = s.PRCo and (a.EDLCode = s.TaxDedn or a.EDLCode = s.SUTALiab)
	where a.PRCo = @prco and s.State = @uistate and (Mth >= @firstmonth or Mth < @quarter)) = 0
	begin
		goto next_State
	end

	--end #131924

   	-- get phone # and UnempID and strip out hyphens
   	select @phone = Isnull(ltrim(rtrim(Phone)),''), @unempid = isnull(ltrim(rtrim(UnempID)),'')
  	from bPRSI with (nolock) where PRCo = @prco and State = @uistate
   
   	select @marker = charindex('-', @phone)
    
	If @marker is null select @marker = 0

   	while @marker <> 0
   	begin
   		select @phone = substring(@phone, 1, @marker-1) + substring(@phone, @marker+1, 15-@marker)
   		select @marker = charindex('-', @phone)
	end
   
   	if @uistate <> 'PA'
	begin
		select @marker = charindex('-', @unempid)

		If @marker is null select @marker = 0

		while @marker <> 0
		begin
			select @unempid = substring(@unempid, 1, @marker-1) + substring(@unempid, @marker+1, 20-@marker)
			select @marker = charindex('-', @unempid)
		end
	end
   

	-- add Unemployment State header
	select @sutaliab = SUTALiab from bPRSI with (nolock) where PRCo = @prco and State = @uistate

	select @rateamt1 = isnull(RateAmt1,0)
	from bPRDL with (nolock) where PRCo=@prco and DLCode=@sutaliab

	--Issue 28009   mh 4/12/07
  	insert bPRUH (PRCo, State, Quarter, EIN, CoName, Address, City, CoState, Zip, ZipExt, Contact,
                       Phone, PhoneExt, TransId, C3, SuffixCode, TotalRemit, CreateDate, Computer,
                       EstabId, StateId, UnempID, TaxType, TaxEntity, ControlId, UnitId, OtherEIN,
                       TaxRate, PrevUnderPay, Interest, Penalty, OverPay, AssesRate1, AssesAmt1,
                       AssessRate2, AssessAmt2, TotalDue, AllocAmt, County, OutCounty, DocControl,
                       MultiCounty, MultiLocation, MultiIndicator, ElectFundTrans, FilingType,
                       LocAddress, Plant, Branch, Penalty2, EMail)

   	select @prco, @uistate, @quarter, convert(char(9),@EIN), convert(varchar(50),h.Name),
   		convert(varchar(40),h.Address), convert(varchar(25),h.City), h.State,
   		substring(h.Zip,1,5), substring(h.Zip,7,5), s.Contact, @phone, s.PhoneExt, s.TransId, s.C3,
   		s.SuffixCode, 0,
   		----#141031
   		dbo.vfDateOnly(),
   		null, s.EstabId, s.StateId, @unempid, s.TaxType,
   		s.TaxEntity, s.ControlId, s.UnitId, null,@rateamt1,
   		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, s.County, s.OutCounty, s.DocControl,
           0,0,0,0,'O', substring(h.Address2,1,22), s.Plant, s.Branch, 0, s.EMail
  	from bPRSI s with (nolock)
      join bHQCO h with (nolock) on s.PRCo = h.HQCo
   	where s.PRCo = @prco and s.State = @uistate

   	if @@rowcount <> 1
	begin
		select @errmsg = 'Could not add Unemployment/Wage Header for ' + @uistate + '.  Initialization cancelled!', @rcode = 1
		goto bspexit
	end
	else
		select @reccount = @reccount + 1

   	-- initialize bPRUE - include unemployment liability amounts, but not taxes
   	insert bPRUE (PRCo, State, Quarter, Employee, SSN, FirstName, MidName, LastName, Suffix, GrossWages, SUIWages,
                       ExcessWages, EligWages, DisWages, TipWages, WksWorked, HrsWorked, StateTax, Seasonal, HealthCode1,
                       HealthCode2, ProbCode, Officer, WagePlan, Mth1, Mth2, Mth3, EmplDate, SepDate, SUIWageType,
                       AnnualGrossWage, AnnualStateTax, ReportUnit, Industry, NAICS )

   	select @prco, @uistate, @quarter, h.Employee,
   		substring(h.SSN, 1, 3) + substring(h.SSN, 5, 2) + substring(h.SSN, 8, 4),
   		upper(h.FirstName), upper(h.MidName), upper(h.LastName), upper(h.Suffix), 0, sum(a.SubjectAmt),
   		sum(a.SubjectAmt) - sum(a.EligibleAmt), sum(a.EligibleAmt), 0, 0,
   		isnull(sum(CASE WHEN s.AccumHrsWks = 'W' THEN a.Hours ELSE 0 END),0),
   		isnull(sum(CASE WHEN s.AccumHrsWks = 'H' THEN a.Hours ELSE 0 END),0),
   		0, null, null, null, null, '0', s.WagePlan, --mh 4/4/07 Add WagePlan
   		CASE WHEN exists (select 1 from bPRTH t		-- worked in a Pay Pd containing the 12th day of the 1st month
   			join bPREH h1 on h1.PRCo = t.PRCo and h1.Employee = t.Employee
   			join bPRPC p on p.PRCo = t.PRCo and p.PRGroup = t.PRGroup and p.PREndDate = t.PREndDate
   			where p.BeginDate <=dateadd (dd, 11, dateadd(mm, -2, @quarter))
   			and p.PREndDate >=dateadd (dd, 11, dateadd(mm, -2, @quarter))
   			and p.PRCo = @prco and t.UnempState = @uistate and h1.Employee = h.Employee)
   			THEN '1' ELSE '0' END,
   		CASE WHEN exists (select 1 from bPRTH t		-- worked in a Pay Pd containing the 12th day of the 2nd month
   			join bPREH h1 on h1.PRCo = t.PRCo and h1.Employee = t.Employee
   			join bPRPC p on p.PRCo = t.PRCo and p.PRGroup = t.PRGroup and p.PREndDate = t.PREndDate
   			where p.BeginDate <=dateadd (dd, 11, dateadd(mm, -1, @quarter))
   			and p.PREndDate >=dateadd (dd, 11, dateadd(mm, -1, @quarter))
   			and p.PRCo = @prco and t.UnempState = @uistate and h1.Employee = h.Employee)
   			THEN '1' ELSE '0' END,
   		CASE WHEN exists (select 1 from bPRTH t		-- worked in a Pay Pd containing the 12th day of the 3rd month
   			join bPREH h1 on h1.PRCo = t.PRCo and h1.Employee = t.Employee
   			join bPRPC p on p.PRCo = t.PRCo and p.PRGroup = t.PRGroup and p.PREndDate = t.PREndDate
   			where p.BeginDate <=dateadd (dd, 11, @quarter)
   			and p.PREndDate >=dateadd (dd, 11, @quarter)
   			and p.PRCo = @prco and t.UnempState = @uistate and h1.Employee = h.Employee)
   			THEN '1' ELSE '0' END,
   		h.HireDate, h.TermDate,'W',0,0,null,null, h.NAICS
   	from bPREH h with (nolock)
   	join bPRSI s with (nolock) on s.PRCo = h.PRCo
   	join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
   	where h.PRCo = @prco and s.State = @uistate and a.Mth >= @firstmonth and a.Mth <= @quarter
   	and a.EDLType = 'L' and a.EDLCode = s.SUTALiab
   	group by h.PRCo, h.Employee, h.SSN, h.FirstName, h.MidName, h.LastName, h.Suffix, h.HireDate, h.TermDate, s.WagePlan, h.NAICS
 

 	-- -- -- insert employees who do not work in the quarter - we need to pick up YTD wages -- New York only
 	if @uistate='NY' and datepart(mm,@quarter) in (12)
	begin
 		insert bPRUE (PRCo, State, Quarter, Employee, SSN, FirstName, MidName, LastName, Suffix, GrossWages, SUIWages,
                       ExcessWages, EligWages, DisWages, TipWages, WksWorked, HrsWorked, StateTax, Seasonal, HealthCode1,
                       HealthCode2, ProbCode, Officer, WagePlan, Mth1, Mth2, Mth3, EmplDate, SepDate, SUIWageType,
                       AnnualGrossWage, AnnualStateTax, ReportUnit, Industry )
 		select @prco, @uistate, @quarter, h.Employee,
 			substring(h.SSN, 1, 3) + substring(h.SSN, 5, 2) + substring(h.SSN, 8, 4),
      		upper(h.FirstName), upper(h.MidName), upper(h.LastName), upper(h.Suffix), 0, 0,
      		0, 0, 0, 0, 0, 0, 0, null, null, null, null, '0', s.WagePlan, --4/4/07 mh
			0,0,0, h.HireDate, h.TermDate,'W',0,0,null,null
 		from bPREH h with (nolock) 
 		join bPRSI s with (nolock) on s.PRCo = h.PRCo
 		join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
 		where h.PRCo = @prco and s.State = @uistate and Year(a.Mth) =Year(@quarter) and a.Mth <= @quarter
 		and a.EDLType = 'L' and a.EDLCode = s.SUTALiab
 		and not exists( select top 1 1 from bPRUE with (nolock) where PRCo=@prco and State=@uistate and Quarter=@quarter and Employee=h.Employee)
 		group by h.PRCo, h.Employee, h.SSN, h.FirstName, h.MidName, h.LastName, h.Suffix, h.HireDate, h.TermDate, s.WagePlan
 	

	end
	
	if @uistate = 'MA' or (@uistate='NY' and datepart(mm,@quarter) in (12)) 
	begin			
		---- add any employees with no suta but have 'NY' state tax
		insert bPRUE (PRCo, State, Quarter, Employee, SSN, FirstName, MidName, LastName, Suffix, GrossWages, SUIWages,
                       ExcessWages, EligWages, DisWages, TipWages, WksWorked, HrsWorked, StateTax, Seasonal, HealthCode1,
                       HealthCode2, ProbCode, Officer, WagePlan, Mth1, Mth2, Mth3, EmplDate, SepDate, SUIWageType,
                       AnnualGrossWage, AnnualStateTax, ReportUnit, Industry )
 		select @prco, @uistate, @quarter, h.Employee,
 			substring(h.SSN, 1, 3) + substring(h.SSN, 5, 2) + substring(h.SSN, 8, 4),
      		upper(h.FirstName), upper(h.MidName), upper(h.LastName), upper(h.Suffix), 0, 0,
      		0, 0, 0, 0, 0, 0, 0, null, null, null, null, '0', s.WagePlan, --4/4/07 mh
			0,0,0, h.HireDate, h.TermDate,'W',0,0,null,null
 		from bPREH h with (nolock) 
 		join bPRSI s with (nolock) on s.PRCo = h.PRCo
 		join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
 		where h.PRCo = @prco and s.State = @uistate and Year(a.Mth) =Year(@quarter) and a.Mth <= @quarter
 		and a.EDLType = 'D' and a.EDLCode = s.TaxDedn
 		and not exists( select top 1 1 from bPRUE with (nolock) where PRCo=@prco and State=@uistate and Quarter=@quarter and Employee=h.Employee)
 		group by h.PRCo, h.Employee, h.SSN, h.FirstName, h.MidName, h.LastName, h.Suffix, h.HireDate, h.TermDate, s.WagePlan
	end

	--potental problem 
 	-- -- -- update bPRUE entries with state tax dedn amounts and state taxable wages
	
 	update bPRUE set GrossWages = isnull((select sum(a.SubjectAmt)
 	from bPREH h with (nolock) 
  	join bPRSI s with (nolock) on s.PRCo = h.PRCo
   	join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
   	where h.PRCo = @prco and h.Employee = u.Employee and s.State = @uistate
   	and a.Mth >= @firstmonth and a.Mth <= @quarter
  	and a.EDLType = 'D' and a.EDLCode = s.TaxDedn),0),

	StateTaxableWages = isnull((select sum(a.EligibleAmt)
 	from bPREH h with (nolock) 
  	join bPRSI s with (nolock) on s.PRCo = h.PRCo
   	join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
   	where h.PRCo = @prco and h.Employee = u.Employee and s.State = @uistate
   	and a.Mth >= @firstmonth and a.Mth <= @quarter
  	and a.EDLType = 'D' and a.EDLCode = s.TaxDedn),0),
   
 	StateTax = isnull((select sum(a.Amount)
 	from bPREH h with (nolock) 
  	join bPRSI s with (nolock) on s.PRCo = h.PRCo
   	join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
   	where h.PRCo = @prco and h.Employee = u.Employee and s.State = @uistate
   	and a.Mth >= @firstmonth and a.Mth <= @quarter
   	and a.EDLType = 'D' and a.EDLCode = s.TaxDedn),0)
   	from bPRUE u 
   	where PRCo = @prco and State = @uistate and Quarter = @quarter
   
 	if @uistate <> 'MO'
	begin
       	-- -- -- make sure to include employees with state tax but no SUTA
       	insert bPRUE ( PRCo, State, Quarter, Employee, SSN, FirstName, MidName, LastName, Suffix, GrossWages, SUIWages,
                           ExcessWages, EligWages, DisWages, TipWages, WksWorked, HrsWorked, StateTax, Seasonal, HealthCode1,
                           HealthCode2, ProbCode, Officer, WagePlan, Mth1, Mth2, Mth3, EmplDate, SepDate, SUIWageType,
                           AnnualGrossWage, AnnualStateTax, ReportUnit, Industry)
       	select h.PRCo, @uistate, @quarter, h.Employee,
   		substring(h.SSN, 1, 3) + substring(h.SSN, 5, 2) + substring(h.SSN, 8, 4),
   		upper(h.FirstName), upper(h.MidName),
       	upper(h.LastName), upper(h.Suffix), sum(a.SubjectAmt), 0, 0, 0, 0, 0, 0, 0, sum(a.Amount),
       	null, null, null, null, '0', s.WagePlan, --4/4/07 mh
		'0', '0', '0', h.HireDate, h.TermDate,'W',0,0,null,null
       	from bPREH h with (nolock) 
  		join bPRSI s with (nolock) on s.PRCo = h.PRCo
       	join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
       	where h.PRCo = @prco and s.State = @uistate
       	and a.Mth >= @firstmonth and a.Mth <= @quarter
       	and a.EDLType = 'D' and a.EDLCode = s.TaxDedn
       	and not exists (select top 1 1 from bPRUE with (nolock) where PRCo = h.PRCo and State = @uistate
       					and Quarter = @quarter and Employee = h.Employee)
       	group by h.PRCo, h.Employee, h.SSN, h.FirstName, h.MidName, h.LastName, h.Suffix, h.HireDate, h.TermDate, s.WagePlan
	end

 	-- -- -- update bPRUE with annual gross wage and annual state tax
 	IF @uistate='NY'
 	BEGIN
 		IF DATEPART(mm,@quarter) < 12 --in first 3 quarters, report quarterly amounts using @firstmonth
 		BEGIN
 			UPDATE dbo.bPRUE SET 
 				AnnualGrossWage = ISNULL((SELECT SUM(a.SubjectAmt)
 				FROM dbo.bPREH h WITH (NOLOCK) 
 				JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 				JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 				WHERE  h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					   AND a.Mth >= @firstmonth AND a.Mth <= @quarter
 					   AND a.EDLType = 'D' AND a.EDLCode = s.TaxDedn),0),
 				AnnualStateTax = ISNULL((SELECT SUM(a.Amount)
 				FROM dbo.bPREH h WITH (NOLOCK) 
 				JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 				JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 				WHERE  h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					   AND a.Mth >= @firstmonth AND a.Mth <= @quarter
 					   AND a.EDLType = 'D' AND a.EDLCode = s.TaxDedn),0)
 				FROM dbo.bPRUE u
 				WHERE PRCo = @prco AND [State] = @uistate AND [Quarter] = @quarter
 		END
 		ELSE IF DATEPART (mm,@quarter) = 12 --last quarter of the year, report annual amounts using @firstofyear
 		BEGIN
 			UPDATE dbo.bPRUE SET 
 				AnnualGrossWage = ISNULL((SELECT SUM(a.SubjectAmt)
 				FROM dbo.bPREH h WITH (NOLOCK) 
 				JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 				JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 				WHERE  h.PRCo = @prco AND h.Employee = u.Employee --AND s.[State] = @uistate -- CHS	10/11/2013
 					   AND a.Mth >= @firstofyear AND a.Mth <= @quarter
 					   AND a.EDLType = 'D' AND a.EDLCode = s.TaxDedn),0),
 				AnnualStateTax = ISNULL((SELECT SUM(a.Amount)
 				FROM dbo.bPREH h WITH (NOLOCK) 
 				JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 				JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 				WHERE  h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					   AND a.Mth >= @firstofyear AND a.Mth <= @quarter
 					   AND a.EDLType = 'D' AND a.EDLCode = s.TaxDedn),0)
 				FROM dbo.bPRUE u
 				WHERE PRCo = @prco AND [State] = @uistate AND [Quarter] = @quarter
 		END
 	END
	ELSE IF @uistate = 'WY'
	BEGIN
 		UPDATE dbo.bPRUE SET AnnualGrossWage = ISNULL((SELECT SUM(a.SubjectAmt)
 		FROM dbo.bPREH h WITH (NOLOCK) 
 		JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 		JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 		WHERE	h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 				AND a.Mth >= @firstofyear AND a.Mth <= @quarter
 				AND a.EDLType = 'L' AND a.EDLCode = s.SUTALiab),0)
		FROM dbo.bPRUE u
		WHERE PRCo = @prco AND [State] = @uistate AND [Quarter] = @quarter
	END
	ELSE
	BEGIN
 		UPDATE dbo.bPRUE SET 
 			AnnualGrossWage = ISNULL((SELECT SUM(a.SubjectAmt)
 			FROM dbo.bPREH h WITH (NOLOCK) 
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE  h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 				   AND a.Mth >= @firstofyear AND a.Mth <= @quarter
 				   AND a.EDLType = 'D' AND a.EDLCode = s.TaxDedn),0),
 			AnnualStateTax = ISNULL((SELECT SUM(a.Amount)
 			FROM dbo.bPREH h WITH (NOLOCK) 
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE  h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 				   AND a.Mth >= @firstofyear AND a.Mth <= @quarter
 				   AND a.EDLType = 'D' AND a.EDLCode = s.TaxDedn),0)
		FROM dbo.bPRUE u
		WHERE PRCo = @prco AND [State] = @uistate AND [Quarter] = @quarter
	END
	
 	-- -- -- update bPRUE with local code amounts assigned in bPRSI
 	IF @uistate='NY'
 	BEGIN
 		IF DATEPART(mm,@quarter) < 12 --in first 3 quarters, report quarterly amounts using @firstmonth
 		BEGIN
 	 		UPDATE dbo.bPRUE SET 
 			Loc1Amt = ISNULL((SELECT SUM(a.Amount)
 			FROM dbo.bPREH h WITH (NOLOCK)
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPRLI l WITH (NOLOCK) ON l.PRCo = h.PRCo AND l.LocalCode = s.LocalCode1
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE	h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					AND a.Mth >= @firstmonth AND a.Mth <= @quarter
 					AND a.EDLType = 'D' AND a.EDLCode = l.TaxDedn),0),
 			Loc2Amt = ISNULL((select SUM(a.Amount)
 			FROM dbo.bPREH h WITH (NOLOCK) 
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPRLI l WITH (NOLOCK) ON l.PRCo = h.PRCo AND l.LocalCode = s.LocalCode2
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE	h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					AND a.Mth >= @firstmonth AND a.Mth <= @quarter
 					AND a.EDLType = 'D' AND a.EDLCode = l.TaxDedn),0),
 			Loc3Amt = 0
 			FROM dbo.bPRUE u
 			WHERE PRCo = @prco AND State = @uistate AND Quarter = @quarter
 		END
 		ELSE IF DATEPART(mm,@quarter) = 12 --last quarter of the year, report annual amounts using @firstofyear
 		BEGIN
 	 		UPDATE dbo.bPRUE SET 
 			Loc1Amt = ISNULL((SELECT SUM(a.Amount)
 			FROM dbo.bPREH h WITH (NOLOCK)
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPRLI l WITH (NOLOCK) ON l.PRCo = h.PRCo AND l.LocalCode = s.LocalCode1
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE	h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					AND a.Mth >= @firstofyear AND a.Mth <= @quarter
 					AND a.EDLType = 'D' AND a.EDLCode = l.TaxDedn),0),
 			Loc2Amt = ISNULL((select SUM(a.Amount)
 			FROM dbo.bPREH h WITH (NOLOCK) 
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPRLI l WITH (NOLOCK) ON l.PRCo = h.PRCo AND l.LocalCode = s.LocalCode2
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE	h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					AND a.Mth >= @firstofyear AND a.Mth <= @quarter
 					AND a.EDLType = 'D' AND a.EDLCode = l.TaxDedn),0),
 			Loc3Amt = 0
 			FROM dbo.bPRUE u
 			WHERE PRCo = @prco AND [State] = @uistate AND [Quarter] = @quarter
 		END
 	END
	ELSE
	BEGIN
 		UPDATE dbo.bPRUE SET 
 			Loc1Amt = ISNULL((SELECT SUM(a.Amount)
 			FROM dbo.bPREH h WITH (NOLOCK)
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPRLI l WITH (NOLOCK) ON l.PRCo = h.PRCo AND l.LocalCode = s.LocalCode1
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE	h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					AND a.Mth >= @firstmonth AND a.Mth <= @quarter
 					AND a.EDLType = 'D' AND a.EDLCode = l.TaxDedn),0),
 			Loc2Amt = ISNULL((select SUM(a.Amount)
 			FROM dbo.bPREH h WITH (NOLOCK) 
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPRLI l WITH (NOLOCK) ON l.PRCo = h.PRCo AND l.LocalCode = s.LocalCode2
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE	h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					AND a.Mth >= @firstmonth AND a.Mth <= @quarter
 					AND a.EDLType = 'D' AND a.EDLCode = l.TaxDedn),0),
 			Loc3Amt = ISNULL((select SUM(a.Amount)
 			FROM dbo.bPREH h WITH (NOLOCK) 
 			JOIN dbo.bPRSI s WITH (NOLOCK) ON s.PRCo = h.PRCo
 			JOIN dbo.bPRLI l WITH (NOLOCK) ON l.PRCo = h.PRCo AND l.LocalCode = s.LocalCode3
 			JOIN dbo.bPREA a WITH (NOLOCK) ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 			WHERE	h.PRCo = @prco AND h.Employee = u.Employee AND s.[State] = @uistate
 					AND a.Mth >= @firstmonth AND a.Mth <= @quarter
 					AND a.EDLType = 'D' AND a.EDLCode = l.TaxDedn),0)
 			FROM dbo.bPRUE u
 			WHERE PRCo = @prco AND [State] = @uistate AND [Quarter] = @quarter
	END
	 
 	-- -- -- update bPRUE with DLCode1 and 2 amounts assigned in bPRSI
 	update bPRUE set DLCode1Amt = isnull((select sum(a.Amount)
 	from bPREH h 
 	join bPRSI s on s.PRCo = h.PRCo
 	join bPRDL l on l.PRCo = h.PRCo and l.DLCode = s.DLCode1
 	join bPREA a on a.PRCo = h.PRCo and a.Employee = h.Employee
 	where h.PRCo = @prco and h.Employee = u.Employee and s.State = @uistate
 	and a.Mth >= @firstmonth and a.Mth <= @quarter and a.EDLCode = l.DLCode),0),
 	DLCode2Amt = isnull((select sum(a.Amount)
 	from bPREH h with (nolock) 
 	join bPRSI s with (nolock) on s.PRCo = h.PRCo
 	join bPRDL l with (nolock) on l.PRCo = h.PRCo and l.DLCode = s.DLCode2
 	join bPREA a with (nolock) on a.PRCo = h.PRCo and a.Employee = h.Employee
 	where h.PRCo = @prco and h.Employee = u.Employee and s.State = @uistate
 	and a.Mth >= @firstmonth and a.Mth <= @quarter and a.EDLCode = l.DLCode),0)
 	from bPRUE u
 	where PRCo = @prco and State = @uistate and Quarter = @quarter
 	-- -- -- delete employees who did not work in quarter for NY if quarter is not 12
 	if @uistate='NY' and datepart(mm,@quarter) < 12
	begin
 		delete from bPRUE where State=@uistate and SUIWages = 0
	end

next_State:
	if @state is null
		begin
		fetch next from bcState into @uistate
		if @@fetch_status = 0 goto init_State
		end

State_End:
	if @opencursor = 1
		begin
		close bcState
		deallocate bcState
		select @opencursor = 0
		end


---- check for Rhode Island Entries (RI)
if not exists(select PRCo from PRUE where PRCo=@prco and Quarter=@quarter and State='RI')
	begin
	goto bspexit
	end

---- for Rhode Island Only need to populate both Weeks and Hours accums
declare bcRIOnly cursor FAST_FORWARD for select Employee 
from bPRUE
where PRCo=@prco and Quarter=@quarter and State='RI'
and (WksWorked = 0 or HrsWorked = 0)

open bcRIOnly
select @openrionly = 1

RIOnly_loop:
fetch next from bcRIOnly into @employee
if @@fetch_status <> 0 goto RIOnly_end

---- reset values
select @wksworked = 0, @hrsworked = 0
---- get hours from bPRTH
select @hrsworked = isnull(sum(a.Hours),0)
from bPRTH a
where a.PRCo=@prco and a.UnempState='RI' and a.Employee=@employee
and a.PREndDate between @qtr_begindate and @qtr_enddate
and a.PaySeq=1
---- udpate hours if zero
update bPRUE set HrsWorked=@hrsworked
where PRCo=@prco and Quarter=@quarter and State='RI' and Employee=@employee and HrsWorked = 0

---- get weeks from bPRPC
select @wksworked = isnull(sum(c.Wks),0)
from bPRPC c
join bPRSQ b on b.PRCo=c.PRCo and b.PRGroup=c.PRGroup and b.PREndDate=c.PREndDate
where c.PRCo=@prco and c.PREndDate between @qtr_begindate and @qtr_enddate
and b.PaySeq=1 and b.Employee=@employee
and exists(select PRCo from bPRTH d where d.PRCo=@prco and d.UnempState='RI' and d.PaySeq=1
		and d.Employee=@employee and d.PREndDate=c.PREndDate)
---- update weeks if zero
update bPRUE set WksWorked=@wksworked
where PRCo=@prco and Quarter=@quarter and State='RI' and Employee=@employee and WksWorked = 0


goto RIOnly_loop


RIOnly_end:
	if @openrionly = 1
		begin
		close bcRIOnly
		deallocate bcRIOnly
		select @openrionly = 0
		end





bspexit:
  	if @opencursor = 1
		begin
		close bcState
		deallocate bcState
		select @opencursor = 0
		end

	if @openrionly = 1
		begin
		close bcRIOnly
		deallocate bcRIOnly
		select @openrionly = 0
		end

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPRUnemplWageInit] TO [public]
GO
