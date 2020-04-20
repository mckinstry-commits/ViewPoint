SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[vspEMEquipValForWarranties]
/***********************************************************
* CREATED BY: DANF 03/21/07
* MODIFIED By :		TRL 08/13/2008 - 126196 check to see Equipment code is being Changed
* USAGE:
*	Validates EMEM.Equipment for warranties
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
*
* OUTPUT PARAMETERS
*	@msg 		error or Description
*
* RETURN VALUE
*	0 success
*	1 error
***********************************************************/
(@emco bCompany = null,
@equip bEquip = null,
@partdesc bDesc output,
@inservicedate bDate output,
@manufacturer varchar(20) output,
@model varchar(20) output,
@purchdate bDate output,
@vinnumber varchar(40) output,
@odometer bHrs output,
@odometerreplaced bHrs output,
@hourmeter bHrs output,
@hourmeterreplaced bHrs output,
@msg varchar(255) output)
   
as

set nocount on

declare @rcode int, @status char(1)

select @rcode = 0
   
if @emco is null
begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto vspexit
end
   
if IsNull(@equip,'')=''
begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto vspexit
end
	
-- Return if Equipment Change in progress for New Equipment Code, 126196.
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
begin
	goto vspexit
end

select  @msg=Description, @status = Status,
@partdesc = Description, @inservicedate = InServiceDate, 
@manufacturer = Manufacturer, @model = Model,
@purchdate = PurchDate, @vinnumber = VINNumber,
@odometer = IsNull(OdoReading,0),@odometerreplaced = IsNull(ReplacedOdoReading,0),
@hourmeter = IsNull(HourReading,0),@hourmeterreplaced= IsNull(ReplacedHourReading,0)
from bEMEM with (nolock)
where EMCo = @emco and Equipment = @equip
if @@rowcount = 0
begin
	select @msg = 'Equipment invalid!', @rcode = 1
	goto vspexit
end
	   
/* Reject if Status inactive. */
if @status = 'I'
begin
	select @msg = 'Equipment Status = Inactive!', @rcode = 1
    goto vspexit
end
   
vspexit:
if @rcode<>0 select @msg=isnull(@msg,'')

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipValForWarranties] TO [public]
GO
