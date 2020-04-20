SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************/
CREATE  proc [dbo].[bspJCProjPhaseCTCalc]
/****************************************************************************
* Created By:	GF  10/07/2000
* Modified By:	TV - 23061 added isnulls
*				GF 03/03/2004 issue #17898 - use bJCUO for options. Additional user options to use.
*				GF 03/09/2004 issue #17898 - added linked cost type update to initialize
*				DANF 07/01/2006 Recode 6.x
*				GF 09/30/2008 - issue #126236 added IncludedCO to JCPB
*				GF 12/22/2008 - issue #129669 include future addon costs
*				GF 01/19/2009 - issue #137604 use new view to calculate over/under with included co values.
*
*
*
* USAGE:
*  Calculates a single phase and cost type projection and forecast.
*  Called from JCProjections when calculate button selected.
*
* INPUT PARAMETERS:
*	User Name, Company, Job, Phase Group, Phase, Cost Type
*
* OUTPUT PARAMETERS:
*  ProjFinalHours, ProjFinalUnits, ProjFinalCosts,
*  ForecastFinalHours, ForecastFinalUnits, ForecastFinalCosts
*****************************************************************************/
(@username bVPUserName, @co bCompany, @job bJob, @phasegroup tinyint, @phase bPhase,
 @costtype bJCCType, @buyoutyn bYN, @projhours bHrs output, @projunits bUnits output,
 @projcosts bDollar output, @forecasthours bHrs output, @forecastunits bUnits output,
 @forecastcosts bDollar output, @msg varchar(255) output)
as
set nocount on

declare @rcode integer, @minpct decimal(16,5), @cminpct decimal (16,5), @pctcalc float,
		@actualhours bHrs, @actualunits bUnits, @actualcosts bDollar,
		@curresthours bHrs, @currestunits bUnits, @currestcosts bDollar, @remaincmtdunits bUnits,
		@remaincmtdcosts bDollar, @acthours bHrs, @actunits bUnits, @actcosts bDollar,
		@esthours bHrs, @estunits bUnits, @estcosts bDollar, @projmethod char(1),
		@includedcohours bHrs, @includedcounits bUnits, @includedcocosts bDollar, @pmolcount int ----#126236

select @rcode = 0, @projhours = 0, @projunits = 0 , @projcosts = 0, @forecasthours = 0, 
		@forecastunits = 0, @forecastcosts = 0, @projmethod = '1',
		@includedcohours = 0, @includedcounits = 0, @includedcocosts = 0, @pmolcount = 0 ----#126236

-- get user options from bJCUO
select @projmethod=ProjMethod
from JCUO with (nolock) where JCCo=@co and Form='JCProjection' and UserName=@username

---- get needed JC company info
select @cminpct=isnull(ProjMinPct,0) from JCCO with (nolock) where JCCo=@co

---- get minimum percentage
select @minpct=isnull(ProjMinPct,0) from JCJP with (nolock)
where JCCo=@co and Job=@job and PhaseGroup=@phasegroup and Phase=@phase
if @minpct = 0
	begin
	select @minpct=isnull(ProjMinPct,0) from JCJM with (nolock) where JCCo=@co and Job=@job
	if @minpct = 0 select @minpct=@cminpct
	end

---- get values to calculate projections from bJCPB
select @actualhours=isnull(ActualHours,0), @actualunits=isnull(ActualUnits,0),
		@actualcosts=isnull(ActualCost,0), @curresthours=isnull(CurrEstHours,0),
		@currestunits=isnull(CurrEstUnits,0), @currestcosts=isnull(CurrEstCost,0),
		@remaincmtdunits=isnull(RemainCmtdUnits,0), @remaincmtdcosts=isnull(RemainCmtdCost,0)
from JCPB with (nolock) where Co=@co and Job=@job and Phase=@phase and CostType=@costtype
if @@rowcount = 0
	begin
	select @msg='Cannot calculate projection, Phase/CostType not found!', @rcode = 1
	goto bspexit
	end

---- get future change order values #126236
---- only when future change order costs are included
select @pmolcount=Count(*)
from PMOL WITH (NOLOCK) where PMCo=@co and Project=@job and PhaseGroup=@phasegroup and Phase=@phase
and CostType=@costtype and InterfacedDate is null
if @pmolcount > 0
	begin
	---- #137604
	select @includedcohours=isnull(sum(l.EstHours),0),
			----#137604
			@includedcounits=isnull(sum(case when l.UM=h.UM then l.EstUnits else 0 end),0),
			@includedcocosts=isnull(sum(l.EstCost),0)
	from PMOL as l with (nolock)
	join PMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join PMSC s with (nolock) on s.Status=i.Status
	left join PMDT t with (nolock) on t.DocType=i.PCOType
	----#137604
	join bJCCH h with (nolock) on h.JCCo=l.PMCo and h.Job=l.Project and h.PhaseGroup=l.PhaseGroup
	and h.Phase=l.Phase and h.CostType=l.CostType
	where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@phase
	and l.CostType=@costtype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end


---- get any future change order add-on costs. these will
---- come from bPMOB for a PMCo and Project - #129669
if exists(select top 1 1 from bPMOB with (nolock) where PMCo=@co and Project=@job)
	begin
	---- get future change order cost to include
	select @includedcocosts = @includedcocosts + isnull(sum(f.AmtToDistribute),0)
	from bPMOB as f with (nolock)
	join bPMOI i with (nolock) on i.PMCo=f.PMCo and i.Project=f.Project and i.PCOType=f.PCOType
	and i.PCO=f.PCO and i.PCOItem=f.PCOItem
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where f.PMCo=@co and f.Project=@job and f.PhaseGroup=@phasegroup and f.Phase=@phase
	and i.ACOItem is null and f.CostType=@costtype
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end


---- calculate projection and forecast
select @esthours=@curresthours, @estunits=@currestunits, @estcosts=@currestcosts
select @acthours=@actualhours, @actunits=@actualunits, @actcosts=@actualcosts

---- #126236
---- added future change order values to estimate values that are flagged to be included in projection
select @esthours = @esthours + @includedcohours
select @estunits = @estunits + @includedcounits
select @estcosts = @estcosts + @includedcocosts

if @projmethod = '2'
	begin
	select @actunits = @actualunits + @remaincmtdunits, @actcosts = @actualcosts + @remaincmtdcosts
	end

if @estunits <> 0
	begin
	select @pctcalc = @actunits /@estunits
	end
else
	begin
	select @pctcalc = 0
	end

if @pctcalc<@minpct or @pctcalc=0
	begin
	select @projhours = @esthours, @projunits = @estunits, @projcosts = @estcosts
	end

if @pctcalc>0 and @pctcalc>=@minpct and @pctcalc<1
	begin
	select @projhours=@acthours/@pctcalc, @projunits=@actunits/@pctcalc, @projcosts=@actcosts/@pctcalc
	end

if @pctcalc>=1
	begin
	select @projhours = @acthours, @projunits = @actunits, @projcosts = @actcosts
	end

if @projmethod='2' and @buyoutyn='Y'
	begin
	select @projhours = @acthours, @projunits = @actunits, @projcosts = @actcosts
	end

if abs(@projhours) < abs(@acthours) select @projhours = @acthours
if abs(@projunits) < abs(@actunits) select @projunits = @actunits
if abs(@projcosts) < abs(@actcosts) select @projcosts = @actcosts

if @projmethod = '2' and @buyoutyn = 'Y'
	begin
	select @forecasthours=@acthours,
			@forecastunits=@actunits,
			@forecastcosts=@actcosts
	end
else
	begin
	select @forecasthours = @projhours,
			@forecastunits = @projunits,
			@forecastcosts = @projcosts
	end


select @rcode = 0




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjPhaseCTCalc] TO [public]
GO
