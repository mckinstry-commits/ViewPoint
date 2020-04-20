SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOUpdateEquipInfo    Script Date: 8/28/99 9:34:36 AM ******/
CREATE  proc [dbo].[bspEMWOUpdateEquipInfo]
/********************************************************
* CREATED BY: 	JM 10/27/98
* MODIFIED BY: JM 12/7/98 - Changed '= null' to 'is null'.
*		MH 9/16/99 - Added parameters for equip fuel and comp fuel
*		TV 02/11/04 - 23061 added isnulls 
*		TV 02/25/05 - 27077 Clean up
*		TJL 06/14/07 - Issue #27974, 6x Recode.  Return values based upon WOItem level
*		TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*
* USAGE:
* 	Retrieves Equipment and Component (when used on item) info from EMEM for EMWOUpdate form.
*
*	
* INPUT PARAMETERS:
*	EM Company
*	WorkOrder
*
* OUTPUT PARAMETERS:
*	@equipment = EMEM.Equipment
*	@equipmentdesc = EMEM.Description
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
   
(@emco bCompany = null, @workorder bWO = null, @woitem int = null, @woequip bEquip output, @equipmentdesc bItemDesc output, @equipodoreading bHrs output, 
	@equipododate bDate output, @equipreplacedodoreading bHrs output, @equiphourreading bHrs output, @equiphourdate bDate output, 
	@equipreplacedhourreading bHrs output, @woequipcomp bEquip output, @componentdesc bItemDesc output, @compodoreading bHrs output, 
	@compododate bDate output, @compreplacedodoreading bHrs output, @comphourreading bHrs output, @comphourdate bDate output, 
	@compreplacedhourreading bHrs output, @equipfuel bUnits output, @compfuel bUnits output, @msg varchar(255) output) 

as 

set nocount on

declare @rcode int
   
select @rcode = 0
   
if @emco is null
	begin
   	select @msg = 'Missing EM Company#.', @rcode = 1
   	goto bspexit
   	end
if @workorder is null
   	begin
   	select @msg = 'Missing WorkOrder.', @rcode = 1
   	goto bspexit
   	end
if @woitem is null
   	begin
   	select @msg = 'Missing WorkOrder Item.', @rcode = 1
   	goto bspexit
   	end
   
/* Get Equipment, Component on this Work Order Item. */
select @woequip = Equipment, @woequipcomp = Component, @msg = Description
from bEMWI with (nolock)
where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem
   		
/* Exit if Equipment not found. */
if @woequip is null
	begin
	select @msg = 'Equipment not found for EMCo/WorkOrder in WorkOrder table.', @rcode = 1
	goto bspexit
	end

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @woequip, @msg output
If @rcode = 1
begin
      goto bspexit
end

/* Get the PRIMARY Equipment Odo and Hour readings from EMEM. */
select @equipmentdesc = Description, @equipodoreading = OdoReading, @equipododate = OdoDate, @equipreplacedodoreading = ReplacedOdoReading,
@equiphourreading = HourReading, @equiphourdate = HourDate,	@equipreplacedhourreading = ReplacedHourReading,@equipfuel = FuelUsed
from bEMEM with (nolock)
where EMCo = @emco	and Equipment = @woequip
   
/* Get SECONDARY Component Odo and Hour readings from EMEM when WOItem has included a Component. */
if isnull(@woequipcomp,'') = ''
   	begin
   	select @woequipcomp = 'N/A'
   	end
else
	begin
   	select @componentdesc = Description, @compodoreading = OdoReading, @compododate = OdoDate, 
   		@compreplacedodoreading = ReplacedOdoReading, @comphourreading = HourReading, @comphourdate = HourDate,
   		@compreplacedhourreading = ReplacedHourReading, @compfuel = FuelUsed
   	from bEMEM with (nolock)
	where EMCo = @emco	and Equipment = @woequipcomp
	end

bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOUpdateEquipInfo]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOUpdateEquipInfo] TO [public]
GO
