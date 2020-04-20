SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJCBatchDescTotals]
  /***********************************************************
   * CREATED BY: DANF 03/06/2005
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Revenue Adjustments, JC Cost Adjustments and JC revenue Adjustments
   * to return the a description to the key field and totals.
   *
   * INPUT PARAMETERS
   *   JCCo   			JC Co 
   *   Month			Month
   *   BatchId			Batch ID
   *   BatchSeq			Batch Seq
   *   Source			Source
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
(@jcco bCompany, @mth bMonth,  @batchid bBatchID, 
 @batchseq int, @source bSource,
 @totalcredits bDollar output, @totaldebits bDollar output, 
 @undistributed bDollar output, @total bDollar output,
 @msg varchar(255) output)
  as
  set nocount on
  
  	declare @rcode int, @rc int, @dmsg varchar(255)
  	select @rcode = 0, @msg='', @dmsg = ''
  
 	if @jcco is not null and  isnull(@mth,'') <> '' and isnull(@source,'')<> ''
		begin
		 	if @source = 'JC CostAdj' or @source = 'JC MatUse'
		  		select @msg = Description 
		  		from dbo.JCCB with (nolock)
		  		where Co = @jcco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
			if @source = 'JC RevAdj'
		  		select @msg = Description 
		  		from dbo.JCIB with (nolock)
		  		where Co = @jcco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

			exec @rc = dbo.vspJCCostRevenueBatchTotals @jcco, @mth, @batchid, @source,  @totalcredits output, @totaldebits output,  @undistributed output, @total output, @dmsg output
		end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCBatchDescTotals] TO [public]
GO
