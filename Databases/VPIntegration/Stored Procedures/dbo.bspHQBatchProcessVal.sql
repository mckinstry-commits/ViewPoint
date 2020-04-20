SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQBatchProcessVal]
/***********************************************************
* CREATED BY: SE   8/20/96
* MODIFIED By : SE 8/20/96
*				RM 02/13/04 = #23061, Add isnulls to all concatenated strings
*
* USAGE:
* validates HQ Batch to make sure it is ready to go through processing
*
* INPUT PARAMETERS
*   Company   Co the batch was started in
*   Month     Month of batch
*   BatchId   Identifier of the batch
*   Source    Source Batch should be in(Optional)
*   Table     Table batch should be working on (Optional)
* OUTPUT PARAMETERS
*   @status   current status of the batch
*   @emsg     If error, description of error
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
   	(@hqco bCompany = 0, @mth bMonth = null, @batchid bBatchID = 0,
   	 @source bSource = null, @table varchar(20), @msg varchar(60) output, @status tinyint output)
   as
   set nocount on
   
   declare @rcode int, @chksource bSource, @chktable varchar(20), @inuseby bVPUserName
   
   select @rcode = 0
   
   if @hqco = 0
   	begin
   	select @msg = 'Missing HQ Company#!', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @msg = 'Missing Batch month!', @rcode = 1
   	goto bspexit
   	end
   
   if @batchid = 0
   	begin
   	select @msg='Missing Batch Id number!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @chksource = Source, @chktable = TableName, @inuseby = InUseBy,
   	@status = Status
   	from bHQBC with (nolock) where Co = @hqco and Mth = @mth and BatchId = @batchid
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
   	goto bspexit
   	end
   
   -- if Source not passed in this check will pass
   if @chksource <> @source
   	begin
   	select @msg = 'Invalid Batch source - must be ' + isnull(@source,''), @rcode = 1
   	goto bspexit
   	end
   
   -- if table name not passed in this check will pass
   if @chktable <> @table
   	begin
   	select @msg = 'Invalid Batch table name - must be ' + isnull(@table,''), @rcode = 1
   	goto bspexit
   	end
   
   if @inuseby is null
   	begin
   	select @msg = 'HQ Batch Control must first be updated as In Use!', @rcode = 1
   	goto bspexit
   	end
   
   if @inuseby <> SUSER_SNAME()
   	begin
   	select @msg = 'Batch already in use by ' + isnull(@inuseby,''), @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQBatchProcessVal] TO [public]
GO
