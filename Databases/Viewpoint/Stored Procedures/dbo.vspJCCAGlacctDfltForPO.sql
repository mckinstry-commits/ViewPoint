SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    proc [dbo].[vspJCCAGlacctDfltForPO]
/***********************************************************
* CREATED: DAN SO 01/05/12 - TK-10952 - need to check to allow GL overrides
* MODIFIED: 
*
* USAGE:
*	*** THIS IS A COPY OF bspJCCAGlacctDflt - TOO MANY PLACES TO UPDATE - SO MADE NEW ONE ***
*	*** Called from PO Entry ***
*
* Called from various forms and stored procedures to retreive a default
* GL Account for a given JC Co#, Job, Phase, and Cost Type.
*
* INPUT PARAMETERS
*    @jcco         JC Company
*    @job          Job
*    @phasegroup   Phase Group
*    @phase        Phase
*    @costtype     Cost Type
*    @override     'Y' = override job 'lock phases' flag, 'N' = no override
*
* OUTPUT PARAMETERS
*    @glacct        default GL Account
*	 @GLOverride	Override GL Account?
*    @msg           error message from
*
* RETURN VALUE
*    none
*  

*   
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @phasegroup bGroup, @phase bPhase = null, @costtype bJCCType = null,
 @override bYN = 'N', @glacct bGLAcct output, @GLOverride bYN output, @msg varchar(30) output)
as 
set nocount on

declare @rcode int, @dept bDept, @status tinyint,@pphase bPhase, @validphasechars int,
		@InputMask varchar(30), @InputType tinyint, @validphase bPhase

---- get JC Department
exec @rcode =  bspJCVPHASE @jcco, @job, @phase, @phasegroup, @override, @dept=@dept output, @msg=@msg output

---- get Phase Format 
select @InputMask = InputMask, @InputType= InputType
from dbo.DDDTShared (nolock) where Datatype ='bPhase'

select @glacct = null

---- if JC Department is null, get it from the first Contract Item
if @dept is null
	begin
	select @dept = i.Department
	from bJCCI i with (nolock) 
	join bJCJM j with (nolock) on j.JCCo = i.JCCo and j.Contract = i.Contract
	where j.JCCo = @jcco and j.Job = @job
	and i.Item = (select min(i.Item) from bJCCI i with (nolock) 
			join bJCJM j with (nolock) on j.JCCo = i.JCCo and j.Contract = i.Contract
			where j.JCCo = @jcco and j.Job = @job)
	end

---- get GL Account from JC Department based on Job Status
if @dept is not null
	begin
	---- get Job Status
	select @status = JobStatus
	from bJCJM with (nolock) where JCCo = @jcco and Job = @job
	---- Closed Jobs are status 3
	---- Issue 14175
	select @glacct = case @status when 3 then d.ClosedExpAcct else d.OpenWIPAcct end
	from bJCDO d with (nolock) join bHQCO c with (nolock) ON d.JCCo = c.HQCo
	where d.JCCo = @jcco and d.Department = @dept and d.Phase = @phase and d.PhaseGroup = c.PhaseGroup
	if @@rowcount = 0
		begin
		---- check Phase Master using valid portion
		---- validate JC Company -  get valid portion of phase code
		select @validphasechars = ValidPhaseChars
		from bJCCO with (nolock) where JCCo = @jcco
		if @@rowcount <> 0
			begin
			if @validphasechars > 0
				begin
				---- select @pphase = substring(@phase,1,@validphasechars) + '%'
				select @validphase  = substring(@phase,1,@validphasechars)
					begin
					exec @rcode = bspHQFormatMultiPart @validphase, @InputMask, @pphase output
						begin
						select @glacct = case @status when 3 then d.ClosedExpAcct else d.OpenWIPAcct end
						from bJCDO d with (nolock) join bHQCO c with (nolock) ON d.JCCo = c.HQCo
						where d.JCCo=@jcco and d.Department=@dept and d.Phase=@pphase and d.PhaseGroup=c.PhaseGroup
						end
					end
				end -- end valid part
			end-- end select of jc company
		end -- end of full phase not found
	end

if @glacct is null
	begin
	select @glacct = case @status when 3 then d.ClosedExpAcct else d.OpenWIPAcct end
	from bJCDC d with (nolock) join bHQCO c with (nolock) ON d.JCCo = c.HQCo
	where d.JCCo = @jcco and d.Department = @dept and d.CostType = @costtype and d.PhaseGroup = c.PhaseGroup
	end

--------------
-- TK-10952 --
--------------
SELECT @GLOverride = GLCostOveride FROM bJCCO WHERE JCCo = @jcco
GO
GRANT EXECUTE ON  [dbo].[vspJCCAGlacctDfltForPO] TO [public]
GO
