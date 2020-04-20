SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************/
CREATE proc [dbo].[vspPMSLUpdateFromJCCH]
/***********************************************************
* Created By:  GF 06/09/2008 - issue #128485
* Modified By:
*
*
* USAGE: Called from PM Project Phases after record update event to update.
* Will update PMSL record if one exists in certain situations. If the old JCCH values
* for units and amount are zero. The source status must be 'Y' or 'N'. The PMSL record
* if a matching record is found must not have a vendor assigned and the units and amount
* must be zero. Also the PMSL UM must match the old JCCH UM.
*
*
* INPUT PARAMETERS
* @pmco        PM Company
* @project     PM Project
* @phasegroup  Phase Group
* @phase       Phase
* @costtype    Phase CostType
* @units       Estimate Units
* @um          Unit of Measure
* @amount      Estimate Cost
* @oldum		Old unit of measure
*
*
* OUTPUT PARAMETERS
* @msg
* RETURN VALUE
* 0         success
* 1         Failure  'if Fails THEN it fails.
*****************************************************/
(@pmco bCompany = null, @project bJob = null, @phasegroup bGroup = null, @phase bPhase = null,
 @costtype bJCCType = null, @units bUnits = null, @um bUM = null, @unitcost bUnitCost = null,
 @amount bDollar = null, @oldum bUM = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @seq int, @slcosttype bJCCType, @slcosttype2 bJCCType, @updatepmsl bYN

select @rcode = 0, @msg = '', @updatepmsl = 'N'

if isnull(@costtype,'') = '' goto bspexit

---- get needed information from PMCO for cost type creation
select @slcosttype=SLCostType, @slcosttype2=SLCostType2
from PMCO with (nolock) where PMCo=@pmco

---- check if subcontract cost type. If valid set add flag.
if isnull(@slcosttype,'') = @costtype
   begin
   select @updatepmsl = 'Y'
   end

if isnull(@slcosttype2,'') = @costtype
   begin
   select @updatepmsl = 'Y'
   end

---- not a subcontract cost type
if @updatepmsl = 'N' goto bspexit

---- get PMSL.Sequence if matches restrictions to update
select @seq=Seq from PMSL with (nolock)
where PMCo=@pmco and Project=@project and PhaseGroup=@phasegroup
and Phase=@phase and CostType=@costtype and Vendor is null
and Units=0 and Amount=0 and UM=@oldum
if @@rowcount <> 1
	begin
	goto bspexit
	end

if @um='LS'
	begin
	select @units=0, @unitcost=0
	end

---- update PMSL record
update PMSL set Units=@units, UM=@um, UnitCost=@unitcost, Amount=@amount
where PMCo=@pmco and Project=@project and PhaseGroup=@phasegroup
and Phase=@phase and CostType=@costtype and Seq=@seq


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSLUpdateFromJCCH] TO [public]
GO
