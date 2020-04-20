SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************/
CREATE  proc [dbo].[bspPMACOItemVal]
/***********************************************************
* CREATED BY: JRE 12/29/97
* Modified By: GF 08/03/2001
*				GF 07/25/2008 - issue #129065 added PCOType, PCO, PCOItem as output parameters.
*
*
* USAGE:
*  Validates PM Approved Change Order Item
*  An error is returned if any of the following occurs
* 	no company passed
*	no project passed
*  no ACO passed
*  no ACO Item passed
*	no matching ACO Item found in PMOI
*
* INPUT PARAMETERS
*   PMCO- JC Company to validate against
*   PROJECT- project to validate against
*   ACO -  Approved Change Order to validate
*   ACOItem - ACO Item to validate
*
* OUTPUT PARAMETERS
*
*   @msg - error message if error occurs otherwise Description of ACOItem in PMOI
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@pmco bCompany = 0, @project bJob = null, @aco varchar(10) = null,
 @acoitem bACOItem = null, @contract bContract = null output, @contractitem bContractItem = null output,
 @um bUM = null output, @units bUnits output, @pcotype bDocType = null output, @pco bPCO = null output,
 @pcoitem bPCOItem = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @pmco is null
	begin
	select @msg = 'Missing PM Company!', @rcode = 1
	goto bspexit
	end

if @project is null
	begin
	select @msg = 'Missing Project!', @rcode = 1
	goto bspexit
	end

if @aco is null
	begin
	select @msg = 'Missing ACO!', @rcode = 1
	goto bspexit
	end

if @acoitem is null
	begin
	select @msg = 'Missing ACO Item!', @rcode = 1
	goto bspexit
	end

---- validate aco item to PMOI
select @msg = Description, @contract=Contract, @contractitem=ContractItem, @um=UM,
	@units=isnull(Units,0), @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem
from bPMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
if @@rowcount = 0
	begin
	select @msg = 'ACO Item not on file!', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMACOItemVal] TO [public]
GO
