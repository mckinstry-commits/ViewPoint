SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspAPCTVal]
/***********************************************************
* CREATED: kb 3/9/99
* MODIFIED: MV 7/30/01 - issue 13988 change error msg
*			MV 10/18/02 - 18878 quoted identifier cleanup
*			ES 03/11/04 - #23061 isnull wrap
*			GG 06/11/07 - #120561 - removed cursor, cleanup
*
* USAGE:
* Validates each entries in AP Clear Transaction batch - must be called
* prior to posting the batch.
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* INPUT PARAMETERS
*   @co			AP Company#        
*   @mth		Batch Month 
*   @batchid	Batch to validate
*
* OUTPUT PARAMETERS
*   @errmsg     error message
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
   
	@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output

as

set nocount on

declare @rcode int, @errortext varchar(255), @status tinyint

select @rcode = 0
   
/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AP Clear', 'APCT', @errmsg output, @status output
if @rcode <> 0
	begin
	select @errmsg = @errmsg, @rcode = 1
	goto bspexit
	end
if @status < 0 or @status > 3
	begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
	end

/* set HQ Batch status to 1 (validation in progress) */
update dbo.bHQBC set Status = 1
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end

/* clear HQ Batch Errors */
delete dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid

/*clear and refresh HQCC entries */
delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, GLCo
from dbo.bAPCD
where Co=@co and Mth=@mth and BatchId=@batchid

-- validate batch entries, Remaining amounts must net to 0.00 by GL Co# and GL Account
if exists(select top 1 1 from dbo.bAPCD 
			where Co = @co and Mth = @mth and BatchId = @batchid
			group by GLCo, GLAcct
			having sum(Remaining) <> 0)
	begin
   	select @errortext = ' The transaction''s payable accounts must have the same GL Account and net to zero to be cleared.'               -- issue 13988
   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	end

   
/* check for HQ Batch Errors to determine status */
select @status = 3	/* valid - ok to post */
if exists(select top 1 1 from dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
select @status = 2	/* validation errors */
  
-- update Batch Status 
update dbo.bHQBC
set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCTVal] TO [public]
GO
