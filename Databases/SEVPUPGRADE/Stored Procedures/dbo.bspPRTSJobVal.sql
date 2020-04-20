SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSJobVal    Script Date: 8/28/99 9:35:03 AM ******/
CREATE    proc [dbo].[bspPRTSJobVal]
   /***********************************************************
    * CREATED BY: EN	2/27/03
    * MODIFIED By:	GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
	*
    *
    * USAGE:
    * validates JC Job for Crew Timesheets
    * an error is returned if any of the following occurs
    * no job is passed, no job found in JCCM.
    *   -If jCCO.PostCLosedJobs='N' and Job status is 2 or 3
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against
    *   Job    Job to validate
    *
    * OUTPUT PARAMETERS
    *   @status   Status of job, Open, SoftClose,Close
    *   @lockphases  weather or not lockphases flag is set
    *	 @crafttemplate	from bJCJM
    *   @msg      error message if error occurs otherwise Description of Job
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@jcco bCompany = 0, @job bJob = null, @status tinyint =null output, 
    @lockphases bYN = null output, @crafttemplate smallint = null output,
    @msg varchar(100) output)
   as
   set nocount on
   
   
   
   	declare @rcode int, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1)
   	select @rcode = 0
   
   
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs = PostSoftClosedJobs
from bJCCO where JCCo=@jcco
if @@rowcount = 0
   	begin
   	select @msg = 'JC Company invalid!', @rcode = 1
   	goto bspexit
   	end
   
   if @job is null
   	begin
   	select @msg = 'Missing Job!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @status=JobStatus, @lockphases=LockPhases, @crafttemplate=CraftTemplate
   	from JCJM
   	where JCCo = @jcco and Job = @job
   
   
	if @@rowcount = 0
	begin
		if exists(select 1 from bJCJM where JCCo = @jcco and Job = @job)
		begin
			select @msg = 'Record already exists, but is unavailable due to Job data security.', @rcode = 1
			goto bspexit
		end
		else
		begin
			select @msg = 'Job not on file!', @rcode = 1
			goto bspexit
		end
	end

if @status=0
	begin
	select @msg='Job Status cannot be Pending!', @rcode=1
	goto bspexit
	end

if @status = 2 and @postsoftclosedjobs = 'N'
	begin
	select @msg='Job is soft-closed!', @rcode=1
	goto bspexit
	end

if @status = 3 and @postclosedjobs = 'N'
	begin
	select @msg='Job is hard-closed!', @rcode=1
	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSJobVal] TO [public]
GO
