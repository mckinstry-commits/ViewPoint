SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************/
CREATE proc [dbo].[bspJCProjInitialize]
/****************************************************************************
* Created By: 	GF 02/11/1999
* Modified By:  GF 07/14/2000
*               GF 10/04/2000 ISSUE #10410 and #10738
*               GF 05/29/2001 Issue #13542 - fix for actual vs plugged
*				GF 02/12/2003 issue #20386 - ignore check of JCPP when pulling in jobs to initialize.
*				GF 03/03/2004 issue #17898 - use bJCUO for options. Additional user options to use.
*				GF 03/09/2004 issue #17898 - added linked cost type update to initialize
*				TV - 23061 added isnulls
*				GF - #24386 need to use different calc when no actual values for linked cost types
*				GF - #24344 sometimes after doing linked not going to next temp table record.
*				GF - #26519 check for HQCC record, add if none exists.
*				GF - issue #26527 use @pctcmplunits for @pctcmplcosts when 0 and units <> 0
*				GF - issue #26764 use the estimate values for linked if used for main cost type (min pct)
*				GF - issue #27183 use JCUO.ProjInactivePhases in query
*				GF - issue #28432 arithematic overflow @pctcalc >99.99 set to 99.99
*				GF 12/14/2005 - issue #119650 only update plugged linked CT when main CT changes.
*				DANF 07/01/06 - 6.x Recode
*				GF - issue #127060 changed the pct data types from bPct to float so that we will not have rounding for linked cost types
*				GF 02/14/2008 - issue #25569 use separate post closed job flags in JCCO
*				GF 03/05/2008 - issue #124377 added a writeoverplug option 3 when actual costs exceed plugged but keep as plugged.
*				GF 03/23/2008 - issue #126993 added Item to JCPB
*				GF 04/06/2008 - issue #127700 changed parse value for selected cost types to comma
*				CHS	10/02/2008	- issue #126236
*				GF 10/27/2008 - issue #130732 linked plugged updated when should not
*				GF 11/04/2008 - issue #130732 changed insert statement for temp table to get PM phase/cost types not interfaced.
*				GF 12/22/2008 - issue #129669 include future addon costs
*				GF 01/19/2009 - issue #131828 allow job in multiple open batches in a month
*				GF 03/15/2009 - issue #132731 need to check if the linked estimate values are less than actual and use actual values if true
*				CHS 04/17/2009 - issue #129898 - projection worksheet detail
*				GF 05/15/2009 - issue #133491 skip if linked cost type is bought out
*				GF 07/15/2009 - issue #134832 problem with worksheet detail not being added to batch for plugged phase cost types.
*				GF 12/22/2009 - issue #135527 job roles to use as filter
*				GF 01/19/2009 - issue #137604 use new view to calculate over/under with included co values.
*				GF 06/16/2010 - issue #140202 multiple roles for user
*
*
*
* USAGE:
* 	Initializes Projections for all jobs, specified range of jobs or by Project Mgr
*	and selected cost types. Then adds any that are different from previous to
*	the batch table JCPB. Deletes all future projections for any job/phase/ct combo.
*	Restricts to open jobs and active phase cost types.
*
* INPUT PARAMETERS:
*	Company, Beginning Job, Ending Job, Project Manager, PhaseGroup,
*	Actual Date, writeover plugs, Month, BatchId
*
* OUTPUT PARAMETERS:
*	None
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@jcco bCompany, @bjob bJob, @ejob bJob, @projectmgr int, @phasegroup tinyint, 
 @actualdate datetime, @writeoverplug tinyint, @mth bMonth, @batchid bBatchID, 
 @username bVPUserName=null, @detailinit tinyint = null, @msg varchar(255) output)
as
set nocount on

declare @rcode integer, @retcode int, @cco tinyint, @cjob varchar(10), @cphasegroup tinyint, @cphase varchar(20),
		@cactualhours decimal(16,5), @cactualunits decimal(16,5), @cactualcosts decimal(16,5),
		@ccurresthours decimal(16,5), @ccurrestunits decimal(16,5), @ccurrestcosts decimal(16,5),
		@cprojhours decimal(16,5), @cprojunits decimal(16,5), @cprojcosts decimal(16,5),
		@cremaincmtdunits decimal(16,5), @cremaincmtdcosts decimal(16,5), @cplugged char(1),
		@ccosttype tinyint, @acthours bHrs, @actunits bUnits, @actcosts bDollar, @esthours bHrs,
		@estunits bUnits, @estcosts bDollar, @pctcalc float, @projhours bHrs, @projunits bUnits,
		@projcosts bDollar, @prevprojuc bUnitCost, @prevforecastuc bUnitCost, @prevprojhours bHrs,
		@prevprojunits bUnits, @prevprojcosts bDollar, @prevforecasthours bHrs,
		@prevforecastunits bUnits, @prevforecastcosts bDollar, @projfinalhours bHrs,
		@projfinalunits bUnits, @projfinalcosts bDollar, @initcount int,
		@forecastfinalhours bHrs, @forecastfinalunits bUnits, @forecastfinalcosts bDollar, 
		@forecastfinaluc bUnitCost, @forefinalhours bHrs, @forefinalunits bUnits, @forefinalcosts bDollar,
		@opencursor tinyint, @cminpct decimal(16,5), @minpct decimal(16,5),
		@projmethod char(1), @buyoutyn bYN, @ovrprojhrs bHrs, @ovrprojunits bUnits, @ovrprojcost bDollar,
		@ovrprojuc bUnitCost, @selectedcosttypes varchar(1000), @thrupriormonth bYN,
		@costtypeoption char(1), @batchseq int, @totalcmtdunits decimal(16,5),
		@totalcmtdcosts decimal(16,5), @includedcohours bHrs, @includedcounits bUnits,
		@includedcocosts bDollar, @pmolcount int ----#126236

declare @opencursor_jcct tinyint, @linkcosttype bJCCType, @linkactive bYN, @pctcalcunits float, 
		@pctcalchours float, @pctcalccosts float, @actualunits bUnits,
		@actualcmtdunits bUnits, @actualhours bHrs, @actualcmtdcosts bDollar, @actualcosts bDollar,
		@origesthours bHrs, @origestunits bUnits, @origestcosts bDollar, @curresthours bHrs,
		@currestunits bUnits, @currestcosts bDollar, @remaincmtdunits bUnits, @remaincmtdcosts bDollar,
		@forecasthours bHrs, @forecastunits bUnits, @forecastcosts bDollar, @projuc bUnitCost,
		@forecastuc bUnitCost, @linkpct float, @linkplugged bYN, @noactunits bYN,
		@noacthours bYN, @noactcosts bYN, @use_estimate bYN, @inactivephases bYN,
		@item bContractItem, @projjobinmultibatch bYN, @jcch_plugged char(1),
		@errmsg varchar(255), @cbuyoutyn bYN, @UserRole varchar(max) ----#135527

select @rcode=0, @prevprojhours=0, @prevprojunits=0, @prevprojcosts=0, @prevprojuc=0,
		@prevforecasthours=0, @prevforecastunits=0, @prevforecastcosts=0, @prevforecastuc=0,
		@projfinalhours=0, @projfinalunits=0, @projfinalcosts=0, @forefinalhours=0, 
		@forefinalunits=0, @forefinalcosts=0, @pctcalc=0, @esthours=0, @estunits=0, 
		@estcosts=0, @acthours=0, @actunits=0, @actcosts=0, @projhours=0, @projunits=0,
		@projcosts=0, @ovrprojhrs=0, @ovrprojunits=0, @ovrprojcost=0, @ovrprojuc=0,
		@opencursor = 0, @opencursor_jcct = 0, @includedcohours = 0, @includedcounits = 0,
		@includedcocosts = 0, @pmolcount = 0


---- validate company
select @cminpct=isnull(ProjMinPct,0), @projjobinmultibatch=isnull(ProjJobInMultiBatch,'N')
from JCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0
	begin
	select @msg = 'Company not set up in JC Company file!', @rcode = 1
	goto bspexit
	end

---- validate group
if (select count(*) from HQGP with (nolock) where Grp=@phasegroup)<>1
	begin
	select @msg = 'Phase group not in HQGP!', @rcode = 1
	goto bspexit
	end

if @projectmgr is null
	begin
	select @projectmgr = 0
	end

if @username is null
	begin
	select @msg = 'User Name is invalid!', @rcode=1
	goto bspexit
	end

if isnull(@detailinit,0) not in (1,2,3)
	begin
	set @detailinit = 1
	end

---- get user options from JCUO
select @projmethod=ProjMethod, @thrupriormonth=ThruPriorMonth, @costtypeoption=CostTypeOption, 
		@selectedcosttypes=replace(SelectedCostTypes,';',','), @inactivephases=ProjInactivePhases
from bJCUO with (nolock) where JCCo=@jcco and Form='JCProjection' and UserName=@username
if @@rowcount = 0
	begin
	select @projmethod = '1', @thrupriormonth = 'N', @costtypeoption = '0',
			@selectedcosttypes = null, @inactivephases = 'N'
	end

---- cost type option
if @costtypeoption = '0' set @selectedcosttypes = null
if @selectedcosttypes is not null
	begin
	select @selectedcosttypes=replace(@selectedcosttypes,' ','')
	end


---- create temp table
CREATE TABLE #tmpProjInit(
	Co              tinyint         NOT NULL,
	Job             varchar(10)     NOT NULL,
	PhaseGroup  	tinyint         NOT NULL,
	Phase           varchar(20)     NOT NULL,
	CostType        tinyint    		NOT NULL,
	ActualHours		decimal(16,5)	NOT NULL,
	ActualUnits		decimal(16,5)   NOT NULL,
	ActualCosts		decimal(16,5)   NOT NULL,
	CurrEstHours	decimal(16,5)   NOT NULL,
	CurrEstUnits	decimal(16,5)   NOT NULL,
	CurrEstCosts	decimal(16,5)   NOT NULL,
	ProjHours		decimal(16,5)   NOT NULL,
	ProjUnits		decimal(16,5)   NOT NULL,
	ProjCosts		decimal(16,5)   NOT NULL,
	ForecastHours	decimal(16,5)   NOT NULL,
	ForecastUnits	decimal(16,5)   NOT NULL,
	ForecastCosts	decimal(16,5)   NOT NULL,
	RemainCmtdUnits	decimal(16,5)   NOT NULL,
	RemainCmtdCosts	decimal(16,5)   NOT NULL,
	Plugged         char(1)         NOT NULL,
	TotalCmtdUnits	decimal(16,5)   NOT NULL,
	TotalCmtdCost	decimal(16,5)   NOT NULL,
	OrigEstHours	decimal(16,5)   NOT NULL,
	OrigEstUnits	decimal(16,5)   NOT NULL,
	OrigEstCost		decimal(16,5)   NOT NULL
)

CREATE UNIQUE INDEX bitmpProjInit ON #tmpProjInit (Co, Job, PhaseGroup, Phase, CostType)


if @projectmgr = 0
	begin
	if @selectedcosttypes is null
		begin
		---- for a range of jobs and all cost types
		insert into #tmpProjInit select h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.CostType,
			isnull(sum(p.ActualHours),0), isnull(sum(p.ActualUnits),0), isnull(sum(p.ActualCost),0),
			isnull(sum(p.CurrEstHours),0), isnull(sum(p.CurrEstUnits),0), isnull(sum(p.CurrEstCost),0),
			isnull(sum(p.ProjHours),0), isnull(sum(p.ProjUnits),0), isnull(sum(p.ProjCost),0),
			isnull(sum(p.ForecastHours),0), isnull(sum(p.ForecastUnits),0), isnull(sum(p.ForecastCost),0),
			isnull(sum(p.RemainCmtdUnits),0), isnull(sum(p.RemainCmtdCost),0), isnull(b.Plugged,h.Plugged),
			isnull(sum(p.TotalCmtdUnits),0), isnull(sum(p.TotalCmtdCost),0),
			isnull(sum(p.OrigEstHours),0),isnull(sum(p.OrigEstUnits),0), isnull(sum(p.OrigEstCost),0)
		from bJCCH as h with (nolock)
		left join bJCCP as p with (nolock) on h.JCCo=p.JCCo and h.Job=p.Job and h.PhaseGroup=p.PhaseGroup and h.Phase=p.Phase and h.CostType=p.CostType
		join bJCJP c with (nolock) on c.JCCo=h.JCCo and c.Job=h.Job and c.PhaseGroup=h.PhaseGroup and c.Phase=h.Phase
		join bJCJM j with (nolock) on j.JCCo=h.JCCo and j.Job=h.Job
		join bJCCO o with (nolock) on o.JCCo=h.JCCo
		left join bJCPB b with (nolock) on b.Co=h.JCCo and b.Job=h.Job and b.PhaseGroup=h.PhaseGroup
		and b.Phase=h.Phase and b.CostType = h.CostType and b.Mth=@mth and b.BatchId=@batchid
		where h.JCCo=@jcco and h.Job>=@bjob and h.Job<=@ejob
		and isnull(p.Mth,'01/01/1980') <= @mth 
		and ((@inactivephases = 'N' and c.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
		---- issue #25569
		and (j.JobStatus = 1 or (j.JobStatus = 2 and o.PostSoftClosedJobs = 'Y') or (j.JobStatus = 3 and o.PostClosedJobs = 'Y'))
		and (@projjobinmultibatch = 'Y' or not exists(select top 1 1 from bJCPB with (nolock) where Co=h.JCCo and Job=h.Job
						and (Mth <> @mth or (BatchId <> @batchid and Mth = @mth)))) ---- #131828
--		and not exists(select top 1 1 from bJCPB with (nolock) where Co=h.JCCo and Job=h.Job
--						and (Mth <> @mth or (BatchId <> @batchid and Mth = @mth)))
		Group by h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.CostType, b.Plugged, h.Plugged
		end
	else
		begin
		---- for a range of jobs and selected cost types
		insert into #tmpProjInit select h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.CostType,
			isnull(sum(p.ActualHours),0), isnull(sum(p.ActualUnits),0), isnull(sum(p.ActualCost),0),
			isnull(sum(p.CurrEstHours),0), isnull(sum(p.CurrEstUnits),0), isnull(sum(p.CurrEstCost),0),
			isnull(sum(p.ProjHours),0), isnull(sum(p.ProjUnits),0), isnull(sum(p.ProjCost),0),
			isnull(sum(p.ForecastHours),0), isnull(sum(p.ForecastUnits),0), isnull(sum(p.ForecastCost),0),
			isnull(sum(p.RemainCmtdUnits),0), isnull(sum(p.RemainCmtdCost),0), isnull(b.Plugged,h.Plugged),
			isnull(sum(p.TotalCmtdUnits),0), isnull(sum(p.TotalCmtdCost),0),
			isnull(sum(p.OrigEstHours),0),isnull(sum(p.OrigEstUnits),0), isnull(sum(p.OrigEstCost),0)
		from bJCCH as h with (nolock)
		left join bJCCP as p with (nolock) on h.JCCo=p.JCCo and h.Job=p.Job and h.PhaseGroup=p.PhaseGroup and h.Phase=p.Phase and h.CostType=p.CostType
		join bJCJP c with (nolock) on c.JCCo=h.JCCo and c.Job=h.Job and c.PhaseGroup=h.PhaseGroup and c.Phase=h.Phase
		join bJCJM j with (nolock) on j.JCCo=h.JCCo and j.Job=h.Job
		join bJCCO o with (nolock) on o.JCCo=h.JCCo
		left join bJCPB b with (nolock) on b.Co=h.JCCo and b.Job=h.Job and b.PhaseGroup=h.PhaseGroup
		and b.Phase=h.Phase and b.CostType = h.CostType and b.Mth=@mth and b.BatchId=@batchid
		where h.JCCo=@jcco and h.Job>=@bjob and h.Job<=@ejob
		and isnull(p.Mth,'01/01/1980') <= @mth 
		and charindex(',' + rtrim(convert(varchar(3),h.CostType)) + ',',@selectedcosttypes) <> 0
		and ((@inactivephases = 'N' and c.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
		---- issue #25569
		and (j.JobStatus = 1 or (j.JobStatus = 2 and o.PostSoftClosedJobs = 'Y') or (j.JobStatus = 3 and o.PostClosedJobs = 'Y'))
		and (@projjobinmultibatch = 'Y' or not exists(select top 1 1 from bJCPB with (nolock) where Co=h.JCCo and Job=h.Job
						and (Mth <> @mth or (BatchId <> @batchid and Mth = @mth)))) ---- #131828
--		and not exists(select top 1 1 from bJCPB with (nolock) where Co=h.JCCo and Job=h.Job
--						and (Mth <> @mth or (BatchId <> @batchid and Mth = @mth)))
		Group by h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.CostType, b.Plugged, h.Plugged
		end
	end

if @projectmgr <> 0
	begin
	---- for a selected project manager and all cost types
	if @selectedcosttypes is null
		begin
		insert into #tmpProjInit select h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.CostType,
			isnull(sum(p.ActualHours),0), isnull(sum(p.ActualUnits),0), isnull(sum(p.ActualCost),0),
			isnull(sum(p.CurrEstHours),0), isnull(sum(p.CurrEstUnits),0), isnull(sum(p.CurrEstCost),0),
			isnull(sum(p.ProjHours),0), isnull(sum(p.ProjUnits),0), isnull(sum(p.ProjCost),0),
			isnull(sum(p.ForecastHours),0), isnull(sum(p.ForecastUnits),0), isnull(sum(p.ForecastCost),0),
			isnull(sum(p.RemainCmtdUnits),0), isnull(sum(p.RemainCmtdCost),0), isnull(b.Plugged,h.Plugged),
			isnull(sum(p.TotalCmtdUnits),0), isnull(sum(p.TotalCmtdCost),0),
			isnull(sum(p.OrigEstHours),0), isnull(sum(p.OrigEstUnits),0), isnull(sum(p.OrigEstCost),0)
		from bJCCH as h with (nolock)
		left join bJCCP as p with (nolock) on h.JCCo=p.JCCo and h.Job=p.Job and h.PhaseGroup=p.PhaseGroup and h.Phase=p.Phase and h.CostType=p.CostType
		join bJCJP c with (nolock) on c.JCCo=h.JCCo and c.Job=h.Job and c.PhaseGroup=h.PhaseGroup and c.Phase=h.Phase
		join bJCJM j with (nolock) on j.JCCo=h.JCCo and j.Job=h.Job
		join bJCCO o with (nolock) on o.JCCo=h.JCCo
		left join bJCPB b with (nolock) on b.Co=h.JCCo and b.Job=h.Job and b.PhaseGroup=h.PhaseGroup
		and b.Phase=h.Phase and b.CostType = h.CostType and b.Mth=@mth and b.BatchId=@batchid
		where h.JCCo=@jcco and isnull(p.Mth,'01/01/1980') <= @mth 
		and ((@inactivephases = 'N' and c.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
		and j.ProjectMgr=@projectmgr
		---- issue #25569
		and (j.JobStatus = 1 or (j.JobStatus = 2 and o.PostSoftClosedJobs = 'Y') or (j.JobStatus = 3 and o.PostClosedJobs = 'Y'))
		and (@projjobinmultibatch = 'Y' or not exists(select top 1 1 from bJCPB with (nolock) where Co=h.JCCo and Job=h.Job
						and (Mth <> @mth or (BatchId <> @batchid and Mth = @mth)))) ---- #131828
--		and not exists(select top 1 1 from bJCPB with (nolock) where Co=h.JCCo and Job=h.Job
--						and (Mth <> @mth or (BatchId <> @batchid and Mth = @mth)))
		Group by h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.CostType, b.Plugged, h.Plugged
		end
	else
		begin
		---- for a selected project manager and selected cost types
		insert into #tmpProjInit select h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.CostType,
			isnull(sum(p.ActualHours),0), isnull(sum(p.ActualUnits),0), isnull(sum(p.ActualCost),0),
			isnull(sum(p.CurrEstHours),0), isnull(sum(p.CurrEstUnits),0), isnull(sum(p.CurrEstCost),0),
			isnull(sum(p.ProjHours),0), isnull(sum(p.ProjUnits),0), isnull(sum(p.ProjCost),0),
			isnull(sum(p.ForecastHours),0), isnull(sum(p.ForecastUnits),0), isnull(sum(p.ForecastCost),0),
			isnull(sum(p.RemainCmtdUnits),0), isnull(sum(p.RemainCmtdCost),0),isnull(b.Plugged,h.Plugged),
			isnull(sum(p.TotalCmtdUnits),0), isnull(sum(p.TotalCmtdCost),0),
			isnull(sum(p.OrigEstHours),0),isnull(sum(p.OrigEstUnits),0), isnull(sum(p.OrigEstCost),0)
		from bJCCH as h with (nolock)
		left join bJCCP as p with (nolock) on h.JCCo=p.JCCo and h.Job=p.Job and h.PhaseGroup=p.PhaseGroup and h.Phase=p.Phase and h.CostType=p.CostType
		join bJCJP c with (nolock) on c.JCCo=h.JCCo and c.Job=h.Job and c.PhaseGroup=h.PhaseGroup and c.Phase=h.Phase
		join bJCJM j with (nolock) on j.JCCo=h.JCCo and j.Job=h.Job
		join bJCCO o with (nolock) on o.JCCo=h.JCCo
		left join bJCPB b with (nolock) on b.Co=h.JCCo and b.Job=h.Job and b.PhaseGroup=h.PhaseGroup
		and b.Phase=h.Phase and b.CostType = h.CostType and b.Mth=@mth and b.BatchId=@batchid
		where h.JCCo=@jcco and isnull(p.Mth,'01/01/1980') <= @mth 
		and charindex(',' + rtrim(convert(varchar(3),h.CostType)) + ',',@selectedcosttypes) <> 0
		and ((@inactivephases = 'N' and c.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
		and j.ProjectMgr=@projectmgr
		---- issue #25569
		and (j.JobStatus = 1 or (j.JobStatus = 2 and o.PostSoftClosedJobs = 'Y') or (j.JobStatus = 3 and o.PostClosedJobs = 'Y'))
		and (@projjobinmultibatch = 'Y' or not exists(select top 1 1 from bJCPB with (nolock) where Co=h.JCCo and Job=h.Job
						and (Mth <> @mth or (BatchId <> @batchid and Mth = @mth)))) ---- #131828
--		and not exists(select top 1 1 from bJCPB with (nolock) where Co=h.JCCo and Job=h.Job
--						and (Mth <> @mth or (BatchId <> @batchid and Mth = @mth)))
		Group by h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.CostType, b.Plugged, h.Plugged
		end
	end

---- declare cursor on #tmpProjInit for Projection calculations and initialize
declare bctmpProjInit cursor LOCAL SCROLL DYNAMIC 
	for select Co, Job, PhaseGroup, Phase, CostType, ActualHours,
	ActualUnits, ActualCosts, CurrEstHours, CurrEstUnits, CurrEstCosts, ProjHours,
	ProjUnits, ProjCosts, ForecastHours, ForecastUnits, ForecastCosts, RemainCmtdUnits,
	RemainCmtdCosts, Plugged,
	TotalCmtdUnits, TotalCmtdCost, OrigEstHours, OrigEstUnits, OrigEstCost 
from #tmpProjInit

---- open cursor and set cursor flag
open bctmpProjInit
select @opencursor = 1, @initcount = 0

---- loop through all rows in #tmpProjInit
tmp_calc_loop:
fetch next from bctmpProjInit into @cco, @cjob, @cphasegroup, @cphase, @ccosttype,
		@cactualhours, @cactualunits, @cactualcosts, @ccurresthours, @ccurrestunits,
		@ccurrestcosts, @cprojhours, @cprojunits, @cprojcosts, @prevforecasthours,
		@prevforecastunits, @prevforecastcosts, @cremaincmtdunits, @cremaincmtdcosts, @cplugged,
		@totalcmtdunits, @totalcmtdcosts, @origesthours, @origestunits, @origestcosts

if (@@fetch_status <> 0) goto tmp_calc_end

set @includedcohours=0
set @includedcounits=0
set @includedcocosts=0


---- create a delimited string of roles for this user #140202
set @UserRole = ''
select @UserRole = @UserRole + r.Role + ';'
from dbo.JCJobRoles r with (nolock)
where r.JCCo=@cco and r.Job=@cjob and r.VPUserName=@username
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
--select @user_role=r.Role
--from dbo.JCJobRoles r with (nolock)
--left join dbo.JCJPRoles p with (nolock) on p.JCCo=r.JCCo and p.Job=r.Job and p.Role=r.Role and p.Process='C'
--where r.JCCo=@cco and r.Job=@cjob and p.Process='C' and r.VPUserName=@username
--and p.JCCo=@cco and p.Job=@cjob
--if @@rowcount = 0 set @user_role = null

---- if we have a role for the user and phases have been assigned to this user for the
---- cost projections process then we need to remove phases from temp table that are
---- not matched in JCJPRoles #135527
if isnull(@UserRole,'') <> ''
	begin
	delete #tmpProjInit
	from #tmpProjInit t
	where t.Job is not null and t.Phase is not null
	and not exists(select 1 from dbo.JCJPRoles p with (nolock) where p.JCCo=@jcco and p.Job=t.Job
			and p.PhaseGroup=@phasegroup and p.Phase=t.Phase and p.Process='C'
			and PATINDEX('%' + p.Role + '%', @UserRole) <> 0)
			----and charindex( convert(varchar(20),p.Role) + ';', @UserRole) <> 0) #140202
	if @@rowcount <> 0 goto tmp_calc_loop
	end


---- get minimum percentage
select @minpct=isnull(ProjMinPct,0), @item=Item
from bJCJP with (nolock) where JCCo=@cco and Job=@cjob and PhaseGroup=@cphasegroup and Phase=@cphase
if @minpct = 0
	begin
	select @minpct=isnull(ProjMinPct,0) from bJCJM WITH (NOLOCK) where JCCo=@cco and Job=@cjob
	if @minpct = 0 select @minpct = @cminpct
	end

---- get buyout flag
select @buyoutyn=BuyOutYN, @jcch_plugged=Plugged
from bJCCH WITH (NOLOCK)
where JCCo=@cco and Job=@cjob and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype
if @buyoutyn <> 'Y' set @buyoutyn='N'
if @jcch_plugged <> 'Y' set @jcch_plugged = 'N'

---- get previous projected and forecasted values
if @thrupriormonth = 'Y'
	begin
	select @prevprojhours=isnull(sum(ProjHours),0),
			@prevprojunits=isnull(sum(ProjUnits),0),
			@prevprojcosts=isnull(sum(ProjCost),0)
	from JCCP WITH (NOLOCK) where JCCo=@cco and Mth<@mth and Job=@cjob
	and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype
	end
else
	begin
	select @prevprojhours=isnull(sum(ProjHours),0),
			@prevprojunits=isnull(sum(ProjUnits),0),
			@prevprojcosts=isnull(sum(ProjCost),0)
	from JCCP WITH (NOLOCK) where JCCo=@cco and Mth<=@mth and Job=@cjob
	and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype
	end


select @prevprojuc = case when @prevprojunits<>0 then (@prevprojcosts/@prevprojunits) else 0 end
select @prevforecastuc = case when @prevforecastunits<>0 then (@prevforecastcosts/@prevforecastunits) else 0 end


---- get future change order values #126236
---- only when future change order costs are included
select @pmolcount=Count(*)
from bPMOL WITH (NOLOCK) where PMCo=@jcco and Project=@bjob and PhaseGroup=@phasegroup and Phase=@cphase
and CostType=@ccosttype and InterfacedDate is null
if @pmolcount > 0
	begin
	---- #137604
	select @includedcohours=isnull(sum(l.EstHours),0),
			@includedcounits=isnull(sum(case when l.UM=h.UM then l.EstUnits else 0 end),0),
			@includedcocosts=isnull(sum(l.EstCost),0)
	from bPMOL as l with (nolock)
	join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	join bJCCH h with (nolock) on h.JCCo=l.PMCo and h.Job=l.Project and h.PhaseGroup=l.PhaseGroup
	and h.Phase=l.Phase and h.CostType=l.CostType
	where l.PMCo=@jcco and l.Project=@bjob and l.PhaseGroup=@phasegroup and l.Phase=@cphase
	and l.CostType=@ccosttype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end

---- get any future change order add-on costs. these will
---- come from bPMOB for a PMCo and Project - #129669
if exists(select top 1 1 from bPMOB with (nolock) where PMCo=@jcco and Project=@bjob)
	begin
	---- get future change order cost to include
	select @includedcocosts = @includedcocosts + isnull(sum(f.AmtToDistribute),0)
	from bPMOB as f with (nolock)
	join bPMOI i with (nolock) on i.PMCo=f.PMCo and i.Project=f.Project and i.PCOType=f.PCOType
	and i.PCO=f.PCO and i.PCOItem=f.PCOItem
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where f.PMCo=@jcco and f.Project=@bjob and f.PhaseGroup=@phasegroup and f.Phase=@cphase
	and i.ACOItem is null and f.CostType=@ccosttype
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end



select @esthours = @ccurresthours, @estunits = @ccurrestunits, @estcosts = @ccurrestcosts
select @acthours = @cactualhours, @actunits = @cactualunits, @actcosts = @cactualcosts

---- #126236
---- added future change order values to estimate values that are flagged to be included in projection
select @esthours = @esthours + @includedcohours
select @estunits = @estunits + @includedcounits
select @estcosts = @estcosts + @includedcocosts
set @use_estimate = 'N'


if @projmethod = '2'
	begin
	select @actunits = @cactualunits+@cremaincmtdunits, @actcosts = @cactualcosts+@cremaincmtdcosts
	end

if @estunits <> 0
	begin
	if (@actunits/@estunits) <= 99.999999
		begin
		select @pctcalc = @actunits / @estunits
		end
	else
		begin
		select @pctcalc = 99.999999
		end
	end
else
	begin
	select @pctcalc = 0
	end

if @pctcalc < @minpct or @pctcalc = 0
	begin
	select @projhours = @esthours, @projunits = @estunits, @projcosts = @estcosts, @use_estimate = 'Y'
	end

if @pctcalc > 0 and @pctcalc >= @minpct and @pctcalc < 1
	begin
	select @projhours = @acthours/@pctcalc, @projunits = @actunits/@pctcalc, @projcosts = @actcosts/@pctcalc
	end

if @pctcalc >= 1
	begin
	select @projhours = @acthours, @projunits = @actunits, @projcosts = @actcosts
	end

if @projmethod = '2' and @buyoutyn = 'Y'
	begin
	select @projhours = @acthours, @projunits = @actunits, @projcosts = @actcosts
	end

if abs(@projhours) < abs(@acthours) select @projhours = @acthours
if abs(@projunits) < abs(@actunits) select @projunits = @actunits
if abs(@projcosts) < abs(@actcosts) select @projcosts = @actcosts

---- problem with null values 
set @projfinalhours = isnull(@projhours,0) - isnull(@prevprojhours,0)
set	@projfinalunits = isnull(@projunits,0) - isnull(@prevprojunits,0)
set	@projfinalcosts = isnull(@projcosts,0) - isnull(@prevprojcosts,0)


if @projmethod='2' and @buyoutyn='Y'
	begin
	select @forecastfinalhours=@acthours,
			@forecastfinalunits=@actunits,
			@forecastfinalcosts=@actcosts
	end
else
	begin
	select @forecastfinalhours = @projfinalhours+@prevprojhours,
			@forecastfinalunits = @projfinalunits+@prevprojunits,
			@forecastfinalcosts = @projfinalcosts+@prevprojcosts
	end

select @forecastfinaluc = case when @forecastfinalunits<>0 then (@forecastfinalcosts/@forecastfinalunits) else 0 end


---- delete record from the batch table
if @cplugged = 'Y'
	begin
	---- plugged value with no writeover option
	if @writeoverplug = 1 goto tmp_skip_delete
	if @writeoverplug in (2,3)
		begin
		---- plugged value writeover actual>plugged costs only
		if @actcosts<=@prevprojcosts
			begin
			goto tmp_skip_delete
			end
		else
			begin
			select @ovrprojhrs = @acthours, @ovrprojunits = @actunits, @ovrprojcost = @actcosts
			select @ovrprojuc = case when @ovrprojunits<>0 then (@ovrprojcost/@ovrprojunits) else 0 end
			end
		end
	end

---- delete from batch table JCPB
delete from bJCPB
where Co=@cco and Mth=@mth and BatchId=@batchid and Job=@cjob
and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype
---- delete from JCPD
delete from bJCPD
where Co=@cco and Mth=@mth and BatchId=@batchid and Job=@cjob
and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype

tmp_skip_delete:

---- update forecast only if plugged and write over plugs set to no and valid changes
if @cplugged = 'Y' and @writeoverplug = 1
	begin
	update bJCPB set ForecastFinalUnits = @forecastfinalunits, ForecastFinalHrs = @forecastfinalhours,
					 ForecastFinalCost = @forecastfinalcosts, ForecastFinalUnitCost = @forecastfinaluc
	where Co=@cco and Mth=@mth and BatchId=@batchid and Job=@cjob
	and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype
	----#134832
	if @@rowcount = 0 and @detailinit > 1
		begin
		exec @retcode = dbo.bspJCProjInitPlugPhaseCT @username, @cco, @mth, @batchid, @cjob, @cphasegroup,
					@actualdate, @minpct, @cphase, @ccosttype, @errmsg output
		end
	goto init_worksheet_detail_main
	end

---- update forecast only if plugged and write over plugs set to actual>plugged
---- and actual costs <= plugged costs and valid changes
if @cplugged = 'Y' and @writeoverplug in (2,3)
	begin
	if @actcosts <= @prevprojcosts
		begin
		update bJCPB set ForecastFinalUnits = @forecastfinalunits, ForecastFinalHrs = @forecastfinalhours,
					ForecastFinalCost = @forecastfinalcosts, ForecastFinalUnitCost = @forecastfinaluc
		where Co=@cco and Mth=@mth and BatchId=@batchid and Job=@cjob
		and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype
		----#134832
		if @@rowcount = 0 and @detailinit > 1
			begin
			exec @retcode = dbo.bspJCProjInitPlugPhaseCT @username, @cco, @mth, @batchid, @cjob, @cphasegroup,
						@actualdate, @minpct, @cphase, @ccosttype, @errmsg output
			end
		goto init_worksheet_detail_main
		end
	else
		begin
		select @cplugged = 'N'
		if @writeoverplug = 3 select @cplugged = 'Y'
		---- insert JCPB record
		insert into bJCPB (Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType, ActualDate,
				ProjFinalUnits, ProjFinalHrs, ProjFinalCost, ProjFinalUnitCost, PrevProjUnits,
				PrevProjHours, PrevProjCost, PrevProjUnitCost, ForecastFinalUnits, ForecastFinalHrs,
				ForecastFinalCost, ForecastFinalUnitCost, PrevForecastUnits, PrevForecastHours,
				PrevForecastCost, PrevForecastUnitCost, Plugged, ActualHours, ActualUnits, ActualCost,
				CurrEstHours, CurrEstUnits, CurrEstCost, RemainCmtdUnits, RemainCmtdCost, TotalCmtdUnits,
				TotalCmtdCost, OrigEstHours, OrigEstUnits, OrigEstCost, ActualCmtdUnits, ActualCmtdCost,
				Item, OldPlugged)
		select @jcco, @mth, @batchid, isnull(max(a.BatchSeq),0) + 1, @cjob, @cphasegroup, @cphase, @ccosttype, @actualdate,
				@ovrprojunits, @ovrprojhrs, @ovrprojcost, @ovrprojuc, @prevprojunits, @prevprojhours,
				@prevprojcosts, @prevprojuc, @forecastfinalunits, @forecastfinalhours, @forecastfinalcosts,
				@forecastfinaluc, @prevforecastunits, @prevforecasthours, @prevforecastcosts,
				@prevforecastuc, @cplugged, @cactualhours, @cactualunits, @cactualcosts, @ccurresthours,
				@ccurrestunits, @ccurrestcosts, @cremaincmtdunits, @cremaincmtdcosts, @totalcmtdunits,
				@totalcmtdcosts, @origesthours, @origestunits, @origestcosts,
				@cactualunits + @cremaincmtdunits, @cactualcosts + @cremaincmtdcosts,
				@item, isnull(@jcch_plugged,'N')
		from bJCPB a where a.Co=@jcco and a.Mth=@mth and a.BatchId=@batchid
		goto init_worksheet_detail_main
		end
	end


select @cplugged = 'N'
---- if above write over plug conditions not met, add projection to batch
insert into bJCPB (Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType, ActualDate,
		ProjFinalUnits, ProjFinalHrs, ProjFinalCost, ProjFinalUnitCost, PrevProjUnits, PrevProjHours,
		PrevProjCost, PrevProjUnitCost, ForecastFinalUnits, ForecastFinalHrs, ForecastFinalCost,
		ForecastFinalUnitCost, PrevForecastUnits, PrevForecastHours, PrevForecastCost,
		PrevForecastUnitCost, Plugged, ActualHours, ActualUnits, ActualCost, CurrEstHours, CurrEstUnits,
		CurrEstCost, RemainCmtdUnits, RemainCmtdCost, TotalCmtdUnits, TotalCmtdCost, OrigEstHours,
		OrigEstUnits, OrigEstCost, ActualCmtdUnits, ActualCmtdCost, Item, OldPlugged)
select @jcco, @mth, @batchid, isnull(max(a.BatchSeq),0) + 1, @cjob, @cphasegroup, @cphase, @ccosttype, @actualdate,
		@forecastfinalunits, @forecastfinalhours, @forecastfinalcosts, @forecastfinaluc, @prevprojunits,
		@prevprojhours, @prevprojcosts, @prevprojuc, @forecastfinalunits, @forecastfinalhours,
		@forecastfinalcosts, @forecastfinaluc, @prevforecastunits, @prevforecasthours, @prevforecastcosts,
		@prevforecastuc, @cplugged, @cactualhours, @cactualunits, @cactualcosts, @ccurresthours,
		@ccurrestunits, @ccurrestcosts, @cremaincmtdunits, @cremaincmtdcosts, @totalcmtdunits,
		@totalcmtdcosts, @origesthours, @origestunits, @origestcosts,
		@cactualunits + @cremaincmtdunits, @cactualcosts + @cremaincmtdcosts,
		@item, isnull(@jcch_plugged,'N')
from bJCPB a where a.Co=@jcco and a.Mth=@mth and a.BatchId=@batchid


---- insert projection worksheet detail #129898
init_worksheet_detail_main:
if @detailinit > 1
	begin
	exec @rcode = dbo.vspJCProjJCPDGet @jcco, @mth, @batchid, @cjob, @cphasegroup, @cphase,
						@ccosttype, @detailinit, @errmsg output
	end

---- this section tries to update linked cost types
Update_Linked_CostTypes:
---- add entry to HQ Close Control as needed
if not exists(select TOP 1 1 from HQCC with (nolock) where Co=@jcco and Mth=@mth and BatchId=@batchid)
	begin
	insert into bHQCC(Co, Mth, BatchId, GLCo)
	select @jcco, @mth, @batchid, @jcco
	end

---- reset values
select @noactunits = 'N', @noacthours = 'N', @noactcosts = 'N'
if @actunits = 0 set @noactunits = 'Y'
if @acthours = 0 set @noacthours = 'Y'
if @actcosts = 0 set @noactcosts = 'Y'

---- get project final for linked to cost type
select @projhours = 0, @projunits = 0, @projcosts = 0
select @projhours=ProjFinalHrs, @projunits=ProjFinalUnits, @projcosts=ProjFinalCost
from bJCPB with (nolock) where Co=@cco and Mth=@mth and BatchId=@batchid and Job=@cjob 
and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype

---- first update count
set @initcount = @initcount + 1
set @pctcalcunits = 0
set @pctcalchours = 0
set @pctcalccosts = 0

---- calculate percent complete for units
if @projunits <> 0
	begin
	set @linkpct = Abs(@actunits / @projunits)
	If @linkpct < 100
		begin
		set @pctcalcunits = @linkpct
		end
	else
		begin
		set @pctcalcunits = 99.999999
		end
	end

---- calculate percent complete for hours
if @projhours <> 0
   	begin
   	set @linkpct = Abs(@acthours / @projhours)
   	If @linkpct < 100
		begin
   		set @pctcalchours = @linkpct
		end
   	else
		begin
   		set @pctcalchours = 99.999999
		end
   	end

---- calculate percent complete for costs
if @projcosts <> 0
	begin
	set @linkpct = Abs(@actcosts / @projcosts)
	If @linkpct < 100
		begin
		set @pctcalccosts = @linkpct
		end
	else
		begin
		set @pctcalccosts = 99.999999
		end
	end

---- check units percent complete
if @pctcalcunits = 0 and @ccurrestunits <> 0 and @projunits <> 0
	begin
	set @linkpct = Abs(@projunits / @ccurrestunits)
	if @linkpct < 100
		begin
		set @pctcalcunits = @linkpct
		end
	else
		begin
		set @pctcalcunits = 99.999999
		end
	end

---- check hours percent complete
if @pctcalchours = 0 and @ccurresthours <> 0 and @projhours <> 0
	begin
	set @linkpct = abs(@projhours / @ccurresthours)
	if @linkpct < 100
		begin
		set @pctcalchours = @linkpct
		end
	else
		begin
		set @pctcalchours = 99.999999
		end
	end

-- -- check costs percent complete
if @pctcalccosts = 0 and @ccurrestcosts <> 0 and @projcosts <> 0
	begin
	set @linkpct = abs(@projcosts / @ccurrestcosts)
	if @linkpct < 100
		begin
		set @pctcalccosts = @linkpct
		end
	else
		begin
		set @pctcalccosts = 99.999999
		end
	end

---- issue #26527
if @pctcalchours = 0 and @pctcalcunits <> 0 set @pctcalchours = @pctcalcunits
if @pctcalccosts = 0 and @pctcalcunits <> 0 set @pctcalccosts = @pctcalcunits

---- check JCCT to see if there are any cost types linked to this cost type. If none loop 
if not exists(select top 1 1 from JCCT	with (nolock) where PhaseGroup=@phasegroup and LinkProgress=@ccosttype)
	begin
	goto tmp_calc_loop
	end

---- declare cursor on JCCT for linked cost types
declare bcJCCT cursor LOCAL FAST_FORWARD for select CostType
from JCCT where PhaseGroup=@phasegroup and LinkProgress=@ccosttype
group by CostType

-- open bJCCT cursor
open bcJCCT
select @opencursor_jcct = 1

-- process through all entries in batch
JCCT_loop:
fetch next from bcJCCT into @linkcosttype

if @@fetch_status = -1 goto JCCT_end
if @@fetch_status <> 0 goto JCCT_loop

---- check if cost type exists for Job-Phase in bJCCH. Get needed data
select @linkactive=ActiveYN, @linkplugged=Plugged, @cbuyoutyn=BuyOutYN ---- #133491
from bJCCH with (nolock) where JCCo=@jcco and Job=@cjob and PhaseGroup=@cphasegroup
and Phase=@cphase and CostType=@linkcosttype

---- per carol, if linked not in JCCH skip it
if @@rowcount = 0 goto check_bctmpProjInit

---- #133491
if @cbuyoutyn <> 'Y' set @cbuyoutyn = 'N'

---- do not insert/update linked cost type if JCCH.ActiveYN flag is 'N'
if @linkactive = 'N' and @inactivephases = 'N' goto check_bctmpProjInit

---- issue #119650 if no change to main cost type skip linked cost type as well #130732
if @cplugged = 'Y' and @writeoverplug in (1,2,3) and @actcosts<=@prevprojcosts  goto check_bctmpProjInit
if @linkplugged = 'Y' and @writeoverplug = 1 goto check_bctmpProjInit

----select @cplugged, @writeoverplug, @actcosts, @prevprojcosts, @pctcalcunits, @pctcalchours, @pctcalccosts
----goto check_bctmpProjInit

---- reset values
select @actualunits=0, @actualcmtdunits=0, @actualhours=0, @actualcmtdcosts=0, @actualcosts=0

---- need to get actual values to calculate projection values 
select @prevprojhours=0, @prevprojunits=0, @prevprojcosts=0, @actualhours=0, 
		@actualunits=0, @actualcosts=0, @origesthours=0, @origestunits=0, 
		@origestcosts=0, @curresthours=0, @currestunits=0, @currestcosts=0, 
		@remaincmtdunits=0, @remaincmtdcosts=0, @actualcmtdunits=0, @actualcmtdcosts=0,
		@prevforecasthours=0, @prevforecastunits=0, @prevforecastcosts=0

---- and add to the batch table bJCPB
if @thrupriormonth = 'Y'
	begin
	---- previous month's values
	select @prevprojhours=isnull(sum(ProjHours),0),
			@prevprojunits=isnull(sum(ProjUnits),0),
			@prevprojcosts=isnull(sum(ProjCost),0),
			@actualhours=isnull(sum(ActualHours),0),
			@actualunits=isnull(sum(ActualUnits),0),
			@actualcosts=isnull(sum(ActualCost),0),
			@origesthours=isnull(sum(OrigEstHours),0),
			@origestunits=isnull(sum(OrigEstUnits),0),
			@origestcosts=isnull(sum(OrigEstCost),0),
			@curresthours=isnull(sum(CurrEstHours),0),
			@currestunits=isnull(sum(CurrEstUnits),0),
			@currestcosts=isnull(sum(CurrEstCost),0),
			@remaincmtdunits=isnull(sum(RemainCmtdUnits),0),
			@remaincmtdcosts=isnull(sum(RemainCmtdCost),0),
			@prevforecasthours=isnull(sum(ForecastHours),0),
			@prevforecastunits=isnull(sum(ForecastUnits),0),
			@prevforecastcosts=isnull(sum(ForecastCost),0),
			@projhours=isnull(sum(ProjHours),0),
			@projunits=isnull(sum(ProjUnits),0),
			@projcosts=isnull(sum(ProjCost),0)
	from JCCP WITH (NOLOCK) where JCCo=@jcco and Job=@cjob and PhaseGroup=@cphasegroup 
	and Phase=@cphase and CostType=@linkcosttype and Mth<@mth

	---- current month values
	select @actualhours=@actualhours + isnull(sum(ActualHours),0),
			@actualunits=@actualunits + isnull(sum(ActualUnits),0),
			@actualcosts=@actualcosts + isnull(sum(ActualCost),0),
			@origesthours=@origesthours + isnull(sum(OrigEstHours),0),
			@origestunits=@origestunits + isnull(sum(OrigEstUnits),0),
			@origestcosts=@origestcosts + isnull(sum(OrigEstCost),0),
			@curresthours=@curresthours + isnull(sum(CurrEstHours),0),
			@currestunits=@currestunits + isnull(sum(CurrEstUnits),0),
			@currestcosts=@currestcosts + isnull(sum(CurrEstCost),0),
			@remaincmtdunits=@remaincmtdunits + isnull(sum(RemainCmtdUnits),0),
			@remaincmtdcosts=@remaincmtdcosts + isnull(sum(RemainCmtdCost),0),
			@prevforecasthours=@prevforecasthours + isnull(sum(ForecastHours),0),
			@prevforecastunits=@prevforecastunits + isnull(sum(ForecastUnits),0),
			@prevforecastcosts=@prevforecastcosts + isnull(sum(ForecastCost),0),
			@projhours=@projhours + isnull(sum(ProjHours),0),
			@projunits=@projunits + isnull(sum(ProjUnits),0),
			@projcosts=@projcosts + isnull(sum(ProjCost),0)
	from JCCP WITH (NOLOCK) where JCCo=@jcco and Job=@cjob and PhaseGroup=@cphasegroup 
	and Phase=@cphase and CostType=@linkcosttype and Mth=@mth
	end
else
	begin
	select @prevprojhours=isnull(sum(ProjHours),0),
			@prevprojunits=isnull(sum(ProjUnits),0),
			@prevprojcosts=isnull(sum(ProjCost),0),
			@actualhours=isnull(sum(ActualHours),0),
			@actualunits=isnull(sum(ActualUnits),0),
			@actualcosts=isnull(sum(ActualCost),0),
			@origesthours=isnull(sum(OrigEstHours),0),
			@origestunits=isnull(sum(OrigEstUnits),0),

			@origestcosts=isnull(sum(OrigEstCost),0),
			@curresthours=isnull(sum(CurrEstHours),0),
			@currestunits=isnull(sum(CurrEstUnits),0),
			@currestcosts=isnull(sum(CurrEstCost),0),
			@remaincmtdunits=isnull(sum(RemainCmtdUnits),0),
			@remaincmtdcosts=isnull(sum(RemainCmtdCost),0),
			@prevforecasthours=isnull(sum(ForecastHours),0),
			@prevforecastunits=isnull(sum(ForecastUnits),0),
			@prevforecastcosts=isnull(sum(ForecastCost),0),
			@projhours=isnull(sum(ProjHours),0),
			@projunits=isnull(sum(ProjUnits),0),
			@projcosts=isnull(sum(ProjCost),0)
	from JCCP WITH (NOLOCK) where JCCo=@jcco and Job=@cjob and PhaseGroup=@cphasegroup 
	and Phase=@cphase and CostType=@linkcosttype and Mth<=@mth
	end

---- get future change order values #126236
---- only when future change order costs are included
select @pmolcount=Count(*)
from PMOL WITH (NOLOCK) where PMCo=@jcco and Project=@cjob and PhaseGroup=@cphasegroup and Phase=@cphase
and CostType=@linkcosttype and InterfacedDate is null
if @pmolcount > 0
	begin
	select @includedcohours=isnull(sum(l.EstHours),0),
			---- #137604
			@includedcounits=isnull(sum(case when l.UM=h.UM then l.EstUnits else 0 end),0),
			----@includedcounits=isnull(sum(l.EstUnits),0),
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
	where l.PMCo=@jcco and l.Project=@cjob and l.PhaseGroup=@cphasegroup and l.Phase=@cphase
	and l.CostType=@linkcosttype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end

---- set estimate, actual, actual + committed
select @actualcmtdunits = @actualunits + @remaincmtdunits, 
		@actualcmtdcosts = @actualcosts + @remaincmtdcosts,
		@esthours = @curresthours, @estunits = @currestunits, @estcosts = @currestcosts,
		@acthours = @actualhours, @actunits = @actualunits, @actcosts = @actualcosts

---- #126236
---- added future change order values to estimate values that are flagged to be included in projection
----select @esthours = @esthours + @includedcohours
----select @estunits = @estunits + @includedcounits
----select @estcosts = @estcosts + @includedcocosts

if @estunits <> 0
	begin
	if (@actunits/@estunits) <= 99.999999
		begin
		select @pctcalc = @actunits / @estunits
		end
	else
		begin
		select @pctcalc = 99.999999
		end
	end
else
	begin
	select @pctcalc = 0
	end

if @pctcalc < @minpct or @pctcalc = 0
	begin
	select @projhours = @esthours, @projunits = @estunits, @projcosts = @estcosts
	end

if @pctcalc > 0 and @pctcalc >= @minpct and @pctcalc < 1
	begin
	if @projmethod = '2'
		begin
		select @projhours = @acthours/@pctcalc, 
				@projunits = @actualcmtdunits/@pctcalc, 
				@projcosts = @actualcmtdcosts/@pctcalc
		end
	else
		begin
		select @projhours = @acthours/@pctcalc, 
				@projunits = @actunits/@pctcalc, 
				@projcosts = @actcosts/@pctcalc
		end
	end

if @pctcalc >= 1
	begin
	if @projmethod = '2'
		begin
		select @projhours = @acthours, @projunits = @actualcmtdunits, @projcosts = @actualcmtdcosts
		end
	else
		begin
		select @projhours = @acthours, @projunits = @actunits, @projcosts = @actcosts
		end
	end

---- #133491
if @projmethod = '2' and @cbuyoutyn = 'Y'
	begin
	select @projhours = @acthours, @projunits = @actualcmtdunits, @projcosts = @actualcmtdcosts
	end

if @projmethod = '2'
	begin
	if abs(@projhours) < abs(@acthours) select @projhours=@acthours
	if abs(@projunits) < abs(@actualcmtdunits) select @projunits=@actualcmtdunits
	if abs(@projcosts) < abs(@actualcmtdcosts) select @projcosts=@actualcmtdcosts
	end
else
	begin
	if abs(@projhours) < abs(@acthours) select @projhours=@acthours
	if abs(@projunits) < abs(@actunits) select @projunits=@actunits
	if abs(@projcosts) < abs(@actcosts) select @projcosts=@actcosts
	end

select @projfinalhours = @projhours - @prevprojhours,
		@projfinalunits = @projunits - @prevprojunits,
		@projfinalcosts = @projcosts - @prevprojcosts

---- #133491
if @projmethod = '2' and @cbuyoutyn = 'Y'
	begin
	select @forecasthours = @acthours, 
			@forecastunits = @actualcmtdunits, 
			@forecastcosts = @actualcmtdcosts
	end
else
	begin
	select @forecasthours = @projfinalhours + @prevprojhours,
			@forecastunits = @projfinalunits + @prevprojunits,
			@forecastcosts = @projfinalcosts + @prevprojcosts
	end

---- now calculate linked cost type projections
select  @projhours=0, @projunits=0, @projcosts=0, @projfinalhours=0, @projfinalunits=0, @projfinalcosts=0

---- do calculations
if @pctcalcunits <> 0
	begin
	select @projunits = @actualunits / @pctcalcunits
	end
else
	begin
	select @projunits = 0
	end

if @pctcalchours <> 0
	begin
	select @projhours = @actualhours / @pctcalchours
	end
else
	begin
	select @projhours = 0
	end

if @pctcalccosts <> 0
	begin
	select @projcosts = @actualcosts / @pctcalccosts
	end
else
	begin
	select @projcosts = 0
	end

---- #133491
if @cbuyoutyn = 'Y'
	begin
	select @projunits = @actualunits, @projhours=@actualhours, @projcosts=@actualcosts
	end

if @projmethod = '2'
	begin
	if @pctcalcunits <> 0
		begin
		select @projunits = @actualcmtdunits / @pctcalcunits
		end
	else
		begin
		select @projunits = 0
		end

	if @pctcalccosts <> 0
		begin
		select @projcosts = @actualcmtdcosts / @pctcalccosts
		end
	else
		begin
		select @projcosts = 0
		end

---- #133491
	if @cbuyoutyn = 'Y'
		begin
		select @projunits=@actualcmtdunits, @projhours=@actualhours, @projcosts=@actualcmtdcosts
		end
	end

if @projmethod = '2'
	begin
	if abs(@projhours) < abs(@actualhours) select @projhours = @actualhours
	if abs(@projunits) < abs(@actualcmtdunits) select @projunits = @actualcmtdunits
	if abs(@projcosts) < abs(@actualcmtdcosts) select @projcosts = @actualcmtdcosts
	end
else
	begin
	if abs(@projhours) < abs(@actualhours) select @projhours = @actualhours
	if abs(@projunits) < abs(@actualunits) select @projunits = @actualunits
	if abs(@projcosts) < abs(@actualcosts) select @projcosts = @actualcosts
	end

---- #133491
if @cbuyoutyn = 'N'
	begin
	if @pctcalcunits <> 0 and @currestunits <> 0 and @noactunits = 'Y'
		begin
		set @projunits = @pctcalcunits * @currestunits
		end

	---- calculate using estimate if no projection and @pctcalchours <> 0
	if @pctcalchours <> 0 and @curresthours <> 0 and @noacthours = 'Y' and @noactunits = 'Y'
		begin
		set @projhours = @pctcalchours * @curresthours
		end

	---- calculate using estimate if no projection and @pctcalccosts <> 0
	if @pctcalccosts <> 0 and @currestcosts <> 0 and @noactcosts = 'Y' and @noactunits = 'Y'
		begin
		set @projcosts = @pctcalccosts * @currestcosts
		end
	end

if @projhours is null set @projhours = 0
if @projunits is null set @projunits = 0
if @projcosts is null set @projcosts = 0

---- #133491
if @cbuyoutyn = 'Y' goto update_linked_cost_type

---- #132731
if @use_estimate = 'Y'
	begin
	select @projhours = @esthours, @projunits = @estunits, @projcosts = @estcosts
	if abs(@projhours) < abs(@acthours) select @projhours = @acthours
	if abs(@projunits) < abs(@actunits) select @projunits = @actunits
	if abs(@projcosts) < abs(@actcosts) select @projcosts = @actcosts
	end

--if @use_estimate = 'Y'
--	begin
--	select @projhours = @esthours, @projunits = @estunits, @projcosts = @estcosts
--	end

if @pctcalchours <> 0 and @curresthours = 0 and @noacthours = 'N' and @projhours = 0
	begin
	set @projhours = @pctcalchours * @actualhours
	end
if @projmethod = '2'
	begin
	if @pctcalccosts <> 0 and @currestcosts = 0 and @noactcosts = 'N' and @projcosts = 0
		begin
		set @projcosts = @pctcalccosts * @actualcmtdcosts
		end
	end
else
	begin
	if @pctcalccosts <> 0 and @currestcosts = 0 and @noactcosts = 'N' and @projcosts = 0
		begin
		set @projcosts = @pctcalccosts * @actualcosts
		end
	end


update_linked_cost_type: ---- #133491
select @projfinalhours = @projhours - @prevprojhours,
	   @projfinalunits = @projunits - @prevprojunits,
	   @projfinalcosts = @projcosts - @prevprojcosts

---- calculate unit costs
select @prevprojuc = case when @prevprojunits <> 0 then (@prevprojcosts/@prevprojunits) else 0 end
select @prevforecastuc = case when @prevforecastunits <> 0 then (@prevforecastcosts/@prevforecastunits) else 0 end
select @projuc = case when @projunits <> 0 then (@projcosts/@projunits) else 0 end
select @forecastuc = case when @forecastunits <> 0 then (@forecastcosts/@forecastunits) else 0 end

---- update projections batch
update bJCPB set ProjFinalUnits=@projunits, ProjFinalHrs=@projhours, ProjFinalCost=@projcosts,
		ProjFinalUnitCost=isnull(@projuc,0), ForecastFinalUnits=@forecastunits, ForecastFinalHrs=@forecasthours, 
		ForecastFinalCost=@forecastcosts, ForecastFinalUnitCost=isnull(@forecastuc,0), Plugged=@cplugged
where Co=@jcco and Mth=@mth and BatchId=@batchid and Job=@cjob and PhaseGroup=@cphasegroup
and Phase=@cphase and CostType=@linkcosttype
if @@rowcount = 0
	begin
	--- insert batch record
   	insert into bJCPB (Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType, ActualDate, 
   			ProjFinalUnits, ProjFinalHrs, ProjFinalCost, ProjFinalUnitCost, PrevProjUnits, 
   			PrevProjHours, PrevProjCost, PrevProjUnitCost, ForecastFinalUnits, ForecastFinalHrs,
   			ForecastFinalCost, ForecastFinalUnitCost, PrevForecastUnits, PrevForecastHours,
   			PrevForecastCost, PrevForecastUnitCost, Plugged, ActualHours, ActualUnits, ActualCost,
			CurrEstHours, CurrEstUnits, CurrEstCost, RemainCmtdUnits, RemainCmtdCost, TotalCmtdUnits,
			TotalCmtdCost, OrigEstHours, OrigEstUnits, OrigEstCost, ActualCmtdUnits, ActualCmtdCost,
			Item, OldPlugged)
   	select @jcco, @mth, @batchid, isnull(max(a.BatchSeq),0) + 1, @cjob, @cphasegroup, @cphase, @linkcosttype, @actualdate, 
   			@projunits, @projhours, @projcosts, isnull(@projuc,0), @prevprojunits, 
   			@prevprojhours, @prevprojcosts, isnull(@prevprojuc,0), @forecastunits, @forecasthours, 
   			@forecastcosts, isnull(@forecastuc,0), @prevforecastunits, @prevforecasthours, 
   			@prevforecastcosts, isnull(@prevforecastuc,0), @cplugged, @cactualhours, @cactualunits,
			@cactualcosts, @ccurresthours, @ccurrestunits, @ccurrestcosts, @cremaincmtdunits,
			@cremaincmtdcosts, @totalcmtdunits, @totalcmtdcosts, @origesthours, @origestunits,
			@origestcosts, @cactualunits + @cremaincmtdunits, @cactualcosts + @cremaincmtdcosts,
			@item, isnull(@jcch_plugged,'N')
	from bJCPB a where a.Co=@jcco and a.Mth=@mth and a.BatchId=@batchid
   	end

---- insert projection worksheet detail #129898
if @detailinit > 1
	begin
	exec @rcode = dbo.vspJCProjJCPDGet @jcco, @mth, @batchid, @cjob, @cphasegroup, @cphase,
						@linkcosttype, @detailinit, @errmsg output
	end

---- add entry to HQ Close Control as needed
if not exists(select TOP 1 1 from bHQCC with (nolock) where Co=@jcco and Mth=@mth and BatchId=@batchid)
	begin
	insert into bHQCC(Co, Mth, BatchId, GLCo)
	select @jcco, @mth, @batchid, @jcco
	end


check_bctmpProjInit:
---- remove from temp table cursor if exists
delete #tmpProjInit
where Co=@jcco and Job=@cjob and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@linkcosttype

goto JCCT_loop



JCCT_end:
	if @opencursor_jcct = 1
		begin
		close bcJCCT
		deallocate bcJCCT
		set @opencursor_jcct = 0
		end

---- next cost type from tmp table
goto tmp_calc_loop


tmp_calc_end:
	begin
	select @msg = isnull(convert(varchar(5),@initcount),'') + ' projections initialized.', @rcode=0
	end




bspexit:
	if @opencursor_jcct = 1
		begin
		close bcJCCT
		deallocate bcJCCT
		set @opencursor_jcct = 0
		end

	if @opencursor = 1
		begin
		close bctmpProjInit
		deallocate bctmpProjInit
		set @opencursor = 0
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjInitialize] TO [public]
GO
