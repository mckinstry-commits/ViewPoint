SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE  proc [dbo].[bspJCProjItemVal]
/****************************************************************************
* Created By:	GF 04/08/2008 - issue #126993 contract item and cycle mode enhancements
* Modified By:
*
*
* USAGE: Validates a item to bJCPB projection batch table.
* If valid, gets minimum phase found for the item.
*
*
* INPUT PARAMETERS:
* JCCo		JC Company
* Mth		JC Projection Batch Month
* BatchId	JC Projection Batch ID
* Job		JC Job
* Item		JC Contract Item
*
*
* OUTPUT PARAMETERS:
* first phase for item
* first cost type for phase
* 0 = description
* 1 = error message
*****************************************************************************/
(@jcco bCompany, @mth bMonth, @batchid bBatchID, @job bJob, @item bContractItem,
 @username bVPUserName, @phase bPhase output, @costtype bJCCType output,
 @item_out bContractItem output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @description bItemDesc, @bphase bPhase, @bitem bContractItem,
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


---- validate item to JCPB and JCCI
select @item_out=i.Item, @description=i.Description
from JCPB b with (nolock)
join JCJM j with (nolock) on j.JCCo=b.Co and j.Job=b.Job
join JCCI i with (nolock) on i.JCCo=b.Co and i.Contract=j.Contract and i.Item=b.Item 
where b.Co=@jcco and b.Mth=@mth and b.BatchId=@batchid and b.Job=@job and b.Item=@item
if @@rowcount = 0
	begin
	select @msg='Invalid item, not in projection batch table.', @rcode = 1
	goto bspexit
	end


---- first check if we have a phase for this item in JCPB
if not exists(select Phase from JCPB with (nolock) where Co=@jcco and Mth=@mth
				and BatchId=@batchid and Job=@job and Item=@item_out)
	begin
	select @msg='No phase cost type found in JC projections batch for this item.', @rcode = 1
	goto bspexit
	end

---- when cycle mode is 'N' all items then just try to find the first phase cost type for item
if @cyclemode <> 'Y'
	begin
	---- get first phase for item
	select @phase=min(Phase)
	from JCPB with (nolock)
	where Co=@jcco and Mth=@mth and BatchId=@batchid and Job=@job and Item=@item_out
	if @@rowcount = 0
		begin
		select @msg='No phase found for item in projections batch table.', @rcode = 1
		goto bspexit
		end
	---- get first cost type for phase
	select @costtype=min(CostType)
	from JCPB with (nolock)
	where Co=@jcco and Mth=@mth and BatchId=@batchid and Job=@job and Phase=@phase
	if @@rowcount = 0
		begin
		select @msg='No cost types found for phase in projections batch table.', @rcode = 1
		goto bspexit
		end
	end

		
---- when cycle mode is 'Y' single item mode then we need to use the projection filter options
---- to find a valid phase cost type. It is possible that there is no phase cost type that meets the
---- filter parameters for the item, which will cause an error
if @cyclemode = 'Y'
	begin
	select @phase = null, @costtype = null
	---- get next contract item
	if @selectedcosttypes is null
		begin
		---- all cost types
		select top 1 @phase = b.Phase, @costtype = b.CostType
		from JCPB b with (nolock)
		left join JCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
		left join JCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
		where b.Co=@jcco and b.Mth=@mth and b.BatchId=@batchid
		and b.Job=@job and b.Item=@item_out and b.Phase >= @begphase and b.Phase <= @endphase
		and ((@inactivephases = 'N' and p.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
		and ((@itemunitsonly = 'Y' and h.ItemUnitFlag = 'Y') or (@itemunitsonly = 'N' and h.ItemUnitFlag is not null))
		and ((@phaseunitsonly = 'Y' and h.PhaseUnitFlag = 'Y') or (@phaseunitsonly = 'N' and h.PhaseUnitFlag is not null))
		and (@showlinkedct = 'Y' or (@showlinkedct = 'N' and b.LinkedToCostType is null))
		and (@changedonly = 'N' or (@changedonly = 'Y' and ((isnull(b.ForecastFinalUnits,0) - isnull(b.PrevForecastUnits,0))
					+ (isnull(b.ForecastFinalHrs,0) - isnull(b.PrevForecastHours,0))
					+ (isnull(b.ForecastFinalCost,0) - isnull(b.PrevForecastCost,0)) <> 0)))
		----#139200 and (@remainunits = 'N' or (@remainunits = 'Y' and @projmethod = '1' and (b.ProjFinalUnits - b.ActualUnits <> 0)))
		and (@remainunits = 'N' or (@remainunits = 'Y' /*and @projmethod <> '1'*/ and (b.ProjFinalUnits - b.ActualCmtdUnits <> 0)))
		----#139200 and (@remaincosts = 'N' or (@remaincosts = 'Y' and @projmethod = '1' and (b.ProjFinalCost - b.ActualCost <> 0)))
		and (@remaincosts = 'N' or (@remaincosts = 'Y' /*and @projmethod <> '1'*/ and (b.ProjFinalCost - b.ActualCmtdCost <> 0)))
		order by b.Co asc,b.Job asc, b.Item asc, b.Phase asc, b.CostType asc, b.BatchSeq asc
		end
	else
		begin
		---- selected cost types only
		select top 1 @phase = b.Phase, @costtype = b.CostType
		from JCPB b with (nolock)
		left join JCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
		left join JCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
		where b.Co=@jcco and b.Mth=@mth and b.BatchId=@batchid
		and b.Job=@job and b.Item=@item_out and b.Phase >= @begphase and b.Phase <= @endphase
		and charindex( convert(varchar(3),b.CostType) + ',', @selectedcosttypes) <> 0
		and ((@inactivephases = 'N' and p.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
		and ((@itemunitsonly = 'Y' and h.ItemUnitFlag = 'Y') or (@itemunitsonly = 'N' and h.ItemUnitFlag is not null))
		and ((@phaseunitsonly = 'Y' and h.PhaseUnitFlag = 'Y') or (@phaseunitsonly = 'N' and h.PhaseUnitFlag is not null))
		and (@showlinkedct = 'Y' or (@showlinkedct = 'N' and b.LinkedToCostType is null))
		and (@changedonly = 'N' or (@changedonly = 'Y' and ((isnull(b.ForecastFinalUnits,0) - isnull(b.PrevForecastUnits,0))
					+ (isnull(b.ForecastFinalHrs,0) - isnull(b.PrevForecastHours,0))
					+ (isnull(b.ForecastFinalCost,0) - isnull(b.PrevForecastCost,0)) <> 0)))
		----#139200 and (@remainunits = 'N' or (@remainunits = 'Y' and @projmethod = '1' and (b.ProjFinalUnits - b.ActualUnits <> 0)))
		and (@remainunits = 'N' or (@remainunits = 'Y' /*and @projmethod <> '1'*/ and (b.ProjFinalUnits - b.ActualCmtdUnits <> 0)))
		----#139200 and (@remaincosts = 'N' or (@remaincosts = 'Y' and @projmethod = '1' and (b.ProjFinalCost - b.ActualCost <> 0)))
		and (@remaincosts = 'N' or (@remaincosts = 'Y' /*and @projmethod <> '1'*/ and (b.ProjFinalCost - b.ActualCmtdCost <> 0)))
		order by b.Co asc,b.Job asc,b.Item asc, b.Phase asc, b.CostType asc, b.BatchSeq asc
		end

	---- if phase is null then no valid JCPB record was found
	if @phase is null
		begin
		select @msg='No valid phase cost type record was found that meets the projection options restrictions.', @rcode = 1
		goto bspexit
		end
	end



select @msg = @description



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjItemVal] TO [public]
GO
