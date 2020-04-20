SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOValWithInfo    Script Date: 8/28/99 9:34:37 AM ******/
   CREATE   proc [dbo].[bspEMWOValWithInfo]
   /***********************************************************
    * CREATED BY: JM 10/29/98
    * MODIFIED By : JM 11/5/98 - Added several outputs.
    *		JM 1/3/99 - Added output of count of WO parts in bEMWP.
    *		bc 02/22/99 - Allowed outputs to be null for batch validations
    *      JM 12/1/99 - Added Equipment as an output parameter.
    *		TV 02/11/04 - 23061 added isnulls 
    * USAGE:
    * 	Validates EM WorkOrder in bEMWH and returns WO Desc
    *	and InvLoc from bEMWH; and Odometer, HourMeter,
    *	ReplacedOdoReading, and ReplacedHourReading for
    *	Equipment on WO from bEMEM.
    *
    * 	Error returned if any of the following occurs:
    * 		No EMCo passed
    *		No WorkOrder passed
    *		WorkOrder not found in EMWH
    *
    * INPUT PARAMETERS:
    *	EMCo   		EMCo to validate against
    * 	WorkOrder 	WorkOrder to validate
    *
    * OUTPUT PARAMETERS:
    *	@odoreading		EMEM.Odometer for EMWH.Equipment
   
    *	@replacedodoreading	EMEM.ReplacedOdoReading for EMWH.Equipment
    *	@hourreading		EMEM.HourMeter for EMWH.Equipment
    *	@replacedhourreading	EMEM.ReplacedHourReading for EMWH.Equipment
    *	@invloc			EMWH.InvLoc for WorkOrder
    *	@partscount		Count in bEMWP for WorkOrder
    *	@msg      		Error message if error occurs, otherwise
    *				Description of WorkOrder from EMWH
    *
    * RETURN VALUE:
    *	0		success
    *	1		Failure
    *****************************************************/
   
   (@emco bCompany = null,
   @workorder bWO = null,
   @odoreading bHrs = null output,
   @replacedodoreading bHrs = null output,
   @hourreading bHrs = null output,
   @replacedhourreading bHrs = null output,
   @invloc bLoc = null output,
   @partscount smallint = null output,
   @equipdesc bItemDesc = null output,
   @equipment bEquip = null output,
   @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int--, @department bDept
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @workorder is null
   	begin
   	select @msg = 'Missing Work Order!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @equipment = Equipment,
   	@invloc = InvLoc
   from bEMWH
   where EMCo = @emco
   	and WorkOrder = @workorder
   if @@rowcount = 0
   	begin
   	select @msg = 'Work Order not on file!', @rcode = 1
   	goto bspexit
   	end
   
   select @odoreading = OdoReading,
       @hourreading = HourReading,
       @equipdesc = Description
   from EMEM
   where EMCo = @emco
   	and Equipment = @equipment
   
   select @partscount = count(*)
   from bEMWP
   where EMCo = @emco
   	and WorkOrder = @workorder
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOValWithInfo]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOValWithInfo] TO [public]
GO
