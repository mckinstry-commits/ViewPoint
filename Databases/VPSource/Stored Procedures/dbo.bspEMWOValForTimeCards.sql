SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspEMWOValForTimeCards]
/***********************************************************
* CREATED BY: JM 7/22/02 - Ref Issue 18015 - Adapted from bspEMWOVal
*				TV 02/11/04 - 23061 added isnulls 
* USAGE:
* 	Validates EM WorkOrder vs bEMWH; returns WO Desc and info on Equipment
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
*	@equipment		Equipment in bEMWH
*	@equiptype		Type in bEMEM for Equipment
*	@equipdesc		Description in bEMEM for Equipment
*	@msg      		Error message if error occurs, otherwise
*				Description of WorkOrder from EMWH
*
* RETURN VALUE:
*	0		success
*	1		Failure
*****************************************************/
   
(@emco bCompany = null,
@workorder bWO = null,
@equipment bEquip = null output,
@equiptype char(1) = null output,
@equipdesc bItemDesc = null output,
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

/* Validate the WO */
select @msg = Description, @equipment = Equipment from bEMWH where EMCo = @emco and WorkOrder = @workorder
if @@rowcount = 0
	begin
	select @msg = 'Work Order not on file!', @rcode = 1
	goto bspexit
	end

/* Get info on Equipment */
select @equiptype = Type, @equipdesc = Description from bEMEM where EMCo = @emco and Equipment = @equipment

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOValForTimeCards]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOValForTimeCards] TO [public]
GO
