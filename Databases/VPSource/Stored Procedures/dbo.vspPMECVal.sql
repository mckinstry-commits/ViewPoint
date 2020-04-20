SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMECVal    Script Date: 02/02/2006 ******/
CREATE proc [dbo].[vspPMECVal]
/*************************************
 * Created By:	GF 05/24/2007 6.x
 * Modified By:	GF 03/23/2009 - issue #129898
 *
 *
 * USAGE:
 * Used to validate budget code in PMEC and return defaults
 *
 *
 * INPUT PARAMETERS
 * @pmco			PM Company
 * @estcode			PM Budget Code to validate
 * @costlevel		PM Budget Detail cost level (D,S,T)
 *
 *
 * OUTPUT PARAMETERS
 *
 * Success returns:
 * 0 and Description from PMEC
 *
 * Error returns:
 * 1 and error message
 **************************************/
(@pmco bCompany, @budgetcode varchar(10), @costlevel varchar(1), 
 @description bDesc = null output, @active bYN = 'Y' output, @phase bPhase = null output,
 @costtype bJCCType = null output, @um bUM = null output, @unitcost bUnitCost = 0 output,
 @hrsperunit bUnitCost = 0 output, @pct bPct = 0 output, @basis char(1) = 'U' output,
 @timeum bUM = null output, @rate bUnitCost = 0 output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- get PMEC data
select @description=Description, @active=Active, @phase=Phase, @costtype=CostType,
	   @um=UM, @unitcost=UnitCost, @hrsperunit=HrsPerUnit, @pct=Percentage,
	   @basis=Basis, @timeum=TimeUM, @rate=Rate,
	   @msg=Description
from PMEC with (nolock) where PMCo=@pmco and BudgetCode=@budgetcode and CostLevel=@costlevel
if @@rowcount = 0
	begin
	select @msg = 'Budget Code not on file', @rcode = 1
	goto bspexit
	end




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMECVal] TO [public]
GO
