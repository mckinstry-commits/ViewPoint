SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************/
CREATE  proc [dbo].[vspJCVCOSTTYPEForPM]
/***********************************************************
 * Created By:	GF 01/06/2005 (6.x)
 * Modified By: GF 01/06/2006 - issue #119595 added OrigUnitCost, UnitPerHour outputs
 *				GF 08/24/2007 - 6.x per Julie need current and original estimated hours
 *				GF 11/28/2007 - issue #25569 added validation for closed jobs using JCCO.PostClosedJobs
 *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
 *
 *
 *
 *
 * USAGE:
 * this is just a modification of VCOSTTYPE to return needed parameters for PM.
 *
 *
 * INPUT PARAMETERS
 * co         Job Cost Company
 * job        Valid job
 * phase      phase to validate
 * costtype   cost type to validate(either CT or CT Abbrev)
 * override   optional if set to 'Y' will override 'lock phases' flag from JCJM
 *
 * OUTPUT PARAMETERS
 * desc	         abbreviated cost type description
 * um            unit of measure from JCCH or JCPC.
 * trackhrs      Y if Tracking hours, otherwise N
 * costtypeout   Actual costtype validated
 * retainpct	 Retainage percent
 * currestunits	 Current Estimate Units
 * currestcost	 Current Estimate Cost
 * origunitcost		Original Unit Cost
 * origunithours	Original Units per hour
 * origum			Original UM
 * origunits		Original Units
 * origcosts		Original Costs
 * activeyn			JCCH Active Flag
 * retainpct		JCCI Retainage Pct
 * @curresthours	JCCP Current Estimated Hours
 * @orighours		JCCH Original Hours
 * msg           cost type abbreviation, or error message.
 *
 * It will validate by first checking in JCCT then JCCH
 *
 * This uses bspVJCCOSTTYPE to validate Cost Type
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@jcco bCompany = null, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null,
 @costtype varchar(10) = null, @override Char(1) = 'N', @costtypeout bJCCType = null output,
 @ctdesc varchar(255) = null output, @billflag char(1) = null output, @um bUM = null output,
 @itemunitflag bYN = null output, @phaseunitflag bYN = null output, @trackhours bYN = 'N' output,
 @currestunits bUnits = 0 output, @currestcost bDollar = 0 output, @origunitcost bUnitCost = 0 output,
 @orighoursunit bUnitCost = 0 output, @origum bUM = null output, @origunits bUnits = 0 output,
 @origcosts bDollar = 0 output, @activeflag bYN = 'Y' output, @retainpct bPct=null output,
 @curresthours bHrs = 0 output, @orighours bHrs = 0 output, @msg varchar(255) = null output)
as
set nocount on
-- #142350 - removing @PhaseGroup
DECLARE @rcode int,
		@exists bYN,
		@pphase bPhase,
		@pgroup bGroup,
		@validcnt int

select @rcode = 0, @currestunits = 0, @currestcost = 0, @origunitcost = 0, @orighoursunit = 0,
		@curresthours = 0, @orighours = 0, @msg = '', @validcnt = 0

if @phasegroup is null
   	begin
   	select @msg = 'Missing Phase Group!', @rcode = 1
   	goto bspexit
   	end
   
if @costtype is null
   	begin
   	select @msg = 'Missing Cost Type!', @rcode = 1
   	goto bspexit
   	end

if @job in ('null', 'Null', 'NULL')
	begin
	select @job = null
	end

if @phase in ('null', 'Null', 'NULL')
	begin
	select @phase = null
	end


---- if no job or phase then validate cost type only
if isnull(@job,'') = '' or isnull(@phase,'') = ''
	begin
	exec @rcode = dbo.bspJCCostTypeVal @phasegroup, @costtype, @costtypeout output, @ctdesc output, @msg output
	if @rcode = 0 select @msg = @ctdesc
	---- get track hours flag
	select @trackhours=isnull(TrackHours,'N')
	from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtypeout
	goto bspexit
	end



---- validate job phase cost type
exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, @override, 
   			@pgroup output, @pphase output, @ctdesc output, @billflag output, @um output,
   			@itemunitflag output, @phaseunitflag output, @exists output, @costtypeout output, @msg output

if @rcode = 0 select @msg = @ctdesc

---- get track hours flag
select @trackhours=isnull(TrackHours,'N')
from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtypeout

---- get current estimate values
select @currestunits=sum(CurrEstUnits), @currestcost=sum(CurrEstCost), @curresthours=sum(CurrEstHours)
from JCCP with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtypeout

---- get original estimates from JCCH if exists
select @activeflag=ActiveYN, @origum=UM, @orighours=OrigHours, @origunits=OrigUnits, @origcosts=OrigCost
from JCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtypeout
if @@rowcount = 0
	begin
	select @activeflag = 'Y'
	end
else
	begin
	if @origunits <> 0 --and isnull(@um,'LS') <> 'LS'
		select @origunitcost = @origcosts / @origunits
	if @trackhours = 'Y' and @origunits <> 0
		select @orighoursunit = @orighours / @origunits
	end

---- try to get contract item retainage pct
select @retainpct=isnull(i.RetainPCT, 0)
from JCCI i with (nolock) join JCJM j with (nolock) on j.JCCo=i.JCCo and j.Contract=i.Contract
where j.JCCo=@jcco and j.Job=@job and i.JCCo=@jcco
and i.Item = (select Item from JCJP with (nolock) where JCCo=@jcco and Job=@job 
   						and PhaseGroup=@phasegroup and Phase=@pphase)
if @@rowcount = 0
	begin
	select @retainpct=isnull(m.RetainagePCT, 0) 
	from JCCM m with (nolock) join JCJM j with (nolock) on j.JCCo=m.JCCo and j.Contract=m.Contract
	where j.JCCo=@jcco and j.Job=@job
	end

if @rcode = 0 select @msg = @ctdesc
if @rcode <> 0 goto bspexit


---- validate job status, cannot add to soft, hard closed jobs if JCCO flag does not allow
if not exists(select top 1 1 from JCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
					and Phase=@phase and CostType=@costtypeout)
	begin
	exec @rcode = dbo.vspJCJMClosedStatusVal @jcco, @job, @msg output
	end

if @rcode = 0 select @msg = @ctdesc


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCVCOSTTYPEForPM] TO [public]
GO
