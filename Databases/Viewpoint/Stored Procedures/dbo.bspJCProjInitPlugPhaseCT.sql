SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************/
CREATE proc [dbo].[bspJCProjInitPlugPhaseCT]
/****************************************************************************
* Created By:	GF 07/15/2009 - issue #134832
* Modified By:
*
*
*
* USAGE:
* Called from bspJCProjInitialize to insert a plugged phase and cost type
* without doing the initialize calculates so that worksheet detail records
* can be pulled in from JCPR to JCPD for a plugged phase and cost type.
*
*
* INPUT PARAMETERS:
* User Name, Company, Month, BatchId, Job, Phase Group,
* Actual Date, ProjMinPct, Form, Phase, Costtype
* 
*
*****************************************************************************/
(@username bVPUserName, @co bCompany, @mth bMonth, @batchid bBatchID, @job bJob,
 @phasegroup tinyint, @actualdate bDate, @projminpct Decimal(16,5),
 @cphase bPhase, @ccosttype bJCCType, @msg varchar(255) output)
as
set nocount on

declare @rcode integer, @form varchar(30), @cdescription bItemDesc,
		@cabbreviation char(5), @cum bUM, @citemunitflag bYN, @cphaseunitflag bYN, @cprojminpct bPct,
		@ctrackhours bYN, @cplugged char(1), @clastprojdate bDate, @minpct decimal(16,5),
		@pctcalc float, @netchange float, @validcnt int, @inJCPB tinyint, @cbuyoutyn bYN,
		@pmolcount int, @inJCCP tinyint, @opencursor tinyint, @batchseq int,

		@cactualhours bHrs, @cactualunits bUnits, @cactualcosts bDollar, @ccurresthours bHrs,
		@ccurrestunits bUnits, @ccurrestcosts bDollar, @cforecasthours bHrs,
		@cforecastunits bUnits, @cforecastcosts bDollar, @ctotalcmtdunits bUnits,
		@ctotalcmtdcosts bDollar, @cremaincmtdunits bUnits, @cremaincmtdcosts bDollar,
		@cprevprojhours bHrs, @cprevprojunits bUnits, @cprevprojcosts bDollar,
		@cprevforecasthours bHrs, @cprevforecastunits bUnits, @cprevforecastcosts bDollar,
		@cfuturecohours bHrs, @cfuturecounits bUnits, @cfuturecocosts bDollar, @cprojhours bHrs,
		@cprojunits bUnits, @cprojcosts bDollar, @ccurrprojhours bHrs, @ccurrprojunits bUnits,
		@ccurrprojcosts bDollar, @corigesthours bHrs, @corigestunits bUnits, @corigestcosts bDollar,
		@cactualcmtdunits bUnits, @cactualcmtdcosts bDollar, @clinkedtoct bJCCType,

		@acthours bHrs, @actunits bUnits, @actcmtdunits bUnits, @actcosts bDollar, @actcmtdcosts bDollar,
		@esthours bHrs, @estunits bUnits, @estcosts bDollar, @projhours bHrs, @projunits bUnits, 
		@projcosts bDollar, @projfinalhours bHrs, @projfinalunits bUnits, @projfinalcosts bDollar,
		@forecastfinalhours bHrs, @forecastfinalunits bUnits, @forecastfinalcosts bDollar,
		@currprevprojhours bHrs, @currprevprojunits bUnits, @currprevprojcosts bDollar,
		@projuc bUnitCost, @forecastuc bUnitCost, @prevprojuc bUnitCost, @prevforecastuc bUnitCost,
		@uniqueattchid uniqueidentifier,

		@changedonly bYN, @itemunitsonly bYN, @phaseunitsonly bYN, @showlinkedct bYN, @showfutureco bYN, 
		@remainunits bYN, @remainhours bYN, @remaincosts bYN, @phaseoption char(1), 
		@begphase bPhase, @endphase bPhase, @costtypeoption char(1), @ctlist varchar(1000),
		@thrupriormonth bYN, @nolinkedct bYN, @projmethod char(1), @citem bContractItem,
		@phase_range bYN, @inactivephases bYN, @item bContractItem, @cincludeco bDollar,
		@cincludecounits bUnits, @cincludecohours bHrs, @pmobcount int, @jcch_plugged char(1),
		@errmsg varchar(255)

select @rcode=0

if @cphase is null goto bspexit
if @ccosttype is null goto bspexit

set @form = 'JCProjection'
---- get user options from bJCUO
select @changedonly=ChangedOnly, @itemunitsonly=ItemUnitsOnly, @phaseunitsonly=PhaseUnitsOnly,
		@showlinkedct=ShowLinkedCT, @showfutureco=ShowFutureCO, @remainunits=RemainUnits,
		@remainhours=RemainHours, @remaincosts=RemainCosts, @phaseoption=PhaseOption, 
		@begphase=BegPhase, @endphase=EndPhase, @costtypeoption=CostTypeOption, 
		@ctlist=replace(SelectedCostTypes,';',','), @thrupriormonth=ThruPriorMonth,
		@nolinkedct=NoLinkedCT, @projmethod=ProjMethod, @inactivephases=ProjInactivePhases
from bJCUO with (nolock) where JCCo=@co and Form=@form and UserName=@username
if @@rowcount = 0 
	begin
	----select @msg = 'Unable to read user options from JCUO.', @rcode = 1
	goto bspexit
	end

if @costtypeoption = '0' set @ctlist = null

---- check if PMCo exists
if @showfutureco = 'Y'
	begin
	if not exists(select PMCo from bPMCO with (nolock) where PMCo=@co)
	set @showfutureco = 'N'
	end

---- get information from JCJP and JCCH
select @cdescription=p.Description, @cprojminpct=p.ProjMinPct, @cum=h.UM, 
		@citemunitflag=h.ItemUnitFlag, @cphaseunitflag=h.PhaseUnitFlag, @cbuyoutyn=h.BuyOutYN, 
		@clastprojdate=h.LastProjDate, @cplugged=h.Plugged, @cabbreviation=c.Abbreviation,
		@ctrackhours=c.TrackHours, @clinkedtoct=c.LinkProgress, @citem=p.Item
from bJCCH h with (nolock)
join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
join bJCCT c with (nolock) on c.PhaseGroup=h.PhaseGroup and c.CostType=h.CostType
where h.JCCo=@co and h.Job=@job and h.PhaseGroup=@phasegroup and h.Phase=@cphase and h.CostType=@ccosttype
if @@rowcount = 0 goto bspexit

---- check buy out
if @cbuyoutyn <> 'Y' set @cbuyoutyn='N'
set @jcch_plugged = isnull(@cplugged, 'N')
---- set min pct
set @minpct = @cprojminpct
if @minpct = 0 set @minpct = @projminpct

---- reset projected values
select @cprevprojhours=0, @cprevprojunits=0, @cprevprojcosts=0, @cactualhours=0, 
		@cactualunits=0, @cactualcosts=0, @corigesthours=0, @corigestunits=0, @corigestcosts=0, 
		@ccurresthours=0, @ccurrestunits=0, @ccurrestcosts=0, @ctotalcmtdunits=0, 
		@ctotalcmtdcosts=0, @cremaincmtdunits=0, @cremaincmtdcosts=0, @cprevforecasthours=0, 
		@cprevforecastunits=0, @cprevforecastcosts=0, @cprojhours=0, @cprojunits=0, @cprojcosts=0,
		@cactualcmtdunits=0, @cactualcmtdcosts=0, @cfuturecohours=0, @cfuturecounits=0, 
		@cfuturecocosts=0, @cincludeco = 0, @cincludecounits = 0, @cincludecohours = 0

---- get projected values
if @thrupriormonth = 'Y'
	begin
	---- previous month's values
	select @cprevprojhours=isnull(sum(ProjHours),0),
			@cprevprojunits=isnull(sum(ProjUnits),0),
			@cprevprojcosts=isnull(sum(ProjCost),0),
			@cactualhours=isnull(sum(ActualHours),0),
			@cactualunits=isnull(sum(ActualUnits),0),
			@cactualcosts=isnull(sum(ActualCost),0),
			@corigesthours=isnull(sum(OrigEstHours),0),
			@corigestunits=isnull(sum(OrigEstUnits),0),
			@corigestcosts=isnull(sum(OrigEstCost),0),
			@ccurresthours=isnull(sum(CurrEstHours),0),
			@ccurrestunits=isnull(sum(CurrEstUnits),0),
			@ccurrestcosts=isnull(sum(CurrEstCost),0),
			@ctotalcmtdunits=isnull(sum(TotalCmtdUnits),0),
			@ctotalcmtdcosts=isnull(sum(TotalCmtdCost),0),
			@cremaincmtdunits=isnull(sum(RemainCmtdUnits),0),
			@cremaincmtdcosts=isnull(sum(RemainCmtdCost),0),
			@cprevforecasthours=isnull(sum(ForecastHours),0),
			@cprevforecastunits=isnull(sum(ForecastUnits),0),
			@cprevforecastcosts=isnull(sum(ForecastCost),0),
			@cprojhours=isnull(sum(ProjHours),0),
			@cprojunits=isnull(sum(ProjUnits),0),
			@cprojcosts=isnull(sum(ProjCost),0)
	from bJCCP WITH (NOLOCK) where JCCo=@co and Job=@job and PhaseGroup=@phasegroup 
	and Phase=@cphase and CostType=@ccosttype and Mth<@mth

	---- current month values
	select @cactualhours=@cactualhours + isnull(sum(ActualHours),0),
			@cactualunits=@cactualunits + isnull(sum(ActualUnits),0),
			@cactualcosts=@cactualcosts + isnull(sum(ActualCost),0),
			@corigesthours=@corigesthours + isnull(sum(OrigEstHours),0),
			@corigestunits=@corigestunits + isnull(sum(OrigEstUnits),0),
			@corigestcosts=@corigestcosts + isnull(sum(OrigEstCost),0),
			@ccurresthours=@ccurresthours + isnull(sum(CurrEstHours),0),
			@ccurrestunits=@ccurrestunits + isnull(sum(CurrEstUnits),0),
			@ccurrestcosts=@ccurrestcosts + isnull(sum(CurrEstCost),0),
			@ctotalcmtdunits=@ctotalcmtdunits + isnull(sum(TotalCmtdUnits),0),
			@ctotalcmtdcosts=@ctotalcmtdcosts + isnull(sum(TotalCmtdCost),0),
			@cremaincmtdunits=@cremaincmtdunits + isnull(sum(RemainCmtdUnits),0),
			@cremaincmtdcosts=@cremaincmtdcosts + isnull(sum(RemainCmtdCost),0),
			@cprevforecasthours=@cprevforecasthours + isnull(sum(ForecastHours),0),
			@cprevforecastunits=@cprevforecastunits + isnull(sum(ForecastUnits),0),
			@cprevforecastcosts=@cprevforecastcosts + isnull(sum(ForecastCost),0),
			@cprojhours=@cprojhours + isnull(sum(ProjHours),0),
			@cprojunits=@cprojunits + isnull(sum(ProjUnits),0),
			@cprojcosts=@cprojcosts + isnull(sum(ProjCost),0)
	from bJCCP WITH (NOLOCK) where JCCo=@co and Job=@job and PhaseGroup=@phasegroup 
	and Phase=@cphase and CostType=@ccosttype and Mth=@mth
	end
else
	begin
	select @cprevprojhours=isnull(sum(ProjHours),0),
			@cprevprojunits=isnull(sum(ProjUnits),0),
			@cprevprojcosts=isnull(sum(ProjCost),0),
			@cactualhours=isnull(sum(ActualHours),0),
			@cactualunits=isnull(sum(ActualUnits),0),
			@cactualcosts=isnull(sum(ActualCost),0),
			@corigesthours=isnull(sum(OrigEstHours),0),
			@corigestunits=isnull(sum(OrigEstUnits),0),
			@corigestcosts=isnull(sum(OrigEstCost),0),
			@ccurresthours=isnull(sum(CurrEstHours),0),
			@ccurrestunits=isnull(sum(CurrEstUnits),0),
			@ccurrestcosts=isnull(sum(CurrEstCost),0),
			@ctotalcmtdunits=isnull(sum(TotalCmtdUnits),0),
			@ctotalcmtdcosts=isnull(sum(TotalCmtdCost),0),
			@cremaincmtdunits=isnull(sum(RemainCmtdUnits),0),
			@cremaincmtdcosts=isnull(sum(RemainCmtdCost),0),
			@cprevforecasthours=isnull(sum(ForecastHours),0),
			@cprevforecastunits=isnull(sum(ForecastUnits),0),
			@cprevforecastcosts=isnull(sum(ForecastCost),0),
			@cprojhours=isnull(sum(ProjHours),0),
			@cprojunits=isnull(sum(ProjUnits),0),
			@cprojcosts=isnull(sum(ProjCost),0)
	from bJCCP WITH (NOLOCK) where JCCo=@co and Job=@job and PhaseGroup=@phasegroup 
	and Phase=@cphase and CostType=@ccosttype and Mth<=@mth
	end

---- get future change order values
---- only when future change order costs are requested
---- per issue #127212 always get PM future change orders
select @pmolcount=Count(*)
from bPMOL WITH (NOLOCK) where PMCo=@co and Project=@job and PhaseGroup=@phasegroup and Phase=@cphase
and CostType=@ccosttype and InterfacedDate is null
if @pmolcount > 0
	begin
	select @cfuturecohours=isnull(sum(l.EstHours),0),
			@cfuturecounits=isnull(sum(l.EstUnits),0),
			@cfuturecocosts=isnull(sum(l.EstCost),0)
	from bPMOL as l with (nolock)
	join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@cphase
	and l.CostType=@ccosttype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') in ('Y','C') and isnull(t.IncludeInProj,'Y')='Y'

	---- get future change order calculated value
	select @cincludecounits=isnull(sum(l.EstUnits),0),
			@cincludecohours=isnull(sum(l.EstHours),0),
			@cincludeco=isnull(sum(l.EstCost),0)
	from bPMOL as l with (nolock)
	join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@cphase
	and l.CostType=@ccosttype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end

---- get any future change order add-on costs. these will
---- come from bPMOB for a PMCo and Project - #129669
if exists(select top 1 1 from bPMOB with (nolock) where PMCo=@co and Project=@job)
	begin
	---- get future change order cost for display
	select @cfuturecocosts = @cfuturecocosts + isnull(sum(f.AmtToDistribute),0)
	from bPMOB as f with (nolock)
	join bPMOI i with (nolock) on i.PMCo=f.PMCo and i.Project=f.Project and i.PCOType=f.PCOType
	and i.PCO=f.PCO and i.PCOItem=f.PCOItem
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where f.PMCo=@co and f.Project=@job and f.PhaseGroup=@phasegroup and f.Phase=@cphase
	and i.ACOItem is null and f.CostType=@ccosttype
	and isnull(s.IncludeInProj,'N') in ('Y','C') and isnull(t.IncludeInProj,'Y')='Y'

	---- get future change order cost to include
	select @cincludeco = @cincludeco + isnull(sum(f.AmtToDistribute),0)
	from bPMOB as f with (nolock)
	join bPMOI i with (nolock) on i.PMCo=f.PMCo and i.Project=f.Project and i.PCOType=f.PCOType
	and i.PCO=f.PCO and i.PCOItem=f.PCOItem
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where f.PMCo=@co and f.Project=@job and f.PhaseGroup=@phasegroup and f.Phase=@cphase
	and i.ACOItem is null and f.CostType=@ccosttype
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end

---- accumulate future values if any
select @esthours = @ccurresthours, @estunits = @ccurrestunits, @estcosts = @ccurrestcosts
select @acthours = @cactualhours, @actunits = @cactualunits, @actcosts = @cactualcosts
select @actcmtdunits = @cactualunits+@cremaincmtdunits, @actcmtdcosts = @cactualcosts+@cremaincmtdcosts

if @estunits <> 0
	begin
	select @pctcalc = @actunits /@estunits
	end
else
	begin
	set @pctcalc = 0
	end

if @pctcalc<@minpct or @pctcalc=0
	begin
	select @projhours = @esthours, @projunits = @estunits, @projcosts = @estcosts
	end

if @pctcalc > 0 and @pctcalc >= @minpct and @pctcalc < 1
	begin
	if @projmethod = '2'
		begin
		set @projhours = @acthours/@pctcalc
		set @projunits = @actcmtdunits/@pctcalc
		if abs(@actcmtdcosts/@pctcalc) < 9999999999 
			begin
			set @projcosts = @actcmtdcosts/@pctcalc
			end
		end
	else
		begin
		set @projhours = @acthours/@pctcalc
		set @projunits = @actunits/@pctcalc
		if abs(@actcosts/@pctcalc) < 9999999999 
			begin
			set @projcosts = @actcosts/@pctcalc
			end
		end
	end

if @pctcalc >= 1
	begin
	if @projmethod = '2'
		begin
		select @projhours = @acthours, @projunits = @actcmtdunits, @projcosts = @actcmtdcosts
		end
	else
		begin
		select @projhours = @acthours, @projunits = @actunits, @projcosts = @actcosts
		end
	end

if @projmethod = '2' and @cbuyoutyn = 'Y'
	begin
	select @projhours = @acthours, @projunits = @actcmtdunits, @projcosts = @actcmtdcosts
	end

if @projmethod = '2'
	begin
	if abs(@projhours) < abs(@acthours) select @projhours=@acthours
	if abs(@projunits) < abs(@actcmtdunits) select @projunits=@actcmtdunits
	if abs(@projcosts) < abs(@actcmtdcosts) select @projcosts=@actcmtdcosts
	end
else
	begin
	if abs(@projhours) < abs(@acthours) select @projhours=@acthours
	if abs(@projunits) < abs(@actunits) select @projunits=@actunits
	if abs(@projcosts) < abs(@actcosts) select @projcosts=@actcosts
	end

select @projfinalhours = @projhours - @cprevprojhours,
		@projfinalunits = @projunits - @cprevprojunits,
		@projfinalcosts = @projcosts - @cprevprojcosts

if @projmethod = '2' and @cbuyoutyn = 'Y'
	begin
	select @forecastfinalhours = @acthours, @forecastfinalunits = @actcmtdunits, @forecastfinalcosts = @actcmtdcosts
	end
else
	begin
	select @forecastfinalhours = @projfinalhours + @cprevprojhours,
			@forecastfinalunits = @projfinalunits + @cprevprojunits,
			@forecastfinalcosts = @projfinalcosts + @cprevprojcosts
	end

select @cactualhours=@acthours, @cactualunits=@actunits, @cactualcosts=@actcosts,
		@cactualcmtdunits=@actcmtdunits, @cactualcmtdcosts=@actcmtdcosts,
		@cforecasthours=isnull(@forecastfinalhours,0), @cforecastunits=isnull(@forecastfinalunits,0),
		@cforecastcosts=isnull(@forecastfinalcosts,0), @netchange=0

select @netchange = abs(@projfinalhours) + abs(@projfinalunits) + abs(@projfinalcosts)

---- check if phase and costtype already in batch
select @cprojunits=isnull(ProjFinalUnits,0), @ccurrprojunits=isnull(ProjFinalUnits,0),
		@cprojhours=isnull(ProjFinalHrs,0), @ccurrprojhours=isnull(ProjFinalHrs,0),
		@cprojcosts=isnull(ProjFinalCost,0), @ccurrprojcosts=isnull(ProjFinalCost,0),
		@cplugged=isnull(Plugged,'N'), @uniqueattchid=UniqueAttchID
from bJCPB WITH (NOLOCK) where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job
and PhaseGroup=@phasegroup and Phase=@cphase and CostType=@ccosttype
if @@rowcount <> 0
	begin
	set @inJCPB=1
	if @changedonly = 'Y' and @netchange = 0
		begin
		update bJCPB set Item=@citem
		where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job
		and PhaseGroup=@phasegroup and Phase=@cphase and CostType=@ccosttype 
		goto bspexit
		end
	goto insert_JCPB
	end
else
	begin
	select @inJCPB=0, @ccurrprojunits=0, @ccurrprojhours=0, @ccurrprojcosts=0, @uniqueattchid = null
	end

if @changedonly='Y' and @netchange=0
	begin
	update bJCPB set Item=@citem
	where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job
	and PhaseGroup=@phasegroup and Phase=@cphase and CostType=@ccosttype 
	goto bspexit
	end

select @ccurrprojhours=@cprevprojhours, @ccurrprojunits=@cprevprojunits, @ccurrprojcosts=@cprevprojcosts

---- #133425
if @cprojhours<>0 or @cprojunits<>0 or @cprojcosts<>0 or @cplugged = 'Y'
	begin
	select @ccurrprojhours=@cprojhours,@ccurrprojunits=@cprojunits,@ccurrprojcosts=@cprojcosts
	end
else
	begin
	select @cprojhours=@ccurrprojhours,@cprojunits=@ccurrprojunits,@cprojcosts=@ccurrprojcosts
	end


insert_JCPB:
---- calculate unit costs
select @prevprojuc = case when @cprevprojunits <> 0 then (@cprevprojcosts/@cprevprojunits) else 0 end
select @prevforecastuc = case when @cprevforecastunits <> 0 then (@cprevforecastcosts/@cprevforecastunits) else 0 end
select @projuc = case when @cprojunits <> 0 then (@cprojcosts/@cprojunits) else 0 end
select @forecastuc = case when @cforecastunits <> 0 then (@cforecastcosts/@cforecastunits) else 0 end

-- update projections batch
if @inJCPB = 0
	begin
	insert bJCPB(Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType, 
		ActualDate, ActualHours, ActualUnits, ActualCost, 
		CurrEstHours, CurrEstUnits, CurrEstCost, 
		ProjFinalUnits, ProjFinalHrs, ProjFinalCost, ProjFinalUnitCost, 
		ForecastFinalUnits, ForecastFinalHrs, ForecastFinalCost, ForecastFinalUnitCost, 
		RemainCmtdUnits, RemainCmtdCost, TotalCmtdUnits, TotalCmtdCost, 
		PrevProjUnits, PrevProjHours, PrevProjCost, PrevProjUnitCost, 
		PrevForecastUnits, PrevForecastHours, PrevForecastCost, PrevForecastUnitCost, 
		FutureCOHours, FutureCOUnits, FutureCOCost, CurrProjHours, CurrProjUnits, CurrProjCost, 
		OrigEstHours, OrigEstUnits, OrigEstCost, ActualCmtdUnits, ActualCmtdCost, 
		LinkedToCostType, Plugged, UniqueAttchID, Item, IncludedCOs, IncludedUnits, IncludedHours,
		OldPlugged)
	select @co, @mth, @batchid, isnull(max(a.BatchSeq),0) + 1, /*@batchseq,*/ @job, @phasegroup, @cphase, @ccosttype, 
		@actualdate, isnull(@cactualhours,0), isnull(@cactualunits,0), isnull(@cactualcosts,0),  
		isnull(@ccurresthours,0), isnull(@ccurrestunits,0), isnull(@ccurrestcosts,0), 
		@cprojunits, @cprojhours, @cprojcosts, @projuc, 
		@cforecastunits, @cforecasthours, @cforecastcosts, @forecastuc, 
		isnull(@cremaincmtdunits,0), isnull(@cremaincmtdcosts,0),
		isnull(@ctotalcmtdunits,0), isnull(@ctotalcmtdcosts,0),  
		@cprevprojunits, @cprevprojhours, @cprevprojcosts, @prevprojuc, 
		@cprevforecastunits, @cprevforecasthours, @cprevforecastcosts, @prevforecastuc, 
		isnull(@cfuturecohours,0), isnull(@cfuturecounits,0), isnull(@cfuturecocosts,0), 
		isnull(@cprojhours,0), isnull(@cprojunits,0), isnull(@cprojcosts,0), 
		isnull(@corigesthours,0), isnull(@corigestunits,0), isnull(@corigestcosts,0),
		isnull(@cactualcmtdunits,0), isnull(@cactualcmtdcosts,0), 
		@clinkedtoct, @cplugged,  @uniqueattchid, @citem, isnull(@cincludeco,0),
		isnull(@cincludecounits,0), isnull(@cincludecohours,0), isnull(@jcch_plugged,'N')
		from bJCPB a where a.Co=@co and a.Mth=@mth and a.BatchId=@batchid
	end
else
	begin
	update bJCPB set ActualHours = isnull(@cactualhours,0), ActualUnits = isnull(@cactualunits,0), 
		ActualCost = isnull(@cactualcosts,0), CurrEstHours = isnull(@ccurresthours,0),
		CurrEstUnits = isnull(@ccurrestunits,0), CurrEstCost = isnull(@ccurrestcosts,0), 
		RemainCmtdUnits = isnull(@cremaincmtdunits,0), RemainCmtdCost = isnull(@cremaincmtdcosts,0),
		TotalCmtdUnits = isnull(@ctotalcmtdunits,0), TotalCmtdCost = isnull(@ctotalcmtdcosts,0), 
		PrevProjUnits = @cprevprojunits, PrevProjHours = @cprevprojhours, PrevProjCost = @cprevprojcosts,
		PrevProjUnitCost = @prevprojuc, PrevForecastUnits = @cprevforecastunits,
		PrevForecastHours = @cprevforecasthours, PrevForecastCost = @cprevforecastcosts,
		PrevForecastUnitCost = @prevforecastuc, FutureCOHours = isnull(@cfuturecohours,0),
		FutureCOUnits = isnull(@cfuturecounits,0), FutureCOCost = isnull(@cfuturecocosts,0), 
		CurrProjHours = isnull(@cprojhours,0), CurrProjUnits = isnull(@cprojunits,0),
		CurrProjCost = isnull(@cprojcosts,0), OrigEstHours = isnull(@corigesthours,0),
		OrigEstUnits = isnull(@corigestunits,0), OrigEstCost = isnull(@corigestcosts,0), 
		ActualCmtdUnits = isnull(@cactualcmtdunits,0),ActualCmtdCost = isnull(@cactualcmtdcosts,0), 
		ProjFinalUnits=@cprojunits, ProjFinalHrs=@cprojhours,
		ProjFinalCost=@cprojcosts, ProjFinalUnitCost=@projuc, ForecastFinalUnits=@cforecastunits,
		ForecastFinalHrs=@cforecasthours, ForecastFinalCost=@cforecastcosts,
		ForecastFinalUnitCost=@forecastuc, Plugged=@cplugged, UniqueAttchID=@uniqueattchid,
		Item=@citem, IncludedCOs = isnull(@cincludeco,0), IncludedUnits = isnull(@cincludecounits,0),
		IncludedHours = isnull(@cincludecohours,0)
	where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job and PhaseGroup=@phasegroup
	and Phase=@cphase and CostType=@ccosttype
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjInitPlugPhaseCT] TO [public]
GO
