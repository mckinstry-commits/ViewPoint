SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOVal    Script Date: 2/12/2002 3:51:13 PM ******/
   /****** Object:  Stored Procedure dbo.bspEMWOVal    Script Date: 8/28/99 9:34:37 AM ******/
   CREATE   proc [dbo].[bspEMWOVal]
   /***********************************************************
    * CREATED BY: JM 10/29/98
    *			   TV 02/11/04 - 23061 added isnulls 
    * USAGE:
    * 	Basic validation of EM WorkOrder vs bEMWH; returns WO Desc
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
    *				Description of WorkOrder from EMWH
    *
    * RETURN VALUE:
    *	0		success
    *	1		Failure
    *****************************************************/
   
   (@emco bCompany = null,
   @workorder bWO = null,
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
   
   select @msg = Description
   from bEMWH
   where EMCo = @emco
   	and WorkOrder = @workorder
   if @@rowcount = 0
   	begin
   	select @msg = 'Work Order not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOVal] TO [public]
GO
