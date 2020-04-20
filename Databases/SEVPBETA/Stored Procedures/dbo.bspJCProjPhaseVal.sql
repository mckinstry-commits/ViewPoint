SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE  proc [dbo].[bspJCProjPhaseVal]
/****************************************************************************
* Created By:	GF 02/12/2004
* Modified By:	TV - 23061 added isnulls
*				DANF - recode for 6.x
*				GF 04/08/2008 - issue #126993 contract item and cycle mode enhancements
*
*
* USAGE: Validates a phase to bJCPB projection work table. If valid, gets
* minimum cost type found for the phase.
*
* INPUT PARAMETERS:
* JCCo		JC Company
* Mth		JC Projection Batch Month
* BatchId	JC Projection Batch ID
* Job		JC Job
* Phase Group
* Phase
*
* OUTPUT PARAMETERS:
* 0 = description and minimum cost type from JCPB
* 1 = error message
*****************************************************************************/
(@jcco bCompany, @mth bMonth, @batchid bBatchID, @job bJob, @phasegroup tinyint, 
 @phase bPhase, @username bVPUserName, @phase_out bPhase output, @costtype bJCCType output,
 @item_out bContractItem output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @description bDesc, @bphase bPhase, @bitem bContractItem,
		@costtypeoption char(1), @selectedcosttypes varchar(1000), @changedonly bYN,
		@itemunitsonly bYN, @phaseunitsonly bYN, @showlinkedct bYN, @showfutureco bYN, 
		@remainunits bYN, @remainhours bYN, @remaincosts bYN, @phaseoption char(1), 
		@begphase bPhase, @endphase bPhase, @thrupriormonth bYN, @nolinkedct bYN,
		@projmethod char(1), @citem bContractItem, @phase_range bYN, @inactivephases bYN,
		@orderby char(1), @cyclemode char(1)

select @rcode = 0

---- get cost type option from JCUO
select @changedonly=ChangedOnly, @itemunitsonly=ItemUnitsOnly, @phaseunitsonly=PhaseUnitsOnly,
		@showlinkedct=ShowLinkedCT, @showfutureco=ShowFutureCO, @remainunits=RemainUnits,
		@remainhours=RemainHours, @remaincosts=RemainCosts, @phaseoption=PhaseOption, 
		@begphase=BegPhase, @endphase=EndPhase, @thrupriormonth=ThruPriorMonth,
		@nolinkedct=NoLinkedCT, @projmethod=ProjMethod, @inactivephases=ProjInactivePhases,
		@costtypeoption=CostTypeOption, @selectedcosttypes=replace(SelectedCostTypes,';',','),
		@orderby=OrderBy, @cyclemode=CycleMode
from JCUO with (nolock) where JCCo=@jcco and Form='JCProjection' and UserName=@username
if @@rowcount = 0
	begin
	select @costtypeoption = '0', @selectedcosttypes = null
	end
if @costtypeoption = '0' select @selectedcosttypes = null

if @selectedcosttypes is not null
	begin
	select @selectedcosttypes=replace(@selectedcosttypes,' ','')
	end

if isnull(@begphase,'') <> '' or isnull(@endphase,'') <> '' set @phase_range = 'Y'
if isnull(@begphase,'') = '' set @begphase = ''
if isnull(@endphase,'') = '' set @endphase = 'zzzzzzzzzzzzzzzzzzzz'
if isnull(@orderby,'') not in ('C','P') select @orderby = 'P'
if isnull(@cyclemode,'') not in ('Y','N') select @cyclemode = 'N'

---- validate phase to JCPB
select @description=p.Description, @item_out = p.Item, @phase_out = p.Phase
from JCPB b with (nolock)
join JCJP p with (nolock) on b.Co = p.JCCo and b.Job = p.Job and b.PhaseGroup = p.PhaseGroup and b.Phase = p.Phase 
where b.Co=@jcco and b.Mth=@mth and b.BatchId=@batchid and b.Job=@job and b.PhaseGroup=@phasegroup and b.Phase=@phase
if @@rowcount = 0
	begin
	select @msg='Invalid phase, not in projection batch table.', @rcode = 1
	goto bspexit
	end

---- verify phase is within the phase range
if not exists(select Phase from JCPB with (nolock) where Co=@jcco and Mth=@mth
			and BatchId=@batchid and Job=@job and Phase = @phase
			and Phase >= @begphase and Phase <= @endphase)
	begin
	select @msg='Phase is not within the projection options phase range.', @rcode = 1
	goto bspexit
	end

---- first check if we have a CostType for this phase in JCPB
if not exists(select CostType from JCPB with (nolock) where Co=@jcco and Mth=@mth
				and BatchId=@batchid and Job=@job and PhaseGroup=@phasegroup and Phase=@phase)
	begin
	select @msg='No cost types found for phase in JC projections batch table.', @rcode = 1
	goto bspexit
	end

---- when cycle mode is 'N' all phases then just try to find the first cost type for phase
if @cyclemode <> 'Y'
	begin
	---- get first cost type for phase
	select @costtype=min(CostType)
	from JCPB with (nolock)
	where Co=@jcco and Mth=@mth and BatchId=@batchid and Job=@job and PhaseGroup=@phasegroup and Phase=@phase
	if @@rowcount = 0
		begin
		select @msg='No cost types found for phase in JC projections batch table.', @rcode = 1
		goto bspexit
		end
	end


---- when cycle mode is 'Y' single phase mode then we need to use the projection filter options
---- to find a valid cost type. It is possible that there is no cost type that meets the
---- filter parameters for the phase, which will cause an error
if @cyclemode = 'Y'
	begin
	select @costtype = null
	---- get next cost type
	if @selectedcosttypes is null
		begin
		---- all cost types
		select top 1 @costtype = b.CostType
		from JCPB b with (nolock)
		left join JCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
		left join JCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
		where b.Co=@jcco and b.Mth=@mth and b.BatchId=@batchid
		and b.Job=@job and b.Phase=@phase
		and ((@inactivephases = 'N' and p.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
		and ((@itemunitsonly = 'Y' and h.ItemUnitFlag = 'Y') or (@itemunitsonly = 'N' and h.ItemUnitFlag is not null))
		and ((@phaseunitsonly = 'Y' and h.PhaseUnitFlag = 'Y') or (@phaseunitsonly = 'N' and h.PhaseUnitFlag is not null))
		and (@showlinkedct = 'Y' or (@showlinkedct = 'N' and b.LinkedToCostType is null))
		and (@changedonly = 'N' or (@changedonly = 'Y' and ((isnull(b.ForecastFinalUnits,0) - isnull(b.PrevForecastUnits,0))
					+ (isnull(b.ForecastFinalHrs,0) - isnull(b.PrevForecastHours,0))
					+ (isnull(b.ForecastFinalCost,0) - isnull(b.PrevForecastCost,0)) <> 0)))
		and (@remainunits = 'N' or (@remainunits = 'Y' and @projmethod = '1' and (b.ProjFinalUnits - b.ActualUnits <> 0)))
		and (@remainunits = 'N' or (@remainunits = 'Y' and @projmethod <> '1' and (b.ProjFinalUnits - b.ActualCmtdUnits <> 0)))
		and (@remaincosts = 'N' or (@remaincosts = 'Y' and @projmethod = '1' and (b.ProjFinalCost - b.ActualCost <> 0)))
		and (@remaincosts = 'N' or (@remaincosts = 'Y' and @projmethod <> '1' and (b.ProjFinalCost - b.ActualCmtdCost <> 0)))
		order by b.Co asc, b.Job asc, b.Phase asc, b.CostType asc, b.Item asc, b.BatchSeq asc
		end
	else
		begin
		---- selected cost types only
		select top 1 @costtype = b.CostType
		from JCPB b with (nolock)
		left join JCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
		left join JCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
		where b.Co=@jcco and b.Mth=@mth and b.BatchId=@batchid
		and b.Job=@job and b.Phase=@phase
		and charindex( convert(varchar(3),b.CostType) + ',', @selectedcosttypes) <> 0
		and ((@inactivephases = 'N' and p.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
		and ((@itemunitsonly = 'Y' and h.ItemUnitFlag = 'Y') or (@itemunitsonly = 'N' and h.ItemUnitFlag is not null))
		and ((@phaseunitsonly = 'Y' and h.PhaseUnitFlag = 'Y') or (@phaseunitsonly = 'N' and h.PhaseUnitFlag is not null))
		and (@showlinkedct = 'Y' or (@showlinkedct = 'N' and b.LinkedToCostType is null))
		and (@changedonly = 'N' or (@changedonly = 'Y' and ((isnull(b.ForecastFinalUnits,0) - isnull(b.PrevForecastUnits,0))
					+ (isnull(b.ForecastFinalHrs,0) - isnull(b.PrevForecastHours,0))
					+ (isnull(b.ForecastFinalCost,0) - isnull(b.PrevForecastCost,0)) <> 0)))
		and (@remainunits = 'N' or (@remainunits = 'Y' and @projmethod = '1' and (b.ProjFinalUnits - b.ActualUnits <> 0)))
		and (@remainunits = 'N' or (@remainunits = 'Y' and @projmethod <> '1' and (b.ProjFinalUnits - b.ActualCmtdUnits <> 0)))
		and (@remaincosts = 'N' or (@remaincosts = 'Y' and @projmethod = '1' and (b.ProjFinalCost - b.ActualCost <> 0)))
		and (@remaincosts = 'N' or (@remaincosts = 'Y' and @projmethod <> '1' and (b.ProjFinalCost - b.ActualCmtdCost <> 0)))
		order by b.Co asc, b.Job asc, b.Phase asc, b.CostType asc, b.Item asc, b.BatchSeq asc
		end

	---- if phase is null then no valid JCPB record was found
	if @costtype is null
		begin
		select @msg='No valid cost type record was found that meets the projection options restrictions.', @rcode = 1
		goto bspexit
		end
	end






select @msg = @description



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjPhaseVal] TO [public]
GO
