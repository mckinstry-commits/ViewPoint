SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMEquipReadingsGet    Script Date:  ******/
CREATE proc [dbo].[vspEMEquipReadingsGet]
/********************************************************
* CREATED BY: 	TJL  06/29/07:  Issue #27980, 6x Recode
* MODIFIED BY:  TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*					
* USAGE:
* 	
*
* INPUT PARAMETERS:
*	EM Company
*	Equipment
*
* OUTPUT PARAMETERS:
*	OdoReading
*	HourReading
*	ReplacedOdoReading
*	ReplacedHourReading
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
   
(@emco bCompany = null, @equipment bEquip = null, @odoreading bHrs = null output, @hourreading bHrs = null output,
	@replacedodoreading bHrs = null output, @replacedhourreading bHrs = null output, @errmsg varchar(255) output) 
as 
set nocount on

declare @rcode int
select @rcode = 0
   
if @equipment is null
	begin
	select @errmsg = 'Missing EM Equipment.', @rcode = 1
	goto vspexit
	end
   
--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipment, @errmsg output
If @rcode = 1
begin
      goto vspexit
end

select @odoreading = OdoReading, @hourreading = HourReading, @replacedodoreading = ReplacedOdoReading,
	 @replacedhourreading = ReplacedHourReading
from bEMEM with (nolock)
where EMCo = @emco and Equipment = @equipment
if @@rowcount = 0
	begin
	select @errmsg = 'Not a valid Equipment.', @rcode=1
	goto vspexit
	end
   
vspexit:
if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipReadingsGet] TO [public]
GO
