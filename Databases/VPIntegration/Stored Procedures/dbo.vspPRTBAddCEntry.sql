SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPRTBAddCEntry]
/****************************************************************
* Created: EN 11/21/08 - #131132
* Modified:	EN 11/24/08 - #126931  Added params to allow for passing in specific earn code and/or hours
*			MH 02/01/11 - 142827 Added support for SM.
*           ECV 08/23/11 - Add SMCostType.
*			JG 02/09/12 - TK-12388 - Added SMJCCostType and SMPhaseGroup.
*           ECV 06/07/12 TK-14637 removed SMPhaseGroup. Use PhaseGroup instead.
*
* Called by bspPRSalaryDistrib (as of 6.1.1), and also vspPRTBAddCEntry, bspPRAutoOTPost and 
* bspPRAutoOTPostLevels (as of 6.2.0) 
* to add a 'Change' type entry to bPRTB.  Includes the facility to handle custom fields.
*
* bPRTB insert trigger updates InUseBatchId in bPRTH
*
* Inputs:
*   @prco			PR Company #
*	@prgroup		PR Group
*	@prenddate		PR Ending Date 
*	@mth			Batch Month
*	@batchid		Batch ID#
*	@employee		Employee #
*	@payseq			Pay Sequence
*	@postseq		Posting Sequence 
*	@prtbud_flag	Y = PRTB has custom ud fields
*	@employee		Employee filter
*	@payseq			Payment Seq# filter
*	@postseq		Posting Seq# filter
*	@daynum			Day number to post on bPRTB entry
*	@markasdelete	Y = flag batch entries for delete, N = flag for change - if reversing will be 'Add'
*	@overriderateamt	Y = override rate and amount with the following 2 input params
*	@o_rate			Rate to use for override
*	@o_amt			amount to use for override
*	@o_earncode		earn code to use for override
*	@overridehours	Y = override hours with the following input param
*	@o_hours		hours to use for override
*
* Output:
*	@msg			Message returned with results
*
* Return value:
*   @rcode			0 = success, 1 = error
*   
****************************************************************/

@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @mth bMonth = null,
@batchid bBatchID = null, @prtbud_flag bYN = 'N', @employee bEmployee = null, @payseq tinyint = null, 
@postseq smallint = null, @daynum smallint = null, @markasdelete bYN, @overriderateamt bYN = 'N',
@o_rate bUnitCost = 0, @o_amt bDollar = 0, @o_earncode bEDLCode =  null, @overridehours bYN = 'N', 
@o_hours bHrs = 0, @msg varchar(255) output

as
set nocount on

declare @rcode int, @batchseq int, @batchtranstype char(1), @earncode bEDLCode, @hours bHrs, 
	@rate bUnitCost, @amt bDollar, @errmsg varchar(255)

select @rcode = 0

--get next available sequence # for this batch
select @batchseq = isnull(max(BatchSeq),0)+1
from dbo.bPRTB with (nolock)
where Co = @prco and Mth = @mth and BatchId = @batchid
    
--determine transaction type   
select @batchtranstype = 'C'
if @markasdelete = 'Y' select @batchtranstype = 'D'

--determine earn code, rate, hours, amount
select @earncode = EarnCode, @hours = Hours, @rate = Rate, @amt = Amt	from dbo.bPRTH
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
	and Employee = @employee and PaySeq = @payseq and PostSeq = @postseq
if @overriderateamt = 'Y' and @o_rate is not null select @rate = @o_rate
if @overriderateamt = 'Y' and @o_amt is not null select @amt = @o_amt
if @o_earncode is not null select @earncode = @o_earncode
if @overridehours = 'Y' and @o_hours is not null select @hours = @o_hours

--add timecard entry
--142827 include SM fields.
insert dbo.bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType,
	Employee, PaySeq, PostSeq, Type, DayNum, PostDate,
	JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode,
	CompType, Component, RevCode, EquipCType, UsageUnits, TaxState, LocalCode,
	UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class, EarnCode,
	Shift, Hours, Rate, Amt, OldEmployee, OldPaySeq, OldPostSeq, OldType,
	OldPostDate, OldJCCo, OldJob, OldPhaseGroup, OldPhase, OldGLCo, OldEMCo, 
	OldWO, OldWOItem, OldEquipment, OldEMGroup, OldCostCode, OldCompType, OldComponent,
	OldRevCode, OldEquipCType, OldUsageUnits, OldTaxState, OldLocalCode, OldUnempState,
	OldInsState, OldInsCode, OldPRDept, OldCrew, OldCert, OldCraft, OldClass,
	OldEarnCode, OldShift, OldHours, OldRate, OldAmt, Memo, OldMemo, EquipPhase,
	OldEquipPhase, UniqueAttchID, SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType,
	SMJCCostType, 
	OldSMCo, OldSMWorkOrder, OldSMScope, OldSMPayType, OldSMCostType,
	OldSMJCCostType) 
select @prco, @mth, @batchid, @batchseq, @batchtranstype,
	Employee, PaySeq, PostSeq, Type, @daynum, PostDate,
	JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode,
	CompType, Component, RevCode, EquipCType, UsageUnits, TaxState, LocalCode,
	UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class, @earncode,
	Shift, @hours, @rate, @amt, Employee, PaySeq, PostSeq, Type,
	PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo,
	WO, WOItem, Equipment, EMGroup, CostCode, CompType, Component,
	RevCode, EquipCType, UsageUnits, TaxState, LocalCode, UnempState,
	InsState, InsCode, PRDept, Crew, Cert, Craft, Class,
	EarnCode, Shift, Hours, Rate, Amt, Memo, Memo, EquipPhase,
	EquipPhase, UniqueAttchID, SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType,
	SMJCCostType, 
	SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType,
	SMJCCostType
from dbo.bPRTH
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
	and Employee = @employee and PaySeq = @payseq and PostSeq = @postseq

if @@rowcount <> 1
	begin
	select @rcode = 2
	goto vspexit
	end

--handle custom fields
if @prtbud_flag = 'Y' 
	begin
	exec @rcode = bspBatchUserMemoInsertExisting @prco, @mth, @batchid,
		@batchseq, 'PR TimeCards', 0, @errmsg output
	if @rcode <> 0
		begin
		select @msg = 'Unable to update custom field(s) to PR Timecard Batch!'
		goto vspexit
		end
	end

vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRTBAddCEntry] TO [public]
GO
