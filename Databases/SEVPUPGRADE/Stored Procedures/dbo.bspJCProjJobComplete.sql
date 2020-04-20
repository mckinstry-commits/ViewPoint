SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************/
CREATE proc [dbo].[bspJCProjJobComplete]
/****************************************************************************
* Created By: 	GF	03/02/2004
* Modified By:  TV				- 23061 added isnulls
*				GF				- issue #27183 use JCUO.ProjInactivePhases in query
*				DANF			- Recode for 6.x
*				GF	02/29/2008	- issue #25569 soft hard closed job flags
*				GF	03/23/2008	- issue #126993 added item to JCPB 
*				CHS	10/02/2008	- issue #126236
*				GF 12/22/2008 - issue #129669 include future addon costs
*				GF 02/05/2009 - issue #131828 allow job in open batches in month
*				GF 12/22/2009 - issue #135527 need to consider phases assigned for the role if any
*				GF 01/19/2009 - issue #137604 use new view to calculate over/under with included co values.
*				GF 06/16/2010 - issue #140202 multiple roles for user
*
*
* USAGE:
* 	Generates projections for a selected job. Deletes all future projections.
*	Restricts to job and active phase cost types. Will set the projected
*	values to equal the actual values. Similar to a buy-out except for entire
*	job. Will also flag as plugged if desired.
*
* INPUT PARAMETERS:
*	Company, Job, PhaseGroup, Month, BatchId, Actual Date, Plugged, 
*
* OUTPUT PARAMETERS:
*	None
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@jcco bCompany, @job bJob, @phasegroup tinyint, @mth bMonth, @batchid bBatchID,
@actualdate bDate, @plugged bYN, @username bVPUserName, @msg varchar(255) output)
as
set nocount on

declare @rcode integer, @cco tinyint, @cjob varchar(10), @cphasegroup tinyint, @cphase varchar(20),
		@cactualhours decimal(16,5), @cactualunits decimal(16,5), @cactualcosts decimal(16,5),
		@ccurresthours decimal(16,5), @ccurrestunits decimal(16,5), @ccurrestcosts decimal(16,5),
		@cprojhours decimal(16,5), @cprojunits decimal(16,5), @cprojcosts decimal(16,5),
		@cremaincmtdunits decimal(16,5), @cremaincmtdcosts decimal(16,5), @cplugged char(1),
		@ccosttype tinyint, @acthours bHrs, @actunits bUnits, @actcosts bDollar, @esthours bHrs,
		@estunits bUnits, @estcosts bDollar, @pctcalc float, @projhours bHrs, @projunits bUnits,
		@projcosts bDollar, @projuc bUnitCost, @prevestuc bUnitCost, @prevactuc bUnitCost,
		@prevprojuc bUnitCost, @prevforecastuc bUnitCost, @prevprojhours bHrs, @prevprojunits bUnits,
		@prevprojcosts bDollar, @prevforecasthours bHrs, @prevforecastunits bUnits,
		@prevforecastcosts bDollar, @projfinalhours bHrs, @projfinalunits bUnits,
		@projfinalcosts bDollar, @initcount int, @projfinaluc bUnitCost, @forecastfinalhours bHrs,
		@forecastfinalunits bUnits, @forecastfinalcosts bDollar, @forecastfinaluc bUnitCost,
		@forefinalhours bHrs, @forefinalunits bUnits, @forefinalcosts bDollar, @forefinaluc bUnitCost,
		@opencursor tinyint, @cminpct decimal(16,5), @minpct decimal(16,5), @projmethod char(1),
		@buyoutyn bYN, @ovrprojhrs bHrs, @ovrprojunits bUnits, @ovrprojcost bDollar,
		@ovrprojuc bUnitCost, @inactivephases bYN, @batchseq int, @citem bContractItem,
		@includedcohours bHrs, @includedcounits bUnits, @includedcocosts bDollar, @pmolcount int,
		@jcch_plugged char(1), @UserRole varchar(max)  ----#126236

select @rcode=0, @prevprojhours=0, @prevprojunits=0, @prevprojcosts=0, @prevprojuc=0,
		@prevforecasthours=0, @prevforecastunits=0, @prevforecastcosts=0, @prevforecastuc=0,
		@projfinalhours=0, @projfinalunits=0, @projfinalcosts=0, @projfinaluc=0,
		@forefinalhours=0, @forefinalunits=0, @forefinalcosts=0, @forefinaluc=0,@pctcalc=0,
		@esthours=0,@estunits=0,@estcosts=0,@acthours=0,@actunits=0,@actcosts=0,@projhours=0,
		@projunits=0,@projcosts=0,@prevestuc=0,@prevactuc=0, @ovrprojhrs=0,
		@ovrprojunits=0, @ovrprojcost=0, @ovrprojuc=0,
		@includedcohours = 0, @includedcounits = 0, @includedcocosts = 0, @pmolcount = 0 ----#126236


select @rcode = 0, @opencursor = 0

---- validate JC company
select @cminpct=isnull(ProjMinPct,0) from JCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0
	begin
	select @msg = 'Company not set up in JC Company file!', @rcode = 1
	goto bspexit
	end

if (select count(*) from JCJM with (nolock) where JCCo=@jcco and Job=@job) <> 1
	begin
	select @msg = 'Invalid Job.', @rcode = 1
	goto bspexit
	end

if (select count(*) from HQGP with (nolock) where Grp=@phasegroup)<>1
	begin
	select @msg = 'Phase group not in HQGP!', @rcode = 1
	goto bspexit
	end

---- get projection method from User Options
select @projmethod=ProjMethod, @inactivephases=ProjInactivePhases
from JCUO with (nolock) 
where JCCo=@jcco and Form='JCProjection' and UserName=@username
if @@rowcount = 0
	begin
	select @msg = 'User Name is invalid!', @rcode=1
	goto bspexit
	end

---- create a delimited string of roles for this user #140202
set @UserRole = ''
select @UserRole = @UserRole + r.Role + ';'
from dbo.JCJobRoles r with (nolock)
where r.JCCo=@jcco and r.Job=@job and r.VPUserName=@username
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
	
------ get the role for this user from JCJPRoles if phases are assigned to the Cost Projections  #135527
--select @user_role=r.Role
--from dbo.JCJobRoles r with (nolock)
--left join dbo.JCJPRoles p with (nolock) on p.JCCo=r.JCCo and p.Job=r.Job and p.Role=r.Role and p.Process='C'
--where r.JCCo=@jcco and r.Job=@job and p.Process='C' and r.VPUserName=@username
--and p.JCCo=@jcco and p.Job=@job
--if @@rowcount = 0 set @user_role = null


---- create temp table
CREATE TABLE #tmpProjInit(
   Co				tinyint         NOT NULL,
   Job				varchar(10)     NOT NULL,
   PhaseGroup		tinyint         NOT NULL,
   Phase			varchar(20)     NOT NULL,
   CostType			tinyint    		NOT NULL,
   ActualHours		decimal(16,5)	NOT NULL,
   ActualUnits		decimal(16,5)   NOT NULL,
   ActualCosts		decimal(16,5)   NOT NULL,
   CurrEstHours		decimal(16,5)   NOT NULL,
   CurrEstUnits		decimal(16,5)   NOT NULL,
   CurrEstCosts		decimal(16,5)   NOT NULL,
   ProjHours		decimal(16,5)   NOT NULL,
   ProjUnits		decimal(16,5)   NOT NULL,
   ProjCosts		decimal(16,5)   NOT NULL,
   ForecastHours	decimal(16,5)   NOT NULL,
   ForecastUnits	decimal(16,5)   NOT NULL,
   ForecastCosts	decimal(16,5)   NOT NULL,
   RemainCmtdUnits	decimal(16,5)   NOT NULL,
   RemainCmtdCosts	decimal(16,5)   NOT NULL,
   Plugged			char(1)         NOT NULL,
   Item				varchar(16)		NULL
)

CREATE UNIQUE INDEX bitmpProjInit ON #tmpProjInit (Co, Job, PhaseGroup, Phase, CostType)


---- insert rows into temp table for the job
insert into #tmpProjInit select p.JCCo, p.Job, p.PhaseGroup, p.Phase, p.CostType,
	isnull(sum(p.ActualHours),0), isnull(sum(p.ActualUnits),0), isnull(sum(p.ActualCost),0),
	isnull(sum(p.CurrEstHours),0), isnull(sum(p.CurrEstUnits),0), isnull(sum(p.CurrEstCost),0),
	isnull(sum(p.ProjHours),0), isnull(sum(p.ProjUnits),0), isnull(sum(p.ProjCost),0),
	isnull(sum(p.ForecastHours),0), isnull(sum(p.ForecastUnits),0), isnull(sum(p.ForecastCost),0),
	isnull(sum(p.RemainCmtdUnits),0), isnull(sum(p.RemainCmtdCost),0), h.Plugged, c.Item
from bJCCP as p with (nolock)
join bJCCH h with (nolock) on h.JCCo=p.JCCo and h.Job=p.Job and h.PhaseGroup=p.PhaseGroup and h.Phase=p.Phase and h.CostType=p.CostType
join bJCJP c with (nolock) on c.JCCo=p.JCCo and c.Job=p.Job and c.PhaseGroup=p.PhaseGroup and c.Phase=p.Phase
join bJCJM j with (nolock) on j.JCCo=p.JCCo and j.Job=p.Job
join JCCO o with (nolock) on o.JCCo=p.JCCo
where p.JCCo=@jcco and p.Mth<=@mth and p.Job=@job
and ((@inactivephases = 'N' and c.ActiveYN = 'Y' and h.ActiveYN = 'Y') or @inactivephases = 'Y')
---- issue #25569
and (j.JobStatus = 1 or (j.JobStatus = 2 and o.PostSoftClosedJobs = 'Y') or (j.JobStatus = 3 and o.PostClosedJobs = 'Y'))
Group by p.JCCo, p.Job, p.PhaseGroup, p.Phase, p.CostType, h.Plugged, c.Item


---- declare cursor on #tmpProjInit for Projection calculations and initialize
declare bctmpProjInit cursor local fast_forward 
	for select Co, Job, PhaseGroup, Phase, CostType, ActualHours, ActualUnits, ActualCosts,
			CurrEstHours, CurrEstUnits, CurrEstCosts, ProjHours, ProjUnits, ProjCosts,
			ForecastHours, ForecastUnits, ForecastCosts, RemainCmtdUnits, RemainCmtdCosts,
			Plugged, Item
from #tmpProjInit

---- open cursor and set cursor flag
open bctmpProjInit
select @opencursor = 1, @initcount = 0

---- loop through all rows in #tmpProjInit
tmp_calc_loop:
fetch next from bctmpProjInit into @cco, @cjob, @cphasegroup, @cphase, @ccosttype, @cactualhours, 
		@cactualunits, @cactualcosts, @ccurresthours, @ccurrestunits, @ccurrestcosts, @cprojhours,
		@cprojunits, @cprojcosts, @prevforecasthours, @prevforecastunits, @prevforecastcosts,
		@cremaincmtdunits, @cremaincmtdcosts, @cplugged, @citem

if @@fetch_status = -1 goto tmp_calc_end
if @@fetch_status <> 0 goto tmp_calc_loop

---- get minimum percentage
select @minpct=isnull(ProjMinPct,0) from JCJP with (nolock)
where JCCo=@cco and Job=@cjob and PhaseGroup=@cphasegroup and Phase=@cphase
if @minpct = 0 set @minpct = @cminpct

---- get previous projected and forecasted values
select @prevprojhours=isnull(sum(ProjHours),0),
		@prevprojunits=isnull(sum(ProjUnits),0),
		@prevprojcosts=isnull(sum(ProjCost),0)
from JCCP WITH (NOLOCK) where JCCo=@cco and Mth<=@mth and Job=@cjob
and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype

---- set previous unit cost
select @prevprojuc = case when @prevprojunits <> 0 then (@prevprojcosts/@prevprojunits) else 0 end
select @prevforecastuc = case when @prevforecastunits<>0 then (@prevforecastcosts/@prevforecastunits) else 0 end

select @jcch_plugged = isnull(@cplugged,'N')

---- get future change order values #126236
---- only when future change order costs are included
select @pmolcount=Count(*)
from bPMOL WITH (NOLOCK) where PMCo=@jcco and Project=@job and PhaseGroup=@phasegroup and Phase=@cphase
and CostType=@ccosttype and InterfacedDate is null
if @pmolcount > 0
	begin
	---- #137604
	select @includedcohours=isnull(sum(l.EstHours),0),
			----#137604
			@includedcounits=isnull(sum(case when l.UM=h.UM then l.EstUnits else 0 end),0),
			@includedcocosts=isnull(sum(l.EstCost),0)
	from bPMOL as l with (nolock)
	join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	----#137604
	join bJCCH h with (nolock) on h.JCCo=l.PMCo and h.Job=l.Project and h.PhaseGroup=l.PhaseGroup
	and h.Phase=l.Phase and h.CostType=l.CostType
	where l.PMCo=@jcco and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@cphase
	and l.CostType=@ccosttype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end


---- get any future change order add-on costs. these will
---- come from bPMOB for a PMCo and Project - #129669
if exists(select top 1 1 from bPMOB with (nolock) where PMCo=@jcco and Project=@job)
	begin
	---- get future change order cost for display
	select @includedcocosts = @includedcocosts + isnull(sum(f.AmtToDistribute),0)
	from bPMOB as f with (nolock)
	join bPMOI i with (nolock) on i.PMCo=f.PMCo and i.Project=f.Project and i.PCOType=f.PCOType
	and i.PCO=f.PCO and i.PCOItem=f.PCOItem
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where f.PMCo=@jcco and f.Project=@job and f.PhaseGroup=@phasegroup and f.Phase=@cphase
	and i.ACOItem is null and f.CostType=@ccosttype
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end


---- calculate projection and forecast
select @esthours = @ccurresthours, @estunits = @ccurrestunits, @estcosts = @ccurrestcosts
select @acthours = @cactualhours, @actunits = @cactualunits, @actcosts = @cactualcosts


---- #126236
---- added future change order values to estimate values that are flagged to be included in projection
select @esthours = @esthours + @includedcohours
select @estunits = @estunits + @includedcounits
select @estcosts = @estcosts + @includedcocosts



if @projmethod = '2'
	begin
	select @actunits = @cactualunits + @cremaincmtdunits, @actcosts = @cactualcosts + @cremaincmtdcosts
	end

select @prevestuc = case when @estunits <> 0 then (@estcosts/@estunits) else 0 end
select @prevactuc = case when @actunits <> 0 then (@actcosts/@actunits) else 0 end

select @projhours = @acthours, @projunits = @actunits, @projcosts = @actcosts

select @projfinaluc = case when @projunits <> 0 then (@projcosts/@projunits) else 0 end

select @projfinalhours = @projhours - @prevprojhours,
		@projfinalunits = @projunits - @prevprojunits,
		@projfinalcosts = @projcosts - @prevprojcosts

select @forecastfinalhours=@acthours,
		@forecastfinalunits=@actunits,
		@forecastfinalcosts=@actcosts

select @forecastfinaluc = case when @forecastfinalunits<>0 then (@forecastfinalcosts/@forecastfinalunits) else 0 end


---- if projection exists in bJCPB batch table then delete
delete from bJCPB
where Co=@cco and Mth=@mth and BatchId=@batchid and Job=@cjob
and PhaseGroup=@cphasegroup and Phase=@cphase and CostType=@ccosttype

---- if we have a role for the user and phases have been assigned to this user for the
---- cost projections process then we need to not buy out the phase cost type #135527
if isnull(@UserRole,'') <> ''
	begin
	if not exists(select 1 from dbo.JCJPRoles p with (nolock) where p.JCCo=@jcco and p.Job=@job
			and p.PhaseGroup=@cphasegroup and p.Phase=@cphase and p.Process='C'
			and PATINDEX('%' + p.Role + '%', @UserRole) <> 0)
			----and charindex( convert(varchar(20),p.Role) + ';', @UserRole) <> 0) #140202
		begin
		goto tmp_calc_loop
		end
	end
	
----select @batchseq=isnull(max(BatchSeq),0) from bJCPB with (nolock) where Co=@cco and Mth=@mth and BatchId=@batchid
----select @batchseq = @batchseq +1
---- add projection to batch
insert into bJCPB (Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType, ActualDate,
	ProjFinalUnits, ProjFinalHrs, ProjFinalCost, ProjFinalUnitCost, PrevProjUnits, PrevProjHours,
	PrevProjCost, PrevProjUnitCost, ForecastFinalUnits, ForecastFinalHrs, ForecastFinalCost,
	ForecastFinalUnitCost, PrevForecastUnits, PrevForecastHours, PrevForecastCost,
	PrevForecastUnitCost, Plugged, Item, OldPlugged)
select @jcco, @mth, @batchid, isnull(max(a.BatchSeq),0) + 1, @cjob, @cphasegroup, @cphase, @ccosttype, @actualdate,
	@forecastfinalunits, @forecastfinalhours, @forecastfinalcosts, @forecastfinaluc, @prevprojunits,
	@prevprojhours, @prevprojcosts, @prevprojuc, @forecastfinalunits, @forecastfinalhours,
	@forecastfinalcosts, @forecastfinaluc, @prevforecastunits, @prevforecasthours,
	@prevforecastcosts, @prevforecastuc, @plugged, @citem, isnull(@jcch_plugged,'N')
from bJCPB a where a.Co=@cco and a.Mth=@mth and a.BatchId=@batchid


select @initcount=@initcount + 1
goto tmp_calc_loop




tmp_calc_end:
	select @msg = convert(varchar(5),isnull(@initcount,0)) + ' projections initialized.', @rcode=0



bspexit:
	if @opencursor = 1
		begin
		close bctmpProjInit
		deallocate bctmpProjInit
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjJobComplete] TO [public]
GO
