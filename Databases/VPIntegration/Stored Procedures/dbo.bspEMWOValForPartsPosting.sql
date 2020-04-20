SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMWOValForPartsPosting]
   /***********************************************************
    * CREATED BY: JM 4/25/02 - Adapted from bspEMWOValWithInfo
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls 
    * Modified by:  TRL 03/27/07 - updated procedure to use view and not tables.
    *
    * USAGE:
    * 	Validates EM WorkOrder in bEMWH
    *	Returns 
    *		WO Desc, InvLoc, Equip from bEMWH 
    *		Equip Desc from EMEM
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
    *	@msg      		Error message if error occurs, otherwise
    *
    * RETURN VALUE:
    *	0		success
    *	1		Failure
    *****************************************************/
   
   (@emco bCompany = null,
   @workorder bWO = null,
   @invloc bLoc = null output,
   @equipment bEquip = null output,
   @equipdesc bDesc = null output,
   @equipcurrodo bHrs = null output,
   @equiptotodo bHrs = null output,
   @equipcurrhrs bHrs = null output,
   @equiptothrs bHrs = null output,
   @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int 
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
   
   select @msg = Description, @equipment = Equipment, @invloc = InvLoc
   from dbo.EMWH with (nolock) where EMCo = @emco and WorkOrder = @workorder
   if @@rowcount = 0
   	begin
   	select @msg = 'Work Order not on file!', @rcode = 1
   	goto bspexit
   	end
   
   /* Get Odo/Hrs info for Equipment */
   select @equipdesc = Description, @equipcurrodo = IsNull(OdoReading,0), @equiptotodo = IsNull(OdoReading,0) + IsNull(ReplacedOdoReading,0),
   	@equipcurrhrs = IsNull(HourReading,0), @equiptothrs = IsNull(HourReading,0) + IsNull(ReplacedHourReading,0)
   from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   
   bspexit:
   	--if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOValForPartsPosting]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOValForPartsPosting] TO [public]
GO
