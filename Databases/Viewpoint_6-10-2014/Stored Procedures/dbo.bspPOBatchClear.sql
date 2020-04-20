SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPOBatchClear    Script Date: 8/28/99 9:33:09 AM ******/
   CREATE   procedure [dbo].[bspPOBatchClear]
   /*************************************************************************************************
    * CREATED BY: kf 12/9/97
    * MODIFIED By :danf 05/24/01
    *              danf 05/01/02
	*              DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
    *
    * USAGE:
    * Clears batch tables
    *
    * INPUT PARAMETERS
    *   POCo        POCo
    *   Month       Month of batch
    *   BatchId     Batch ID to validate
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    **************************************************************************************************/
   
   	(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output)
   as
   set nocount on
   declare @rcode int, @source bSource, @tablename char(20), @status  tinyint, @inuseby bVPUserName,
   	@batchsource bSource
   
   select @status=Status, @inuseby=InUseBy,  @tablename=TableName from HQBC where Co=@co and Mth=@mth and BatchId=@batchid
   
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
   	select @batchsource=Source
   	       from HQBC
   	       where Co=@co and BatchId=@batchid and Mth=@mth
   	    if @@rowcount<>0
   	       begin
   		select @errmsg = 'Batch already in use by ' +
   		      convert(varchar(2),DATEPART(month, @mth)) + '/' +
   		      substring(convert(varchar(4),DATEPART(year, @mth)),3,4) +
   			' batch # ' + convert(varchar(6),@batchid) + ' - ' + 'Batch Source: ' + @batchsource, @rcode = 1
   
   		goto bspexit
   	       end
   	    else
   	       begin
   		select @errmsg='Batch already in use by another batch!', @rcode=1
   		goto bspexit
   	       end
   	end
   
   if @tablename='POCB'
   	begin
   	delete from bPOCA where POCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bPOCI where POCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bPOCB where Co=@co and Mth=@mth and BatchId=@batchid
   	end
   
   if @tablename='PORB'
   	begin
   	delete from bPORA where POCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bPORI where POCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bPORB where Co=@co and Mth=@mth and BatchId=@batchid
       delete from bPORE where POCo=@co and Mth=@mth and BatchId=@batchid
       delete from bPORJ where POCo=@co and Mth=@mth and BatchId=@batchid
       delete from bPORG where POCo=@co and Mth=@mth and BatchId=@batchid
       delete from bPORN where POCo=@co and Mth=@mth and BatchId=@batchid
   	end
   
   if @tablename='POXB'
   	begin
   	delete from bPOXA where POCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bPOXI where POCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bPOXB where Co=@co and Mth=@mth and BatchId=@batchid
   	end
   
   if @tablename='POHB'
   	begin
   	delete from bPOIA where POCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bPOII where POCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bPOIB where Co=@co and Mth=@mth and BatchId=@batchid
   	delete from bPOHB where Co=@co and Mth=@mth and BatchId=@batchid
   	end
   
   if @tablename='PORS'
   	begin
   	delete from bPORS where Co=@co and Mth=@mth and BatchId=@batchid
       delete from bPORH where Co=@co and Mth=@mth and BatchId=@batchid
       delete from bPORE where POCo=@co and Mth=@mth and BatchId=@batchid
       delete from bPORJ where POCo=@co and Mth=@mth and BatchId=@batchid
       delete from bPORG where POCo=@co and Mth=@mth and BatchId=@batchid
       delete from bPORN where POCo=@co and Mth=@mth and BatchId=@batchid
   	end
   
   update bHQBC set Status=6 where Co=@co and Mth=@mth and BatchId=@batchid
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOBatchClear] TO [public]
GO
