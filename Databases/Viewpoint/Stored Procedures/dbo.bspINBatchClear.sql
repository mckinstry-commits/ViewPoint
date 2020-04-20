SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspINBatchClear]
/*************************************************************************************************
* CREATED BY: GR 01/26/00
* Modified: GG 03/12/02 - Added 'MO Entry' and 'MO Confirm' Sources
*			GG 04/17/02 - Added 'MO Close' source
*			GG 09/15/06 - #120561 - remove bHQCC entries
*           DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
*
* USAGE:
* Clears batch tables and distribution tables
*
* INPUT PARAMETERS
*	@co        	IN Company
*  @mth      	Month of batch
*  @batchid    Batch ID 
* 
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/
   
   	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @errmsg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @source bSource, @tablename char(20), @status  tinyint, @inuseby bVPUserName
   
   select @status = Status, @inuseby = InUseBy,  @tablename = TableName
   from dbo.HQBC with(nolock)
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount=0
   	begin
   	select @errmsg = 'Invalid batch.', @rcode = 1
   	goto bspexit
   	end
   if @status = 4
    	begin
    	select @errmsg='Batch posting was interrupted - cannot clear!', @rcode = 1
    	goto bspexit
    	end
   if @status = 5
   	begin
   	select @errmsg='Batch has already been posted - cannot clear!', @rcode = 1
   	goto bspexit
   	end
   if @status = 6
    	begin
    	select @errmsg='Batch was cancelled - nothing to clear!', @rcode = 1
    	goto bspexit
    	end
   if isnull(@inuseby,'') <> SUSER_SNAME()
   	begin
   	select @errmsg = 'Batch is not ''locked'' by the current user - cannot clear!', @rcode = 1
   	goto bspexit
   	end
   
   -- Clear distribution tables first, then clear batch tables
   if @tablename='INAB'	-- Adjustments
   	begin
       delete dbo.bINAG where INCo = @co and Mth = @mth and BatchId = @batchid
   	delete dbo.bINAB where Co = @co and Mth = @mth and BatchId = @batchid
   	end
   if @tablename='INTB'	-- Transfers
   	begin
       delete dbo.bINTG where INCo = @co and Mth = @mth and BatchId = @batchid
   	delete dbo.bINTB where Co = @co and Mth = @mth and BatchId = @batchid
   	end
   if @tablename='INPB'	-- Production
   	begin
       delete dbo.bINPG where INCo = @co and Mth = @mth and BatchId = @batchid
   	delete dbo.bINPD where Co = @co and Mth = @mth and BatchId = @batchid
       delete bINPB where Co = @co and Mth = @mth and BatchId = @batchid
   	end
   if @tablename='INMB'	-- MO Entry
   	begin
       delete dbo.bINJC where INCo = @co and Mth = @mth and BatchId = @batchid
   	delete dbo.bINIB where Co = @co and Mth = @mth and BatchId = @batchid
       delete dbo.bINMB where Co = @co and Mth = @mth and BatchId = @batchid
   	end
   if @tablename='INCB'	-- MO Confirmation
   	begin
       delete dbo.bINCJ where INCo = @co and Mth = @mth and BatchId = @batchid
   	delete dbo.bINCG where INCo = @co and Mth = @mth and BatchId = @batchid
       delete dbo.bINCB where Co = @co and Mth = @mth and BatchId = @batchid
   	end
   if @tablename='INXB'	-- MO Close
   	begin
       delete dbo.bINXJ where INCo = @co and Mth = @mth and BatchId = @batchid
   	delete dbo.bINXI where INCo = @co and Mth = @mth and BatchId = @batchid
   	delete dbo.bINXB where Co = @co and Mth = @mth and BatchId = @batchid
   	end

	-- remove HQ Close Control entries
    delete from dbo.bHQCC where Co=@co and Mth=@mth and BatchId=@batchid
   
	-- update Batch Status to 'canceled'
   update dbo.bHQBC set Status = 6 where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode=1
   	goto bspexit
   	end
   	
   bspexit:
     --  if @rcode <> 0 select @errmsg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINBatchClear] TO [public]
GO
