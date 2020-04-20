SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMGetImportBatchInfo]
   /************************************************************************
   * CREATED:   RT 06/26/03 for issue #21226. 
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Return the status and batch id matching the import id passed in.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successful 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@Co int, @ImportId varchar(20), @batchmth bMonth, @BatchId bBatchID output, @BatchStatus tinyint output, @msg varchar(80) = null output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @ImportId is null
   	begin
   		select @msg = 'Missing ImportId.', @rcode = 1
   		goto bspexit
   	end
   	
   select top 1 @BatchId = a.BatchId, @BatchStatus = b.Status
   	from IMBC a with (nolock) JOIN HQBC b with (nolock) ON a.BatchId = b.BatchId and
   	a.Co = b.Co and a.Mth = b.Mth
   	where a.ImportId = @ImportId and a.Co = @Co and a.Mth = @batchmth and b.Status = 0
   	order by b.DateCreated desc
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMGetImportBatchInfo] TO [public]
GO
