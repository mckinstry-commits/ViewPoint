SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCAddJCCHFromJCPC    Script Date: 8/28/99 9:34:59 AM ******/
CREATE  proc [dbo].[bspJCAddJCCHFromJCPC]

/***********************************************************
* CREATED BY: SE   11/10/96
* MODIFIED By : JRE 2/16/98
*               LM 01/26/00 - added check to see if we are trying to insert a record that already exists.
*				TV - 23061 added isnulls
* USAGE:
* creates JCCH entries from JCPC for the Job phase passed in
* an error is returned if any goes wrong.             
* 
* If we have an exact match in JCJP then add it's phases, otherwise use the 
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

declare @rcode int, @validphasechars int, @lockphases bYN, @PhaseGroup tinyint

select @rcode = 0

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

---- Validate the Company and get valid portion of phase and phase group
select @validphasechars = ValidPhaseChars, @PhaseGroup=bHQCO.PhaseGroup 
from bJCCO with (nolock) join bHQCO with (nolock) on bHQCO.HQCo=bJCCO.JCCo where bJCCO.JCCo = @jcco
if @@rowcount = 0 
	begin
	select @msg = 'Invalid Job Cost Company!', @rcode = 1
	goto bspexit
	end
   
   
---- if the phase=pphase then must have validated against JCPM 
if @phase=@pphase
	begin
	insert into bJCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag)
	select @jcco, @job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
	from bJCPC with (nolock) where PhaseGroup=@PhaseGroup and Phase = @phase
	and not exists(select top 1 1 from bJCCH j with (nolock) where JCCo=@jcco and Job=@job 
			and PhaseGroup=@PhaseGroup and Phase = @phase and CostType=j.CostType)
	end
else
	begin
	-- if the phase<>pphase then see if partial match exists in JCJP, if so
	-- then pull costtype from partial phase of  JCCH
	-- otherwise pull partialphase from JCPC
	if exists(select 1 from bJCJP with (nolock) where JCCo=@jcco and Job=@job and Phase=@pphase)
		-- Otherwise copy the valid part of the phases JCPC records
    		insert into bJCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag)
		select @jcco, @job, PhaseGroup, @phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
		   from bJCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@PhaseGroup and Phase = @pphase
		and not exists(select top 1 1 from bJCCH j with (nolock) where JCCo=@jcco and Job=@job 
				and PhaseGroup=@PhaseGroup and Phase = @phase and bJCCH.CostType=j.CostType)
	else
		insert into bJCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag)
		select @jcco, @job, PhaseGroup, @phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
		   from bJCPC with (nolock) where PhaseGroup=@PhaseGroup and Phase = @pphase
		and not exists(select top 1 1 from bJCCH j with (nolock) where JCCo=@jcco and Job=@job 
				and PhaseGroup=@PhaseGroup and Phase = @phase and CostType=j.CostType)
	end


select @rcode = 0, @msg = isnull(convert(varchar(5),@@rowcount),'') + 'Rows inserted!'


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCAddJCCHFromJCPC] TO [public]
GO
