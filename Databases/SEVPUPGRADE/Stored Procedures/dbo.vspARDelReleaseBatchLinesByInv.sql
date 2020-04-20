SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARDeleteBatchLines    Script Date: 5/16/05 9:34:08 AM ******/
CREATE procedure [dbo].[vspARDelReleaseBatchLinesByInv]
/*************************************************************************************************
* CREATED BY: 	TJL 05/16/05 - Issue #27715, 6x Rewrite
* MODIFIED By :
*
* USAGE:
*
* Called from ARRelease form if existing ARBL records for a single Invoice/ApplyTrans
* have all been set to 0.00 value by user.  Usually occurs from the ARRelease Form or
* ARReleaseDetail form if user has zero'd out existing entries.  In this case, these
* detail records will be deleted from the ARBL batch table.
*
* Code is also in place in ARCashReceipts to use this routine in the same way.  Form
* code is currently Rem'd out but could be used if desired.
*
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*	BatchSeq	Batch Sequence
*	@invapplymth	Invoice Transaction Month
*	@invapplytrans	Invoice Transaction number
*	
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/

(@co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @source bSource, 
	@invapplymth bMonth, @invapplytrans bTrans, @errmsg varchar(60) output)
as

set nocount on
  
declare @rcode int

select @rcode = 0

if @mth is null or @batchid is null or @batchseq is null
	begin
	select @errmsg = 'Missing Batch information.', @rcode = 1
	goto vspexit
	end
if @invapplymth is null or @invapplytrans is null
	begin
	select @errmsg = 'Missing Invoice/Transaction apply information.', @rcode = 1
	goto vspexit
	end

delete from bARBL 
where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq = @batchseq
	and ApplyMth = @invapplymth and ApplyTrans = @invapplytrans
if @@rowcount = 0
	begin
	select @errmsg = 'Not all detail records were deleted for this Invoice Transaction.', @rcode = 1
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(10) + char(13) + char(10) + char(13) + '[dbo.vspARDelReleaseBatchLinesByInv]'  
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARDelReleaseBatchLinesByInv] TO [public]
GO
