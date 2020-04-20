SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMWOCopyGridFill]
    /*******************************************************************
     * CREATED: 3/1/02 JM
     * LAST MODIFIED: TV 02/11/04 - 23061 added isnulls 
     *				  Terry Lis 07/02/07 added @emco to elimnate other company records being returned
	 *				incase autoinitsessionid exits for another company	and removed select statement
	 *				in where clause with replaced with a join statement
     *
     * USAGE: Called by EMWOCopy form to report the new WO/Items/Parts created by the copy process
     *
     * INPUT PARAMS:
     *	@emco		Controlling EM Company
     *	@beginningwo	First EMWH.WorkOrder for which Items/Parts were initialized
     *	@endingwo	Last EMWH.WorkOrder for which Items/Parts were initialized
     *	@GridToFill	W for WO, I for WOItems or P for Parts
     *
     * OUTPUT PARAMS:
     *	@rcode		Return code; 0 = success, 1 = failure
     *	@errmsg		Error message; # copied if success,
     *			error message if failure
     ********************************************************************/
   (@emco bCompany = null, @AutoInitSessionID varchar(30) = null,
   @GridToFill char(1) = null)
    
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
   if @beginningwo is null
    	begin
    	select @errmsg = 'Missing Beginning Work Order!', @rcode = 1
    	goto bspexit
    	end
   if @endingwo is null
    	begin
    	select @errmsg = 'Missing Ending Work Order!', @rcode = 1
    	goto bspexit
    	end
   if @GridToFill is null
    	begin
    	select @errmsg = 'Missing Grid To Fill!', @rcode = 1
    	goto bspexit
    	end*/
    																																																		
    /* Return recordset to VB */
   if @GridToFill = 'W'
   	select WorkOrder, Description, Equipment, Shop, InvLoc, INCo 
	from dbo.EMWH with(nolock) where AutoInitSessionID = @AutoInitSessionID and EMCo=@emco
   if @GridToFill = 'I'
   	select a.WorkOrder, a.WOItem, a.Description, a.Equipment, a.ComponentTypeCode, a.Component, a.CostCode, a.InHseSubFlag, a.StatusCode, a.RepairType, a.RepairCode, a.EstHrs, a.QuoteAmt, a.Priority 
   	from dbo.EMWI a with (nolock)
	Inner Join dbo.EMWH b with(nolock) on a.EMCo=b.EMCo and a.WorkOrder =b.WorkOrder
	where b.AutoInitSessionID =@AutoInitSessionID and a.EMCo=@emco
   if @GridToFill = 'P'
   	select a.WorkOrder, a.WOItem, a.Material, a.Description, a.Equipment, a.PartsStatusCode, a.InvLoc, a.INCo, a.UM, a.QtyNeeded, a.PSFlag, a.Required
   	from dbo.EMWP a with(nolock)
	Inner Join dbo.EMWH b with(nolock) on a.EMCo=b.EMCo and a.WorkOrder =b.WorkOrder
	where  b.AutoInitSessionID =@AutoInitSessionID and a.EMCo=@emco
   bspexit:
   /* 	if @rcode<>0 select @errmsg=@errmsg + char(13) + char(10) + '[bspEMWOCopyGridFill]'*/
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOCopyGridFill] TO [public]
GO
