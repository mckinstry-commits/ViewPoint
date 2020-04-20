SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspJCProActualDateGet]
   
   /****************************************************************************
   * CREATED BY: 	DANF 
   * MODIFIED BY:  
   * USAGE:
   * 	Retrieves Actual Date from an existing batch - JCPP - JCPB 
   *    for progress or projection postings.
   *
   * INPUT PARAMETERS:
   *	Batch Table, Batch Id, Month,
   *	
   * OUTPUT PARAMETERS:
   *	Actual Date
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   
   	(@co bCompany = 0, @batchid bBatchID = 0, @mth bMonth = null, @table varchar(4) = null,
   	@date bDate output, @job bJob output, @msg varchar(255) output)
   as
set nocount on
   declare @rcode int
   select @rcode = 0, @date  = null, @job = null

   if @co is null
      begin
      select @msg = 'Missing Batch Month!', @rcode = 1
      goto bspexit
      end
   	
   if @mth is null
      begin
      select @msg = 'Missing Batch Month!', @rcode = 1
      goto bspexit
      end
   
   if @batchid = 0
      begin
      select @msg='Missing Batch Id Number!', @rcode = 1
      goto bspexit
      end
   
   if @table is null
      begin
      select @msg='Missing table!', @rcode = 1
      goto bspexit
      end

   if @table = 'JCPP'
		begin
		select top 1 @date = ActualDate, @job  = Job 
		from JCPP with (nolock)
		where Co = @co and Mth=@mth and BatchId=@batchid
		order by ActualDate
		end

	if @table = 'JCPB'
		begin
   		select top 1 @date = ActualDate, @job  = Job 
		from JCPB with (nolock)
		where Co = @co and Mth=@mth and BatchId=@batchid
		order by ActualDate
		end

	if @table = 'JCIR'
		begin
   		select top 1 @date = ActualDate, @job  = Contract 
		from JCIR with (nolock)
		where Co = @co and Mth=@mth and BatchId=@batchid
		order by ActualDate
		end


bspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProActualDateGet] TO [public]
GO
