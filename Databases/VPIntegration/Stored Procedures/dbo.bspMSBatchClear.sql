SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************/
   CREATE  procedure [dbo].[bspMSBatchClear]
   /*************************************************************************************************
    * Created By:  GF 10/12/2000
    * Modified By: GF 10/26/2000
    *              GG 11/08/00 - Added bMSRB delete for Ticket Batch
    *					    Added Hauler Time Sheet and Invoice Batch clear
    *			    GG 11/20/00 - Added check for batch status 4 (posting in progress)
    *               GG 01/31/01 - Handle MS Hauler Payment Batch
    *				GF 02/22/2005 - issue #19185 material vendor payment enhancement
    *				DAN SO 10/28/2009 - Issue: #129350 - clear associated Surcharges
	*               DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
    *
    *
    *
    * USAGE:
    * Clears entries associated with MS Ticket, Hauler Time Sheet, and Invoice batches
    *
    * INPUT PARAMETERS
    *   @msco       	MS Company
    *   @mth			Month of batch
    *   @batchid		Batch to clear
    *
    * OUTPUT PARAMETERS
    *   @errmsg     	if something went wrong
    *
    * RETURN VALUE
    *   0   		success
    *   1   		fail
    **************************************************************************************************/
   (@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @source bSource, @tablename char(20), @status tinyint,
           @inuseby bVPUserName
   
   select @rcode = 0
   
   -- get batch information
   select @status=Status, @inuseby=InUseBy, @tablename=TableName
   from bHQBC where Co=@msco and Mth=@mth and BatchId=@batchid
   if @@rowcount=0
       begin
    	select @msg='Invalid batch.', @rcode=1
    	goto bspexit
    	end
   if @status=4
    	begin
    	select @msg='Batch posting was interrupted, cannot clear!', @rcode=1
    	goto bspexit
    	end
   if @status=5
    	begin
    	select @msg='Batch has already been posted, cannot clear!', @rcode=1
    	goto bspexit
    	end
   if @inuseby<>SUSER_SNAME()
    	begin
    	select @msg='Batch is already in use by ' + isnull(@inuseby,'') + ' !', @rcode=1
    	goto bspexit
    	end
   
   -- clear batch based on tablename
   if @tablename='MSTB'	-- Ticket batch
    	begin
    	delete from bMSJC where MSCo=@msco and Mth=@mth and BatchId=@batchid
   		delete from bMSRB where MSCo=@msco and Mth=@mth and BatchId=@batchid -- remove Revenue Breakdown before Usage
    	delete from bMSEM where MSCo=@msco and Mth=@mth and BatchId=@batchid
    	delete from bMSIN where MSCo=@msco and Mth=@mth and BatchId=@batchid
    	delete from bMSPA where MSCo=@msco and Mth=@mth and BatchId=@batchid
   		delete from bMSGL where MSCo=@msco and Mth=@mth and BatchId=@batchid
   		delete from bMSSurcharges where Co=@msco and Mth=@mth and BatchId=@batchid -- ISSUE: #129350
   		delete from bMSTB where Co=@msco and Mth=@mth and BatchId=@batchid	-- trigger will unlock Trans Detail
    	end
   
   if @tablename = 'MSHB'	-- Hauler Time Sheet batch
   		begin
   		delete from bMSJC where MSCo=@msco and Mth=@mth and BatchId=@batchid
   		delete from bMSRB where MSCo=@msco and Mth=@mth and BatchId=@batchid  -- remove Revenue Breakdown before Usage
    	delete from bMSEM where MSCo=@msco and Mth=@mth and BatchId=@batchid
    	delete from bMSIN where MSCo=@msco and Mth=@mth and BatchId=@batchid
    	delete from bMSGL where MSCo=@msco and Mth=@mth and BatchId=@batchid
   		delete from bMSLB where Co=@msco and Mth=@mth and BatchId=@batchid	-- remove Haul Lines before Headers
   		delete from bMSHB where Co=@msco and Mth=@mth and BatchId=@batchid	-- trigger will unlock existing Haul Header
    	end
   
   if @tablename = 'MSIB'	-- Invoice batch
   		begin
   		delete from bMSIG where MSCo=@msco and Mth=@mth and BatchId=@batchid
   		delete from bMSMX where MSCo=@msco and Mth=@mth and BatchId=@batchid
    	delete from bMSAR where MSCo=@msco and Mth=@mth and BatchId=@batchid
		delete from bMSID where Co=@msco and Mth=@mth and BatchId=@batchid	-- remove Detail before Headers
   		delete from bMSIB where Co=@msco and Mth=@mth and BatchId=@batchid	-- trigger will unlock existing Invoices
    	end
   
   if @tablename = 'MSWH'  -- Hauler Payment Batch
       begin
       delete from bMSAP where MSCo=@msco and Mth=@mth and BatchId=@batchid
       delete from bMSWG where MSCo=@msco and Mth=@mth and BatchId=@batchid
       delete from bMSWD where Co=@msco and Mth=@mth and BatchId=@batchid  -- remove Detail before Headers
       delete from bMSWH where Co=@msco and Mth=@mth and BatchId=@batchid
       end
   
   if @tablename = 'MSMH'  -- Material Vendor Payment Batch
       begin
       delete from bMSMA where MSCo=@msco and Mth=@mth and BatchId=@batchid
       delete from bMSMG where MSCo=@msco and Mth=@mth and BatchId=@batchid
       delete from bMSMT where Co=@msco and Mth=@mth and BatchId=@batchid  -- remove Detail before Headers
       delete from bMSMH where Co=@msco and Mth=@mth and BatchId=@batchid
       end
   
   
   -- update Batch Status in HQBC
   update bHQBC set Status=6		-- cancelled
   where Co=@msco and Mth=@mth and BatchId=@batchid
   if @@rowcount = 0
   	begin
   	select @msg = 'Unable to update status on Batch Control entry.', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSBatchClear] TO [public]
GO
