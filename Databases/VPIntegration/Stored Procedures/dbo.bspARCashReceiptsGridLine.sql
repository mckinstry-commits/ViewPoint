SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCashReceiptsGridLine    Script Date: 07/01/04 9:34:10 AM ******/
   CREATE proc [dbo].[bspARCashReceiptsGridLine]
   /****************************************************************************
   * CREATED BY: TJL 07/01/04 - Issue #25141, Speed Up performance of ARCashReceipts Form (OldCastle)
   * MODIFIED BY:  TJL 06/05/08 - Issue #128457:  ARCashReceipts International Sales Tax
   *
   *
   * USAGE:
   * 	Used by ARCashReceipts form to refresh a single grid line in AR Cash Receipts and also to 
   *   refresh the Header Labels at top of form. 
   *
   * INPUT PARAMETERS:
   *
   * 
   *
   *
   * OUTPUT PARAMETERS:
   *	See Select statement below
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@arco bCompany = null, @batchmth bMonth, @batchid bBatchID, @batchseq int,
   	@applymth bMonth, @applytrans bTrans, @seqtotapp bDollar output, @seqtaxapp bDollar output,
   	@seqdisctaken bDollar output, @seqtaxdisc bDollar output, @seqretgapp bDollar output,
   	@seqretgtaxapp bDollar output, @seqfcapp bDollar output, @invtotapp bDollar output,
   	@invtaxapp bDollar output, @invdisctaken bDollar output, @invtaxdisc bDollar output,
   	@invretgapp bDollar output, @invfcapp bDollar output, @onacctamt bDollar output, 
   	@errmsg varchar(250) output)
   as
   set nocount on
   declare @rcode integer
   
   select @rcode = 0 
 
   /* Get individual Invoice values */
   select @invtotapp = sum(Amount), @invtaxapp = sum(TaxAmount), @invdisctaken = sum(DiscTaken), 
   	@invtaxdisc = sum(TaxDisc), @invretgapp = sum(Retainage), @invfcapp = sum(FinanceChg)
   from bARBL with (nolock)
   where Co = @arco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq 
   	and ApplyMth = @applymth and ApplyTrans = @applytrans
   
   /* Get batch sequence values */
   select @seqtotapp = sum(Amount), @seqtaxapp = sum(TaxAmount), @seqdisctaken = sum(DiscTaken), 
   	@seqtaxdisc = sum(TaxDisc), @seqretgapp = sum(Retainage), @seqfcapp = sum(FinanceChg),
	@seqretgtaxapp = sum(RetgTax)
   from bARBL with (nolock)
   where Co = @arco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq 
   
   /* Get on account values */
   select @onacctamt = isnull(sum(l.Amount),0)
   from bARBL l with (nolock)
   join bARBH h with (nolock) on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId
   	and h.BatchSeq = l.BatchSeq
   where l.Co = @arco and l.Mth = @batchmth and l.BatchId = @batchid
   	and l.BatchSeq  =@batchseq and h.ARTransType='P'
   	and ((l.ApplyMth = l.Mth and l.ApplyTrans = l.ARTrans and l.ApplyLine = l.ARLine)
   		or (l.ApplyTrans is Null))
   
   /* Regarding errmsg:
   
      For the moment there are no error alerts in this procedure.  In some cases this procedure
      gets called when a form closes and it is difficult to determine if the grid on the closing form 
      was modified or not.  Therefore it gets run to obtain batch values even if none exist.
   
      A NULL dollar value simply means that nothing was found in the batch.  When this occurs, 
      the form knows to replace NULL with 0.00 when updating the ARCashReceipts Header labels
      or when making Grid change comparisons.  It works just fine.  Therefore until a need arises
      that requires a distinct errmsg, none will be returned.  
   
      A complete failure here should be evident to the user, by other means, when using the
      ARCashReceipts form. */
    
   bspexit:
   
   if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARCashReceiptsGridLine]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARCashReceiptsGridLine] TO [public]
GO
