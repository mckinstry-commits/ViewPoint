SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCJMProgressVal]
/***********************************************************
     * CREATED BY:  DANF 05/03/2006 
     * MODIFIED By: GF 12/12/2007 - issue #25569 use separate post closed job flags from JCCO
*
*
     * USAGE:
     * validates JC Job
     * an error is returned if any of the following occurs
     * no job is passed, no job found in JCCM.
     *  
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
(@jcco bCompany = 0, @job bJob = null, @batch bBatchID = 0, @mth bMonth = null,
 @actualdate bDate = null, @filter bYN = null, @contract bContract  = null output,
 @lockphases bYN = null output, @msg varchar(60) output)
as
set nocount on  
  
declare @rcode int, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1), @otherbatch bBatchID, @othermth bMonth, @status tinyint

select @rcode = 0, @contract=''

if @jcco is null
    	begin
    	select @msg = 'Missing JC Company!', @rcode = 1
    	goto bspexit
    	end

select @postclosedjobs=PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
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

if @actualdate is null and isnull(@filter,'N') = 'N'
    	begin
    	select @msg = 'Missing Actual Date!', @rcode = 1
    	goto bspexit
    	end

if @mth is null
    	begin
    	select @msg = 'Missing Month!', @rcode = 1
    	goto bspexit
    	end

select @msg = Description, @contract=Contract, @status=JobStatus, @lockphases=LockPhases
from JCJM with (nolock) where JCCo = @jcco and Job = @job
if @@rowcount = 0
    	begin
    	select @msg = 'Job not on file!', @rcode = 1
    	goto bspexit
    	end
---- check status
if @status = 0
        begin
        select @msg='Job Status cannot be Pending!', @rcode=1
        goto bspexit
        end
if @status = 2 and @postsoftclosedjobs = 'N'
	begin
	select @msg = 'Job Soft-Closed!', @rcode = 1
	end
if @status = 3 and @postclosedjobs = 'N'
	begin
	select @msg='Job Hard- Closed!', @rcode=1
	end

if exists(select top 1 1 from bJCPP with (nolock) where Co=@jcco and Job=@job and (Mth<>@mth or (BatchId<>@batch and Mth=@mth)))
	begin
	select @otherbatch = BatchId, @othermth = Mth
	from bJCPP with (nolock) where Co=@jcco and Job=@job and (Mth<>@mth or (BatchId<>@batch and Mth=@mth))
	select @msg = 'Warning: Job ' + isnull(@job,'') + ' exists in batch ' + isnull(convert(varchar(8),@otherbatch),'') + 
    				' in month of ' + isnull(convert(varchar(12),@othermth),'') + '', @rcode = 1
	goto bspexit
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJMProgressVal] TO [public]
GO
