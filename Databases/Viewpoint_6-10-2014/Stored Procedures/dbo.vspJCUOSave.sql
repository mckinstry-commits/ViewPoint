SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE   proc [dbo].[vspJCUOSave]
/***********************************************************
* CREATED BY:	DANF 07/07/2006
* MODIFIED BY:	GF 03/27/2008 -  issue #126993 added 2 columns to bJCUO
*
*
*
*
* USAGE:
*  Updates the user options for projections
*
*
* INPUT PARAMETERS
*	JCCo		JC Company
*	Form		JC Form Name
*	UserName	VP UserName
*
* OUTPUT PARAMETERS
*   @msg

* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@jcco bCompany, 
@form varchar(30), 
@username bVPUserName, 
@changedonly bYN, --
@itemunitsonly bYN, --
@phaseunitsonly bYN, --
@showlinkedct bYN, --
@showfutureco bYN, --
@remainunits bYN, --
@remainhours bYN, --
@remaincosts bYN, --
@openform bYN,  --
@phaseoption char(1), --
@begphase bPhase, --
@endphase bPhase, --
@costtypeoption char(1), --
@selectedcosttypes varchar(1000), --
@visiblecolumns varchar(1000), --
@columnorder varchar(1000), --
@thrupriormonth bYN, --
@nolinkedct bYN, --
@projmethod char(1), --
@production char(1), --
@writeoverplug char(1), --
@initoption char(1), --
@projinactivephases bYN, --
@orderby char(1),
@cyclemode bYN,
@msg varchar(255) output)
as
set nocount on


declare @rcode integer, @jcco_projmethod char(1)

select @rcode = 0

-- validate JCCo
select @jcco_projmethod=ProjMethod
from dbo.bJCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0
	begin
	select @msg = 'Invalid JC Company.', @rcode = 1
	goto bspexit
	end

-- validate form
if not exists(select Form from dbo.DDFI with (nolock) where Form=@form)
	begin
	select @msg = 'Invalid JC Form.', @rcode = 1
	goto bspexit
	end
   
update bJCUO 
	Set
	OpenForm = @openform, 
	VisibleColumns = @visiblecolumns, 
	ColumnOrder = @columnorder, 
	ProjMethod = @projmethod, 
	Production = @production, 
	ShowFutureCO = @showfutureco,
	ThruPriorMonth = @thrupriormonth,
	ChangedOnly = @changedonly, 
	ItemUnitsOnly = @itemunitsonly,
	PhaseUnitsOnly = @phaseunitsonly, 
	ShowLinkedCT = @showlinkedct, 
	RemainUnits = @remainunits, 
	RemainHours = @remainhours, 
	RemainCosts = @remaincosts,  
	PhaseOption = @phaseoption,
	BegPhase = @begphase, 
	EndPhase = @endphase, 
	CostTypeOption = @costtypeoption, 
	SelectedCostTypes = @selectedcosttypes, 
	NoLinkedCT = @nolinkedct, 
	ProjInitOption = @initoption, 
	ProjWriteOverPlug = @writeoverplug,
	ProjInactivePhases = @projinactivephases,
	OrderBy = @orderby,
	CycleMode = @cyclemode
where JCCo= @jcco and Form= @form and UserName= @username
if @@rowcount = 0
   	begin
   	select @msg = 'Unable to save default user options into JCUO.', @rcode = 1
   	goto bspexit
   	end


bspexit:
	if @rcode<>0 select @msg=@msg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCUOSave] TO [public]
GO
