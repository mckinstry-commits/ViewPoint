SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspJCJMValWithDesc]
/***********************************************************
* CREATED BY:	CHS	04/25/2008 copied from bspJCJMValWithDesc for issue #126600 (added paramter @jobstatus)
* MODIFIED By:	CHS	01/22/2009	- issue #26087 
*				GF 01/20/2010 - issue #135527 - job roles
*				GP	01/09/2012 - TK-11616 Added new output parameter for Project Manager
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
(@jcco bCompany = 0, @job bJob = null, @jobdesc bItemDesc = null output,
 @jobstatus bStatus = null output, @roles_exist char(1) = 'N' output,
 @ProjectManager int = null output,
 @msg varchar(60) output)

   as
   set nocount on  
   
declare @rcode int

set @roles_exist = 'N'
   
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
   
	select @msg = [Description], @jobstatus = JobStatus, @ProjectManager = ProjectMgr
   	from dbo.JCJM
   	where JCCo = @jcco and Job = @job 
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Job not on file!', @rcode = 1
   	goto bspexit
   	end
   	
---- check if roles exist for job
if exists(select 1 from dbo.vJCJobRoles with (nolock) where JCCo=@jcco and Job=@job)
	begin
	set @roles_exist = 'Y'
	end
   
   bspexit:
   	select @jobdesc=@msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJMValWithDesc] TO [public]
GO
