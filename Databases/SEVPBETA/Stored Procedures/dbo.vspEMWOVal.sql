SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspEMWOVal]
   /***********************************************************
    * CREATED BY:	GP 05/12/2008	Issue #127494, validate EM Work Order & 
	*									return bEMWH Complete bYN value.
    *			   
    * USAGE:
    * 	Basic validation of EM WorkOrder vs bEMWH; returns Complete flag
    *
    * 	Error returned if any of the following occurs:
    * 		No EMCo passed
    *		No WorkOrder passed
    *		WorkOrder not found in EMWH
    *
    * INPUT PARAMETERS:
    *	@emco  		EMCo to validate against
    * 	@workorder 	WorkOrder to validate
    *
    * OUTPUT PARAMETERS:
	*	@complete	bYN value, if WO is completed
    *	@msg      	Error message if error occurs
    *
    * RETURN VALUE:
    *	0		success
    *	1		Failure
    *****************************************************/
(@emco bCompany = null,
 @workorder bWO = null, @complete bYN = 'N' output,
 @msg varchar(255) output)
as
set nocount on
   
	declare @rcode int
	select @rcode = 0, @complete = 'N'
   
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


select @msg = Description, @complete=Complete
from EMWH with (nolock) where EMCo = @emco and WorkOrder = @workorder
--if @@rowcount = 0
------	begin
------	select @complete = Complete from EMWH with (nolock) where EMCo = @emco and WorkOrder = @workorder
------	---- if @@rowcount = 0 select @complete = 'N'
------	----	select @msg = 'Work Order not on file!', @rcode = 1
------	----	goto bspexit
------	end
------else
--	begin
--	select @msg = 'Work Order not on file.'
--	end
   


bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOVal] TO [public]
GO
