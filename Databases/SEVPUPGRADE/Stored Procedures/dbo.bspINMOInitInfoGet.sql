SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspINMOInitInfoGet]
    /***********************************************************
     * CREATED BY	: RM 04/04/02
     * MODIFIED BY	: TRL 07/07/06  Added Job Description for form INMOInit
     *
     
     * USAGE:
     * validates MO, returns MO Description
     * an error is returned if any of the following occurs
     *
     * INPUT PARAMETERS
     * INCo		IN Company to validate against
     * JCCo		JCCompany from MO
     * MO		to validate
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of MO
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    (@inco bCompany = null,@mo varchar(10) = null, @jcco bCompany = null output,
     @job bJob = null output,@jobdescription bDesc = null output,  @msg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int, @status int
    
    select @rcode = 0, @status = 0
    
    if @inco is null
    	begin
    	select @msg = 'Missing IN Company!', @rcode = 1
    	goto bspexit
    	end
    
    if @mo is null
    	begin
    	select @msg = 'Missing MO!', @rcode = 1
    	goto bspexit
    	end
    
    -- if it is in INMO then it must have a status of pending or open
    select @msg = INMO.Description, @job=INMO.Job, @jobdescription = JCJM.Description, @jcco=INMO.JCCo, @status=INMO.Status
    from dbo.INMO 
	Left Join dbo.JCJM with(nolock)on INMO.JCCo = JCJM.JCCo and INMO.Job = JCJM.Job
	where INCo = @inco and MO = @mo

    if @@rowcount = 0
    begin
    	select @msg = 'MO ' + @mo + ' not valid for INCo ' + convert(varchar(10),@inco) + '.',@rcode = 1
    	goto bspexit
    end
    
    
    
    
    
    bspexit:
      --  if @rcode<>0 select @msg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOInitInfoGet] TO [public]
GO
