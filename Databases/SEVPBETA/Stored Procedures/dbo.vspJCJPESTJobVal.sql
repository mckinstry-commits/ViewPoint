SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspJCJPESTJobVal]
/***********************************************************
* Created By:  DANF 06/24/2005
* Modified By:	GP  11/20/2008 - Issue 130926, added @JobTotal to sum cost in JCCH.
*				CHS 05/29/2009 - issue #133735
*
* USAGE:
* validates JC Job
* and returns contract, Contract Description, and Locked Phase Flag.
* an error is returned if any of the following occurs
* no job passed, no job found in JCJM, no contract found in JCCM
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   Job    Job to validate
*
* OUTPUT PARAMETERS
*   @contract returns the contract for this job.
*   @contractdesc returns the contract desc for this contract
*   @lockedphases returns the locked phase flag for this job.
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @contract bContract = null output,
	@contractdesc bDesc = null output, @lockphases bYN output,
	@status tinyint = null output, @JobTotal numeric(14,2) = 0 output, 
	@autoadditemyn bYN = 'N' output, @msg varchar(60) output)

  as
  set nocount on
  
  declare @rcode int, @JobStatus tinyint
  select @rcode = 0, @contract='', @contractdesc='', @lockphases='N'
  
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
  
  select @msg=j.Description, @contract=j.Contract, @contractdesc=c.Description,
		@lockphases=j.LockPhases, @status=j.JobStatus, @autoadditemyn = j.AutoAddItemYN
  from dbo.JCJM j with (nolock)
  join dbo.JCCM c with (nolock)
  on j.JCCo = c.JCCo and j.Contract = c.Contract
  where j.JCCo=@jcco and j.Job=@job
  if @@rowcount = 0
  	begin
  	select @msg = 'Job not on file, or no associated contract!', @rcode = 1
  	goto bspexit
  	end

  if isnull(@status,99) = 0
  	begin
  	select @msg = 'Job is pending, access not allowed.', @rcode = 1
  	goto bspexit
  	end

	-- Get JobTotal by summing Cost in JCCH
	select @JobTotal = isnull(sum(OrigCost),0)
	from JCCH with (nolock) where JCCo = @jcco and Job = @job
	if @@rowcount = 0 
	begin
		set @JobTotal = 0
	end  

  bspexit:
      if @rcode<>0 select @msg=@msg
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJPESTJobVal] TO [public]
GO
