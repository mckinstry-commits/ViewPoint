SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARPmtDetailApplyTotals    Script Date: 09/15/05 9:34:10 AM ******/
CREATE proc [dbo].[vspARPmtDetailApplyTotals]
/****************************************************************************
* CREATED BY: TJL 07/01/04 - Issue #27710, 6x rewrite
* MODIFIED BY: 
*
*
* USAGE:
* 	Used by ARPmtDetail form to refresh Applied Totals for an Invoice. 
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
	@applymth bMonth, @applytrans bTrans, @invtotapp bDollar output, @invtaxapp bDollar output,
	@invdisctaken bDollar output, @invtaxdisc bDollar output, @invretgapp bDollar output, 
	@invfcapp bDollar output, @errmsg varchar(250) output)
as
set nocount on
declare @rcode integer

select @rcode = 0 
  
/* Get individual Invoice values */
select @invtotapp = isnull(sum(Amount), 0), @invtaxapp = isnull(sum(TaxAmount), 0), 
	@invdisctaken = isnull(sum(DiscTaken), 0), @invtaxdisc = isnull(sum(TaxDisc), 0), 
	@invretgapp = isnull(sum(Retainage), 0), @invfcapp = isnull(sum(FinanceChg), 0)
from bARBL with (nolock)
where Co = @arco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq 
	and ApplyMth = @applymth and ApplyTrans = @applytrans
  
/* Regarding errmsg:

 For the moment there are no error alerts in this procedure.  A NULL dollar value simply means that 
 nothing was found in the batch table.  When this occurs, the procedure knows to replace NULL with 0.00
 and 0.00 will be placed into the Apply Amt lables on form. */
   
vspexit:

if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[vspARPmtDetailApplyTotals]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARPmtDetailApplyTotals] TO [public]
GO
