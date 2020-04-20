SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCJMValWithDesc    Script Date: 2/12/97 3:25:05 PM ******/
CREATE   proc [dbo].[bspJCJMValWithDesc]
/***********************************************************
* CREATED BY: SE   2/12/97
* MODIFIED By : LM 2/12/97
*				TV - 23061 added isnulls
*				CHS 01/22/2009 - issue #26087
*
* USAGE:
* validates JC Job
* and returns job Desc, and Job Desc or Message
* an error is returned if any of the following occurs
* no job passed, no job found in JCJM, 
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against 
*   Job    Job to validate
*
* OUTPUT PARAMETERS
*   @jobdesc   returns a description of the job
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany = 0, @job bJob = null, @jobdesc bItemDesc output, @msg varchar(60) output)

   as
   set nocount on   
   
   	declare @rcode int
   
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
   
   select @msg = j.Description 
   	from JCJM j with(nolock)
   	where j.JCCo = @jcco 
   	and j.Job = @job 
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Job not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	select @jobdesc=@msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJMValWithDesc] TO [public]
GO
