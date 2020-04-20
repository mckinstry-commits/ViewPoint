SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE proc [dbo].[vspJCUOGet]
/***********************************************************
* CREATED BY:	DANF 07/07/2006
* MODIFIED BY:	GF 03/27/2008 - issue #126993 added 2 columns to JCUO
*				GP 06/01/2009 - Issue 133774 commented out line setting @projmethod twice
*
*
*
*
*
* USAGE:
*  Returns the user options for projections
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
@changedonly bYN output, --
@itemunitsonly bYN output, --
@phaseunitsonly bYN output, --
@showlinkedct bYN output, --
@showfutureco bYN output, --
@remainunits bYN output, --
@remainhours bYN output, --
@remaincosts bYN output, --
@openform bYN output,  --
@phaseoption char(1) output, --
@begphase bPhase output, --
@endphase bPhase output, --
@costtypeoption char(1) output, --
@selectedcosttypes varchar(1000) output, --
@visiblecolumns varchar(1000) output, --
@columnorder varchar(1000) output, --
@thrupriormonth bYN output, --
@nolinkedct bYN output, --
@projmethod char(1) output, --
@production char(1) output, --
@writeoverplug char(1) output, --
@initoption char(1) output, --
@projinactivephases bYN output, --
@orderby char(1) output,
@cyclemode bYN output,
@columnwidth varchar(max) output,
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
   
select 
	@openform = OpenForm, 
	@visiblecolumns = VisibleColumns, 
	@columnorder = ColumnOrder, 
	@projmethod = ProjMethod, 
	@production = Production, 
	@showfutureco = ShowFutureCO,
	@thrupriormonth = ThruPriorMonth,
	@changedonly = ChangedOnly, 
	@itemunitsonly = ItemUnitsOnly,
	@phaseunitsonly = PhaseUnitsOnly, 
	@showlinkedct = ShowLinkedCT, 
	@remainunits = RemainUnits, 
	@remainhours = RemainHours, 
	@remaincosts = RemainCosts,  
	@phaseoption = PhaseOption,
	@begphase = BegPhase, 
	@endphase = EndPhase, 
	@costtypeoption = CostTypeOption, 
	@selectedcosttypes = SelectedCostTypes, 
	@nolinkedct = NoLinkedCT, 
	@initoption = ProjInitOption, 
	@writeoverplug = ProjWriteOverPlug,
	@projinactivephases = ProjInactivePhases,
	@orderby = OrderBy,
	@cyclemode = CycleMode,
	@columnwidth = ColumnWidth
from bJCUO with (nolock)
where JCCo= @jcco and Form= @form and UserName= @username
if @@rowcount = 0
   	begin
   	select @msg = 'Unable to insert default user options into JCUO.', @rcode = 1
   	goto bspexit
   	end
    
if isnull(@changedonly,'') not in ('Y','N') set @changedonly = 'N'
if isnull(@itemunitsonly,'') not in ('Y','N') set @itemunitsonly = 'N'
if isnull(@phaseunitsonly,'') not in ('Y','N') set @phaseunitsonly = 'N'
if isnull(@showlinkedct,'') not in ('Y','N') set @showlinkedct = 'N'
if isnull(@showfutureco,'') not in ('Y','N') set @showfutureco = 'N'
if isnull(@remainunits,'') not in ('Y','N') set @remainunits = 'N'
if isnull(@remainhours,'') not in ('Y','N') set @remainhours = 'N'
if isnull(@remaincosts,'') not in ('Y','N') set @remaincosts = 'N'
if isnull(@openform,'') not in ('Y','N') set @openform = 'N'
if isnull(@phaseoption,'') not in ('0','1') set @phaseoption = '0'
if isnull(@costtypeoption,'') not in ('0','1') set @costtypeoption = '0'
if isnull(@thrupriormonth,'') not in ('Y','N') set @thrupriormonth = 'N'
if isnull(@nolinkedct,'') not in ('Y','N') set @nolinkedct = 'N'
--if isnull(@projmethod,'') not in ('1','2') set @projmethod = '1'
if isnull(@production,'') not in ('0','1','2','3') set @production = '0'
if isnull(@writeoverplug,'') not in ('0','1','2') set @writeoverplug = '1'
if isnull(@initoption,'') not in ('0','1') set @initoption = '1'
if isnull(@projinactivephases,'') not in ('Y','N') set @projinactivephases = 'N'
if isnull(@projmethod,'') = '' set @projmethod = isnull(@jcco_projmethod, '1')
if isnull(@orderby,'') not in ('C','P') set @orderby = 'P'
if isnull(@cyclemode,'') not in ('Y','N') set @cyclemode = 'N'


bspexit:
	if @rcode<>0 select @msg=@msg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCUOGet] TO [public]
GO
