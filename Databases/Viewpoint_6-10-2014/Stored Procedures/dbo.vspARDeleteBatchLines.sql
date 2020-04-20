SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARDeleteBatchLines    Script Date: 5/16/05 9:34:08 AM ******/
CREATE procedure [dbo].[vspARDeleteBatchLines]
/*************************************************************************************************
* CREATED BY: 	TJL 05/16/05 - Issue #27704, 6x Rewrite
* MODIFIED By :
*
* USAGE:
* Clears batch detail table (ARBL) for a particular sequence and clears Distribution tables.
* Called from ARFinChg form where, in some circumstances, user is allowed to delete a Header Seq and automatically
* delete the detail records as part of deleting the Header record action.
* Called from ARRelease form if Auto Release option has failed.
*
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*	BatchSeq	Batch Sequence
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/

(@co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @source bSource, @errmsg varchar(60) output)
as

set nocount on
  
declare @rcode int, @tablename char(20), @status tinyint, @inuseby bVPUserName

select @rcode = 0

select @status=Status, @inuseby=InUseBy, @tablename=TableName
from bHQBC
where Co=@co and Mth=@mth and BatchId=@batchid

if @@rowcount=0
	begin
	select @errmsg='Invalid batch.', @rcode=1
	goto vspexit
	end
if @status=5
	begin
	select @errmsg='Cannot clear, batch has already been posted!', @rcode=1
	goto vspexit
	end
if @status=4
	begin
	select @errmsg='Batch posting was interrupted, cannot clear!', @rcode=1
	goto vspexit
	end
if @inuseby<>SUSER_SNAME()
	begin
	select @errmsg='Batch is already in use by @inuseby ' + @inuseby + '!', @rcode=1
	goto vspexit
	end

if @tablename='ARBH'
	begin
	delete from bARBC where ARCo=@co and Mth=@mth and BatchId=@batchid
	delete from bARBM where Co=@co and Mth=@mth and BatchId=@batchid
	delete from bARBI where ARCo=@co and Mth=@mth and BatchId=@batchid
	delete from bARBJ where ARCo=@co and Mth=@mth and BatchId=@batchid
	delete from bARBA where Co=@co and Mth=@mth and BatchId=@batchid
	delete from bARBL where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq = @batchseq
	--delete from bARBH where Co=@co and Mth=@mth and BatchId=@batchid
	end

--update bHQBC set Status=6 where Co=@co and Mth=@mth and BatchId=@batchid

vspexit:
if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[dbo.vspARDeleteBatchLines]'  
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARDeleteBatchLines] TO [public]
GO
