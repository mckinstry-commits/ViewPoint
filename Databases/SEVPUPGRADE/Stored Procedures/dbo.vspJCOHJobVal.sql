SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCOHJobVal    Script Date: 8/28/99 9:33:00 AM ******/
  CREATE      proc [dbo].[vspJCOHJobVal]
  /***********************************************************
   * CREATED BY:	JM   6/23/98
   * MODIFIED By: GF 04/01/2003 - issue #20871 - use PostClosedJobs flag when checking Job Status
   *				TV - 23061 added isnulls
   *			 DANF 10/21/2005 - Modified for 6.x to return lock phases 
*					GF 12/12/2007 - issue #25569 separate post closed job flags in JCCO
*
*
   * USAGE:
   * Validates JC Job and returns Contract, Contract Description and Job Status.
   * An error is returned if any of the following occurs:
   *
   *	No job passed
   *	No job found in JCJM
   *	No contract found in JCCM
   *
   * INPUT PARAMETERS
   *   JCCo   JC Co to validate against 
   *   Job    Job to validate
   *
   * OUTPUT PARAMETERS
   *   @contract - returns the contract for the job.  
   *   @contractdesc - returns the contract desc for the contract                       
   *   @msg - error message if error occurs otherwise Description of Job
   * RETURN VALUE
   *   0         success
   *   1         failure
   *****************************************************/ 
(@jcco bCompany = 0, @job bJob = null, @contract bContract output,
  @contractdesc bDesc output, @lockphases bYN output, @contractstatus tinyint = null output , 
  @postclosedjobs bYN = null output, @postsoftclosedjobs bYN = null output, @msg varchar(60) output)
as
set nocount on

declare @rcode int, @jobstatus tinyint

select @rcode = 0, @contract='', @contractdesc='', @jobstatus = null

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

select @postclosedjobs=PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from dbo.bJCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0
  	begin
  	select @msg = 'Invalid JC Company!', @rcode = 1
  	goto bspexit
  	end


select @msg = j.Description, @contract=j.Contract, @contractdesc=c.Description,
		@jobstatus=j.JobStatus, @lockphases = j.LockPhases, @contractstatus = c.ContractStatus
from dbo.JCJM j with (nolock)
join dbo.JCCM c with (nolock)
on j.JCCo = c.JCCo and j.Contract=c.Contract
where j.JCCo = @jcco and j.Job = @job 
if @@rowcount = 0
  	begin
  	select @msg = 'Job not on file, or no associated contract!', @rcode = 1
  	goto bspexit
  	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCOHJobVal] TO [public]
GO
