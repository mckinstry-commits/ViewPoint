SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************/
CREATE PROCEDURE[dbo].[vspPMECJCVal]
/*************************************
* Created By:		CHS 03/05/2009
* Modified By:
*
*
* USAGE:
* Used to validate budget code in PMECJC and return defaults
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
* 0 and Description from PMECJC
*
* Error returns:
* 1 and error message
**************************************/
(@pmco bCompany, @budgetcode varchar(10), 
 @description bDesc = null output, @um bUM = null output, 
 @unitcost bUnitCost = 0 output, @hrsperunit bUnitCost = 0 output,
 @basis char(1) = 'U' output, @timeum bUM = null output,
 @rate bRate=0 output, @pmec_um bUM = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- get PMEC data
select @description=Description, @um=UM, @unitcost=UnitCost, @rate=Rate,
		@hrsperunit=HrsPerUnit, @basis=Basis, @timeum=TimeUM,
		@msg=Description, @pmec_um=UM
from PMECJC with (nolock) where PMCo=@pmco and BudgetCode=@budgetcode
if @@rowcount = 0
	begin
	select @msg = 'Budget Code not on file', @rcode = 1
	goto bspexit
	end

---- @pmec_um depends on basis
if @basis = 'H'
	begin
	set @pmec_um = @timeum
	end
	

bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMECJCVal] TO [public]
GO
