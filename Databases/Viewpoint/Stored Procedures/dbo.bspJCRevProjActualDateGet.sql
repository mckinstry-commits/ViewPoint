SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCRevProjActualDateGet    Script Date: 8/28/99 9:33:01 AM ******/
    CREATE       proc [dbo].[bspJCRevProjActualDateGet]
    
    /****************************************************************************
    * CREATED BY: 	DANF 02/24/2005 
    
    * MODIFIED BY:  
    
    * USAGE:
    * 	Retrieves Actual Date from an existing batch - JCIR
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
    
    	(@jcco bCompany, @batch bBatchID = 0, @mth bMonth = null, 
    	 @actualdate smalldatetime output, @contract bContract output, @msg varchar(255) output)
    as
    set nocount on
    declare @rcode int, @query varchar(200)
    select @rcode = 0
    	
    if @mth is null
       begin
       select @msg = 'Missing Batch Month!', @rcode = 1
       goto bspexit
       end
    
    if @batch = 0
       begin
       select @msg='Missing Batch Id Number!', @rcode = 1
       goto bspexit
       end
    
        
    select top 1 @actualdate = ActualDate, @contract = Contract 
    from dbo.bJCIR with (nolock)
    where Co = @jcco and Mth= @mth and BatchId= @batch
    order by ActualDate desc, Contract desc
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCRevProjActualDateGet] TO [public]
GO
