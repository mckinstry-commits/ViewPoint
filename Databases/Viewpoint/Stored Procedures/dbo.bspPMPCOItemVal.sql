SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPCOItemVal    Script Date: 8/28/99 9:33:05 AM ******/
CREATE  proc [dbo].[bspPMPCOItemVal]
/***********************************************************
    * CREATED BY: JRE 12/29/97
    * Modified By: GF 08/02/2001
    *
    * USAGE:
    *  Validates PM Pending Change Order Item
    *  An error is returned if any of the following occurs
    * 	no company passed
    *	no project passed
    *  no PCO Type passed
    *  no PCO passed
    *  no PCO Item passed
    *	no matching PCO Item found in PMOI
    *
    * INPUT PARAMETERS
    *   PMCO- JC Company to validate against
    *   PROJECT- project to validate against
    *   PCOType - PCO type
    *   PCO - Pending Change Order to validate
    *   PCOItem - PCO Item to validate
    *
    * OUTPUT PARAMETERS
	* Contract
	* ContractItem
	* UM
	* Units
	* ACO
	* ACOItem
    * @msg - error message if error occurs otherwise Description of PCOItem in PMOI
	*
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @pcotype bDocType =null, @pco bPCO = null,
 @pcoitem bPCOItem = null, @contract bContract output, @contractitem bContractItem output,
 @um bUM output, @units bUnits output, @aco bACO output, @acoitem bACOItem output,
 @msg varchar(255) output)
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
   
if @pco is null
   	begin
   	select @msg = 'Missing PCO!', @rcode = 1
   	goto bspexit
   	end
   
if @pcotype is null
   	begin
   	select @msg = 'Missing PCO Type!', @rcode = 1
   	goto bspexit
   	end
   
if @pcoitem is null
   	begin
   	select @msg = 'Missing PCO Item!', @rcode = 1
   	goto bspexit
   	end

---- validate PCO Item
select @msg = Description, @contract=Contract, @contractitem=ContractItem, @um=UM,
		@units=isnull(Units,0), @aco=ACO, @acoitem=ACOItem
from PMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
if @@rowcount = 0
	begin
   	select @msg = 'PCO Item not on file!', @rcode = 1
   	goto bspexit
   	end
if isnull(@acoitem,'') <> ''
	begin
	select @msg = 'This PCO Item has been approved.', @rcode = 1
	goto bspexit
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOItemVal] TO [public]
GO
