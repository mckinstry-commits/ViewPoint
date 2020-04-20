SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE  proc [dbo].[bspJCProjUpdateData]
/***********************************************************
* CREATED By:	GF 02/23/2004
* MODIFIED BY: TV - 23061 added isnulls
*				GF - #24386 need to use different calc when no actual values for linked cost types
*				GF - issue #26527 use @pctcmplunits for @pctcmplcosts when 0 and units <> 0
*				GF - issue #27183 use JCUO.ProjInactivePhases in query
*				DANF - Update Stored procedure for the removal of the JCPT table.
*				GF 02/05/2008 - issue #122799 use main ct plugged value if no calc cost for linked 
*				GF 02/08/2008 - issue #127060 changed bPct to float for rounding problems
*				GF 03/23/2008 - issue #126993 added Item to JCPB
*				GF 07/25/2008 - issue #129120 when plug with no actual for main or linked, use constant to calculate pct.
*				CHS	10/02/2008	- issue #126236
*				GF 05/15/2009 - issue #133491 skip if linked cost type is bought out
*
*
* USAGE:
*  Updates BuyOutFlag and ProjNotes in JCCH.
*  Called from frmJCProjection.
*
* INPUT PARAMETERS
*	JCCo		JC Company
*	Job			JC Job
*	PhaseGroup	PhaseGroup
*	Phase		Phase
*	CostType	Cost Type
*	Mth			Batch month
*	BatchId		JCPB BatchId
*	Plugged		JC Plugged Flag
*	BuyOutYN	BuyOut Flag
*  ProjNotes   Projection Notes
*
* OUTPUT PARAMETERS
*   @msg
*  
* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @costtype bJCCType,
 @mth bMonth, @batchid bBatchID, @plugged bYN, @buyout bYN, @projnotes varchar(Max), 
 @pctcalcunits float, @pctcalchours float, @pctcalccosts float, @projmethod char(1),
 @prevprojflag bYN, @msg varchar(255) output)
as
set nocount on

declare @rcode integer, @opencursor int, @linkcosttype tinyint, @linkactive bYN, 
		@curresthours bHrs, @currestunits bUnits, @currestcosts bDollar, 
		@origesthours bHrs, @origestunits bUnits, @origestcosts bDollar,
		@actualhours bHrs, @actualunits bUnits, @actualcosts bDollar,
		@projhours bHrs, @projunits bUnits, @projcosts bDollar,
		@forecasthours bHrs, @forecastunits bUnits, @forecastcosts bDollar,
		@currprojhours bHrs, @currprojunits bUnits, @currprojcosts bDollar,
		@prevprojhours bHrs, @prevprojunits bUnits, @prevprojcosts bDollar,
		@projfinalhours bHrs, @projfinalunits bUnits, @projfinalcosts bDollar,
		@prevforecasthours bHrs, @prevforecastunits bUnits, @prevforecastcosts bDollar,
		@forecastfinalhours bHrs, @forecastfinalunits bUnits, @forecastfinalcosts bDollar,
		@remaincmtdunits bUnits, @remaincmtdcosts bDollar, @actualcmtdunits bUnits, 
		@actualcmtdcosts bDollar, @prevprojuc bUnitCost, @prevforecastuc bUnitCost, 
		@projuc bUnitCost, @forecastuc bUnitCost, @actualdate bDate, @esthours bHrs,
		@estunits bUnits, @estcosts bDollar, @acthours bHrs, @actunits bUnits, 
		@actcosts bDollar, @pctcalc float, @minpct bPct, @linkplugged bYN,
		@noactunits bYN, @noacthours bYN, @noactcosts bYN, @inactivephases bYN,
		@username bVPUserName, @batchseq int, @ct_pluggedcost bDollar,
		@item bContractItem, @includedcohours bHrs, @includedcounits bUnits,
		@includedcocosts bDollar, @pmolcount int, @cbuyoutyn bYN ----#126236

select @rcode = 0, @opencursor = 0, @msg = '', @includedcohours = 0, @includedcounits = 0,
		@includedcocosts = 0, @pmolcount = 0 ----#126236

---- first if the input parameters for percent complete are not zero, divide by 100
if isnull(@pctcalcunits,0) <> 0
	begin
	select @pctcalcunits = abs(@pctcalcunits /100)
	end
else
	begin
	select @pctcalcunits = 0
	end

if isnull(@pctcalchours,0) <> 0
	begin
	select @pctcalchours = abs(@pctcalchours /100)
	end
else
	begin
	select @pctcalchours = 0
	end

if isnull(@pctcalccosts,0) <> 0
	begin
	select @pctcalccosts = abs(@pctcalccosts /100)
	end
else
	begin
	select @pctcalccosts = 0
	end


---- update JCCH buyout and notes first
if (select BuyOutYN from bJCCH with (nolock) where JCCo=@jcco and Job=@job
		and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype) <> @buyout
	or
	(select isnull(ProjNotes,'') from bJCCH with (nolock) where JCCo=@jcco and Job=@job
		and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype) <> isnull(@projnotes,'')
	begin
	Update bJCCH set BuyOutYN=@buyout, ProjNotes=@projnotes
	where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
	end

select @username = InUseBy
from HQBC with (nolock) where Co=@jcco and Mth=@mth and BatchId=@batchid

---- get JC user options
select @inactivephases = ProjInactivePhases
from bJCUO with (nolock) where JCCo=@jcco and Form='JCProjection' and UserName=@username
if isnull(@inactivephases,'') = '' set @inactivephases = 'N'

---- get minimum percentage and Item
select @minpct=isnull(ProjMinPct,0), @item=Item
from bJCJP with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase
if @minpct = 0
	begin
	select @minpct=isnull(ProjMinPct,0)
	from bJCJM WITH (NOLOCK) where JCCo=@jcco and Job=@job
	end

if isnull(@minpct,0) = 0
	begin
	select @minpct = 0
	end

---- get info from JCPB for main cost type
select @actualdate=ActualDate, @ct_pluggedcost=ProjFinalCost
from bJCPB with (nolock) where Co=@jcco and Mth=@mth and BatchId=@batchid
and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
if isnull(@actualdate,'') = ''
	begin
	select @actualdate=min(ActualDate) from JCPB with (nolock)
	where Co=@jcco and Mth=@mth and BatchId=@batchid
	end


---- check JCCT to see if there are any cost types linked to this cost type. If none exit
if not exists(select top 1 1 from bJCCT with (nolock) where PhaseGroup=@phasegroup and LinkProgress=@costtype)
	begin
	goto bspexit
	end

---- if the pctcalcunits, hours, or costs is zero check to see if actual values and estimate values
---- if no actuals but estimates exist and there is a projected final then need to calculate
---- percentage using projected / estimated
select @noactunits = 'N', @noacthours = 'N', @noactcosts = 'N'
if @pctcalcunits = 0 or @pctcalchours = 0 or @pctcalccosts = 0
	begin
	select @actualunits=ActualUnits, @actualcmtdunits=ActualCmtdUnits, @actualhours=ActualHours,
			@actualcosts=ActualCost, @actualcmtdcosts=ActualCmtdCost,
			@curresthours=CurrEstHours, @currestunits=CurrEstUnits, @currestcosts=CurrEstCost,
			@projfinalhours=ProjFinalHrs, @projfinalunits=ProjFinalUnits, @projfinalcosts=ProjFinalCost
	from bJCPB with (nolock) where Co=@jcco and Job=@job and PhaseGroup=@phasegroup 
	and Phase=@phase and CostType=@costtype and Mth=@mth and BatchId=@batchid
	-- -- check units percent complete
	if @pctcalcunits = 0 and @currestunits <> 0 and @projfinalunits <> 0
		begin
		select @pctcalcunits = @projfinalunits / @currestunits, @noactunits = 'Y'
		end
	-- -- check hours percent complete
	if @pctcalchours = 0 and @curresthours <> 0 and @projfinalhours <> 0
		begin
		select @pctcalchours = @projfinalhours / @curresthours, @noacthours = 'Y'
		end
	-- -- check costs percent complete
	if @pctcalccosts = 0 and @currestcosts <> 0 and @projfinalcosts <> 0
		begin
		select @pctcalccosts = @projfinalcosts / @currestcosts, @noactcosts = 'Y'
		end
	end

---- issue #26527
if @pctcalchours = 0 and @pctcalcunits <> 0
	begin
	select @pctcalchours = @pctcalcunits, @noacthours = 'Y'
	end
if @pctcalccosts = 0 and @pctcalcunits <> 0
	begin
	select @pctcalccosts = @pctcalcunits, @noactcosts = 'Y'
	end

---- issue #129120
if @projmethod = '2'
	begin
	if @pctcalcunits = 0 and @actualcmtdunits = 0 set @noactunits = 'Y'
	if @pctcalchours = 0 and @actualhours = 0 set @noacthours = 'Y'
	if @pctcalccosts = 0 and @actualcmtdcosts = 0  set @noactcosts = 'Y'
	end
else
	begin
	if @pctcalcunits = 0 and @actualunits = 0 set @noactunits = 'Y'
	if @pctcalchours = 0 and @actualhours = 0 set @noacthours = 'Y'
	if @pctcalccosts = 0 and @actualcosts = 0  set @noactcosts = 'Y'
	end


---- declare cursor on bJCCT for linked cost types
declare bcJCCT cursor LOCAL FAST_FORWARD for select CostType
from bJCCT where PhaseGroup=@phasegroup and LinkProgress=@costtype
group by CostType

---- open bJCCT cursor
open bcJCCT
select @opencursor = 1

---- process through all entries in batch
JCCT_loop:
fetch next from bcJCCT into @linkcosttype

if @@fetch_status = -1 goto JCCT_end
if @@fetch_status <> 0 goto JCCT_loop


if @linkcosttype = @costtype goto JCCT_loop

---- check if cost type exists for Job-Phase in bJCCH. Get needed data
select @linkactive=ActiveYN, @linkplugged=Plugged, @cbuyoutyn=BuyOutYN ---- #133491
from bJCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
and Phase=@phase and CostType=@linkcosttype

---- per carol, if linked not in JCCH skip it
if @@rowcount = 0 goto JCCT_loop

---- #133491
if @cbuyoutyn = 'Y' goto JCCT_loop

---- do not insert/update linked cost type if JCCH.ActiveYN flag is 'N'
if @linkactive = 'N' and @inactivephases = 'N' goto JCCT_loop

---- reset values
select @actualunits=0, @actualcmtdunits=0, @actualhours=0, @actualcmtdcosts=0, @actualcosts=0,
		@currestunits=0, @curresthours=0, @currestcosts=0
---- use bJCPB
select @actualunits=ActualUnits, @actualcmtdunits=ActualCmtdUnits, @actualhours=ActualHours,
		@actualcosts=ActualCost, @actualcmtdcosts=ActualCmtdCost, @curresthours=CurrEstHours, 
		@currestunits=CurrEstUnits, @currestcosts=CurrEstCost
from bJCPB with (nolock) where Co=@jcco and Job=@job and PhaseGroup=@phasegroup 
and Phase=@phase and CostType=@linkcosttype and Mth=@mth and BatchId=@batchid
if @@rowcount <> 0
begin
if @projmethod = '2'
	begin
	select @actualunits = @actualcmtdunits, @actualcosts = @actualcmtdcosts
	end

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

if @buyout = 'Y'
	begin
	select @projunits = @actualunits, @projhours=@actualhours, @projcosts=@actualcosts
	end

if abs(@projhours) < abs(@actualhours) select @projhours = @actualhours
if abs(@projunits) < abs(@actualunits) select @projunits = @actualunits
if abs(@projcosts) < abs(@actualcosts) select @projcosts = @actualcosts

------ calculate using estimate if no projection and @pctcalcunits <> 0
------ if @pctcalcunits <> 0 and @projunits = 0 and @actunits = 0 and @currestunits <> 0
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

---- check main cost type to see if we need to set projected to estimated (100%)
if @noactcosts = 'Y' and @noacthours = 'Y' and @noactunits = 'Y'
	begin
	if exists(select top 1 1 from bJCPB with (nolock) where Co=@jcco and Job=@job and Mth=@mth
				and BatchId=@batchid and Phase=@phase and CostType=@costtype and ActualCost = 0
				and ActualHours = 0 and ActualUnits = 0
				and ProjFinalUnits = (CurrEstUnits + IncludedUnits)
				and ProjFinalHrs = (CurrEstHours + IncludedHours)
				and ProjFinalCost = (CurrEstCost + IncludedCOs))
		begin
		select @projunits = @currestunits, @projhours = @curresthours, @projcosts=@currestcosts
		end
	end


	---- update JCPT - will update JCPB in trigger
	update bJCPB set ProjFinalUnits=@projunits, ProjFinalHrs=@projhours, ProjFinalCost=@projcosts, Plugged=@plugged
	where Co=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase 
	and CostType=@linkcosttype and Mth=@mth and BatchId=@batchid

	goto JCCT_loop
	end




JCCT_end:
	if @opencursor = 1
		begin
		close bcJCCT
		deallocate bcJCCT
		set @opencursor = 0
		end





bspexit:
	if @opencursor = 1
		begin
		close bcJCCT
		deallocate bcJCCT
		set @opencursor = 0
		end

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJCProjUpdateData] TO [public]
GO
