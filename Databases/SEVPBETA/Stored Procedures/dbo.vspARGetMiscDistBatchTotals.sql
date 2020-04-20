SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARGetMiscDistBatchTotals]
/*********************************************************************************
*  Created by:	TJL  07/21/05:  Issue #27721, 6X rewrite
*  Modified by:	
*		
*  
* Called from ARMiscDistributions Tab/Form from ARInvoiceEntry or ARCashReceipts
* to compare the MiscDist Totals against the Transaction amounts.  Its used to give
* a very simple warning to user when Distributions don't match Transaction Amounts.
*
* Inputs:
*	@arco			-	AR Company
*	@batchmth		-	BatchMth
*	@batchid		-	BatchId
*	@batchseq		-	BatchSeq
*	@custgroup		-	Customer Group
*
* Outputs:
*	@msg			-	error message
*   @rcode	
*
*************************************************************************************/
(@arco bCompany = null, @batchmth bMonth, @batchid bBatchID, @batchseq int, 
	@custgroup bGroup, @amount bDollar output, @errmsg varchar(375) output)
as
set nocount on

declare @rcode int
  
select @rcode = 0

/* Get MiscDistCode totals from ARBM for this BatchSeq */
select @amount = isnull(sum(Amount), 0)
from bARBM with (nolock)
where Co = @arco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq
	and CustGroup = @custgroup

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '  [vspARGetMiscDistBatchTotals]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARGetMiscDistBatchTotals] TO [public]
GO
