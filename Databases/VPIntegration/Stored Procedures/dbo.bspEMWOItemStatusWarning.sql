SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMWOItemStatusWarning]
   /********************************************************
   * CREATED BY: 	JM 4/6/2000
   * MODIFIED BY: TV 02/11/04 - 23061 added isnulls 
   * Modified by:  TRL 03/27/07 changed procedure to use views
   *
   * USAGE:
   * 	Returns whether a WOItem is Status = Closed
   *
   * INPUT PARAMETERS:
   *	EM Company
   *  WorkOrder
   *  WOItem
   *
   * OUTPUT PARAMETERS:
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0	WOItem Closed
   *  1  WOItem Open
   *	2 	Failure
   *********************************************************/
   
   (@emco bCompany,
   @workorder bWO,
   @woitem as smallint,
   @emgroup as bGroup,
   @errmsg varchar(60) output)
   
   as
   
   set nocount on
   
   declare @rcode int,
      @statuscode varchar(10),
      @statustype char(1),
      @wopostfinal bYN
   
   select @rcode = 0
   
   /* Verify required parameters passed. */
   if @emco is null
    	begin
    	select @errmsg = 'Missing EM Company#!', @rcode = 2
    	goto bspexit
    	end
   if @workorder is null
    	begin
    	select @errmsg = 'Missing Work Order!', @rcode = 2
    	goto bspexit
    	end
   if @woitem is null
    	begin
    	select @errmsg = 'Missing WO Item!', @rcode = 2
    	goto bspexit
    	end
   if @emgroup is null
    	begin
    	select @errmsg = 'Missing EMGroup!', @rcode = 2
    	goto bspexit
    	end
   
   /* Get StatusCode for WOItem. */
   select @statuscode = StatusCode
   from dbo.EMWI with (nolock)
   where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem
   
   /* Get StatusType from bEMWS. */
   select @statustype = StatusType
   from dbo.EMWS with (nolock)
   where EMGroup = @emgroup and StatusCode = @statuscode
   
   /* Get WOPostFinal from bEMCO. */
   select @wopostfinal = WOPostFinal from dbo.EMCO with (nolock) where EMCo = @emco
   
   /* Set @rcode to 1 if StatusType is final and WOPostFinal is 'Y'. */
   if @statustype = 'F' and @wopostfinal = 'Y' select @rcode = 1
   
   bspexit:
   	--if @rcode=2 select @errmsg=isnull(@errmsg,'')	--+ '-[bspEMWOItemStatusWarning]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOItemStatusWarning] TO [public]
GO
