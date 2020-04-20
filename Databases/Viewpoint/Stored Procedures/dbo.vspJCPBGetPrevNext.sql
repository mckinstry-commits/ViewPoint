SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE proc [dbo].[vspJCPBGetPrevNext]
/****************************************************************************
 * Created By:	GF 03/28/2008
 * Modified By:	GF 04/27/2010 - issue #139200 remaining cost filter option not working.
 *
 *
 *
 * USAGE:
 * Called when previous/next button clicked in JC Projections for a phase or item.
 * Will return the next seq, item, and phase to be used in JC Projections to move
 * current record
 *
 * INPUT PARAMETERS:
 * JC Company, Mth, BatchId, BatchSeq, OrderBy, CycleMode, PrevNext Flag
 *
 * OUTPUT PARAMETERS:
 * Next Sequence, Item, Phase 
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @batchseq int = null,
 @orderby char(1) = 'P', @cyclemode bYN = 'N', @prevnext char(1) = 'N', @username bVPUserName=null,
 @seq int = null output, @item bContractItem = null output, @phase bPhase = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @job bJob, @phasegroup bGroup, @bphase bPhase, @bitem bContractItem,
		@costtypeoption char(1), @selectedcosttypes varchar(1000), @changedonly bYN,
		@itemunitsonly bYN, @phaseunitsonly bYN, @showlinkedct bYN, @showfutureco bYN, 
		@remainunits bYN, @remainhours bYN, @remaincosts bYN, @phaseoption char(1), 
		@begphase bPhase, @endphase bPhase, @thrupriormonth bYN, @nolinkedct bYN,
		@projmethod char(1), @citem bContractItem, @phase_range bYN, @inactivephases bYN
		
select @rcode = 0, @msg = ''

---- check input parameters
if @co is null or @mth is null or @batchid is null or @batchseq is null
	begin
	goto bspexit
	end

if isnull(@orderby,'') not in ('C','P') select @orderby = 'P'
if isnull(@cyclemode,'') not in ('Y','N') select @cyclemode = 'N'
if isnull(@prevnext,'') not in ('P','N') select @prevnext = 'N'

---- get cost type option from JCUO
select @changedonly=ChangedOnly, @itemunitsonly=ItemUnitsOnly, @phaseunitsonly=PhaseUnitsOnly,
		@showlinkedct=ShowLinkedCT, @showfutureco=ShowFutureCO, @remainunits=RemainUnits,
		@remainhours=RemainHours, @remaincosts=RemainCosts, @phaseoption=PhaseOption, 
		@begphase=BegPhase, @endphase=EndPhase, @thrupriormonth=ThruPriorMonth,
		@nolinkedct=NoLinkedCT, @projmethod=ProjMethod, @inactivephases=ProjInactivePhases,
		@costtypeoption=CostTypeOption, @selectedcosttypes=replace(SelectedCostTypes,';',',')
from bJCUO with (nolock) where JCCo=@co and Form='JCProjection' and UserName=@username
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

---- get JCPB info for batch sequence
select @job=Job, @phasegroup=PhaseGroup, @bphase=Phase, @bitem=Item
from bJCPB with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
if @@rowcount = 0 goto bspexit


---- 'C' contract item order
if @orderby = 'C'
	begin
	if @prevnext = 'N'
		begin
		---- get next contract item
		if @selectedcosttypes is null
			begin
			---- all cost types
			select top 1 @seq = b.BatchSeq, @item = b.Item, @phase = b.Phase
			from bJCPB b with (nolock)
			left join bJCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
			left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
			where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq<>@batchseq
			and b.Job=@job and b.Item>@bitem and b.Phase >= @begphase and b.Phase <= @endphase
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
		else
			begin
			---- selected cost types only
			select top 1 @seq = b.BatchSeq, @item = b.Item, @phase = b.Phase
			from bJCPB b with (nolock)
			left join bJCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
			left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
			where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq<>@batchseq
			and b.Job=@job and b.Item>@bitem and b.Phase >= @begphase and b.Phase <= @endphase
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
		end
	else
		begin
		---- get previous contract item
		if @selectedcosttypes is null
			begin
			select top 1 @seq = b.BatchSeq, @item = b.Item, @phase = b.Phase
			from bJCPB b with (nolock)
			left join bJCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
			left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
			where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq<>@batchseq
			and b.Job=@job and b.Item<@bitem and b.Phase >= @begphase and b.Phase <= @endphase
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
			order by b.Co desc, b.Job desc, b.Item desc, b.Phase desc, b.CostType desc, b.BatchSeq desc
			end
		else
			begin
			select top 1 @seq = b.BatchSeq, @item = b.Item, @phase = b.Phase
			from bJCPB b with (nolock)
			left join bJCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
			left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
			where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq<>@batchseq
			and b.Job=@job and b.Item<@bitem and b.Phase >= @begphase and b.Phase <= @endphase
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
			order by b.Co desc, b.Job desc, b.Item desc, b.Phase desc, b.CostType desc, b.BatchSeq desc
			end
		end
	end


---- 'P' phase order
if @orderby = 'P'
	begin
	if @prevnext = 'N'
		begin
		---- get next phase
		if @selectedcosttypes is null
			begin
			---- all cost types
			select top 1 @seq = b.BatchSeq, @item = b.Item, @phase = b.Phase
			from bJCPB b with (nolock)
			left join bJCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
			left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
			where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq<>@batchseq
			and b.Job=@job and b.Phase>@bphase and b.Phase >= @begphase and b.Phase <= @endphase
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
			order by b.Co asc, b.Job asc, b.Phase asc, b.CostType asc, b.Item asc, b.BatchSeq asc
			end
		else
			begin
			---- selected cost types only
			select top 1 @seq = b.BatchSeq, @item = b.Item, @phase = b.Phase
			from bJCPB b with (nolock)
			left join bJCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
			left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
			where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq<>@batchseq
			and b.Job=@job and b.Phase>@bphase and b.Phase >= @begphase and b.Phase <= @endphase
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
			order by b.Co asc, b.Job asc, b.Phase asc, b.CostType asc, b.Item asc, b.BatchSeq asc
			end
		end
	else
		begin
		---- get previous phase
		if @selectedcosttypes is null
			begin
			select top 1 @seq = b.BatchSeq, @item = b.Item, @phase = b.Phase
			from bJCPB b with (nolock)
			left join bJCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
			left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
			where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq<>@batchseq
			and b.Job=@job and b.Phase<@bphase and b.Phase >= @begphase and b.Phase <= @endphase
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
			order by b.Co desc, b.Job desc, b.Phase desc, b.CostType desc, b.Item desc, b.BatchSeq desc
			end
		else
			begin
			---- selected cost types only
			select top 1 @seq = b.BatchSeq, @item = b.Item, @phase = b.Phase
			from bJCPB b with (nolock)
			left join bJCCH h with (nolock) on h.JCCo=b.Co and h.Job=b.Job and h.PhaseGroup=b.PhaseGroup and h.Phase=b.Phase and h.CostType=b.CostType
			left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
			where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq<>@batchseq
			and b.Job=@job and b.Phase<@bphase and b.Phase >= @begphase and b.Phase <= @endphase
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
			order by b.Co desc, b.Job desc, b.Phase desc, b.CostType desc, b.Item desc, b.BatchSeq desc
			end
		end
	end



bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPBGetPrevNext] TO [public]
GO
