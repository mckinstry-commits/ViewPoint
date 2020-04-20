SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.[vspPMJCCHGetEstimates] ******/
CREATE  proc [dbo].[vspPMJCCHGetEstimates]
/*************************************
 * Created By:	GF 10/05/2006 6.x
 * Modified By:
 *
 *
 * USAGE:
 * Called from any form where PMOrigEstPanel has been added to form.
 * Returns original and current estimates from JCCH/JCCP for the
 * JCCo/Job/Phase/CostType.
 *
 *
 * INPUT PARAMETERS
 * @jcco			JC Company
 * @job				JC Job
 * @phasegroup		Phase Group
 * @phase			Phase
 * @costtype		Cost Type
 *
 * Success returns:
 * @rcode = 0
 * @origum			JCCH.UM
 * @origunits		JCCH.OrigUnits
 * @orighours		JCCH.OrigHours
 * @origcost		JCCH.OrigCost
 * @currestunits	JCCP.Units
 * @currestcosts	JCCP.Costs
 * @activeyn		JCCH.ActiveYN
 *
 * Error returns:
 *	1 - no message
 **************************************/
(@jcco bCompany, @job bJob, @phasegroup bGroup = null, @phase bPhase, @costtype bJCCType,
 @origum bUM = null output, @origunits bUnits = 0 output, @orighours bHrs = 0 output,
 @origcost bDollar = 0 output, @currunits bUnits = 0 output, @currcosts bDollar = 0 output,
 @active bYN = 'Y' output)
as
set nocount on

declare @rcode int

select @rcode = 0, @origum = '', @origunits = 0, @orighours = 0, @origcost = 0,
		@currunits = 0, @currcosts = 0, @active = 'Y'

if @jcco is null or @job is null or @phase is null or @costtype is null goto bspexit

---- if @phasegroup is null get from HQCo for @jcco
if @phasegroup is null
	begin
	select @phasegroup=PhaseGroup from HQCO with (nolock) where HQCo=@jcco
	if @@rowcount = 0 goto bspexit
	end

---- get JCCH info
select @origum=UM, @origunits=OrigUnits, @orighours=OrigHours, @origcost=OrigCost, @active=ActiveYN
from JCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
---- get current estimate values
select @currunits=sum(CurrEstUnits), @currcosts=sum(CurrEstCost)
from JCCP with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMJCCHGetEstimates] TO [public]
GO
