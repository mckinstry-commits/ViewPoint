SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRAutoEarnInit]    Script Date: 12/04/2007 13:55:12 ******/
CREATE  procedure [dbo].[bspPRAutoEarnInit]
/****************************************************************
* CREATED: kb 03/09/98
* MODIFIED: EN 5/8/99
*			kb 12/14/99 - It was calculating auto earnings on all pay seq's instead
*                          of the pay seq that you are running the Auto Earnings for
*           DANF 12/18/99 - Added ability to post auto earnings on all payment sequences.
*           DANF 02/16/2000 - Added setting of GLCO for job entries
*           DANF 04/24/2000 - Added Pay Sequence restriction for PRTA.
*           GG 5/1/00 - Added Memo columns to bPRTH and bPRTB
*           DANF 05/11/00 - Added the ability to distribute earnings back to the state and local code for non true earnings
*                         - Any differnce in distribution and total amt will be reflected in the last posting sequence.
*           DANF 07/11/00 - Corrected Error message to convert employee number to a varchar.
*           EN 8/16/00 - Equipment cost type field wasn't being filled
*           DANF 10/17/2000 - Fixed posting of local code for non true earnings posting.
*           DANF 10/18/2000 - Fixed distribution to lines that may not be subject to addons
*           GG 03/14/01 - fixed for null local codes - was not able to fully distribute amounts
*           MV 05/18/01 - Issue #9574 - Auto Earnings limit enhancement - use standard annual limit from bPREC unless
*                       - overridden in bPRAE
*           MV 05/23/01 - Issue #11028 - don't skip an employee with unposted timecards if those earnings are
*                         posted to another Pay Seq or not subject to auto earnings
*           GG 06/14/01 = #13407 - correct unemployment state posted with distribution of nontrue earnings
*           danf 06/29/01 = 13874 - Added column names to delete insert statement for user memos that may have been added to the prtb table
*			GG 07/30/01 - when checking for unposted timecards, exclude current batch (#14147)
*           danf 08/01/01 - change distribution cursor to use taxlocalcode varabile.
*			GG 09/12/01 - fixed calculation for rate/hour based earnings using 'std hours' Issue #14591
*			GG 01/14/02 - #14733 - added bPREC.SubjToAutoEarns column
*           danf 04/12/04 - Added Default of GL Company if the GL Company is null in PREH and PRAE. #16931
*			GG 05/24/02 - #17473 - fixed YTD accum for limit check
*			MV 7/1/02 - #17288 added coding to count # of employees added to the batch and return the #.
*			MV 7/19/02 - #14691 - insert Costcode in bPRTB with MechanicsCC from bPRAE, get @equipcosttype
*								from bEMEM for equip usage, or labor costtype from bEMCO for mechanic's time.
*			MV 7/23/02 - #14690 - expanded limit check to include pay period and monthly.
*			MV 8/23/02 - #14691 - added case statment to insert bPRTB for Type - 'M'for mechanics or'J'for job
*			EN 10/7/02 - issue 18877 change double quotes to single
*			EN 11/04/03 - issue 22878  skip limit check and adjustment for rate of gross/hour calcs on pay seq's with no earnings/hours
*			EN 12/03/03 - issue 23061  added isnull check, with (nolock), and dbo
*			EN 5/10/04 - issue 22878 additional fix for rejection #1
*			EN 5/11/04 - issue 24300  check current batch for pre-existing employee entries prior to posting
*			EN 9/03/04 - issue 24334 method to calculate earnings as rate of STE
*			EN 10/11/04 - fix to issue 24300  remove original fix and start over
*			EN 10/22/04 - issue 24300  redo fix to properly check for unposted empl/pay seq's before posting
*			EN 10/15/04 - issue 25651  prevent non-true earnings addons from being distributed to earnings that are not subject to addons
*			EN 1/10/05 - issue 26700 use Empl Tax State as reciprocal state if it's a reciprocal state to the job/office tax state
*			EN 3/15/05 - issue 26439 removed code to default cost type for mech timecards added with 5.71 issue 14691
*			EN 5/26/05 - issue 25651 fix for issue rejection #2
*			EN 3/9/06 - issue 119993  on mechanic timecards, EMCO GLCo overrides PREH GLCo if available
*			EN 12/05/07 - issue 122531  added @addlaccum to track amounts posted on an auto earning on earlier pay sequences so that limit can be checked more accurately
*			EN 1/04/08 - issue 124360  when insert into PRTB, set EquipPhase equal to Phase
*			EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
*			EN 4/18/08 - #122531  additional fix to handle non-true earnings distributions properly
*			EN 4/18/08 - #123590  apply earn type annual limit
*			EN 4/25/08 - #122531  fix for rejection #2
*			EN 7/9/2009 #132752  use null local code if job was posted but no job local was defined ... was using empl local in that case
*									also recoded defaults for tax, insurance, and unemployment states which were confusing
*			EN 10/29/2009 #136365
*			EN 1/20/2010 #136987  restrict @stateearns total to only include earnings subject to auto earnings
*			EN 2/03/2010 #136011  utilize new 'Use regular hourly rate' checkbox ... if checked get rate from bPREH or Craft/Class/Template structure, whichever is greater
*			EN 2/05/2010 #136039  add ability to use earnings method for an auto earning (for AUS RDO accrual)
*			EN 2/18/2010 #132653 add ability to execute AmtPerDay routine using specific parameters
*			mh 02/19/2010 #137971 - modified to allow date compares to use other then calendar year.
*			TJL 03/01/10 - Issue #135490, Add Office TaxState & Office LocalCode to PR Employee Master
*			EN 3/4/2010 #132653 add ability to execute OTMealAllow routine
*			EN 3/5/2010 #132653 add ability to execute OTCribAllow and OTWeekendCrib routines
*			EN 3/10/2010 #137971 modification to restore previous code to compute @a2 amount
*			EN 3/19/2010 #137622 replace 6.2.1 fix for issue #130542 that somehow got lost
*								 (#130542  traced this back to fix made for 122531 ... replaced with better code)
*			EN 5/6/2010 #136011  addition fix to original made back in February ... wasn't doing a good job of getting the Craft effective date
*			CHS	08/24/2010	#140890
*			EN 8/25/2010 #140370  add ability to call a custom earnings routine using a standard set of input/output parameters
*			MV 09/08/10 - #141210 - Moved 'Posted Hours' calculations out of 'Method' logic. Posted Hours are calculated regardless of method used.
*			EN 9/30/2010  #141284 Removed code to specifically call Australian earnings routine bspPR_AU_RDOAccrual
*			CHS 02/21/2011	- #142620
*			KK/EN 06/09/2011 TK-05849 Added code to handle CA AmtPerDay routine
*			CHS 06/05/2011	- #146557 TK-15385 D-05231
*			EN 06/05/2012 - D-05200/TK-152389/#146483 added call to bspPR_AU_AmountPerDiemAward
*			EN 08/29/2012 - D-05698/TK-17502 added params to bspPR_AU_ROSG routine call due to added feature ... 
*												routine can now be called to compute auto earnings
*			EN 08/16/2012 B-10534/TK-18448 added call to bspPR_AU_RDOAccrualDaily
*
* USAGE:
* Called by the PR Post Automatic Earnings form to initialize timecard
* entries into bPRTB based Employee Auto Earnings setup in bPRAE.
*
* INPUT:
*   @co      		PR Company
*   @mth        	Batch month
*   @batchid    	Batch ID
*   @prgroup    	Payroll Group
*   @prenddate  	Pay Period Ending Date
*   @employee		Employee - null for all active Employees in PR Group
*   @sendpayseq		Payment Seq to post - unless overridden in bPRAE
*   @sendpostdate	Post Date for new timecards
*   @deleteyn		Y = delete existing timecards, N = skip if earnings already exist
*   @rstallseqyn	Y = restrict to single Pay Seq, N = process all Pay Seqs
*
* OUTPUT:
*   @errmsg		Error message
*
* RETURN:
*   0		Sucess
*   1		Failure
********************************************************/
	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @prgroup bGroup = null,
	 @prenddate bDate = null, @employee int = null, @sendpayseq tinyint = null,
	 @sendpostdate bDate = null, @deleteyn bYN = 'N', @rstallseqyn bYN = 'N',@empcount varchar (5)= null output,
	 @errmsg varchar(200) = null output)
as
set nocount on

--Issue #135490, remove PRCo, Job, Employ variables related to State & LocalCodes & flags
-- Pay Period Control variables
declare @begindate bDate, @paidmth bMonth, @prpchours bHrs, @status tinyint
-- Employee variables
declare @empprdept bDept,  @empglco bCompany,  @empuseins bYN, @crew varchar(10), @cert bYN
-- misc variables
-- #136011 added @effectdate, @template, @payRate, @variableRate, and @classrate
declare @rcode int, @openAutoEarn tinyint, @earncode bEDLCode, @payseq tinyint, @prdept bDept,
	@inscode bInsCode, @craft bCraft, @class bClass, @jcco bCompany, @job bJob,  @phasegroup bGroup,
	@phase bPhase, @glco bCompany, @emco bCompany, @equip bEquip, @emgroup bGroup, @revcode bRevCode,
	@usageunits bHrs, @stdhours bYN, @praehours bHrs, @useregrate bYN, @rateamt bUnitCost, @ovrstdlimitYN bYN,
	@limitovramt bDollar, @StandardLimit bDollar, @trueYN bYN, @method char(1), @saveemployee bEmployee,
	@hours bHrs, @seq int, @amt bDollar, @rate bUnitCost, @daynum smallint, @taxstate varchar(4),
	@localcode bLocalCode, @unempstate varchar(4), @insstate varchar(4), @shift tinyint, @prthhours bHrs,
	@prthamt bDollar, @prthearncode bEDLCode, @totamt bDollar, @prthpostdate bDate, @savepostdate bDate,
	@daycount tinyint, @tothours bHrs, @openAccumEarns tinyint, @postseq smallint, @postdate bDate,
	@skip tinyint, @totearns bDollar, @a1 bDollar, @a2 bDollar,
	@a3 bDollar, @a4 bDollar, @ytdamt bDollar, @stateearns bDollar, @saveamt bDollar,
	@openDeleteEarns tinyint, @openNonTrueDist tinyint, @overinscode bInsCode, @jobcraft bCraft,
	@savehours bHrs, @openPaySeq tinyint, @freq bFreq, @taxlocalcode bLocalCode, @disamt bDollar,
	@lastseq int, @equipctype bJCCType, @numrows int, @prglco bCompany, @nextemployee int, 
	@prevemployee int, @employeecount int, @mechanicscc bCostCode, @limitperiod varchar(1), @limit bDollar,
	@accumamt bDollar, @limitmth bDate, 
	@effectdate bDate, @template smallint, @payRate bUnitCost, @variableRate bUnitCost, @classrate bUnitCost,
	@accumearnsfound bYN, --issue 22878
	@a5 bDollar, @a6 bDollar, --#130542
	@routine varchar(10), @procname varchar(30) --#136039

--
select @rcode = 0, @openAutoEarn = 0, @employeecount=0, @nextemployee=0, @prevemployee=0 --******17288

--issue 122531
--#130542 commented out ... no longer needed
--declare @addlaccum bDollar
--select @addlaccum = 0

--#123590 declarations
declare @earntype bEarnType, @hqetannuallimit bDollar
declare @EarnTypeEarnings TABLE (EarnType bEarnType NOT NULL, HQETLimit bDollar NOT NULL, AnnualEarnings bDollar NOT NULL)

--#140370 declaration
declare @MiscAmt1 bDollar, @MiscAmt2 bDollar

-- get PR Company info
--Issue #135490, remove PRCo values related to State & LocalCodes & flags
select @prglco = GLCo
from dbo.bPRCO with (nolock) where PRCo = @co
if @@rowcount = 0
	begin
	select @errmsg = 'Missing PR Company entry!', @rcode = 1
	goto bspexit
	end
-- get Pay Period Control info
select  @begindate = BeginDate, @prpchours = Hrs, @status = Status, @limitmth = LimitMth,
	@paidmth = case MultiMth when 'Y' then EndMth else BeginMth end	-- expected paid month needed for limit check
from dbo.bPRPC with (nolock)
where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
if @@rowcount = 0
	begin
	select @errmsg = 'Missing Pay Period Control entry!', @rcode = 1
	goto bspexit
	end
if @status = 1
	begin
	select @errmsg = 'Pay Period is closed!', @rcode = 1
	goto bspexit
	end
   

--137971
declare @yearendmth tinyint, @beginmth bMonth, @endmth bMonth

select @yearendmth = case h.DefaultCountry when 'AU' then 6 else 12 end
from bHQCO h with (nolock) 
where h.HQCo = @co

exec vspPRGetMthsForAnnualCalcs @yearendmth, @paidmth, @beginmth output, @endmth output, @errmsg output


   
--issue 24300 create & fill table variable with employee/pay seq's to be skipped because unposted earnings exist
declare @EmplSeqs table (ESemployee int, ESpayseq tinyint)

insert into @EmplSeqs (ESemployee, ESpayseq)
select distinct t.Employee, t.PaySeq
from dbo.bPRTB t with (nolock)
join dbo.bPREH e with (nolock) on e.PRCo = t.Co and e.Employee = t.Employee
join dbo.bPRAE a with (nolock) on t.Co = a.PRCo and t.Employee = a.Employee
join dbo.bHQBC b with (nolock) on b.Co = t.Co and b.Mth = t.Mth and b.BatchId = t.BatchId
where t.Co = @co and b.PRGroup = @prgroup and b.PREndDate = @prenddate and e.ActiveYN = 'Y'
   
   
-- create a cursor to process Auto Earnings
declare bcAutoEarn cursor for
select a.EarnCode, a.Employee, a.PaySeq, a.PRDept, a.InsCode, a.Craft, a.Class,
	a.JCCo, a.Job, a.PhaseGroup, a.Phase, a.GLCo, a.EMCo, a.Equipment, a.EMGroup,
    a.RevCode, a.UsageUnits, a.StdHours, a.Hours, a.UseRegRate, a.RateAmt, a.LimitOvrAmt, a.OvrStdLimitYN,
    e.TrueEarns, e.Method, e.StandardLimit, a.MechanicsCC, e.LimitType, e.Routine
from dbo.bPRAE a with (nolock)
join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
join dbo.bPREH h with (nolock) on h.PRCo = a.PRCo and h.Employee = a.Employee
where a.PRCo = @co and a.Employee = isnull(@employee,a.Employee)
	and h.PRGroup = @prgroup and h.ActiveYN = 'Y'       -- Employee must be in PRGroup and Active
  	and a.Frequency in (select Frequency from dbo.bPRAF with (nolock) where PRCo = @co and PRGroup = @prgroup
		and PREndDate = @prenddate)       -- Frequency must be active for Pay Period
  	and ((@rstallseqyn = 'Y' and ((a.PaySeq = @sendpayseq) or a.PaySeq is null) or (@rstallseqyn = 'N')))
--       	and ((@rstallseqyn = 'Y' and a.PaySeq = isnull(@sendpayseq,a.PaySeq)) or @rstallseqyn = 'N') --possible fix for pay seq selection is to replace above code with this
order by a.Employee, a.PaySeq DESC, a.EarnCode, a.Seq   -- process earnings not assigned a pay sequence last
 
open bcAutoEarn
select @openAutoEarn = 1
         
-- loop through Auto Earnings in cursor
next_AutoEarn:
	fetch next from bcAutoEarn into @earncode, @employee, @payseq, @prdept, @inscode,@craft, @class,
		@jcco, @job, @phasegroup, @phase, @glco, @emco, @equip, @emgroup,
		@revcode, @usageunits, @stdhours, @praehours, @useregrate, @rateamt, @limitovramt, @ovrstdlimitYN,
		@trueYN, @method, @StandardLimit, @mechanicscc, @limitperiod, @routine

	if @@fetch_status <> 0 goto bspexit

	--#136011 if Use Regular Hourly Rate checkbox is checked use rate from bPREH or Craft/Class/Template structure, whichever is greater
	if @useregrate = 'Y'
		begin --useregrate = 'Y'

		--get craft template from JCJM
		select @template = CraftTemplate from dbo.JCJM (nolock) where JCCo=@jcco and Job=@job

		--get effective from PRCM or from PRCT if override exists
		--#136011 5/6/2010 added 'left' to join and moved ct.Template=@template to join's 'on' list for when there is no template
		select @effectdate = (case when ct.OverEffectDate='Y' and ct.EffectiveDate is not null then ct.EffectiveDate else cm.EffectiveDate end)
		from dbo.PRCM cm (nolock)
		left join dbo.PRCT ct (nolock) on ct.PRCo=cm.PRCo and ct.Craft=cm.Craft and ct.Template=@template
		where cm.PRCo=@co and cm.Craft=@craft

		--get rate from Craft/Class/Template structure
	    if @template is not null
 	  		begin

			--get rate from PRTP or from PRTE if variable earnings override exists
			select @payRate = (case when @sendpostdate >= @effectdate then tp.NewRate else tp.OldRate end)
			from dbo.PRTP tp (nolock)
			where tp.PRCo=@co and tp.Craft=@craft and tp.Class=@class and tp.Template=@template and tp.Shift=1

			select @variableRate =(case when @sendpostdate >= @effectdate then te.NewRate else te.OldRate end)
			from dbo.PRTE te (nolock)
			where te.PRCo=@co and te.Craft=@craft and te.Class=@class and te.Template=@template and te.Shift=1 and te.EarnCode=@earncode

			select @classrate = (case when @payRate is not null then @payRate else @variableRate end)

			end

		--if no job template or rate not found for template, get rate from Craft/Class structure
		if @template is null or (@template is not null and @classrate is null)
			begin

			--get rate from PRCP or from PRCE if variable earnings override exists
			select @payRate = (case when @sendpostdate >= @effectdate then cp.NewRate else cp.OldRate end)
			from dbo.PRCP cp (nolock)
			where cp.PRCo=@co and cp.Craft=@craft and cp.Class=@class and cp.Shift=1

			select @variableRate =(case when @sendpostdate >= @effectdate then ce.NewRate else ce.OldRate end)
			from dbo.PRCE ce (nolock)
			where ce.PRCo=@co and ce.Craft=@craft and ce.Class=@class and ce.Shift=1 and ce.EarnCode=@earncode

			select @classrate = (case when @payRate is not null then @payRate else @variableRate end)

			end

		if @classrate is null select @classrate = 0

		select @rateamt = (case when HrlyRate > @classrate then HrlyRate else @classrate end)
		from dbo.bPREH (nolock) 
		where PRCo = @co and Employee = @employee

		end --useregrate = 'Y'

	select @openPaySeq = 0
	select @nextemployee = @employee --17288
	--#130542 commented out ... no longer needed
	--select @addlaccum = 0 --issue 122531 clear variable prior after done posting this auto earning
   
   
	-- if not restricted to a single Pay Seq and auto earnings has no assigned Pay Seq, process for all Pay Seqs
	if @rstallseqyn = 'N' and @payseq is null
	-- if @rstallseqyn = 'N'  or (@rstallseqyn = 'Y' and @payseq is null) --possible fix for pay seq selection is to replace above code with this
		begin
		-- create a cursor to process Pay Sequences
		declare bcPaySeq cursor for
		select PaySeq
		from dbo.bPRPS with (nolock)
		where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
		order by PaySeq

		open bcPaySeq
		select @openPaySeq = 1
         
		next_PaySeq:    -- loop through
			fetch next from bcPaySeq into @payseq
			if @@fetch_status <> 0
				begin
				close bcPaySeq
		        deallocate bcPaySeq
				select @openPaySeq = 0
				goto next_AutoEarn
				end
		end
	else
		begin
		if @payseq is null select @payseq = @sendpayseq
		end
         
	-- skip if Employee/Pay Seq is already paid
    select @numrows = count(*)
    from dbo.bPRSQ with (nolock)
    where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
		and PaySeq = @payseq and (CMRef is not null or PaidMth is not null)
    if @numrows > 0
        begin
        if @openPaySeq = 1 goto next_PaySeq else goto next_AutoEarn
        end
         
	-- make sure Pay Seq is valid for this Pay Period
	select @numrows = count(*)
	from dbo.bPRPS with (nolock)
	where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and PaySeq = @payseq
	if @numrows = 0
		begin
		if @openPaySeq = 1 goto next_PaySeq else goto next_AutoEarn
		end
   
   	-- skip if Employee/Pay Seq had unposted timecards before processing began
   	select @numrows = count(*) from @EmplSeqs where ESemployee = @employee and ESpayseq = @payseq
    if @numrows > 0
		begin
        if @openPaySeq = 1 goto next_PaySeq else goto next_AutoEarn
        end
        
	-- skip if Employee has unposted timecards for this Pay Period and Seq with
	-- earnings subject to auto earnings
    select @numrows = count(*)
	from dbo.bPRTB t with (nolock)
    join dbo.bHQBC b with (nolock) on b.Co = t.Co and b.Mth = t.Mth and b.BatchId = t.BatchId
    join dbo.bPREC e with (nolock) on e.PRCo = t.Co and e.EarnCode = t.EarnCode
    where b.Co = @co and b.PRGroup = @prgroup and b.PREndDate = @prenddate and
          t.Employee = @employee and t.PaySeq = @payseq and e.SubjToAutoEarns = 'Y'
  	and (b.Co <> @co or b.Mth <> @mth or b.BatchId <> @batchid)	-- exclude current batch
    if @numrows > 0
		begin
        if @openPaySeq = 1 goto next_PaySeq else goto next_AutoEarn
        end
   
	--  get Employee info
	--Issue #135490, remove Employee values related to State & LocalCodes & flags
	if @saveemployee is null or @saveemployee <> @employee
		begin
		select @empprdept = PRDept, @empglco = GLCo, @crew = Crew, @cert = CertYN, @empuseins=UseIns
		from dbo.bPREH with (nolock) where PRCo = @co and Employee = @employee
		if @@rowcount = 0
			begin
			select @errmsg = 'Posting has stopped - Employee ' + convert(varchar(10),@employee)  + ' is missing header entry!', @rcode = 1
			goto bspexit
			end

		--#123590 clear earn type earnings tracker if data exists for a previous employee
		if (select count(1) from @EarnTypeEarnings) > 0 delete from @EarnTypeEarnings

		select @saveemployee = @employee   -- save Employee#
		end
         
	-- check for previously posted earnings - skip or delete
	select @numrows = count(*)
	from dbo.bPRTH with (nolock)
	where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
		and Employee = @employee and PaySeq = @payseq and EarnCode = @earncode and InUseBatchId is null
	if @numrows > 0
		begin
	    if @deleteyn = 'N'
			begin
			-- skip to next Pay Seq or Auto earnings
			if @openPaySeq = 1 goto next_PaySeq else goto next_AutoEarn
			end
	    if @deleteyn = 'Y'
		    begin
			-- create a cursor to delete existing Timecards for this Employee/Pay Seq and Earn code
			declare bcDeleteEarns cursor for
			select PostSeq, PostDate
			from dbo.bPRTH with (nolock)
			where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
				and PaySeq = @payseq and EarnCode = @earncode and InUseBatchId is null

		    open bcDeleteEarns
		    select @openDeleteEarns = 1
         
			-- loop through Timecards in cursor
			next_DeleteEarn:
				fetch next from bcDeleteEarns into @postseq, @postdate

				if @@fetch_status <> 0 goto end_DeleteEarns

				select @daynum = datediff(day,@begindate,@postdate) + 1   -- convert posting date to day number

				-- get next available batch seq#
				select @seq = isnull(max(BatchSeq),0) + 1   -- next Batch Seq #
				from dbo.bPRTB with (nolock)
				where Co = @co and Mth = @mth and BatchId = @batchid

				-- add to Timecard Batch as a 'delete' trans type -- insert trigger on bPRTB will flag bPRTH as 'in use'
		        insert dbo.bPRTB(Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, PostSeq, Type, DayNum, PostDate,
					JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode, CompType,
					Component, RevCode, EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode,
					PRDept, Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, OldEmployee, OldPaySeq,
					OldPostSeq, OldType, OldPostDate, OldJCCo, OldJob, OldPhaseGroup, OldPhase, OldGLCo, OldEMCo, OldWO, OldWOItem, OldEquipment,
					OldEMGroup, OldCostCode, OldCompType, OldComponent, OldRevCode, OldEquipCType, OldUsageUnits, OldTaxState, OldLocalCode,
					OldUnempState, OldInsState, OldInsCode, OldPRDept, OldCrew, OldCert, OldCraft, OldClass, OldEarnCode, OldShift, OldHours, OldRate, OldAmt, Memo, OldMemo)
				select @co, @mth, @batchid, @seq, 'D', @employee, @payseq, @postseq, Type, @daynum, @postdate,
					JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode, CompType,
					Component, RevCode, EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode,
					PRDept, Crew, Cert, Craft, Class, @earncode, Shift, Hours, Rate, Amt, @employee, @payseq,
					@postseq, Type, @postdate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment,
					EMGroup, CostCode, CompType, Component, RevCode, EquipCType, UsageUnits, TaxState, LocalCode,
					UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class, @earncode, Shift, Hours, Rate, Amt, Memo, Memo
				from dbo.bPRTH with (nolock)
				where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
					and PaySeq = @payseq and PostSeq = @postseq

		        goto next_DeleteEarn
   
         	end_DeleteEarns:     -- finished with existing Timecards
				close bcDeleteEarns
            	deallocate bcDeleteEarns
                select @openDeleteEarns = 0
                end
            end
         
		/****** Prepare to create Timecard Batch entries from Auto Earnings info ******/
		-- initialize totals and amounts
		select @savepostdate = null, @daycount = 0, @tothours = 0, @totamt = 0
 		select @accumearnsfound = 'N' --issue 22878
   
		--#123590 establish accum tracking for earn type if not already established
		-- get EarnType from bPREC and AnnualLimit from HQET 
		select @earntype = EarnType from dbo.bPREC with (nolock) where PRCo = @co and EarnCode = @earncode
		select @hqetannuallimit = AnnualLimit from dbo.bHQET with (nolock) where EarnType = @earntype
		If @hqetannuallimit <> 0 
			begin
			-- if earn type is not already established in @EarnTypeEarnings, do so
			if (select count(*) from @EarnTypeEarnings where EarnType = @earntype) = 0
				begin
				-- get AnnualLimit from HQET and add Earn Type entry to @EarnTypeEarnings
				insert into @EarnTypeEarnings values (@earntype, @hqetannuallimit, 0)

				--Get YTD Earnings for Earn Type and add to earnings tracker Annual Earnings amount
				--year-to-date accums based on year of expected paid month
/*Issue 137971				
				select @a1 = isnull(sum(a.Amount),0)
				from dbo.bPREA a with (nolock) 
				join dbo.bPREC e with (nolock) on e.PRCo=a.PRCo and e.EarnCode=a.EDLCode
				where a.PRCo = @co and a.Employee = @employee and datepart(year,Mth) = datepart(year,@paidmth)
					and a.EDLType = 'E' and e.EarnType=@earntype
*/

				select @a1 = isnull(sum(a.Amount),0)
				from dbo.bPREA a with (nolock) 
				join dbo.bPREC e with (nolock) on e.PRCo=a.PRCo and e.EarnCode=a.EDLCode
				where a.PRCo = @co and a.Employee = @employee and a.Mth between @beginmth and @endmth
					and a.EDLType = 'E' and e.EarnType=@earntype


				--current amounts from earlier Pay Periods where Final Accum update has not been run
				select @a2 = isnull(sum(d.Amount),0)
				from dbo.bPRDT d with (nolock)
				join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
					and s.Employee = d.Employee and s.PaySeq = d.PaySeq
				join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
				join dbo.bPREC e with (nolock) on e.PRCo=d.PRCo and e.EarnCode=d.EDLCode
				where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
					and d.EDLType = 'E' and e.EarnType=@earntype
					and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
					and ((s.PaidMth is null and datepart(year,case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end) = datepart(year,@paidmth))
     				or (datepart(year,s.PaidMth) = datepart(year,@paidmth)))
     				and c.GLInterface = 'N'

--removed Issue 137971 code to compute @a2 amount and restored previous code which is working correctly - EN 3/12/10
--				select @a2 = isnull(sum(d.Amount),0)
--				from dbo.bPRDT d with (nolock)
--				join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
--					and s.Employee = d.Employee and s.PaySeq = d.PaySeq
--				join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
--				join dbo.bPREC e with (nolock) on e.PRCo=d.PRCo and e.EarnCode=d.EDLCode
--				where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
--					and d.EDLType = 'E' and e.EarnType=@earntype
--					and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
--            	    and ((s.PaidMth is null and datepart(year,case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end) = datepart(year,@paidmth))
--     				or (datepart(year,s.PaidMth) = datepart(year,@paidmth)))
--					and c.GLInterface = 'N'

     				
				--old amounts from earlier Pay Periods where Final Accum update has not been run
/*Issue 137971 
				select @a3 = isnull(sum(d.OldAmt),0)
				from dbo.bPRDT d with (nolock)
				join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
				join dbo.bPREC e with (nolock) on e.PRCo=d.PRCo and e.EarnCode=d.EDLCode
				where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
					and d.EDLType = 'E' and e.EarnType=@earntype
					and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
					and datepart(year,d.OldMth) = datepart(year,@paidmth) and c.GLInterface = 'N'
*/				
					
					
				select @a3 = isnull(sum(d.OldAmt),0)
				from dbo.bPRDT d with (nolock)
				join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
				join dbo.bPREC e with (nolock) on e.PRCo=d.PRCo and e.EarnCode=d.EDLCode
				where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
					and d.EDLType = 'E' and e.EarnType=@earntype
					and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
					and d.OldMth between @beginmth and @endmth and c.GLInterface = 'N'					
					
					
				--old amounts from current and later Pay Periods - need to back out of accums
/*Issue 137971 		
				select @a4 = isnull(sum(d.OldAmt),0)
				from dbo.bPRDT d with (nolock)
				join dbo.bPREC e with (nolock) on e.PRCo=d.PRCo and e.EarnCode=d.EDLCode
				where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
					and d.EDLType = 'E' and e.EarnType=@earntype
					and (d.PREndDate > @prenddate or (d.PREndDate = @prenddate and d.PaySeq >= @payseq))
					and datepart(year,d.OldMth) = datepart(year,@paidmth)
*/

				select @a4 = isnull(sum(d.OldAmt),0)
				from dbo.bPRDT d with (nolock)
				join dbo.bPREC e with (nolock) on e.PRCo=d.PRCo and e.EarnCode=d.EDLCode
				where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
					and d.EDLType = 'E' and e.EarnType=@earntype
					and (d.PREndDate > @prenddate or (d.PREndDate = @prenddate and d.PaySeq >= @payseq))
					and d.OldMth between @beginmth and @endmth
					
				--year-to-date is accums + net from earlier Pay Pds - old from later Pay Pds
				select @ytdamt = @a1 + (@a2 - @a3) - @a4

				if @ytdamt <> 0 update @EarnTypeEarnings set AnnualEarnings = AnnualEarnings + @ytdamt where EarnType = @earntype
				end
			end

		-- create a cursor to sort posted and unposted earnings by date
     	if @method = 'S' --issue 24334 get Straight Time Equivalent amount for Method 'S' calculations
     		begin
 	        declare bcAccumEarns cursor for
 	        -- select t.Hours, t.Amt/e.Factor, t.EarnCode, t.PostDate -- CHS	02/15/2011	- #142620 deal with divide by zero 
 	        select t.Hours, 
 				Case when e.Factor = 0.00 then 0 else t.Amt/e.Factor end, 
 				t.EarnCode, 
 				t.PostDate
 	        from dbo.bPRTH t with (nolock)     -- existing timecards
 	        join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
 	        where t.PRCo = @co and t.PRGroup = @prgroup and t.PREndDate = @prenddate
 	       	    and t.Employee = @employee and t.InUseBatchId is null and e.SubjToAutoEarns = 'Y' and t.PaySeq = @payseq
 	        union all
 	        --select 0, a.Amt/e.Factor, a.EarnCode, h.PostDate -- CHS	02/15/2011	- #142620 deal with divide by zero 
 	        select 0, 
 				case when e.Factor = 0.00 then 0.00 else a.Amt/e.Factor end, 
 				a.EarnCode, 
 				h.PostDate
 	        from dbo.bPRTA a with (nolock)     -- existing timecard addons
 	        join dbo.bPRTH h with (nolock) on h.PRCo = a.PRCo and h.PRGroup = a.PRGroup and h.PREndDate = a.PREndDate
 	            and h.Employee = a.Employee and h.PaySeq = a.PaySeq and h.PostSeq = a.PostSeq
 	        join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
 	        where a.PRCo = @co and a.PRGroup = @prgroup and a.PREndDate = @prenddate
 	       	    and a.Employee = @employee and h.InUseBatchId is null and e.SubjToAutoEarns = 'Y' and a.PaySeq = @payseq
 	        union all
 	        --select b.Hours, b.Amt/e.Factor, b.EarnCode, b.PostDate -- CHS	02/15/2011	- #142620 deal with divide by zero 
 	        select b.Hours, 
 				case when e.Factor = 0.00 then 0.00 else b.Amt/e.Factor end, 
 				b.EarnCode, 
 				b.PostDate
 	        from dbo.bPRTB b with (nolock)     -- new entries may exist in current batch
 	        join dbo.bPREC e with (nolock) on e.PRCo = b.Co and e.EarnCode = b.EarnCode
 	        where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.Employee = @employee
 	            and PaySeq = @payseq and b.BatchTransType = 'A' and e.SubjToAutoEarns = 'Y'
 	        order by t.PostDate
 			end
		else
     		begin
 	        declare bcAccumEarns cursor for
 	        select t.Hours, t.Amt, t.EarnCode, t.PostDate
 	        from dbo.bPRTH t with (nolock)     -- existing timecards
 	        join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
 	        where t.PRCo = @co and t.PRGroup = @prgroup and t.PREndDate = @prenddate
 	       	    and t.Employee = @employee and t.InUseBatchId is null and e.SubjToAutoEarns = 'Y' and t.PaySeq = @payseq
 	        union all
 	        select 0, a.Amt, a.EarnCode, h.PostDate
 	        from dbo.bPRTA a with (nolock)     -- existing timecard addons
 	        join dbo.bPRTH h with (nolock) on h.PRCo = a.PRCo and h.PRGroup = a.PRGroup and h.PREndDate = a.PREndDate
 	            and h.Employee = a.Employee and h.PaySeq = a.PaySeq and h.PostSeq = a.PostSeq
 	        join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
 	        where a.PRCo = @co and a.PRGroup = @prgroup and a.PREndDate = @prenddate
 	       	    and a.Employee = @employee and h.InUseBatchId is null and e.SubjToAutoEarns = 'Y' and a.PaySeq = @payseq
 	        union all
 	        select b.Hours, b.Amt, b.EarnCode, b.PostDate
 	        from dbo.bPRTB b with (nolock)     -- new entries may exist in current batch
 	        join dbo.bPREC e with (nolock) on e.PRCo = b.Co and e.EarnCode = b.EarnCode
 	        where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.Employee = @employee
 	            and PaySeq = @payseq and b.BatchTransType = 'A' and e.SubjToAutoEarns = 'Y'
 	        order by t.PostDate
     		end
         
		open bcAccumEarns
        select @openAccumEarns = 1
         
		-- loop through earnings by date cursor to get totals
		next_AccumEarns:
			fetch next from bcAccumEarns into @prthhours, @prthamt, @prthearncode, @prthpostdate
 
			if @@fetch_status <> 0 goto end_AccumEarns
 
			select @accumearnsfound = 'Y' --issue 22878

			if @savepostdate is null or @savepostdate <> @prthpostdate select @daycount = @daycount + 1  -- accum days
			select @savepostdate = @prthpostdate
 
			select @tothours = @tothours + @prthhours, @totamt = @totamt + @prthamt -- accum hours & amounts
 
			goto next_AccumEarns
 
		end_AccumEarns: -- close earnings accumulation cursor
    	    close bcAccumEarns
    	    deallocate bcAccumEarns
			select @openAccumEarns = 0
         
             -- Non True earnings require total of all True earnings for Tax State, Unempl State, and Local Code distribution
             if @trueYN = 'N'
                 begin
                 select @totearns = isnull(sum(t.Amt),0)
                 from dbo.bPRTH t with (nolock)   -- existing Timecards
                 join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
                 where t.PRCo = @co and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
                     and t.PaySeq = @payseq and t.InUseBatchId is null and e.TrueEarns = 'Y'
   				  and e.SubjToAutoEarns='Y' --issue 25651 added for issue rejection #2
         
                 select @totearns = @totearns + isnull(sum(Amt),0)
                 from dbo.bPRTB t with (nolock)   -- any new entries in the current batch
                 join bPREC e on e.PRCo = t.Co and e.EarnCode = t.EarnCode
                 where t.Co = @co and t.Mth = @mth and t.BatchId = @batchid and t.BatchTransType = 'A'
                     and t.Employee = @employee and t.PaySeq = @payseq and e.TrueEarns = 'Y'
   				  and e.SubjToAutoEarns='Y' --issue 25651 added for issue rejection #2
                 end

			-- Calculate earnings amounts
			SELECT @hours = 0, @rate = 0, @amt = 0, @shift = 1

			-- rate per Day
			IF @method = 'D'
			BEGIN
				IF @trueYN = 'N' AND @totamt <> 0 SELECT @amt = @daycount * @rateamt
				ELSE IF @trueYN = 'Y' SELECT @amt = @daycount * @rateamt
			END

			-- Rate of Gross
			ELSE IF @method = 'G' SELECT @amt = @totamt * @rateamt

            -- Rate per Hour
            ELSE IF @method='H'
				BEGIN
				IF @stdhours = 'N' SELECT @amt = @prpchours * @rateamt     -- use Pay Pd std hours
				IF @stdhours = 'Y' AND @praehours <> 0 SELECT @amt = @praehours * @rateamt -- use auto earnings hours
				IF @stdhours = 'Y' AND @praehours = 0 SELECT @amt = @tothours * @rateamt  -- use actual hrs for calculation
				-- Moved lines below out of 'Method' logic, posted hours must be set for all method types - #141210
				--#140890 brought code up from commented lines below.
				-- Posted hours				
--				IF @stdhours = 'N' SELECT @hours = @prpchours     -- use Pay Pd std hours
--				IF @stdhours = 'Y' SELECT @hours = @praehours     -- use override hours
--				IF @hours <> 0 SELECT @rate = @rateamt	                 
				END

            -- Flat Amount
            ELSE IF @method = 'A'
                 BEGIN
                 IF @trueYN = 'N' and @totamt <> 0 SELECT @amt = @rateamt
                 IF @trueYN = 'Y' SELECT @amt = @rateamt
                 END

            -- Rate of STE
            ELSE IF @method = 'S' SELECT @amt = @totamt * @rateamt
         
			-- Posted hours are set regardless of Method used, removed it from 'Method H' logic above. - Issue #141210 
			-- Posted hours				
			IF @stdhours = 'N' SELECT @hours = @prpchours     -- use Pay Pd std hours
			IF @stdhours = 'Y' SELECT @hours = @praehours     -- use override hours
			IF @method = 'H' AND @hours <> 0 SELECT @rate = @rateamt 


			-- #136039 Routine
			-- #141210 - commented out 'ELSE IF' to disconnect it from the rest of the 'ELSE IF' method logic above.
			--	because 'bspPR_AU_RDOAccrual' executed below returns @hours as well as @amt. 
--			ELSE IF @method = 'R'
			IF @method = 'R'
			BEGIN --Routine
			
				IF @routine IS NULL
				BEGIN
					SELECT @errmsg = 'Missing Routine for earn code ' + CONVERT(VARCHAR(4),@earncode), @rcode = 1
					GOTO bspexit
				END

				-- get procedure name --#140370 get MiscAmt1 as well
				SELECT @procname = NULL, @MiscAmt1 = NULL, @MiscAmt2 = NULL
				
				SELECT @procname = ProcName, @MiscAmt1 = MiscAmt1, @MiscAmt2 = MiscAmt2 
				FROM dbo.bPRRM 
				WHERE PRCo = @co AND Routine = @routine
				
				IF @procname IS NULL
				BEGIN
					SELECT @errmsg = 'Missing Routine procedure name for earn code ' + CONVERT(VARCHAR(4),@earncode), @rcode = 1
					GOTO bspexit
				END
				IF not exists(SELECT * FROM sysobjects WHERE NAME = @procname and TYPE = 'P')
				BEGIN
					SELECT @errmsg = 'Invalid Routine procedure - ' + @procname, @rcode = 1
					GOTO bspexit
				END

				SELECT @rate = @rateamt

				IF @procname IN ('bspPR_AU_AmtPerDay', 'bspPR_CA_AmtPerDay')--compute amount per day based on subject earnings, eg. Fare allow/1st aid/Travel allow
				BEGIN
					EXEC @rcode = @procname @co, @earncode, @prgroup, @prenddate, @employee, @payseq, NULL, NULL, 
									NULL, 'N', 'N', @rate, @amt OUTPUT, @errmsg OUTPUT
					IF @@error <> 0 SELECT @rcode = 1
					IF @rcode <> 0 GOTO bspexit
				END

				-- EN 06/05/2012	- D-05200/TK-152389/#146483
				ELSE IF @procname = 'bspPR_AU_AmountPerDiemAward' --compute amount per day award with hours thresholds from Routine Master
				BEGIN
					EXEC @rcode = @procname @co,			--PR Company
											@earncode,		--Auto Earning Code
											'N',			--Flag indicating an amount is being computed for auto earnings
											@prgroup,		--PR Group of pay period to which the auto earnings is being applied
											@prenddate,		--Pay Period Ending Date
											@employee,		--Employee
											@payseq,		--Pay Sequence
											@MiscAmt1,		--hours threshold for weekdays
											@MiscAmt2,		--hours threshold for weekends
											NULL, 
											NULL, 
											NULL, 
											@rate,			--per day amount to compute
											@amt OUTPUT,	--amount of award
											@errmsg OUTPUT
					IF @@error <> 0 SELECT @rcode = 1
					IF @rcode <> 0 GOTO bspexit
				END

				-- CHS 06/05/2011	- #146557 TK-15385 D-05231
				ELSE IF @procname IN ('bspPR_AU_OTMealAllow', 'bspPR_AU_OTCribAllow', 'bspPR_AU_OTWeekendCrib', 'bspPR_AU_Allowance')
				-- bspPR_AU_OTMealAllow: compute overtime meal allowance
				-- bspPR_AU_OTCribAllow: compute overtime crib allowance
				-- bspPR_AU_OTWeekendCrib: compute overtime meal/rest/crib allowance
				BEGIN
					EXEC @rcode = @procname @co, @earncode, 'N', @prgroup, @prenddate, @employee, @payseq, NULL, NULL, 
									NULL, @rate, @amt OUTPUT, @errmsg OUTPUT
					IF @@error <> 0 SELECT @rcode = 1
					IF @rcode <> 0 GOTO bspexit
				END

				-- EN 08/16/2012 B-10534/TK-18448 added this call
				ELSE IF @procname = 'bspPR_AU_RDOAccrualDaily' --compute RDO daily accrual
				BEGIN
					EXEC @rcode = @procname @prco = @co,				--PR Company
											@earncode = @earncode,		--Auto Earning Code
											@prgroup = @prgroup,		--PR Group
											@prenddate = @prenddate,	--Pay Period Ending Date
											@employee = @employee,		--Employee
											@payseq = @payseq,			--Pay Sequence
											@rate = @rate,				--rate per RDO hour
											@routine = @routine,		--routine name
											@hours = @hours OUTPUT,		--RDO hours for the pay period
											@amt = @amt OUTPUT,			--RDO amount for the pay period
											@errmsg = @errmsg OUTPUT
					IF @@error <> 0 SELECT @rcode = 1
					IF @rcode <> 0 GOTO bspexit
				END

				-- EN 08/29/2012 D-05698/TK-17502 add ability to call ROSG routine as an auto earning
				ELSE IF @procname IN ('bspPR_AU_ROSG') --compute rate of gross earnings for Australia, eg. leave loading
				BEGIN
					--get accumulated YTD earnings for the earn code
					DECLARE @ytdearns bDollar
					EXEC	@rcode = [dbo].[vspPRProcessGetAccumSubjEarnAUS]
							@prco = @co,
							@prgroup = @prgroup,
							@prenddate = @prenddate,
							@employee = @employee,
							@earncode = @earncode,
							@payseq = @payseq,
							@ytdearns = @ytdearns OUTPUT,
							@errmsg = @errmsg OUTPUT
					--compute the auto earnings amount
    				EXEC @rcode = @procname @prco = @co,
    										@earncode = @earncode,
											@addonYN = 'N',
											@prgroup = @prgroup,
											@prenddate = @prenddate, 
    										@employee = @employee,	
    										@payseq = @payseq,
    										@craft = NULL,			
    										@class = NULL, 
    										@template = NULL,	
    										@rate = @rate,		
    										@ytdearns = @ytdearns,		
    										@exemptamt = @MiscAmt1,
    										@amt = @amt OUTPUT, 
    										@errmsg = @errmsg OUTPUT
   					IF @@ERROR <> 0 SELECT @rcode = 1
    				IF @rcode <> 0 GOTO bspexit
				END

				ELSE
				-- #140370  Use general purpose to execute all other routines including custom routines.  
				-- These routines must declare all input/output parameters, even if not all are used in the routine.
				-- Input parameters include:
				--		@co		PR Company
				--		@earncode	Earnings Code being computed
				--		@prgroup	PR Group of the pay period being posted to
				--		@prenddate	Pay Period Ending Date
				--		@employee	Employee for whom to compute the earnings
				--		@payseq
				--		@rate		Highest hourly rate comparing PREH.Rate to the rate derived from Craft/Class/Template 
				--					hierachy comparing Timecard Code passed in from the front-end against effective date
				--					to select from old/new rate.  
				--		@tothours	total hours posted to PRTH and PRTB that is subject to Auto Earnings
				--		@totamt		total earnings amount posted to PRTH, PRTB and Addon Earnings that is subject to Auto Earnings
				--		@stdhours	from PRAE.StdHours ... =Y if using overriding PRPC.Hrs value with PRAE.Hours
				--		@praehours	Hours column from PRAE
				--		@prpchours	Hrs column from PRPC
				--		@daycount	# of days for which timecards have been posted to this employee in the pay period 
				--		@MiscAmt1	value from bPRRM
				--	
				-- Output parameters include:
				--		@hours		hours computation
				--		@amt		amount computation
				--		@errmsg
				BEGIN
					EXEC @rcode = @procname @co, @earncode, @prgroup, @prenddate, @employee, @payseq, @rate, 
									@tothours, @totamt, @stdhours, @praehours, @prpchours, @daycount, @MiscAmt1,
									@hours OUTPUT, @amt OUTPUT, @errmsg OUTPUT
					IF @@error <> 0 SELECT @rcode = 1
					IF @rcode <> 0 GOTO bspexit
				END

			END --Routine
         
             -- use Employee override or standard annual limit
             select @limit= case @ovrstdlimitYN when 'Y' then @limitovramt else @StandardLimit end
         
             if @limit = 0 goto end_LimitCheck     -- skip limit check
         
         
         	/* #14690 - do limit check based on limit period; annual, pay period or monthly */
         	--Annual limit check
         	if @limitperiod = 'A'
         	BEGIN
             -- year-to-date accums based on year of expected paid month
             
/*Issue 137971 	             
             select @a1 = isnull(sum(Amount),0)
             from dbo.bPREA with (nolock)
             where PRCo = @co and Employee = @employee and datepart(year,Mth) = datepart(year,@paidmth)
                 and EDLType = 'E' and EDLCode = @earncode
*/                 

             select @a1 = isnull(sum(Amount),0)
             from dbo.bPREA with (nolock)
             where PRCo = @co and Employee = @employee and Mth between @beginmth and @endmth
                 and EDLType = 'E' and EDLCode = @earncode                 
                 
                 
             -- current amounts from earlier Pay Periods where Final Accum update has not been run
             select @a2 = isnull(sum(d.Amount),0)
             from dbo.bPRDT d with (nolock)
             join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
                 and s.Employee = d.Employee and s.PaySeq = d.PaySeq
             join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
             where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
                 and d.EDLType = 'E' and d.EDLCode = @earncode
            	    and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
            	    and ((s.PaidMth is null and datepart(year,case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end) = datepart(year,@paidmth))
         			or (datepart(year,s.PaidMth) = datepart(year,@paidmth)))
         		and c.GLInterface = 'N'
         		
--removed Issue 137971 code to compute @a2 amount and restored previous code which is working correctly - EN 3/12/10
--             select @a2 = isnull(sum(d.Amount),0)
--             from dbo.bPRDT d with (nolock)
--             join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
--                 and s.Employee = d.Employee and s.PaySeq = d.PaySeq
--             join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
--             where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
--                 and d.EDLType = 'E' and d.EDLCode = @earncode
--            	    and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
--            	    and (s.PaidMth is null and @paidmth between @beginmth and @endmth)
--         			or (s.PaidMth between @beginmth and @endmth)
--         		and c.GLInterface = 'N'
         		         		
/*Issue 137971           		
             -- old amounts from earlier Pay Periods where Final Accum update has not been run
             select @a3 = isnull(sum(OldAmt),0)
             from dbo.bPRDT d with (nolock)
             join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
             where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
                 and d.EDLType = 'E' and d.EDLCode = @earncode
            	    and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
            	    and datepart(year,d.OldMth) = datepart(year,@paidmth) and c.GLInterface = 'N'
*/
             select @a3 = isnull(sum(OldAmt),0)
             from dbo.bPRDT d with (nolock)
             join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
             where d.PRCo = @co and d.PRGroup = @prgroup and d.Employee = @employee
                 and d.EDLType = 'E' and d.EDLCode = @earncode
            	    and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
            	    and d.OldMth between @beginmth and @endmth and c.GLInterface = 'N'
            	    
/*Issue 137971              	    
             -- old amounts from current and later Pay Periods - need to back out of accums
             select @a4 = isnull(sum(OldAmt),0)
             from dbo.bPRDT with (nolock)
             where PRCo = @co and PRGroup = @prgroup and Employee = @employee
                 and EDLType = 'E' and EDLCode = @earncode
            	    and (PREndDate > @prenddate or (PREndDate = @prenddate and PaySeq >= @payseq))
            	    and datepart(year,OldMth) = datepart(year,@paidmth)
*/            	    
             select @a4 = isnull(sum(OldAmt),0)
             from dbo.bPRDT with (nolock)
             where PRCo = @co and PRGroup = @prgroup and Employee = @employee
                 and EDLType = 'E' and EDLCode = @earncode
            	    and (PREndDate > @prenddate or (PREndDate = @prenddate and PaySeq >= @payseq))
            	    and OldMth between @beginmth and @endmth
            	    
            	    
             --  year-to-date is accums + net from earlier Pay Pds - old from later Pay Pds
             select @ytdamt = @a1 + (@a2 - @a3) - @a4
 
 			 -- #130542  Adjust ytdamt for entries posted to this batch or an earler pay seq
 			 -- add entries posted to this batch for an earlier pay seq
 			 select @a5 = isnull(sum(Amt),0)
 			 from dbo.bPRTB with (nolock)
 			 where Co = @co and Mth = @mth and BatchId = @batchid and Employee = @employee and 
 				EarnCode = @earncode and BatchTransType = 'A' and PaySeq < @payseq
 			 -- delete entries posted to this batch for an earlier pay seq
 			 select @a6 = isnull(sum(Amt),0)
 			 from dbo.bPRTB with (nolock)
 			 where Co = @co and Mth = @mth and BatchId = @batchid and Employee = @employee and 
 				EarnCode = @earncode and BatchTransType = 'D' and PaySeq < @payseq
 			 select @ytdamt = @ytdamt + @a5 - @a6
 			 -- end #130542

			 --#130542 commented out ... replaced with code block above 
 			 --select @ytdamt = @ytdamt + @addlaccum --issue 122531 include any amounts posted during this run in the ytd accum amount

             -- adjust for annual limit
             if abs(@ytdamt + @amt) > abs(@limit) select @amt = @limit - @ytdamt
         	goto end_LimitCheck
         	END
         
         	-- Pay Period limit check
         	if @limitperiod = 'P'
         	BEGIN
         	-- amounts from unposted time cards
         	 select @a1 = isnull(sum(Amt),0)       
         	    from dbo.bPRTB a with (nolock)
         		join dbo.bHQBC b with (nolock) on a.Co=b.Co and a.Mth=b.Mth and a.BatchId=b.BatchId
         		where b.Co = @co and b.PRGroup = @prgroup and b.PREndDate = @prenddate
         	     	and a.Employee = @employee and a.PaySeq <= @payseq and a.EarnCode = @earncode
         			and a.BatchTransType <> 'D'	-- exclude timecards flagged for delete
         	-- amounts from posted time cards 
         	select @a2 = isnull(sum(Amt),0)
         		from dbo.bPRTH with (nolock)
         		where PRCo=@co and PRGroup=@prgroup and PREndDate=@prenddate and Employee=@employee
         			and PaySeq <= @payseq and EarnCode=@earncode and InUseBatchId is null --don't use timecards pulled back into a batch
         	select @accumamt = @a1 + @a2
       	if abs(@accumamt + @amt) > abs(@limit) select @amt = @limit - @accumamt
         	goto end_LimitCheck
         	END
         
         	-- Monthly limit check
         	if @limitperiod = 'M'
         	BEGIN
         	-- amounts from unposted time cards
         	 select @a1 = isnull(sum(Amt),0)       
         	    from dbo.bPRTB a with (nolock)
         		join dbo.bHQBC b with (nolock) on a.Co=b.Co and a.Mth=b.Mth and a.BatchId=b.BatchId
         		join dbo.bPRPC c with (nolock) on b.Co=c.PRCo and b.PRGroup=c.PRGroup and b.PREndDate=c.PREndDate
         		where b.Co = @co and b.PRGroup = @prgroup and a.Employee = @employee and a.EarnCode = @earncode
         			and ((c.PREndDate < @prenddate and c.LimitMth = @limitmth) or (c.PREndDate = @prenddate and
         			a.PaySeq <= @payseq)) and a.BatchTransType <> 'D'
         	-- amounts from posted time cards 
         	select @a2 = isnull(sum(Amt),0)
         		from dbo.bPRTH a with (nolock)
         		join dbo.bPRPC b with (nolock) on a.PRCo=b.PRCo and a.PRGroup=b.PRGroup and a.PREndDate=b.PREndDate
         		where a.PRCo=@co and a.PRGroup=@prgroup and Employee=@employee and a.EarnCode = @earncode
         			and ((b.PREndDate < @prenddate and b.LimitMth = @limitmth) or (b.PREndDate = @prenddate
         			and a.PaySeq <= @payseq))and a.EarnCode=@earncode and InUseBatchId is null --don't use timecards pulled back into a batch*/
         	select @accumamt = @a1 + @a2
         	if abs(@accumamt + @amt) > abs(@limit) select @amt = @limit - @accumamt
         	goto end_LimitCheck
         	END
         
             end_LimitCheck: -- finished with limit check
                 if @trueYN = 'N' and (@amt = 0 or ((@method = 'G' or @method = 'H') and @accumearnsfound = 'N'))   -- skip non_true earnings if 0.00 --issue 22878 skip if no earnings found for this pay seq and method is G or H
                 begin
                 if @openPaySeq = 1 goto next_PaySeq else goto next_AutoEarn
                 end
         
				 --#123590 if earn type has a limit, perform annual limit check for earn type
				 select @hqetannuallimit = 0, @accumamt = 0
				 select @hqetannuallimit = HQETLimit, @accumamt = AnnualEarnings from @EarnTypeEarnings where EarnType = @earntype

				 if @hqetannuallimit <> 0
					begin
					--get annual earnings for this employee/earn type and adjust amount for limit if needed
					if abs(@accumamt + @amt) > abs(@hqetannuallimit) select @amt = @hqetannuallimit - @accumamt
					--update annual earnings stored amt by added resulting amt
					update @EarnTypeEarnings set AnnualEarnings = AnnualEarnings + @amt where EarnType = @earntype
					end

                 -- get Job info
				 --Issue #135490, remove Job values related to State & LocalCodes & flags
                 if @jcco is not null and @job is not null
                     begin
                     -- get JC GL Co#
                     select @glco = GLCo from dbo.bJCCO with (nolock) where JCCo = @jcco
                     end
         
				 -- #119993; on mechanic timecards, use GLCo from EMCO if available
				 if @mechanicscc is not null and @emco is not null 
					begin
					select @glco = GLCo from dbo.bEMCO where EMCo = @emco
					end

                 -- get Equipment cost type for usage
                 select @equipctype = null
   --              if @emco is not null and @equip is not null
   --                  begin	/*14691 use labor cost type for mechanics time cost code */
   --      			if @mechanicscc is not null
   --      				begin
   --      				select @equipctype = LaborCT from dbo.bEMCO with (nolock) where EMCo=@emco
   --      				end
   --      			else
   --      				begin			
   --      		          select @equipctype = UsageCostType from dbo.bEMEM with (nolock) where EMCo = @emco and Equipment = @equip
   --      				end
   --                  end
   
   				--26439 only default equip cost type on job timecards ... use EMEM usage cost type (this replaces the commented out code above)
         			if @mechanicscc is null
         				begin
         		          	select @equipctype = UsageCostType from dbo.bEMEM with (nolock) where EMCo = @emco and Equipment = @equip
                     	end
         
                 -- set Day Number
                 select @daynum = datediff(day, @begindate, @sendpostdate) + 1
         
                 -- use Employee GL Co unless overridden by JC GL Co#
                 if @glco is null select @glco = @empglco
         
                 -- use Payroll company GL Co if Employee company is null unless overridden by JC GL Co#
                 if @glco is null select @glco = @prglco
         
				-- Get State and Local defaults
				--Issue #135490, moved code to common procedure below which could be accessed by other procedures
				exec @rcode = vspPRGetStateLocalDflts @co, @employee, @jcco, @job, @localcode output, @taxstate output,
					@unempstate output, @insstate output, @errmsg output
				if @rcode <> 0 goto bspexit
	        
                 -- Insurance State and Code
                 if @inscode is not null
                     begin
                     -- check for rate based Insurance Code override
                     select @overinscode = null
                     select @overinscode = OverrideInsCode
                     from dbo.bPRIN with (nolock)
                     where PRCo = @co and State = @insstate and InsCode = @inscode
                         and UseThreshold = 'Y' and ThresholdRate <= @rate
                     if @overinscode is not null select @inscode = @overinscode  -- use override Insur code
                     end
         
                 -- Department
                 if @prdept is null select @prdept = @empprdept
                 -- Craft and Class
                 if @craft is not null and @class is not null
                     begin
                     -- check for Job Craft override
    
                     if @jcco is not null and @job is not null
                         begin
                         select @jobcraft = null
                         select @jobcraft = JobCraft
                         from dbo.bPRCT t with (nolock)
                         join dbo.bJCJM j with (nolock) on j.CraftTemplate = t.Template
                         where t.PRCo = @co and t.Craft = @craft and j.JCCo = @jcco and j.Job = @job
                             and t.RecipOpt = 'O'
                         if @jobcraft is not null select @craft = @jobcraft  -- use Job Craft
                         end
                     end
         

                 -- true earnings and nontrue earnings if total earnings are negative are ready for posting
                 if @trueYN = 'Y' or (@trueYN = 'N' and @totearns <= 0) goto add_TimeCard
         
                 /****** Non True Earnings Distribution *****/
            	    select @openNonTrueDist = 0, @saveamt = @amt, @savehours = @hours, @lastseq = 0, @disamt = 0
         
                 -- create a cursor on Tax State, Unemployment State, and Local Code
            	    declare bcNonTrueDist cursor for
                 select TaxState, UnempState, LocalCode
            	    from dbo.bPRTH t with (nolock)    -- existing Timecards
                 join dbo.bPREC e with (nolock) on t.PRCo = e.PRCo and t.EarnCode = e.EarnCode
                 where t.PRCo = @co and t.PRGroup = @prgroup and t.PREndDate = @prenddate
            		   and t.Employee = @employee and t.PaySeq = @payseq and t.InUseBatchId is null and e.TrueEarns = 'Y'
    			  and e.SubjToAutoEarns='Y' --issue 25651
                 union
            	    select TaxState, UnempState, LocalCode
                 from dbo.bPRTB t with (nolock)    -- new entries may exist in current batch
                 join dbo.bPREC e with (nolock) on t.Co = e.PRCo and t.EarnCode = e.EarnCode
                 where t.Co = @co and t.Mth = @mth and t.BatchId = @batchid and t.Employee = @employee
                    and t.PaySeq = @payseq and t.BatchTransType = 'A' and e.TrueEarns = 'Y'
    			  and e.SubjToAutoEarns='Y' --issue 25651
            	    order by TaxState, UnempState, LocalCode
         
            	    open bcNonTrueDist
             	select @openNonTrueDist = 1
         
                 next_NonTrueDist:    -- cycle through all posted Tax State, Unemployment State, and Local Code combinations
                     fetch next from bcNonTrueDist into @taxstate, @unempstate, @taxlocalcode
         
           	        if @@fetch_status <> 0
                         -- close Non True Distribution cursor
                         begin
                         close bcNonTrueDist
                         deallocate bcNonTrueDist
                         select @openNonTrueDist = 0
         
                         if @saveamt <> @disamt -- update the last seq with rounding
                             begin
                      	    update dbo.bPRTB
           	                set Amt = Amt + (@saveamt - @disamt)
           	                where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @lastseq
           	                if @@rowcount = 0
           		                begin
            			            select @errmsg = 'Unable to update difference for Employee ' + convert(varchar(10),@employee) +
            				             ' into PR Timecard Batch!', @rcode = 1
            			            goto bspexit
           		                end
                             end

						 --#130542 commented out ... no longer needed
						 --select @addlaccum = @addlaccum + @amt --issue 122531 add amount to total amount posted for this auto earning during this run

                         if @openPaySeq = 1 goto next_PaySeq

						 goto next_AutoEarn

                         end
                     if @taxstate is null or @unempstate is null
                         begin
                         select @errmsg = 'Posting has stop - Employee ' + convert(varchar(10),@employee)
                         + ' has a time card line missing a Tax and/or Unemployment State.', @rcode = 1
                         goto bspexit
                         end
         
                     -- get all True earnings posted to this Tax State, Unemployment State and Local Code
            	        select @stateearns = isnull(sum(t.Amt),0)
                     from dbo.bPRTH t with (nolock)
                     join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
                     where t.PRCo = @co and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
                         and t.PaySeq = @payseq and t.TaxState = @taxstate and t.UnempState = @unempstate
                         and t.InUseBatchId is null and isnull(t.LocalCode,'') = isnull(@taxlocalcode,'')
                         and e.TrueEarns = 'Y' and e.SubjToAutoEarns='Y' --#136987 added SubjToAutoEarns condition
         
                     select @stateearns = @stateearns + isnull(sum(Amt),0)
                     from dbo.bPRTB t with (nolock)
                     join dbo.bPREC e with (nolock) on e.PRCo = t.Co and e.EarnCode = t.EarnCode
                     where t.Co = @co and t.Mth = @mth and t.BatchId = @batchid and t.BatchTransType = 'A'
                         and t.Employee = @employee and t.PaySeq = @payseq and t.TaxState = @taxstate
                         and t.UnempState = @unempstate and isnull(t.LocalCode,'') = isnull(@taxlocalcode,'')
                         and e.TrueEarns = 'Y' and e.SubjToAutoEarns='Y' --#136987 added SubjToAutoEarns condition
         
            	        -- distribute amount and hours as proportion of total earnings
                     select @amt = @saveamt * (@stateearns / @totearns)
                     select @hours = @savehours * (@stateearns / @totearns)
                     select @localcode = @taxlocalcode
         
                 add_TimeCard:   -- add new entry to Timecard Batch
                     if @amt <> 0
                         BEGIN
                         -- get next available seq #
                         select @seq = isnull(max(BatchSeq),0)+ 1
                         from dbo.bPRTB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
         
            		        insert dbo.bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, Type, DayNum,
                             PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, Equipment, EMGroup,CostCode, RevCode,
                             EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode, PRDept,
                             Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, EquipPhase)
            	      	    values (@co, @mth, @batchid, @seq, 'A', @employee, @payseq,
         				case when @mechanicscc is not null then 'M' else 'J' end, @daynum,
                             @sendpostdate, @jcco, @job, @phasegroup, @phase, @glco, @emco, @equip, @emgroup,@mechanicscc,
         				@revcode,@equipctype, @usageunits, @taxstate, @localcode, @unempstate, @insstate, @inscode,
         				@prdept,@crew, @cert, @craft, @class, @earncode, @shift, @hours, @rate, @amt, 
						case when @equip is not null then @phase else null end)
                         if @@rowcount = 0
            			        begin
            			        select @errmsg = 'Unable to insert entry for Employee ' + convert(varchar(6),@employee) +
            				     ' into PR Timecard Batch!', @rcode = 1
            			        goto bspexit
                             end
                         -- save last posting seq # and accumulate amount posted
                         select @lastseq = @seq, @disamt = @disamt + @amt

         			--17288 count employees added to batch and return # 
         			 if @nextemployee <> @prevemployee -- bump up employee counter 
         			  	begin
         				select @employeecount = @employeecount + 1
         				select @prevemployee = @nextemployee
         				end
                         END
         		
                   if @trueYN = 'N' and @totearns > 0 goto next_NonTrueDist -- next distribution for nontrue earnings

				   --#130542 commented out ... no longer needed
				   --select @addlaccum = @addlaccum + @amt --issue 122531 add amount to total amount posted for this auto earning during this run
          	
                   if @openPaySeq = 1 goto next_PaySeq
           		
         	  goto next_AutoEarn
         
         bspexit:
             if @openAutoEarn = 1
                 begin
            		close bcAutoEarn
            		deallocate bcAutoEarn
            		end
             if @openPaySeq = 1
                 begin
            		close bcPaySeq
            		deallocate bcPaySeq
            		end
             if @openDeleteEarns = 1
                 begin
            		close bcDeleteEarns
            		deallocate bcDeleteEarns
            		end
             if @openAccumEarns = 1
                 begin
            		close bcAccumEarns
            		deallocate bcAccumEarns
            		end
             if @openNonTrueDist = 1
                 begin
            		close bcNonTrueDist
            		deallocate bcNonTrueDist
            		end
             if @rcode > 0 select @errmsg = isnull(@errmsg,'') --+ char(13) + char(10) + '[bspPRAutoEarnInit]'
             if @rcode = 0 select @empcount = convert (varchar (5),@employeecount)
             return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRAutoEarnInit] TO [public]
GO
