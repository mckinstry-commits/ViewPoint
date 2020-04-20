SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCJMClosedStatusVal  ******/
CREATE  proc [dbo].[vspJCJMClosedStatusVal]
/*************************************
 * Created By:	GF 12/07/2007
 * Modified By:
 *
 *
 * USAGE:
 * Use this procedure to validate the job soft-closed (2) or hard-closed (3) statuses
 * to the JC Company Soft and Hard Closed Flags. JCCO.PostSoftClosedJobs, JCCO.PostClosedJobs
 *
 *
 *
 * INPUT PARAMETERS
 * @jcco			JC Company
 * @job				JC Job
 *
 * Success returns:
 * 0 and no message
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@jcco bCompany, @job bJob, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @jobstatus tinyint, @postclosedjobs bYN, @postsoftclosedjobs bYN

select @rcode = 0, @errmsg = ''

---- Validate and check to make sure Job is not closed
select @postclosedjobs=PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from JCCO with (nolock) where JCCo = @jcco
if @@rowcount = 0
	begin
	select @errmsg = 'JC Company: ' + convert(varchar(3), @jcco) + ' is invalid.', @rcode=1
	goto bspexit
 	end

---- check project
select @jobstatus=JobStatus
from JCJM with (nolock) where JCCo=@jcco and Job=@job
if @@rowcount = 0
	begin
	select @errmsg='Job: ' + isnull(@job,'') + ' must be setup in JC Job Master.', @rcode=1
	goto bspexit
 	end

---- check job status for soft closed jobs
if @postsoftclosedjobs = 'N' and @jobstatus = 2
	begin
	select @errmsg='Job: ' + isnull(@job,'') + ' is soft-closed and you are not allowed to post to soft-closed jobs.', @rcode=1
	goto bspexit
 	end

---- check job status for hard closed jobs
if @postclosedjobs='N' and @jobstatus=3
	begin
	select @errmsg='Job: ' + isnull(@job,'') + ' is hard-closed and you are not allowed to post to hard-closed jobs.', @rcode=1
	goto bspexit
 	end








bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJMClosedStatusVal] TO [public]
GO
