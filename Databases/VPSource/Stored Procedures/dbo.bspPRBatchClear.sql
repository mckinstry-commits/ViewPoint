SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRBatchClear    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE   procedure [dbo].[bspPRBatchClear]
   /*************************************************************************************************
    * CREATED BY: EN 2/25/98
    * MODIFIED By : EN 4/3/98
    *				EN 10/7/02 - issue 18877 change double quotes to single
    *				EN 12/03/03 - issue 23061  added isnull check, with (nolock), and dbo
   	*				EN 12/04/06 - issue 27864 changed HQBC TableName reference from 'PRTZGrid' to 'PRTB'
	*               DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
  *
    * USAGE:
    * Clears batch tables
    *
    * INPUT PARAMETERS
    *   @co        PRCo
    *   @mth       Month of batch
    *   @batchid   Batch ID to validate
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    **************************************************************************************************/
   
   	(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output)
   as
   set nocount on
   declare @rcode int, @tablename char(20), @status tinyint, @inuseby bVPUserName
   
   select @rcode = 0
   
   select @status=Status, @inuseby=InUseBy, @tablename=TableName from dbo.HQBC with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid
   
   if @@rowcount=0
   	begin
   	select @errmsg='Invalid batch.', @rcode=1
   	goto bspexit
   	end
   
   if @status=5
   	begin
   	select @errmsg='Cannot clear, batch has already been posted!', @rcode=1
   	goto bspexit
   	end
   
   if @status=4
   	begin
   	select @errmsg='Cannot clear, batch status is posting in progress!', @rcode=1
   	goto bspexit
   	end
   
   if @inuseby<>SUSER_SNAME()
   	begin
   	select @errmsg='Batch is already in use by @inuseby ' + isnull(@inuseby,'') + '!', @rcode=1
   	goto bspexit
   	end
   
   
   if @tablename='PRTB' delete from dbo.bPRTB where Co=@co and Mth=@mth and BatchId=@batchid
   
   if @tablename='PRAB' delete from dbo.bPRAB where Co=@co and Mth=@mth and BatchId=@batchid
   
   
   update dbo.HQBC set Status=6 where Co=@co and Mth=@mth and BatchId=@batchid
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRBatchClear] TO [public]
GO
