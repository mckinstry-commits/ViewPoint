SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOItemsUpdateGridFill    Script Date: 8/28/99 9:34:36 AM ******/
CREATE proc [dbo].[bspEMWOItemsUpdateGridFill]
/*******************************************************************
* CREATED: 11/2/98 JM
* LAST MODIFIED: TV 02/11/04 - 23061 added isnulls 
*		TJL  06/22/07 - Issue #27980,  Minor change to use "with nolock", cleanup up white space
*		TRL 03/20/08 - Issue 126198 add PRCo to output
*
* USAGE: Returns recordset containing WOItems for an EMCo/WorkOrder.
* 	Called by EMWOUpdateItems form to report the WOItems modified
* 	in bulk operation.
*
* INPUT PARAMS:
*	@emco		Controlling EMWI.EMCo
*	@workorder	Controlling EMWI.WorkOrder
*
* OUTPUT PARAMS:
*	@rcode		Return code; 0 = success, 1 = failure
*	@errmsg		Error if failure
********************************************************************/
(@emco bCompany = null, @workorder bWO = null) --, @errmsg varchar(255) output)
as
set nocount on
declare @rcode integer
select @rcode = 0

/* Verify required parameters passed. */
/*if @emco is null
begin
select @errmsg = 'Missing EM Company!', @rcode = 1
goto bspexit
end
if @workorder is null
begin
select @errmsg = 'Missing Work Order!', @rcode = 1
goto bspexit
end
*/

/* Select WO Items from bEMWI.  */
select WOItem, Description,PRCo /*126198*/, Mechanic, /*'' as HiddenMech,*/ StatusCode,
RepairType, DateCompl, CurrentOdometer, TotalOdometer,
CurrentHourMeter, TotalHourMeter
from dbo.EMWI with (nolock)
where EMCo = @emco and WorkOrder = @workorder

bspexit:
 --if @rcode<>0 select @errmsg=@errmsg + char(13) + char(10)
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOItemsUpdateGridFill] TO [public]
GO
