SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRTBInsertExistingTrans]
/****************************************************************
* Created: GG 06/06/07 - #17291 - Enhancement for V6.0
* Modified:  EN 11/24/08 - #126931  replaced code to add a 'Change' type bPRTB entry with call to vspPRTBAddCEntry
*			JG 02/09/2012 - TK-12388 - Added SMJCCostType and SMPhaseGroup
*			ECV 06/07/12 TK-14637 removed SMPhaseGroup. Use PhaseGroup instead.
*
* Used by the PR Timecard Entry to pull existing timecards into a 
* batch for change or delete, or create reversing entires based on
* timecards from another pay period.
*
* bPRTB insert trigger updates InUseBatchId in bPRTH
*
* Inputs:
*   @prco			PR Company #
*	@prgroup		PR Group
*	@prenddate		PR Ending Date 
*	@mth			Batch Month
*	@batchid		Batch ID#
*	@addoption		Add option: A = pull existing timecards, R = add reversing timecards
*	@revprenddate	PR Ending Date used to create reversing timecards
*	@revpayseq		Post to Pay Seq for reversing timecards, use original Pay Seq if null
*	@timecardtype	Timecard type filter: J = Job, M = Mechanics, null = both
*	@lastbatchid	Last Batch filter, uses Batch Month
*	@employee		Employee filter
*	@payseq			Payment Seq# filter
*	@postseq		Posting Seq# filter
*	@begindate		Beginning Timecard date filter
*	@enddate		Ending Timecard date filter
*	@craft			Craft filter
*	@class			Class filter
*	@earncode		Earnings code filter
*	@shift			Shift filter
*	@jcco			JC Co# filter
*	@job			Job filter
*	@phase			Phase fitler, exact match or all if null
*	@excludeifpaid	Y = skip if employee/pay seq is paid, N = include even if paid
*	@markasdelete	Y = flag batch entries for delete, N = flag for change - if reversing will be 'Add'
*
* Output:
*	@msg			Message returned with results
*
* Return value:
*   @rcode			0 = success, 1 = error
*   
****************************************************************/

@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @mth bMonth = null,
@batchid bBatchID = null, @addoption char(1) = null, @revprenddate bDate = null, @revpayseq tinyint = null,
@timecardtype char(1) = null, @lastbatchid bBatchID = null, @employee bEmployee = null,
@payseq tinyint = null, @postseq smallint = null, @begindate bDate = null, @enddate bDate = null,
@craft bCraft = null, @class bClass = null, @earncode bEDLCode = null, @shift tinyint = null,
@jcco bCompany = null, @job bJob = null, @phase bPhase = null, @smco bCompany = null, @smworkorder int = null, 
@smscope int=null, @smpaytype varchar(10)=null, @smcosttype smallint=null, @smjccosttype dbo.bJCCType=NULL, @smphasegroup dbo.bGroup=NULL,
@excludeifpaid bYN, @markasdelete bYN, @msg varchar(255) output

as
set nocount on

declare @rcode int, @count int, @invpayseq bYN, @prtbud_flag bYN, @opencursor tinyint,
	@errtext varchar(255), @status tinyint, @prbegindate bDate, @prthemployee dbo.bEmployee,
	@prthpayseq tinyint, @prthpostseq smallint, @anotherbatch bYN, @prthenddate bDate,
	@inusebatchid bBatchID, @batchseq int, @rc int, @errmsg varchar(255), @xpayseq tinyint,
	@prthpostdate bDate, @daynum smallint --#126931 added @daynum

    
select @rcode = 0, @count = 0, @anotherbatch = 'N', @invpayseq = 'N', @prtbud_flag = 'N', @opencursor = 0
   
-- validate current Timecard Batch Control entry
exec @rcode = bspHQBatchProcessVal @prco, @mth, @batchid, 'PR Entry', 'PRTB', @errtext output, @status output
if @rcode <> 0
	begin
 	select @msg = @errtext, @rcode = 1
 	goto vspexit
	end
if @status <> 0
	begin
	select @msg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
	goto vspexit
	end

--validate and set batch transaction type
if @addoption not in ('A','R')
	begin
	select @msg = 'Timecard option must be ''A'' or ''R''.', @rcode = 1
	goto vspexit
	end

-- check Timecard Batch table for custom fields
if exists(select top 1 1 from sys.syscolumns (nolock) where name like 'ud%' and id = object_id('dbo.PRTB'))
	set @prtbud_flag = 'Y'	-- bPRTB has custom fields
   
    
--get PR Begin Date for current pay period, used to calculate day number
select @prbegindate = BeginDate
from dbo.bPRPC (nolock)
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate

-- create cursor of eligible timecards
declare bcPRTH cursor local fast_forward for
select t.PREndDate, t.Employee, t.PaySeq, t.PostSeq, t.PostDate
from dbo.bPRTH t (nolock)
join dbo.bPRSQ s (nolock) on s.PRCo = t.PRCo and s.PRGroup = t.PRGroup and s.PREndDate = t.PREndDate
	and s.Employee = t.Employee and s.PaySeq = t.PaySeq
where t.PRCo = @prco and t.PRGroup = @prgroup
	and t.PREndDate = case @addoption when 'A' then @prenddate when 'R' then @revprenddate else '' end 
	and t.Type = isnull(@timecardtype,t.Type) and t.BatchId = isnull(@lastbatchid,t.BatchId)
	and t.Employee = isnull(@employee,t.Employee) and t.PaySeq = isnull(@payseq,t.PaySeq) and t.PostSeq = isnull(@postseq,t.PostSeq)
	and t.PostDate >= isnull(@begindate,t.PostDate) and t.PostDate <= isnull(@enddate,t.PostDate)
	and isnull(t.Craft,'') = isnull(@craft,isnull(t.Craft,'')) and isnull(t.Class,'') = isnull(@class,isnull(t.Class,''))
	and t.EarnCode = isnull(@earncode,t.EarnCode) and t.Shift = isnull(@shift,t.Shift)
	and isnull(t.JCCo,'') = isnull(@jcco,isnull(t.JCCo,''))	and isnull(t.Job,'') = isnull(@job,isnull(t.Job,''))
	and isnull(t.Phase,'') = isnull(@phase,isnull(t.Phase,''))
	and isnull(t.SMCo,'') = isnull(@smco, isnull(t.SMCo,'')) and isnull(t.SMWorkOrder,'')=isnull(@smworkorder,isnull(t.SMWorkOrder,''))
	and isnull(t.SMScope,'') = isnull(@smscope, isnull(t.SMScope,'')) and isnull(t.SMPayType,'')=isnull(@smpaytype,isnull(t.SMPayType,''))
	and isnull(t.SMCostType,0)=isnull(@smcosttype,isnull(t.SMCostType,0))
	and isnull(t.SMJCCostType,0)=isnull(@smjccosttype,isnull(t.SMJCCostType,0))
	and isnull(t.PhaseGroup,0)=isnull(@smphasegroup,isnull(t.PhaseGroup,0))
	and (@excludeifpaid = 'N' or (@excludeifpaid = 'Y' and s.CMRef is null))

--open cursor and set flags 
open bcPRTH
select @opencursor = 1, @anotherbatch = 0
    
--loop through all rows in cursor
pr_posting_loop:
	fetch next from bcPRTH into @prthenddate, @prthemployee, @prthpayseq, @prthpostseq, @prthpostdate

	if @@fetch_status <> 0 goto pr_posting_end

	-- check if Timecard in use in a batch
	select @inusebatchid = InUseBatchId
	from dbo.bPRTH (nolock)
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prthenddate
		and Employee = @prthemployee and PaySeq = @prthpayseq and PostSeq = @prthpostseq
	if @@rowcount = 0
		begin
		select @msg = 'Missing timecard', @rcode = 1
		goto vspexit
		end
	-- if timecard is in a batch set flag for return message and skip
	 if @inusebatchid is not null
         begin
         select @anotherbatch = 1 
         goto pr_posting_loop
         end
	
	-- #126931 compute day number based on timecard date
	select @daynum = datediff(day,@prbegindate,@prthpostdate)+1

	if @addoption = 'A'	-- pull existing timecards into batch
		begin
			--#126931
   			exec @rcode = vspPRTBAddCEntry @prco, @prgroup, @prthenddate, @mth, @batchid, @prtbud_flag,
				@prthemployee, @prthpayseq, @prthpostseq, @daynum, @markasdelete, 'N', null, null, null, 'N', null, @msg output
			if @rcode = 2 select @msg = 'Unable to add timecard into batch.', @rcode = 1
   			if @rcode <> 0 goto vspexit
		end

	if @addoption = 'R'		-- add reversing timecards into batch
		begin
		/* get next available sequence # for this batch */
		select @batchseq = isnull(max(BatchSeq),0)+1
		from dbo.bPRTB
		where Co = @prco and Mth = @mth and BatchId = @batchid

		insert dbo.bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType,
			Employee, PaySeq, PostSeq, Type, DayNum, PostDate,
			JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode,
			CompType, Component, RevCode, EquipCType, UsageUnits, TaxState, LocalCode,
			UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class, EarnCode,
			Shift, Hours, Rate, Amt, Memo, EquipPhase, SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType,
			SMJCCostType) 
		select @prco, @mth, @batchid, @batchseq, 'A',
			Employee, isnull(@revpayseq,PaySeq), PostSeq, Type, @daynum, PostDate,
			JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode,
			CompType, Component, RevCode, EquipCType, (-1*UsageUnits), TaxState, LocalCode,
    	 	UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class, EarnCode,
			Shift, (-1*Hours), Rate, (-1*Amt), Memo, EquipPhase, SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType,
			SMJCCostType
		from dbo.bPRTH
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prthenddate
			and Employee = @prthemployee and PaySeq = @prthpayseq and PostSeq = @prthpostseq
		if @@rowcount <> 1
			begin
			select @msg = 'Unable to add reversing timecard into batch.', @rcode = 1
			goto vspexit
			end

		-- check for invalid pay sequence within the posted to pay period 
		select @xpayseq = isnull(@revpayseq,@prthpayseq)
		exec @rc = bspPRPaySeqVal @prco, @prgroup, @prenddate, @xpayseq , @errmsg 
    	if @rc <> 0 select @invpayseq = 1

		end

	select @count = @count + 1	-- count timecards added to batch

    goto pr_posting_loop
    
pr_posting_end:
	close bcPRTH
    deallocate bcPRTH
	set @opencursor = 0

	select @msg = convert(varchar,@count) + ' entries have been added to this batch.'
	if @anotherbatch = 'Y' select @msg = char(10) + char(13) + 'One or more timecards were in another batch and could not be added.'
    if @invpayseq = 'Y' select @msg = char(10) + char(13) + 'Reversing timecards were added using one or more Pay Seq#s not valid for this Payroll.  Use Pay Period Control to set them up.'
           
vspexit:
    if @opencursor = 1
		begin
     	close bcPRTH
     	deallocate bcPRTH
     	end
    
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRTBInsertExistingTrans] TO [public]
GO
