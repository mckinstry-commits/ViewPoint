SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCJMValForProgress]
/***********************************************************
     * CREATED BY: 	DANF 08/31/2006
     * MODIFIED By:	GF 12/12/2007 - issue #25569 separate post closed job flags in JCCO
*
	 *
     * USAGE:
     * validates JC Job
     * an error is returned if any of the following occurs
     * no job is passed, no job found in JCCM.
     *   -If JCCO.PostCLosedJobs='N' and Job status is 2 or 3
     *
     * INPUT PARAMETERS
     *   JCCo   JC Co to validate against
     *   Job    Job to validate
     *
     * OUTPUT PARAMETERS
     *   @contract returns the contract for this job.
     *   @status   Status of job, Open, SoftClose,Close
     *   @lockphases  weather or not lockphases flag is set
     *   @msg      error message if error occurs otherwise Description of Job
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
(@jcco bCompany = 0, @job bJob = null, @batchmth bMonth = null , @batchid bBatchID = null, 
 @actualdate bDate = null, @contract bContract = null output, @status tinyint = null output, 
 @lockphases bYN = null output, @wcode as int = null output, @wmsg varchar(100) = null output,
 @msg varchar(60) output)
as
set nocount on

declare @rcode int, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1)

select @rcode = 0

if @jcco is null
    	begin
    	select @msg = 'Missing JC Company!', @rcode = 1
    	goto bspexit
    	end

if @batchmth is null
    	begin
    	select @msg = 'Missing Batch Month!', @rcode = 1
    	goto bspexit
    	end

if @batchid is null
    	begin
    	select @msg = 'Missing Batch ID!', @rcode = 1
    	goto bspexit
    	end

if @actualdate is null
    	begin
    	select @msg = 'Missing actual Date !', @rcode = 1
    	goto bspexit
    	end

select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from bJCCO with (nolock) where JCCo=@jcco
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

select @msg = Description, @status=JobStatus, @lockphases=LockPhases, @contract = Contract
from JCJM with (nolock) where JCCo = @jcco and Job = @job
if @@rowcount = 0
    	begin
    	select @msg = 'Job not on file!', @rcode = 1
    	goto bspexit
    	end

if @status=0
	begin
	select @msg='Job Status cannot be Pending!', @rcode=1
	goto bspexit
	end

if @status=2 and @postsoftclosedjobs = 'N'
	begin
	select @msg='Job Soft-Closed!', @rcode=1
	goto bspexit
	end

if @status=3 and @postclosedjobs = 'N'
	begin
	select @msg='Job Hard-Closed!', @rcode=1
	goto bspexit
	end

exec @wcode = bspJCJobInJCPPCheck @jcco, @job, @batchid, @batchmth, @actualdate, @wmsg output


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJMValForProgress] TO [public]
GO
