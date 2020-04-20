SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCAddJCCHFromJCPCForJCJPEST    Script Date: 12/01/2004 ******/
CREATE  proc [dbo].[bspJCAddJCCHFromJCPCForJCJPEST]
/***********************************************************
    * CREATED BY:	GF 12/01/2004
    * MODIFIED By:	GF 12/12/2007 - issue #25569 use separate post to closed job flags in JCCO enhancement
    *
    *
    *
    * USAGE:
    * creates JCCH entries from JCPC for the Job phase passed in
    * from JCJPEST. The cost type initialize is a little different from JCJP.
    *
    * An error is returned if any goes wrong.             
    * 
    * If we have an exact match in JCJP then add it's phases, otherwise use the 
    * partial phase and add it's cost types to JCCH
    *
    * INPUT PARAMETERS
    * JCCo   JC Company
    * Job    JC Job
    * Phase  JC Phase
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@jcco bCompany = 0, @job bJob = null, @phase bPhase = null, @phasegroup bGroup = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validphasechars int, @pphase bPhase
   
   select @rcode = 0, @msg = ''
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @phase is null
   	begin
   	select @msg = 'Missing phase!', @rcode = 1
   	goto bspexit
   	end
   
   -- Validate the Company and get valid portion of phase and phase group
   select @validphasechars = ValidPhaseChars
   from bJCCO with (nolock) where JCCo=@jcco
   if @@rowcount = 0 
   	begin
   	select @msg = 'Invalid Job Cost Company!', @rcode = 1
   	goto bspexit
   	end

---- first check and see if cost type exist for exact phase in JCCH
---- if cost types found then done, exit stored procedure
if exists(select top 1 1 from bJCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase)
   	goto bspexit

---- validate job status with JCCo post to closed flags
exec @rcode = dbo.vspJCJMClosedStatusVal @jcco, @job, @msg output
if @rcode <> 0 goto bspexit

---- check for cost types that exist for exact phase in JCPC
---- if cost types found then load into JCCH
   if exists(select top 1 1 from bJCPC where PhaseGroup=@phasegroup and Phase=@phase)
   	begin
   	insert into bJCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag)
   	select @jcco, @job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
   	from bJCPC with (nolock) where PhaseGroup=@phasegroup and Phase = @phase
   	and not exists(select top 1 1 from bJCCH j with (nolock) where JCCo=@jcco and Job=@job 
   						and PhaseGroup=@phasegroup and Phase = @phase and CostType=j.CostType)
   	goto bspexit
   	end
   
   
   -- -- -- check for a valid portion
   if isnull(@validphasechars,0) = 0 goto bspexit
   -- format valid portion of Phase
   select @pphase = substring(@phase,1,@validphasechars) + '%'
   -- check valid portion of Phase in Job Phase table
   select Top 1 @pphase=Phase
   from bJCJP with (nolock) where JCCo = @jcco and Job = @job and Phase like @pphase
   Group By JCCo, Job, Phase
   
   -- -- -- see if partial match exists in JCJP, if so then pull cost types 
   -- -- -- from partial phase of JCCH, otherwise pull partial phase from JCPC
   if exists(select 1 from bJCJP with (nolock) where JCCo=@jcco and Job=@job and Phase=@pphase)
   	begin
   	insert into bJCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag)
   	select @jcco, @job, PhaseGroup, @phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
   	from bJCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@pphase
   	and not exists(select top 1 1 from bJCCH j with (nolock) where JCCo=@jcco and Job=@job 
   				and PhaseGroup=@phasegroup and Phase=@phase and bJCCH.CostType=j.CostType)
   	goto bspexit
   	end
   else
   	begin
   	insert into bJCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag)
   	select @jcco, @job, PhaseGroup, @phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
   	from bJCPC with (nolock) where PhaseGroup=@phasegroup and Phase=@pphase
   	and not exists(select top 1 1 from bJCCH j with (nolock) where JCCo=@jcco and Job=@job 
   				and PhaseGroup=@phasegroup and Phase=@phase and CostType=j.CostType)
   	goto bspexit
   	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCAddJCCHFromJCPCForJCJPEST] TO [public]
GO
