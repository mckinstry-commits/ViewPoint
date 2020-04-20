SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJCJobPhaseRolesListView]
/***********************************************************
* CREATED BY:	GP 12/01/2009 - Issue 135527
* MODIFIED BY:		
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
(@JCCo bCompany = null, @Job bJob = null, @PhaseGroup bGroup = null, @FilterPhases bYN =  'N', @Role varchar(20) = null, 
@Process char(1))
as

declare @rcode int
set @rcode = 0

if @PhaseGroup = 0
	begin
	select @PhaseGroup = PhaseGroup
	from dbo.HQCO h with (nolock)
	where h.HQCo = @JCCo
	end


if @FilterPhases = 'N'
begin
	select p.Phase, p.Description, null as [Role], 'No' as [InUse]
	from dbo.JCJP p with (nolock)
	where p.JCCo=@JCCo and p.Job=@Job and p.PhaseGroup=@PhaseGroup and not exists
		(select top 1 1 from dbo.JCJPRoles r with (nolock) where r.JCCo=@JCCo and r.Job=@Job 
		and r.PhaseGroup=@PhaseGroup and r.Phase=p.Phase --and r.Role=@Role 
		and r.Process=(case when @Process = 'B' then r.Process else @Process end))
end

if @FilterPhases = 'Y'
begin
	select distinct p.Phase, min(p.Description), min(r.Role), 'No' as [InUse]
	from dbo.JCJP p with (nolock) 
	left join dbo.JCJPRoles r with (nolock) on r.JCCo=p.JCCo and r.Job=p.Job and r.PhaseGroup=p.PhaseGroup and r.Phase=p.Phase
	where p.JCCo=@JCCo and p.Job=@Job and p.PhaseGroup=@PhaseGroup
	group by p.Phase
end
GO
GRANT EXECUTE ON  [dbo].[vspJCJobPhaseRolesListView] TO [public]
GO
