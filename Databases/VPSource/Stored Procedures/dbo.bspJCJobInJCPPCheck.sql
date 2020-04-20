
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[bspJCJobInJCPPCheck]
    /***********************************************************
     * CREATED BY:   LM 04/08/97
     * MODIFIED By : GF 07/05/2001 - Fixed ErrMsg batchId expanded from 3 to 8 chars
     *				TV - 23061 added isnulls
     *				GF 06/10/2004 - issue #22373 - modified job in batch message. added warning.
     *				SCOTTP 03/22/13 - TFS44545 - Remove param ActualDate. Is not used
     *
     * USAGE:
     * 	Checks for Current Job in JC Projections in any JCPB Batch.
     *
     *
     *
     * INPUT PARAMETERS
     *   JCCo, Job, BatchId, Month, Actual Date, error msg
     *
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Phase
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    (@jcco bCompany = 0, @job bJob = null, @batch bBatchID = 0,
     @mth bMonth = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @otherbatch bBatchID, @othermth bMonth
   
   select @rcode = 0, @otherbatch = 0
   
    if @jcco = 0
    	begin
    	select @msg = 'Missing JC Company!', @rcode = 1
    	goto bspexit
    	end
    
    if @job is null
    	begin
    	select @msg = 'Missing Job!', @rcode = 1
    	goto bspexit
    	end
    
    if @mth is null
    	begin
    	select @msg = 'Missing Month!', @rcode = 1
    	goto bspexit
    	end
    
   if exists(select * from bJCPP where Co=@jcco and Job=@job and (Mth<>@mth or (BatchId<>@batch and Mth=@mth)))
   	begin
   	select @otherbatch = BatchId, @othermth = Mth
   	from bJCPP where Co=@jcco and Job=@job and (Mth<>@mth or (BatchId<>@batch and Mth=@mth))
   	select @msg = 'Warning: Job ' + isnull(@job,'') + ' exists in batch ' + isnull(convert(varchar(8),@otherbatch),'') + 
    				' in month of ' + isnull(convert(varchar(12),@othermth),'') + '', @rcode = 1
   	goto bspexit
    	end
   
   
   
   
   bspexit:
   	return @rcode


GO

GRANT EXECUTE ON  [dbo].[bspJCJobInJCPPCheck] TO [public]
GO
