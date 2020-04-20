SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBLInsertExistingTrans    Script Date: 8/28/99 9:34:08 AM ******/
CREATE  procedure [dbo].[bspARBLInsertExistingTrans]
/***********************************************************
* CREATED BY: CJW 6/16/97
* MODIFIED By :  bc 03/16/99 added @mth to the 'cannot be found' select statement
*  		bc 11/27/99 - when a credit memo is being applied to a retainage invoice, the rev gl acct now comes from the department
*        			instead of the existing acct in artl.
*   	bc 06/07/01 wasn't writing ARTrans out to ARBL and that can cause problems when posting a line marked for delete
*		TJL 09/27/01 - Issue #13104, Acquire correct GLRevAcct if applying (A, C, or W) against a Released Retainage Invoice.
*		TJL 04/15/02 - Issue #15759, Add new FinanceChg column and TaxDisc column
*		TJL 06/03/02 - Issue #17531, Corrected for WriteOffs to Intercompany Contract Invoices.
*		TJL 01/16/04 - Issue #23477, Get Correct GLCo if applying (A, C, or W) against a Released Retainage Invoice.
*		TJL 06/02/08 - Issue #128286, ARInvoiceEntry International Sales Tax
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*
*
* USAGE:
* This procedure is used by the AR Invoice program to pull existing
* transactions from bARTL into bARBL for editing.
*
* Checks batch info in bHQBC, and transaction info in bARTL.
* Adds entry to the Item that it is in ARTL for the seq passed in
*
*
*  insert trigger will update InUseBatchId in
*
* INPUT PARAMETERS
*   Co         JC Co to pull from
*   BatchMth   Month of batch
*   BatchId    Batch ID to insert transaction into
*   Mth	Applied to month
*   AR Line    ar to pull
*   Item       Item to pull
*   Seq        Seq to put item under
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
*   3   not found  if no errors but just not available
*****************************************************/
@co bCompany, @batchmth bMonth, @batchid bBatchID,@mth bMonth,
   	@ar bTrans=null, @line int, @seq int, @headertype varchar(1), @headeraction varchar(1), @errmsg varchar(200) output
as
set nocount on
declare @rcode int, @inuseby bVPUserName, @status tinyint, @source bSource, @cnt int,
 	@dtsource bSource, @inusebatchid bBatchID, @inusemth bMonth, @errtext varchar(60)

select @rcode = 0
   
/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @batchmth, @batchid, 'AR Invoice', 'ARBH', @errtext output, @status output
if @rcode <> 0
	begin
	select @errmsg = @errtext, @rcode = 1
	goto bspexit
	end
   
if @status <> 0
   	begin
   	select @errmsg = 'Invalid Batch status -  must be -open- !', @rcode = 1
   	goto bspexit
   	end 
   
select @cnt = count(*)
from ARBL
where Co= @co and BatchId = @batchid and Mth = @batchmth and ARTrans = @ar and ARLine = @line and BatchSeq = @seq
if @cnt <> 0 goto bspexit
   
select @inusebatchid = null
/* all ar's can be pulled into a batch as long as it's InUseFlag is set to null*/
select @inusebatchid = InUseBatchID from ARTH where ARCo=@co and ARTrans=@ar and Mth = @mth
   
if @@rowcount = 0
 	begin
 	select @errmsg = 'The AR Transaction :' + isnull(convert(varchar(5),@ar),'') + ' cannot be found.' , @rcode = 1
 	goto bspexit
 	end
   
if @inusebatchid is not null and @inusebatchid <> @batchid
 	begin
 	select @source=Source
 	from HQBC
 	where Co=@co and BatchId=@inusebatchid and Mth=@batchmth
 	if @@rowcount<>0
 		begin
 		select @errmsg = 'Transaction already in use by ' +
 		      convert(varchar(2),DATEPART(month, @batchmth)) + '/' +
 		      substring(convert(varchar(4),DATEPART(year, @batchmth)),3,4) +
 			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
 		goto bspexit
		end
	else
		begin
 		select @errmsg='Transaction already in use by another batch!' + isnull(convert(varchar(10),@ar),''), @rcode=1
 		goto bspexit
		end
 	end

/*Now make sure the Item is not flaged */
select 1 from ARTL where ARCo=@co and ARTrans=@ar and Mth = @mth and ARLine = @line
if @@rowcount = 0
 	begin
 	select @errmsg = 'The AR Line :' + isnull(convert(varchar(5),@line),'') + ' cannot be found.' , @rcode = 3
 	goto bspexit
 	end

insert into bARBL(Co, Mth, BatchId, BatchSeq, ARTrans, ARLine, TransType, LineType, JCCo, Contract,
 	Item, RecType, Description, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgTax, RetgPct, Retainage,
 	DiscOffered, TaxDisc, DiscTaken, FinanceChg, ContractUnits, ApplyMth, ApplyTrans, ApplyLine,  PhaseGroup, Phase,
 	CostType, UM, INCo, Loc, MatlGroup, MatlUnits, ECM, Material, Notes,
 	oldRecType, oldLineType, oldDescription, oldGLCo,oldGLAcct, oldTaxGroup, oldTaxCode,
 	oldAmount, oldTaxBasis, oldTaxAmount, oldRetgTax, oldRetgPct, oldRetainage, oldDiscOffered, oldTaxDisc, oldDiscTaken, oldFinanceChg,
 	oldApplyMth,oldApplyTrans, oldApplyLine, oldJCCo, oldContract, oldItem, oldContractUnits,
 	oldPhaseGroup, oldPhase, oldCostType, oldUM, oldINCo, oldLoc, oldMatlGroup, oldMaterial, oldUnitPrice, oldMatlUnits, oldNotes)
select l.ARCo, @batchmth, @batchid, @seq, l.ARTrans, l.ARLine, @headeraction,
	case l.LineType when 'R' then (case when l.Contract is null then 'O' else 'C' end) else l.LineType end, 
	l.JCCo, l.Contract, l.Item, l.RecType, l.Description, 
	case @headertype when 'W' then l.ARCo else l.GLCo end,
	/* when applying a credit memo to a retainage line, pull in the gl acct from the department */
 	case @headertype when 'W' then t.GLWriteOffAcct else l.GLAcct end,
	l.TaxGroup, l.TaxCode,
 	/* fill in amount based on header action and the type - If the type is credit memo or write-off then switch signs.*/
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.Amount) else l.Amount end) else 0 end,			/*amount*/
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.TaxBasis) else l.TaxBasis end) else 0 end,		/*taxbasis */
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.TaxAmount) else l.TaxAmount end) else 0 end,	/*taxamount */
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.RetgTax) else l.RetgTax end) else 0 end,		/*retgtax */
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then (l.RetgPct) else l.RetgPct end) else 0 end,			/*retgpct*/
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.Retainage) else l.Retainage end) else 0 end,	/*retainage*/
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.DiscOffered) else l.DiscOffered end) else 0 end,		/*discount offered*/
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.TaxDisc) else l.TaxDisc end) else 0 end, 		/*TaxDisc*/  	
	l.DiscTaken,
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.FinanceChg) else l.FinanceChg end) else 0 end, 	/*FinanceChg*/
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.ContractUnits) else l.ContractUnits end) else 0 end,	/*contractUnits*/
 	l.ApplyMth, l.ApplyTrans, l.ApplyLine, l.PhaseGroup, l.Phase, l.CostType, l.UM, l.INCo, l.Loc, l.MatlGroup,
 	case @headeraction when ('C') then (case when @headertype in ('C','W') then -(l.MatlUnits) else l.MatlUnits end) else 0 end,	/*material Units*/
 	l.ECM, l.Material,l.Notes,
 	--fill in old values Only need to do it if not in add mode
 	--see issue 2179, we don't want old values if adding new apply to trans
 	case @headeraction when ('A') then NULL else l.RecType end,
 	case @headeraction when ('A') then NULL else l.LineType end,
 	case @headeraction when ('A') then NULL else l.Description end,
 	case @headeraction when ('A') then NULL else l.GLCo end,
 	case @headeraction when ('A') then NULL else l.GLAcct end,
 	case @headeraction when ('A') then NULL else l.TaxGroup end,
 	case @headeraction when ('A') then NULL else l.TaxCode end,
 	case @headeraction when ('A') then NULL else l.Amount end,
 	case @headeraction when ('A') then NULL else l.TaxBasis end,
 	case @headeraction when ('A') then NULL else l.TaxAmount end,
	case @headeraction when ('A') then NULL else l.RetgTax end,
 	case @headeraction when ('A') then NULL else l.RetgPct end,
 	case @headeraction when ('A') then NULL else l.Retainage end,
 	case @headeraction when ('A') then NULL else l.DiscOffered end,
	case @headeraction when ('A') then NULL else l.TaxDisc end,
 	case @headeraction when ('A') then NULL else l.DiscTaken end,
	case @headeraction when ('A') then NULL else l.FinanceChg end,
 	case @headeraction when ('A') then NULL else l.ApplyMth end,
 	case @headeraction when ('A') then NULL else l.ApplyTrans end,
 	case @headeraction when ('A') then NULL else l.ApplyLine end,
 	case @headeraction when ('A') then NULL else l.JCCo end,
 	case @headeraction when ('A') then NULL else l.Contract end,
 	case @headeraction when ('A') then NULL else l.Item end,
 	case @headeraction when ('A') then NULL else l.ContractUnits end,
 	case @headeraction when ('A') then NULL else l.PhaseGroup end,
 	case @headeraction when ('A') then NULL else l.Phase end,
 	case @headeraction when ('A') then NULL else l.CostType end,
 	case @headeraction when ('A') then NULL else l.UM end,
 	case @headeraction when ('A') then NULL else l.INCo end,
 	case @headeraction when ('A') then NULL else l.Loc end,
 	case @headeraction when ('A') then NULL else l.MatlGroup end,
 	case @headeraction when ('A') then NULL else l.Material end,
 	case @headeraction when ('A') then NULL else l.UnitPrice end,
 	case @headeraction when ('A') then NULL else l.MatlUnits end,
	case @headeraction when ('A') then NULL else l.Notes end
from bARTL l
join ARRT t on t.ARCo = l.ARCo and t.RecType = l.RecType
--left join JCCO o on o.JCCo = l.JCCo
--left join JCCM m on m.JCCo = l.JCCo and m.Contract = l.Contract
--left join JCDM d on d.JCCo = m.JCCo and d.Department = m.Department and o.GLCo = d.GLCo
where l.ARCo=@co and l.ARTrans = @ar and l.Mth = @mth and l.ARLine = @line
   
bspexit:
   
if @rcode<>0 select @errmsg=@errmsg			--+ char(13) + char(10) + '[bspARBLInsertExistingTrans]'
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspARBLInsertExistingTrans] TO [public]
GO
