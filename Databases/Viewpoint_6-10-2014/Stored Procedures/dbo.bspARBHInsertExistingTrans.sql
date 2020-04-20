SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBHInsertExistingTrans    Script Date: 8/28/99 9:36:05 AM ******/
CREATE procedure [dbo].[bspARBHInsertExistingTrans]
/***********************************************************
* CREATED BY  : CJW  5/29/97
* MODIFIED By : 
*		JM   08/04/98 - Added CMDeposit column to insert statement (ovelooked).
*		bc   08/20/98 - AR Misc Cash Columns.
*		JM   11/17/98 - removed case condition for DiscTaken and oldDiscTake in insert statement that
*					    recalls record to bARBL. Ref Issue 3227.
*		GG   04/26/00 - mods for MS
*		bc   01/09/00 - cannot add existing transactions with a JB source into an AR batch
*                   - can only add MS existing MS transactions into a Receipt batch
*		SR   01/10/01 - Uncommenting  case when @artranstype in ('M','C','W') then -DiscTaken else DiscTaken end,
*                     this statement should be based on artranstype
*		TJL  03/13/01 - Add ReasonCode
*		MV   06/29/01 - Issue 12769 BatchUserMemoInsertExisting
*		TJL  08/07/01 - Correctly add ALL EM related fields back into bARBL batch table upon 'Add Transaction'
*		TJL  09/07/01 - Issue #13931, Check EditTrans on 'P' or 'R' ARTransTypes.  If set 'N' do not allow adding back into batch.
*		TJL  10/02/01 - Issue #14776, Related to #13931, Modify error message sent to user when EditTrans = 'N'
*		TV   05/28/02 - Move Attchment back to posting table
*		TJL  07/01/03 - Issue #21610, Validate change in RecType at the header level
*		TJL  09/29/03 - Issue #22596, Correct NULL Source when calling bspBatchUserMemoInsertExisting from CashReceipts
*		GWC  03/11/04 - Issue #23960, Validate change in Contract at the header level
			  - Added with (nolock) to select statements 
*		TJL  02/08/08 - Issue #127006, Correct Missing TaxGroup when Transaction added back into batch.
*		TJL 06/02/08 - Issue #128286, ARInvoiceEntry International Sales Tax
*		TJL 11/13/09 - Issue #135335, Reverse issue #127006.  Batch Val problems when Applied Trans has TaxGroup but orig does not.
*
* USAGE:
*	This procedure is used by the AR Invoice Entry and
*	AR Cash Receipts programs to pull existing transactions
*	from bARTH into bARBH for editing.
*
*	Checks batch info in bHQBC, and transaction info in bARTH.
*	Adds entry to next available Seq# in bARBH
*
*	bARTH insert trigger will update InUseBatchId in bARTH
*
* INPUT PARAMETERS
*	Co         JC Co to pull from
*	Mth        Month of batch
*	BatchId    Batch ID to insert transaction into
*	AR         AR Trans to Pull
*	IncludeItems  Y will pull all items also
*	Source     AR Source

* OUTPUT PARAMETERS
*
* RETURN VALUE
*	0   success
*	1   fail
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @artrans bTrans,
@source char(10), @errmsg varchar(200) output
as

set nocount on

declare @artranstype char(1), @dtsource bSource, @errtext varchar(60), @inusebatchid bBatchID,
	@inuseby bVPUserName, @postedmth bMonth, @rcode int, @seq int, @status tinyint,
 	@applymth bMonth, @applytrans bTrans, @ARTHSource bSource, @formname varchar(30),
	@edittrans char(1)
   
select @rcode = 0

/* validate source */
if @source not in ('AR Invoice','AR Receipt','ARFinanceC')
	begin
    select @errmsg = @source + ' is invalid', @rcode = 1
    goto bspexit
	end
   
select @ARTHSource = h.Source, @edittrans = h.EditTrans	
from bARTH h with (nolock)
where h.ARCo = @co and h.Mth = @mth and h.ARTrans = @artrans

if @ARTHSource = 'JB' or (@ARTHSource = 'MS' and @source <> 'AR Receipt')
	begin
	select @errmsg = @ARTHSource + ' is an invalid source for this form', @rcode = 1
	goto bspexit
	end

if @edittrans = 'N'
	begin
	select @errmsg = 'Edits not allowed on any Retg Transactions or Payment transactions if related invoices have been deleted!', @rcode = 1
	goto bspexit
	end

/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'ARBH', @errtext output, @status output
if @rcode <> 0
	begin
	select @errmsg = @errtext, @rcode = 1
	goto bspexit
	end

if @status <> 0
	begin
	select @errmsg = 'Invalid Batch status -  must be open!', @rcode = 1
	goto bspexit
	end
   
/* all Transactions can be pulled into a batch as long as its InUseFlag is set to null
and month is same as current*/
select @inusebatchid = InUseBatchID, @artranstype=ARTransType, @postedmth=Mth
from ARTH with (nolock)
where ARCo=@co and Mth = @mth and ARTrans=@artrans 
   
if @@rowcount = 0
	begin
	select @errmsg = 'The AR Trans :' + isnull(convert(varchar(10),@artrans),'') + ' cannot be found.' , @rcode = 1
	goto bspexit
	end
if @artranstype is null
	begin
	select @errmsg ='The transaction type is invalid!'
	goto bspexit
	end
   
if @inusebatchid is not null
	begin
	select @dtsource=Source
	from HQBC with (nolock)
	where Co=@co and BatchId=@inusebatchid and Mth=@mth
	if @@rowcount<>0
		begin
		select @errmsg = 'Transaction already in use by ' +
		      isnull(convert(varchar(2),DATEPART(month, @mth)),'') + '/' +
		      isnull(substring(convert(varchar(4),DATEPART(year, @mth)),3,4),'') +
			' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' + isnull(@dtsource,''), @rcode = 1
 		goto bspexit
		end
	else
		begin
		select @errmsg='Transaction already in use by another batch!', @rcode=1
		goto bspexit
		end
	end

if @postedmth <> @mth
   	begin
	select @errmsg = 'The AR transaction was posted in a prior month. Cannot edit!' + isnull(convert(varchar(60),@postedmth),'') + ',' + isnull(convert(varchar(60), @mth),''), @rcode = 1
	goto bspexit
	end
if @source='AR Invoice' and @artranstype not in ('I','C','A','W')
	begin
	select @errmsg = 'Not a valid Invoice Transaction Type.  Cannot edit!', @rcode = 1
	goto bspexit
	end
if @source='AR Receipt' and @artranstype not in ('P','M')
	begin
	select @errmsg = 'Not a valid Receipt Transaction Type.  Cannot edit!', @rcode = 1
	goto bspexit
	end
if @source='ARFinanceC' and @artranstype not in ('F')
	begin
	select @errmsg = 'Not a valid Finance Charge Transaction Type.  Cannot edit!', @rcode = 1
	goto bspexit
	end
   
/* get next available sequence # for this batch */
select @seq = isnull(max(BatchSeq),0)+1 from bARBH where Co = @co and Mth = @mth and BatchId = @batchid

/* add AR to batch */
insert into bARBH (Co, Mth, BatchId, BatchSeq, TransType, ARTrans, Source, ARTransType, CustGroup,
	Customer, Invoice, CheckNo, Description, CustRef, RecType, TransDate, DueDate, DiscDate,
	CheckDate, AppliedMth, AppliedTrans, CMCo, CMAcct, CMDeposit, JCCo, Contract, CreditAmt,
	PayTerms, ReasonCode, Notes, oldCustRef, oldInvoice, oldCheckNo, oldDescription, oldTransDate, oldDueDate,
	oldDiscDate, oldCheckDate, oldCMCo, oldCMAcct, oldCMDeposit, oldCreditAmt, oldPayTerms, oldReasonCode,UniqueAttchID,
	oldRecType, oldJCCo, oldContract)
Select ARCo, @mth, @batchid, @seq, 'C', ARTrans, @source , ARTransType, CustGroup, Customer, Invoice,
	CheckNo, Description, CustRef, RecType, TransDate, DueDate, DiscDate, CheckDate, AppliedMth,
	AppliedTrans, CMCo, CMAcct, CMDeposit, JCCo, Contract, CreditAmt, PayTerms, ReasonCode, Notes,
 	/* Start filling in old values */
	CustRef, Invoice, CheckNo, Description, TransDate, DueDate, DiscDate, CheckDate, CMCo, CMAcct,
	CMDeposit, CreditAmt, PayTerms, ReasonCode, UniqueAttchID, RecType, JCCo, Contract 
from ARTH with (nolock)
where ARCo=@co and ARTrans=@artrans and Mth = @mth
   
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to AR Entry Batch!', @rcode = 1
	goto bspexit
	end
   
/* BatchUserMemoInsertExisting - update the user memo in the batch record */
Select @formname = case @source when 'AR Invoice'then 'AR InvoiceEntry'
                               when 'ARFinanceC'then 'AR FinanceCharge' end
if @source = 'AR Receipt'
	begin
	select @formname = case @artranstype when 'M' then 'AR MiscRec' else 'AR CashReceipts' end
	end

exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, @formname,
    0, @errmsg output
    if @rcode <> 0
		begin
		select @errmsg = 'Unable to update User Memos in ARBH', @rcode = 1
		goto bspexit
		end
   
insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType, LineType,
	Description,GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgTax, RetgPct, Retainage, DiscOffered,
	TaxDisc, DiscTaken, FinanceChg, ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, ContractUnits,
	Job, PhaseGroup, Phase, CostType, UM, JobUnits, JobHours, ActDate, INCo, Loc, MatlGroup, Material,
	UnitPrice, ECM, MatlUnits, CustJob, CustPO, EMCo, Equipment, EMGroup, CompType, Component, CostCode, EMCType, Notes,
/* oldvalues */
	oldRecType, oldLineType, oldDescription, oldGLCo,oldGLAcct, oldTaxGroup, oldTaxCode,
	oldAmount, oldTaxBasis, oldTaxAmount, oldRetgTax, oldRetgPct, oldRetainage, oldDiscOffered, oldTaxDisc, oldDiscTaken,
	oldFinanceChg, oldApplyMth, oldApplyTrans, oldApplyLine, oldJCCo, oldContract, oldItem, oldContractUnits,
	oldJob, oldPhaseGroup, oldPhase, oldCostType, oldUM, oldJobUnits, oldJobHours, oldActDate, oldINCo,
	oldLoc, oldMatlGroup, oldMaterial, oldUnitPrice, oldECM, oldMatlUnits, oldCustJob, oldCustPO,
	oldEMCo, oldEquipment, oldEMGroup, oldCompType, oldComponent, oldCostCode, oldEMCType, oldNotes)
select ARCo, @mth, @batchid, @seq, ARLine,'C', ARTrans, RecType, LineType, Description,
	GLCo, GLAcct, 
	TaxGroup,
	TaxCode,
	case when @artranstype in ('P','M','C','W') then -Amount else Amount end,
	case when @artranstype in ('P','M','C','W') then -TaxBasis else TaxBasis end,
	case when @artranstype in ('P','M','C','W') then -TaxAmount else TaxAmount end,
	case when @artranstype in ('P','M','C','W') then -RetgTax else RetgTax end, 
	RetgPct,
	case when @artranstype in ('P','M','C','W') then -Retainage else Retainage end,
	case when @artranstype in ('P','M','C','W') then -DiscOffered else DiscOffered end,
	case when @artranstype in ('P','M','C','W') then -TaxDisc else TaxDisc end,
	case when @artranstype in ('P','M','C','W') then -DiscTaken else DiscTaken end,
	case when @artranstype in ('P','W') then -FinanceChg else FinanceChg end,
	ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item,
	case when @artranstype in ('P', 'M', 'C','W') then -ContractUnits else ContractUnits end,
	Job, PhaseGroup, Phase, CostType, UM,
	case when @artranstype = 'M' then -JobUnits else JobUnits end,
	case when @artranstype = 'M' then -JobHours else JobHours end,
	ActDate, INCo, Loc, MatlGroup, Material,
	UnitPrice, ECM, 
	case when @artranstype in ('P', 'M', 'C','W') then -MatlUnits else MatlUnits end,
	CustJob, CustPO, EMCo, Equipment, EMGroup, CompType, Component, CostCode, EMCType, Notes,
	/*Start filling old values */
	RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
	case when @artranstype in ('P','M','C','W') then -Amount else Amount end,
	case when @artranstype in ('P','M','C','W') then -TaxBasis else TaxBasis end,
	case when @artranstype in ('P','M','C','W') then -TaxAmount else TaxAmount end,
	case when @artranstype in ('P','M','C','W') then -RetgTax else RetgTax end,
	RetgPct,
	case when @artranstype in ('P','M','C','W') then -Retainage else Retainage end,
	case when @artranstype in ('P','M','C','W') then -DiscOffered else DiscOffered end,
	case when @artranstype in ('P','M','C','W') then -TaxDisc else TaxDisc end,
	case when @artranstype in ('P','M','C','W') then -DiscTaken else DiscTaken end,
	/* DiscTaken, this should be commented out see Jim or Shayona */
	case when @artranstype in ('P','W') then -FinanceChg else FinanceChg end,
	ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item,
	case when @artranstype in ('P', 'M', 'C','W') then -ContractUnits else ContractUnits end,
	Job, PhaseGroup, Phase, CostType, UM,
	case when @artranstype = 'M' then -JobUnits else JobUnits end,
	case when @artranstype = 'M' then -JobHours else JobHours end,
	ActDate, INCo,
	Loc, MatlGroup, Material, UnitPrice, ECM, 
	case when @artranstype in ('P', 'M', 'C','W') then -MatlUnits else MatlUnits end,
	CustJob, CustPO,
	EMCo, Equipment, EMGroup, CompType, Component, CostCode, EMCType, Notes
from ARTL with (nolock)
where ARCo=@co and ARTrans = @artrans and Mth = @mth

/* BatchUserMemoInsertExisting - update the user memo in the detail batch record */
Select @formname = case @source   when 'AR Invoice'then 'AR InvoiceEntryDetail'
                                 when 'ARFinanceC'then 'AR FinanceChargeDetail' end
if @source = 'AR Receipt'
	begin
	select @formname = case @artranstype when 'M' then 'AR MiscRecDetail'
		else 'AR CashReceipts' end
	end

exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, @formname,
    0, @errmsg output
if @rcode <> 0
    begin
	select @errmsg = 'Unable to update User Memos in ARBL', @rcode = 1
	goto bspexit
	end
   
/* need to add Miscellaneous distributions if present*/
insert into bARBM(Co, Mth, BatchId, CustGroup, MiscDistCode, BatchSeq, TransType, ARTrans,
	DistDate, Description, Amount, oldDistDate, oldDescription, oldAmount)
select ARCo, @mth, @batchid, CustGroup, MiscDistCode, @seq,'C',ARTrans, DistDate, Description,
	Amount,	DistDate, Description, Amount
from ARMD with (nolock)
where ARCo = @co and ARTrans = @artrans and Mth = @mth

bspexit:
if @rcode <> 0 select @errmsg = @errmsg			--+ char(13) + char(10) + '[bspARBHInsertExistingTrans]'
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspARBHInsertExistingTrans] TO [public]
GO
