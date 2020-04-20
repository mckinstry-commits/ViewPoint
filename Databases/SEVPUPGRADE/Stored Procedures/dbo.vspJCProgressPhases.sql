SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCProgressPhases]
/****************************************************************************
* Created By:		DANF	04/04/2006
* Modified By:		CHS		12/22/2009 - #135527
*					GF 02/01/2010 - issue #135527 job roles enhancement
*					GF 06/16/2010 - issue #140202 multiple roles for user
*
* USAGE:
* Used to popoulate Progress Phase List
*
* INPUT PARAMETERS:
* JC Company, job
*
* OUTPUT PARAMETERS:
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@jcco bCompany = null, @job bJob = null, @UserName varchar(200) = null, @phase_option char(1) = null,
 @mth bMonth = null, @batchid bigint = null)
as
set nocount on

declare @rcode int, @Role varchar(20), @UserRole varchar(max)

select @rcode = 0, @Role = ''

if isnull(@phase_option,'') = '' set @phase_option = 'S'


---- create a delimited string of roles for this user #140202
set @UserRole = ''
select @UserRole = @UserRole + r.Role + ';'
from dbo.JCJobRoles r with (nolock)
where r.JCCo=@jcco and r.Job=@job and r.VPUserName=@UserName
and exists(select top 1 1 from dbo.JCJPRoles p with (nolock) where p.JCCo=r.JCCo and p.Job=r.Job
		and p.Role=r.Role and p.Process='C')
if @@rowcount = 0
	begin
	select @UserRole = ''
	end
else
	begin
	if isnull(@UserRole,'') <> ''
		begin
		select @UserRole = left(@UserRole, len(@UserRole)- 1) -- remove last semi-colon
		end
	end
	
---- get the role for this user from JCJPRoles if phases are assigned to the Cost Projections  #135527
----select @user_role=r.Role
----from dbo.JCJobRoles r with (nolock)
----left join dbo.JCJPRoles p with (nolock) on p.JCCo=r.JCCo and p.Job=r.Job and p.Role=r.Role and p.Process='P'
----where r.JCCo=@jcco and r.Job=@job and p.Process='P' and r.VPUserName=@UserName
if isnull(@UserRole,'') = ''
----if @@rowcount = 0 
	begin
	set @UserRole = null
	select j.Phase as 'Phase', j.Description as 'Phase Desc', j.Item as 'Contract Item', c.Description as 'Item Desc', '' as 'Role'
	from dbo.JCJP j with(nolock)
	join dbo.JCCI c with(nolock)
	on j.JCCo = c.JCCo and j.Contract = c.Contract and j.Item = c.Item
	where j.JCCo = @jcco and j.Job = @job and j.ActiveYN = 'Y'
	end
else
	begin
	---- #135527
	---- if phase option for user is 'S' - selected then populate the JCPPPhases table with job phases for role
	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.JCPPPhases x WITH (NOLOCK) WHERE x.Co=@jcco AND x.Job=@job AND x.BatchId=@batchid
					AND x.Month=@mth)
		begin
		insert into dbo.JCPPPhases(Co, Month, BatchId, Job, PhaseGroup, Phase)
		select @jcco, @mth, @batchid, @job, j.PhaseGroup, j.Phase
		from dbo.JCJP j with (nolock)
		join dbo.vJCJPRoles p with (nolock) on j.JCCo = p.JCCo and j.Job = p.Job and j.PhaseGroup = p.PhaseGroup and j.Phase = p.Phase and p.Process='P'
		where j.JCCo = @jcco and j.Job = @job  and j.ActiveYN = 'Y'
		and PATINDEX('%' + p.Role + '%', @UserRole) <> 0
		----and charindex( convert(varchar(20),p.Role) + ';', @UserRole) <> 0) #140202
		AND NOT EXISTS(SELECT 1 FROM dbo.JCPPPhases x WITH (NOLOCK) WHERE x.Co=@jcco AND x.Job=@job AND x.Phase=j.Phase
				AND x.Month=@mth AND x.BatchId=@batchid)
		end
	
	---- return initial list of phases to display in phase list box
	select j.Phase as 'Phase', j.Description as 'Phase Desc', j.Item as 'Contract Item', c.Description as 'Item Desc', p.Role as 'Role'
	from dbo.JCJP j with(nolock)
	join dbo.JCCI c with(nolock) on j.JCCo = c.JCCo and j.Contract = c.Contract and j.Item = c.Item
	join dbo.vJCJPRoles p with (nolock) on j.JCCo = p.JCCo and j.Job = p.Job and j.PhaseGroup = p.PhaseGroup and j.Phase = p.Phase and p.Process='P'
	where j.JCCo = @jcco and j.Job = @job  and j.ActiveYN = 'Y'
	and PATINDEX('%' + p.Role + '%', @UserRole) <> 0
	----and charindex( convert(varchar(20),p.Role) + ';', @UserRole) <> 0) #140202
	---- #135527
	end



bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProgressPhases] TO [public]
GO
