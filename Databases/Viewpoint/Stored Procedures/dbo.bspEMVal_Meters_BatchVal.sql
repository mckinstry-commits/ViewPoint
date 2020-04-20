SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMVal_Meters_BatchVal    Script Date: 8/28/99 9:34:33 AM ******/
   CREATE    procedure [dbo].[bspEMVal_Meters_BatchVal]
   /***********************************************************
    * CREATED BY: JM 5/23/99
    * MODIFIED By :JM 5-10-02 Ref Issue 16906 - Block posting of a meter batch if a prior batch exists that is not
    *		Posted (Status 5) or Cancelled (Status 6).
    *				GF 09/25/2002 - Issue 16906 - Month was not included in select statement Mth <= @mth
    *		JM 11-25-02 - Issue 19482 - Moved check of batch being in another active batch to form validation of Equipment
    *		TV 02/11/04 - 23061 added isnulls 
    * USAGE:
    * 	Called by bspEMVal_Meters_Main to validate batch data,
    *	set HQ Batch status. clear HQ Batch Errors. and clear and
    *	refresh HQCC entries.
    *
    * INPUT PARAMETERS
    *	EMCo        EM Company
    *	Month       Month of batch
    *	BatchId     Batch ID to validate
    *
    * OUTPUT PARAMETERS
    *	@errmsg     if something went wrong
    *
    * RETURN VALUE
    *	0   Success
    *	1   Failure
    *****************************************************/
   @co bCompany,
   @mth bMonth,
   @batchid bBatchID,
   @errmsg varchar(255) output
   as
   declare @maxopen tinyint,
   	@rcode int,
   	@status tinyint
   set nocount on
   select @rcode = 0
   /* Verify parameters passed in. */
   if @co is null
   	begin
   	select @errmsg = 'Missing Batch Company!', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @errmsg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   if @batchid is null
   	begin
   	select @errmsg = 'Missing BatchID!', @rcode = 1
   	goto bspexit
   	end
   /* Validate HQ Batch */
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'EMMeter', 'EMBF', @errmsg output, @status output
   if @rcode <> 0
   	begin
       	select @rcode = 1
       	goto bspexit
      	end
   if @status < 0 or @status > 3
   	begin
   	select @errmsg = 'Invalid Batch status!', @rcode = 1
   	goto bspexit
   	end
   
   /* JM 11-25-02 - Ref Issue 19482 - Moved this check to Equipment's form-level validation procedure so that user
   cannot get an Equipment into a batch that is a member of a batch that hasn't been posted successfully or cancelled -
   see bspEMEquipValForMeterReadings */
   /* Ref Issue 16906 - Block posting of a meter batch if a prior batch exists that is not Posted (Status 5) or Cancelled (Status 6). */
   /*select * from bHQBC where Co = @co and Source = 'EMMeter' and Mth <= @mth and (Status <> 5 and Status <> 6) and BatchId <> @batchid
   if @@rowcount > 0
   	begin
   	select @errmsg = 'Cannot post Meter batch with prior batch not Posted or Canceled!', @rcode = 1
   	goto bspexit
   	end*/
   
   /* Set HQ Batch status to 1 (validation in progress). */
   update bHQBC
   set Status = 1
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   /* Clear HQ Batch Errors. */
   delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   /* Clear and refresh HQCC entries. */
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   insert into bHQCC(Co, Mth, BatchId, GLCo)
   select distinct Co, Mth, BatchId, GLCo from bEMBF
   	where Co=@co and Mth=@mth and BatchId=@batchid
   
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Meters_BatchVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Meters_BatchVal] TO [public]
GO
