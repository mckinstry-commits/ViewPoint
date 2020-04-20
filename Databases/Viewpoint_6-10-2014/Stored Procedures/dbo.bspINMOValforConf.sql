SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[bspINMOValforConf]
    /*******************************************
    Created: RM 04/04/02
    
    
    Usage: Used to validate that a MO# exists.
    
    In:
    	@inco - IN Company
        @mo   - Material Order
    Out:
    	@msg   - error message
        @rcode - return code, 1 if error, 0 if OK.
    *******************************************/
    (@inco bCompany = null, @mo varchar(10) = null,@mth bMonth,
     @batchid bBatchID,@jcco bCompany = null output, @job bJob = null output,
     @jobdesc bDesc=null output,@orderdate bDate = null output,
     @orderedby varchar(30) = null output, @msg varchar(255) = null output)
    as
    
    
    declare @rcode int,@inusebatch bBatchID,@inusemth bMonth
    select @rcode = 0
    
    if @inco is null
    begin
    	select @msg = 'Missing IN Company.',@rcode = 1
    	goto bspexit
    end
    
    if @mo is null
    begin
    	select @msg = 'Missing Material Order.',@rcode = 1
    	goto bspexit
    end
    --
    If (select IsNull(INMO.Status,0) from dbo.INMO with (nolock)where INCo=@inco and MO=@mo) = 2
      begin
    	select @msg = 'Material Order is Closed.',@rcode = 1
    	goto bspexit
    end
    
    --if not exists(select 1 from bINMO where INCo=@inco and MO=@mo)
    select @inusebatch=InUseBatchId,@inusemth=InUseMth,@job=Job,@jcco=JCCo,
    	@orderdate=OrderDate,@orderedby=OrderedBy,@msg=Description
    from dbo.INMO with (nolock)
    where INCo=@inco and MO=@mo
    if @@rowcount = 0
    begin
    	select @msg = 'Invalid Material Order.',@rcode = 1
    	goto bspexit
    end
    
    if not (@inusemth=@mth and @inusebatch=@batchid)
    begin
    	select @msg = 'Material Order already in use in Mth ' + convert(varchar(30),datepart(mm,@inusemth)) + '/' + convert(varchar(30),datepart(yy,@inusemth)) + ' Batch ' + convert(varchar(30),@inusebatch) + '.',@rcode = 1
    	goto bspexit
    end
    
    --Get Job Description
    select @jobdesc = Description from dbo.JCJM with(nolock) where JCCo=@jcco and Job=@job
   
    
    bspexit:
    	--if @rcode =1 select @msg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOValforConf] TO [public]
GO
