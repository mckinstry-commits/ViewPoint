SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMUsePostingJobVal  Script Date: ******/
CREATE proc [dbo].[vspEMUsePostingJobVal]
/***********************************************************
* CREATED BY:	TJL 12/07/06 - Issue #27979, 6x Recode EMUsePosting
* MODIFIED By:	GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*				CHS 04/24/20008 - issue # 126600
*
* USAGE:
*	Validates JC Job
*	Calls vspEMUsePostingFlagsGet for other values
*	Calls vspEMUsePostingRevRateUMDflt for other values
*
*
* INPUT PARAMETERS
*
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@emco bCompany, @emgroup bGroup, 
	@equip bEquip = null, @category bCat = null, @revcode bRevCode = null, @jcco bCompany = null,
    @job bJob = null, @postworkunits bYN output, @allowrateoride bYN = null output,
    @revbasis char(1) = null output, @hrfactor bHrs = null output, @updatehrs bYN = null output,
	@rate bDollar = null output, @timeum bUM = null output, @workum bUM = null output,
	@lockphases bYN = null output, @jobstatus bStatus = null output, @msg varchar(255) output)
as
set nocount on


declare @rcode int, @status tinyint, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1),
		@unusedmsg varchar(255)


select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end
if @emgroup is null
	begin
	select @msg = 'Missing EM Group.', @rcode = 1
	goto vspexit
	end
if @equip is null
	begin
	select @msg = 'Missing Equipment.', @rcode = 1
	goto vspexit
	end
if @revcode is null
	begin
	select @msg = 'Missing Revenue Code.', @rcode = 1
	goto vspexit
	end
if @jcco is null
	begin
	select @msg = 'Missing JC Company.', @rcode = 1
	goto vspexit
	end
if @job is null
	begin
	select @msg = 'Missing Job.', @rcode = 1
	goto vspexit
	end

select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs = PostSoftClosedJobs
from JCCO with (nolock) 
where JCCo = @jcco

/* Validate Job */   
select @msg = Description, @status = JobStatus, @jobstatus = JobStatus, @lockphases = LockPhases
from JCJM with (nolock)
where JCCo = @jcco and Job = @job
if @@rowcount = 0
	begin
	select @msg = 'Job not on file.', @rcode = 1
	goto vspexit
	end

if @status = 0
    begin
    select @msg='Job Status cannot be Pending.', @rcode=1
    goto vspexit
    end

if @status = 2 and @postsoftclosedjobs = 'N'
	begin
	select @msg = 'Job is Soft-Closed.', @rcode=1
	goto vspexit
	end

if @status = 3 and @postclosedjobs = 'N'
	begin
	select @msg = 'Job is Hard-Closed.', @rcode=1
	goto vspexit
	end

/* Retrieve EM usage flags. */
exec @rcode = vspEMUsePostingFlagsGet @emco, @emgroup, @equip, @category, @revcode, @jcco, @job, 
	@postworkunits output, @allowrateoride output, @revbasis output, @hrfactor output, 
    @updatehrs output, @unusedmsg output
if @rcode <> 0 goto vspexit

/* Retrieve Rate and UM values. */
exec @rcode = vspEMUsePostingRevRateUMDflt @emco, @emgroup, @equip, @category, @revcode, @jcco, @job, 
	@rate output, @timeum output, @workum output,
    @msg output
if @rcode <> 0 goto vspexit
    
vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMUsePostingJobVal] TO [public]
GO
