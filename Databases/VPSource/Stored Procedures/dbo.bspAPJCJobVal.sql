SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspAPJCJobVal]
   
   	(@jcco bCompany = 0, @job bJob = null, 
   	 @msg varchar(60) output) 
   as
   set nocount on
   /***********************************************************
    * CREATED BY: MV   10/23/01
    * MODIFIED By :   kb 10/28/2 - issue #18878 - fix double quotes
    *
    * USAGE:
    * validates JC Job and returns the job description
    * an error is returned if any of the following occurs
    * no job passed, no job found in JCJM
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against 
    *   Job    Job to validate
    *
    * OUTPUT PARAMETERS
    *   @desc returns the job desc for this contract                       
    *   @msg      error message if error occurs otherwise Description of Job
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   
   	declare @rcode int
   	select @rcode = 0 
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @job is null
   	begin
   	select @msg = 'Missing Job!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg=Description 
   	from JCJM 
   	where JCCo = @jcco 
   	and Job = @job 
   	
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Job not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPJCJobVal] TO [public]
GO
