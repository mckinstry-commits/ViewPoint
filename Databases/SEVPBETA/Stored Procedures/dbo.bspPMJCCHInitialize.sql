SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE proc [dbo].[bspPMJCCHInitialize]
/***********************************************************
 * CREATED BY:	GF 01/19/2002
 * MODIFIED By: GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *				GF 09/24/2007 - issue #125552 problem with valid part phase, in some cases was @phase.
 *								Changed to check JCCH and JCPC for cost types, if none found then use
 *								valid part phase.
 *				GF 12/12/2007 - issue #124407 use post to closed job flags from JCCO enhancement
 *				GF 01/23/2009 - issue #131274 changed order of checks for JCPC and JCPM
 *
 *
 *
 *
 * USAGE:
 * creates JCCH entries from JCPC for the Job phase passed in
 * from PM Project Phase CostTypes form. Used from the PM side only.       
 * 
 * If we have an exact match in JCJP then add it's cost types, otherwise use the 
 * partial phase and add it's cost types to JCCH
 *
 * INPUT PARAMETERS
 *   JCCo   JC Co to get JCPC recs from
 *   Job    Job to get JCPC recs from
 *   Phase  Phase to get JCPC recs from
 *   PPhase  Partial phase that phase was validated against
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs 
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/ 
(@jcco bCompany = 0, @job bJob = null, @phase bPhase = null, @pphase bPhase = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @validphasechars int, @lockphases bYN, @phasegroup tinyint,
   		@costtype tinyint, @um bUM, @units bUnits, @unitcost bUnitCost, @amount bDollar,
   		@errmsg varchar(255), @openJCPCcursor tinyint, @openJCCHcursor tinyint, @recs_added int

select @rcode = 0, @units = 0, @unitcost = 0, @amount = 0, @openJCPCcursor = 0, @openJCCHcursor = 0

select @recs_added = 0

if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end

if @job is null
   	begin
   	select @msg = 'Missing Job', @rcode = 1
   	goto bspexit
   	end

if @phase is null
   	begin
   	select @msg = 'Missing phase!', @rcode = 1
   	goto bspexit
   	end

---- validate JC company and get valid portion of phase
select @validphasechars = ValidPhaseChars from JCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0 
	begin
   	select @msg = 'Invalid JC Company', @rcode = 1
   	goto bspexit
   	end

---- get phase group
select @phasegroup = PhaseGroup from HQCO with (nolock) where HQCo = @jcco
if @@rowcount = 0  
   	begin
   	select @msg = 'Missing Phase Group', @rcode = 1
   	goto bspexit
	end

---- validate job status with JCCo post to closed flags
exec @rcode = dbo.vspJCJMClosedStatusVal @jcco, @job, @msg output
if @rcode <> 0 goto bspexit

---- first set @pphase = phase from JCJP if exists
select @pphase=Phase
from JCJP where JCCo = @jcco and Job = @job and Phase = @phase

---- check for a valid portion, if zero then look for exact match in JCPM #131274
if isnull(@validphasechars,0) = 0
	begin
	---- full match in Phase Master will override description from partial match in Job Phase
	select @pphase = isnull(Phase,@phase)
	from JCPM with (nolock) 
	where PhaseGroup = @phasegroup and Phase = @phase
	if @@rowcount = 0 select @pphase=@phase
	goto skipvalidportion
	end

---- check for full phase in JCPM first - #131274
select @pphase = isnull(Phase,@phase)
from JCPM with (nolock) 
where PhaseGroup = @phasegroup and Phase = @phase
if @@rowcount = 1 goto skipvalidportion 

---- format valid portion of Phase
select @pphase = substring(@phase,1,@validphasechars) + '%'

---- check valid portion of Phase in Job Phase table
select TOP 1 @pphase = Phase
from JCCH where JCCo = @jcco and Job = @job and Phase like @pphase
Group By JCCo, Job, Phase
if @@rowcount = 0
	begin
	---- full match in Phase Master will override description from partial match in Job Phase #131274
	select @pphase = isnull(Phase,@phase)
	from JCPM with (nolock) 
	where PhaseGroup = @phasegroup and Phase = @phase
	IF @@rowcount = 0
		begin
		select top 1 @pphase=Phase
		from JCPC where PhaseGroup=@phasegroup and Phase like @pphase
		Group By PhaseGroup, Phase
		if @@rowcount = 0
			begin
			select @pphase=@phase
			end
		end
	end



skipvalidportion:
---- full match in Phase Master will override description from partial match in Job Phase
----select @pphase = isnull(Phase,@phase)
----from JCPM where PhaseGroup = @phasegroup and Phase = @phase
----select @pphase, @phase, @validphasechars
if @phase <> @pphase goto Partial_Phase
-- -- -- need to create cursor to create cost types three different ways
-- -- -- if phase=pphase then initialize cost types from JCPC
declare bcJCPC cursor LOCAL FAST_FORWARD for select CostType, UM
from JCPC where PhaseGroup=@phasegroup and Phase=@phase

open bcJCPC
set @openJCPCcursor = 1

-- -- -- process cost types
JCPC_loop:
fetch next from bcJCPC into @costtype, @um

if @@fetch_status = -1 goto JCPC_end
if @@fetch_status <> 0 goto JCPC_loop

-- -- -- insert row into bJCCH
insert JCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, SourceStatus)
select @jcco, @job, @phasegroup, @phase, @costtype, @um, BillFlag, ItemUnitFlag, PhaseUnitFlag, 'Y'
from JCPC with (nolock) where PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
and not exists (select top 1 1 from bJCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
   					and Phase=@phase and CostType=@costtype)
if @@rowcount = 1
	begin
	select @recs_added = @recs_added + 1
   	exec @retcode = dbo.bspPMSubOrMatlOrigAdd @jcco, @job, @phasegroup, @phase, @costtype, @units, @um, @unitcost, @amount, @errmsg output
   	end

goto JCPC_loop

JCPC_end:
	close bcJCPC
	deallocate bcJCPC
	set @openJCPCcursor = 0
	goto bspexit



Partial_Phase:
-- -- -- if the phase<>pphase, then see if partial match exists in JCJP.
-- -- -- If found then pull cost types from partial phase in JCCH.
if exists(select 1 from JCJP with (nolock) where JCCo=@jcco and Job=@job and Phase=@pphase)
BEGIN

   	declare bcJCCH cursor LOCAL FAST_FORWARD
   	for select CostType, UM from JCCH
   	where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@pphase
   
   	open bcJCCH
   	set @openJCCHcursor = 1
   
   	-- -- -- process cost types
   	JCCH_loop:
   	fetch next from bcJCCH into @costtype, @um
   
   	if @@fetch_status = -1 goto JCCH_end
   	if @@fetch_status <> 0 goto JCCH_loop
   
   	-- -- -- insert row into bJCCH
   	insert JCCH(JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, SourceStatus)
   	select @jcco, @job, @phasegroup, @phase, @costtype, @um, BillFlag, ItemUnitFlag, PhaseUnitFlag, 'Y'
   	from JCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@pphase and CostType=@costtype
   	and not exists (select top 1 1 from bJCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
   					and Phase=@phase and CostType=@costtype)
   	if @@rowcount = 1
   		begin
		select @recs_added = @recs_added + 1
   		exec @retcode = dbo.bspPMSubOrMatlOrigAdd @jcco, @job, @phasegroup, @phase, @costtype, @units, @um, @unitcost, @amount, @errmsg output
   		end
   
   	goto JCCH_loop



	JCCH_end:
   		close bcJCCH
   		deallocate bcJCCH
   		set @openJCCHcursor = 0
		goto bspexit
	END



-- -- -- Last part - pull cost types from partial phase in JCPC
declare bcJCPC cursor LOCAL FAST_FORWARD
for select CostType, UM from JCPC
where PhaseGroup=@phasegroup and Phase=@pphase

open bcJCPC
set @openJCPCcursor = 1

-- -- -- process cost types
JCPC1_loop:
fetch next from bcJCPC into @costtype, @um

if @@fetch_status = -1 goto JCPC1_end
if @@fetch_status <> 0 goto JCPC1_loop

-- -- -- insert cost type into bJCCH
insert JCCH(JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, SourceStatus)
select @jcco, @job, @phasegroup, @phase, @costtype, @um, BillFlag, ItemUnitFlag, PhaseUnitFlag, 'Y'
from JCPC where PhaseGroup=@phasegroup and Phase=@pphase and CostType=@costtype
and not exists (select top 1 1 from bJCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
   					and Phase=@phase and CostType=@costtype)
if @@rowcount = 1
   	begin
	select @recs_added = @recs_added + 1
   	exec @retcode = dbo.bspPMSubOrMatlOrigAdd @jcco, @job, @phasegroup, @phase, @costtype, @units, @um, @unitcost, @amount, @errmsg output
   	end

goto JCPC1_loop



JCPC1_end:
   	close bcJCPC
   	deallocate bcJCPC
   	set @openJCPCcursor = 0



 
bspexit:
   	if @openJCPCcursor = 1
   		begin
   		close bcJCPC
   		deallocate bcJCPC
   		set @openJCPCcursor = 0
   		end
   
   	if @openJCCHcursor = 1
   		begin
   		close bcJCCH
   		deallocate bcJCCH
   		set @openJCCHcursor = 0
   		end

	if @rcode = 0 select @msg = 'Cost Type records added: ' + convert(varchar(6),@recs_added) + '.'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMJCCHInitialize] TO [public]
GO
