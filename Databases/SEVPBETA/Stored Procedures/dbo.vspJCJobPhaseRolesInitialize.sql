SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImmportDataJob   Script Date: 05/22/2006 ******/
CREATE proc [dbo].[vspJCJobPhaseRolesInitialize]
/*************************************
 * Created By:	GP 11/30/2009 - Issue 135527
 * Modified By:	GF & GP 03/10/2010 - issue #135527 added progress batchid and mth to parameters, added code to clear JCPPPhases and re-add
 *
 * Called from JC Job Phase Roles Initialize form.
 *
 * Pass:
 * @JCCo		JC Company
 * @Job			Job
 * @UserName	VP User Name
 * @Role		Role
 * @Process		Process (C-Cost Projections, P-Progress Entry, or B-Both)
 * @PhaseGroup	Phase Group
 * @PhaseList	Delimited List of Phases
 *
 * Returns:
 * @msg			Returns either an error message or successful completed message
 *
 * rcode returns:
 *	0 on Success, 1 on Error
 **************************************/
(@JCCo bCompany = null, @Job bJob = null, @UserName bVPUserName = null, @Role varchar(20) = null, @Process char(1) = null,
	@PhaseGroup bGroup = null, @PhaseList varchar(max) = null, @BatchId bBatchID = null, 
	@BatchMth bMonth = null, @FormName varchar(60) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @PhaseListEdit varchar(max), @CurrPhase bPhase, @ValidPhase bYN, @DisplayPhaseError bYN
select @rcode = 0, @PhaseListEdit = @PhaseList, @ValidPhase = 'N', @DisplayPhaseError = 'N'


-- Validation --
if @JCCo is null
begin
	select @msg = 'Missing JC Company.', @rcode = 1
	goto vspexit
end

if @Job is null
begin
	select @msg = 'Missing Job.', @rcode = 1
	goto vspexit
end

if @UserName is null
begin
	select @msg = 'Missing VP User Name.', @rcode = 1
	goto vspexit
end

if @Role is null
begin
	select @msg = 'Missing Role.', @rcode = 1
	goto vspexit
end

if @Process is null
begin
	select @msg = 'Missing Process.', @rcode = 1
	goto vspexit
end

if @Process not in ('C','P','B')
begin
	select @msg = 'Process must be C-Cost Projections, P-Progress Entry, or B-Both.', @rcode = 1
	goto vspexit
end

if @PhaseList is null
begin
	select @msg = 'No phases selected to initialize.', @rcode = 1
	goto vspexit
end

if not exists(select top 1 1 from dbo.JCJobRoles with (nolock) where JCCo=@JCCo and Job=@Job and Role=@Role)
begin
	select @msg = 'Role does not exist in vJCJobRoles.', @rcode = 1
	goto vspexit
end

if isnull(@PhaseGroup,'') = ''
begin
	select @PhaseGroup = PhaseGroup from dbo.HQCO where HQCo=@JCCo
end


--delete all existing records for this role and process
if exists(select top 1 1 from dbo.JCJPRoles with (nolock) where JCCo=@JCCo and Job=@Job and Process=(case when @Process = 'B' then Process else @Process end) and Role=@Role)
begin
	delete dbo.JCJPRoles
	where JCCo=@JCCo and Job=@Job and Process=(case when @Process = 'B' then Process else @Process end) and Role=@Role
end

--list gets sent in blank if no phases, set to null
if @PhaseListEdit = '' set @PhaseListEdit = null

--Parse phases and insert
while @PhaseListEdit is not null
begin
	--if contains delimiter, else assumes last phase
	if charindex('|', @PhaseListEdit) <> 0
	begin
		select @CurrPhase = substring(@PhaseListEdit, 1, charindex('|', @PhaseListEdit) - 1)
	end	
	else
	begin
		select @CurrPhase = @PhaseListEdit, @PhaseListEdit = null
	end		

	--shorten phase list, minus currphase
	select @PhaseListEdit = substring(@PhaseListEdit, charindex('|', @PhaseListEdit) + 1, len(@PhaseListEdit))
	
	--validate phase against bJCJP
	if exists(select top 1 1 from dbo.JCJP with (nolock) where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup 
		and Phase=@CurrPhase) set @ValidPhase = 'Y' else set @ValidPhase = 'N'

	--insert records
	if @Process in ('C','P') and @ValidPhase = 'Y'
	begin
		--if not exists, ensures no duplicate key inserts
		if not exists(select top 1 1 from dbo.JCJPRoles with (nolock) where JCCo=@JCCo and Job=@Job 
			and PhaseGroup=@PhaseGroup and Phase=@CurrPhase and Process=@Process and Role=@Role)
		insert dbo.JCJPRoles(JCCo, Job, PhaseGroup, Phase, Process, Role)
		values(@JCCo, @Job, @PhaseGroup, @CurrPhase, @Process, @Role)
	end

	if @Process = 'B' and @ValidPhase = 'Y'
	begin
		if not exists(select top 1 1 from dbo.JCJPRoles with (nolock) where JCCo=@JCCo and Job=@Job 
			and PhaseGroup=@PhaseGroup and Phase=@CurrPhase and Process='C' and Role=@Role)	
		insert dbo.JCJPRoles(JCCo, Job, PhaseGroup, Phase, Process, Role)
		values(@JCCo, @Job, @PhaseGroup, @CurrPhase, 'C', @Role)

		if not exists(select top 1 1 from dbo.JCJPRoles with (nolock) where JCCo=@JCCo and Job=@Job 
			and PhaseGroup=@PhaseGroup and Phase=@CurrPhase and Process='P' and Role=@Role)
		insert dbo.JCJPRoles(JCCo, Job, PhaseGroup, Phase, Process, Role)
		values(@JCCo, @Job, @PhaseGroup, @CurrPhase, 'P', @Role)		
	end	
	
	if @ValidPhase = 'N' set @DisplayPhaseError = 'Y'
end --end phase loop

--clear JC Progress Filter list, insert new records
if @FormName = 'JCProgress' and @Process = 'P'
begin
	delete dbo.JCPPPhases where Co=@JCCo and Month=@BatchMth and BatchId=@BatchId

	insert dbo.JCPPPhases (Co, Month, BatchId, Job, PhaseGroup, Phase)
	select @JCCo, @BatchMth, @BatchId, @Job, @PhaseGroup, Phase 
		from dbo.JCJPRoles with (nolock) 
		where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Process=@Process and Role=@Role
end

--display error if phases skipped
if @DisplayPhaseError = 'Y'
begin
	select @msg = 'Some of the phases selected do not exist in JC Job Phases and were not initialized.', @rcode = 1
	goto vspexit
end


vspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'') 
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspJCJobPhaseRolesInitialize] TO [public]
GO
