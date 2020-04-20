SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   proc [dbo].[vspJCVCOSTTYPEForCommit]
/***********************************************************
 * Created By:	GF	02/18/2010 - (AUS) committed budget model
 * Modified By: AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
 *
 *
 * USAGE:
 * this is just a modification of VCOSTTYPE used in JCJPEST.
 *
 * PM Modification:
 * Override flag may be set to 'P'.  This will cause the Cost Type to only be validated in
 * JCCT and if in JCCH, will not care if it is inactive.  It will also act like lock phases override is 'Y'.
 * Override flag may be set to 'S'. Used from PMSubcontract and PMSLItems to validate cost type to JCCH
 *                                  using the PM company subcontract option. If 1 works like locked phases.
 * Override flag may be set to 'M'. Used from PMMaterial and PMPOItems to validate cost type to JCCH
 *                                  using the PM company material option. If 1 works like locked phases.
 *
 *
 * INPUT PARAMETERS
 *    co         Job Cost Company
 *    job        Valid job
 *    phasegroup Phase Group
 *    phase      phase to validate
 *    costtype   cost type to validate(either CT or CT Abbrev)
 *    override   optional if set to 'Y' will override 'lock phases' flag from JCJM
 *
 * OUTPUT PARAMETERS
 *    desc	    	abbreviated cost type description
 *    um            unit of measure from JCCH or JCPC.
 *    trackhrs      Y if Tracking hours, otherwise N
 *    costtypeout   Actual costtype validated
 *    retainpct	    Retainage percent
 *	  SourceStatus	Status of Phase/CostType from JCCH
 *    msg           cost type abbreviation, or error message. *
 *    It will validate by first checking in JCCT then JCCH
 *
 *    This uses bspVJCCOSTTYPE to validate Cost Type, then
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null,
 @costtype varchar(10), @override bYN = 'N', @ctdesc varchar(60)=null output,
 @um bUM output, @trackhours bYN ='N' output, @costtypeout bJCCType =null output,
 @sourcestatus char(1) output, @billflag char(1) output, 
 @ccorig_budget bDollar = 0 OUTPUT, @ccrevise_budget bDollar = 0 OUTPUT, @ccvariation bDollar = 0 OUTPUT,
 @ctorig_budget bDollar = 0 OUTPUT, @ctrevise_budget bDollar = 0 OUTPUT, @ctvariation bDollar = 0 OUTPUT, 
 @orig_commit bDollar = 0 OUTPUT, @curr_commit bDollar = 0 OUTPUT,
 @contingency bDollar = 0 OUTPUT, @gainloss bDollar = 0 OUTPUT,
 @msg varchar(255) output)
as
set nocount on
--#142350 - renmaing @PhaseGroup
DECLARE @rcode int,
		@pphase bPhase,
		@itemunitflag bYN,
		@phaseunitflag bYN,
		@item bContractItem,
		@PhaseGrp tinyint,
		@exists bYN

select @rcode = 0, @trackhours='Z', @sourcestatus = 'J'
SET @ccorig_budget = 0
SET @ctorig_budget = 0
SET @ccrevise_budget = 0
SET @ctrevise_budget = 0
SET @ccvariation = 0
SET @ctvariation = 0
SET @curr_commit = 0
SET @orig_commit = 0
SET @gainloss = 0
SET @contingency = 0

if isnull(@costtype,'') = '' or isnull(@costtype,'') = 'NEW' goto bspexit
    
exec @rcode =  bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, @override, @PhaseGrp output, @pphase output,
		@ctdesc output, @billflag output, @um output, @itemunitflag output, @phaseunitflag output, @exists output,
		@costtypeout output, @msg output
if @rcode = 0
	begin
	-- cost type info
	select @trackhours=TrackHours, @ctdesc=Description, @msg=Description
	from bJCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtypeout
	-- cost header info
	select @sourcestatus=SourceStatus
	from bJCCH with (nolock) where JCCo=@jcco and Job=@job and Phase=@phase and CostType=@costtypeout
	
	---- validate job status, cannot add to soft, hard closed jobs if JCCO flag does not allow
	if not exists(select top 1 1 from JCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
						and Phase=@phase and CostType=@costtypeout)
		begin
		exec @rcode = dbo.vspJCJMClosedStatusVal @jcco, @job, @msg output
		end
	end

---- get phase budget totals
SELECT @ccorig_budget = SUM(OrigEstCost), @ccrevise_budget = SUM(CurrEstCost)
FROM dbo.JCCP WITH (NOLOCK) WHERE JCCo=@jcco AND Job=@job AND Phase=@phase
IF @@ROWCOUNT = 0 SELECT @ccorig_budget = 0, @ccrevise_budget = 0
IF @ccorig_budget IS NULL SET @ccorig_budget = 0
IF @ccrevise_budget IS NULL SET @ccrevise_budget = 0
---- set variation as revised - original budget
SET @ccvariation = @ccrevise_budget - @ccorig_budget

---- get cost type totals
SELECT @ctorig_budget = SUM(OrigEstCost), @ctrevise_budget = SUM(CurrEstCost)
FROM dbo.JCCP WITH (NOLOCK) WHERE JCCo=@jcco AND Job=@job AND Phase=@phase AND CostType=@costtypeout
IF @@ROWCOUNT = 0 SELECT @ctorig_budget = 0, @ctrevise_budget = 0
IF @ctorig_budget IS NULL SET @ctorig_budget = 0
IF @ctrevise_budget IS NULL SET @ctrevise_budget = 0
---- set variation as revised - original budget
SET @ctvariation = @ctrevise_budget - @ctorig_budget


IF @orig_commit IS NULL SET @orig_commit = 0
---- get current committment
SELECT @curr_commit = SUM(Amount)
FROM dbo.JCPR WITH (NOLOCK) WHERE JCCo=@jcco AND Job=@job AND Phase=@phase AND CostType=@costtypeout AND BudgetCode = 'COMM'
IF @@rowcount = 0 SET @curr_commit = 0
IF @curr_commit IS NULL SET @curr_commit = 0

---- get contingency total
SELECT @contingency = SUM(Amount)
FROM dbo.JCPR WITH (NOLOCK) WHERE JCCo=@jcco AND Job=@job AND Phase=@phase AND CostType=@costtypeout AND BudgetCode = 'CONT'
IF @@rowcount = 0 SET @contingency = 0
IF @contingency IS NULL SET @contingency = 0

---- calculate gain/loss
SET @gainloss = ISNULL(@ctrevise_budget,0) - ISNULL(@curr_commit,0) - ISNULL(@contingency,0)
IF @gainloss IS NULL SET @gainloss = 0

bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJCVCOSTTYPEForCommit] TO [public]
GO
