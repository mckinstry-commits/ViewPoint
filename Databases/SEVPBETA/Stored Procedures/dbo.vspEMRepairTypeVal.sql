SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspEMRepairTypeVal]

/***********************************************************
* CREATED BY: JM 8/21/98
* MODIFIED By : TV 02/11/04 - 23061 added isnulls
*					TV 10/18/05 - Moved to 6X
*
* USAGE:
* Validates EM Repair Type vs EMRX.
* Error returned if any of the following occurs:
*
* 	No EM Group passed
*	No Repair Type passed
*	Repair Type not found in EMRX
*
* INPUT PARAMETERS
*   EMGroup   	EM Group to validate against 
*   RepairType Repair Type to validate 
*
* OUTPUT PARAMETERS
*   @msg      Error message if error occurs, otherwise 
*		Description of Repair Type from EMRX
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@emgroup bGroup = null, @repairtype bCostCode = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0

if @emgroup is null
	begin
	select @msg = 'Missing EM Group!', @rcode = 1
	goto bspexit
	end

if @repairtype is null
	begin
	select @msg = 'Missing Repair Type!', @rcode = 1
	goto bspexit
	end

select @msg = Description 
from bEMRX
where EMGroup = @emgroup and RepType = @repairtype 

if @@rowcount = 0
	begin
	select @msg = 'Repair Type not on file!', @rcode = 1
	goto bspexit
	end

bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRepairTypeVal] TO [public]
GO
