SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspARGetPmtOnAcctBatchTotals]
/*********************************************************************************
*  Created by:	TJL  10/11/05:  Issue #27711, 6X rewrite
*  Modified by:	
*		
*  
* Called from ARPmtOnAcct Form from ARCashReceipts to fill the ARPmtOnAcct
* Seq Totals at top of form.  
*
* Inputs:
*	@arco			-	AR Company
*	@batchmth		-	BatchMth
*	@batchid		-	BatchId
*	@batchseq		-	BatchSeq
*
* Outputs:
*	@msg			-	error message
*   @rcode	
*
*************************************************************************************/
(@arco bCompany = null, @batchmth bMonth, @batchid bBatchID, @batchseq int, 
	@amount bDollar output, @taxamount bDollar output, @disctaken bDollar output, @errmsg varchar(375) output)
as
set nocount on

declare @rcode int
  
select @rcode = 0

/* Get Payment on Account totals from ARBL for this BatchSeq */
select @amount = isnull(sum(Amount), 0), @taxamount = isnull(sum(TaxAmount), 0), @disctaken = isnull(sum(DiscTaken), 0)
from bARBL with (nolock)
where Co = @arco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq
	and LineType = 'A'

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '  [vspARGetPmtOnAcctBatchTotals]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARGetPmtOnAcctBatchTotals] TO [public]
GO
