SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMListImportBatchInfo]
   /************************************************************************
   * CREATED:  DanF 06/26/2007 
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    List batch information for matching import id.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successful 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   ( @ImportId varchar(20), @msg varchar(80) = null output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @ImportId is null
   	begin
   		select @msg = 'Missing ImportId.', @rcode = 1
   		goto bspexit
   	end
   	
	select Co, convert(varchar(2),Mth,1) + '/' + convert(varchar(2),Mth,2) as Month, BatchId, RecordCount 
    from IMBC with (nolock)
	where ImportId = @ImportId 
	order by Mth, BatchId

  
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMListImportBatchInfo] TO [public]
GO
