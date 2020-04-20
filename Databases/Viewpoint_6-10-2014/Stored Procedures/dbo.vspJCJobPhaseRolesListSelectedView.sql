SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJCJobPhaseRolesListSelectedView]
/***********************************************************
* CREATED BY:	GP 12/01/2009	- Issue 135527
* MODIFIED BY:	CHS 12/22/2009	- Issue 135527
*
* USAGE:
* 	Called to fill Available Job Phases list view in JC Job Phase Roles Init.
*
* INPUT PARAMETERS:
*   JCCo
*	Job
*	PhaseGroup
*	FilterPhases
*
* OUTPUT PARAMETERS:
*	
*
*****************************************************/
(@JCCo bCompany = null, @Process char(1) = 'P', @Role varchar(20) = null, @Job bJob = null, @PhaseGroup bGroup = null, 
@FilterPhases bYN = 'N')
as

declare @rcode int
set @rcode = 0

if @PhaseGroup = 0
	begin
	select @PhaseGroup = PhaseGroup
	from dbo.HQCO h with (nolock)
	where h.HQCo = @JCCo
	end


select distinct r.Phase, p.Description, null as [Role] ----,
	----(select case when count(s.Phase) > 1 then 'Yes' else 'No' end from dbo.JCJPRoles s where s.JCCo=@JCCo 
	----and s.Job=@Job and s.PhaseGroup=@PhaseGroup and s.Process=(case when @Process = 'B' then r.Process else @Process end)
	----and s.Phase=r.Phase) as [InUse],
	----r.Process
from dbo.JCJPRoles r with (nolock)
join dbo.JCJP p with (nolock) on p.JCCo=r.JCCo and p.Job=r.Job and p.PhaseGroup=r.PhaseGroup and p.Phase=r.Phase
where r.JCCo=@JCCo and r.Job=@Job and r.PhaseGroup=@PhaseGroup 
	and r.Process=(case when @Process = 'B' then r.Process else @Process end) and r.Role=@Role


GO
GRANT EXECUTE ON  [dbo].[vspJCJobPhaseRolesListSelectedView] TO [public]
GO
