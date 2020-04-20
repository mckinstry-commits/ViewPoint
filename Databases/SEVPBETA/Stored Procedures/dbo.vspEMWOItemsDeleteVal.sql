SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMWOItemsDeleteVal]
    /********************************************************
    * CREATED BY: TRL 06/05/07 
    *
    * USAGE:- Checks for any WOItems that are flagged Complete.
    * Also counts WO Item Parts and Checks to see if WO Item is on EM Cost Detail
    *
    * INPUT PARAMETERS:
    *	EMCo
    *	WO
    *
    * OUTPUT PARAMETERS:
    *   EWMPCount
    *	Error message if WOItems for WO are flagged Complete
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    **********************************************************/
    
    (@emco bCompany = null,
    @emgroup bGroup = null,
    @workorder varchar(10) = null,
	@emwicount int = 0 output,
  	@emwpcount int = 0 output,
    @errmsg varchar(255) output)
    
    as
    
    set nocount on
    
    declare @rcode int
    select @rcode = 0
    
    if @emco is null
    	begin
    	select @errmsg = 'Missing EM Company!', @rcode = 1
    	goto vspexit
    	end
   if @emgroup is null
    	begin
    	select @errmsg = 'Missing EM Group!', @rcode = 1
    	goto vspexit
    	end
     if @workorder is null
    	begin
    	select @errmsg = 'Missing WorkOrder!', @rcode = 1
    	goto vspexit
    	end
    
  --Check to see if any WO Items are Complete
   if exists(select top 1 1 from dbo.EMWI with (nolock) where EMCo = @emco and WorkOrder = @workorder and 
   	StatusCode in (select StatusCode from dbo.EMWS with (nolock) where EMGroup = @emgroup and StatusType = 'F'))
   	begin
   	select @errmsg = 'Cannot delete Work Order ' + @workorder + '.  Some items are flagged has complete.' ,@rcode = 1
   	goto vspexit
   	end
   
  --Check EMCD for costs.
   if exists(select top 1 1 from dbo.EMCD with (nolock) where EMCo = @emco and WorkOrder = @workorder)
       begin
   		select @errmsg = 'Cost detail records exist in EMCD with WorkOrder ' + @workorder +'.', @rcode=1
   		goto vspexit
   	   end

--Counts all Work Order Parts
   Select @emwicount= IsNull(Count(WorkOrder),0) from dbo.EMWI with (nolock) Where EMCo=@emco and WorkOrder = @workorder
	
  --Counts all Work Order Parts
   Select @emwpcount= IsNull(Count(WorkOrder),0) from dbo.EMWP with (nolock) Where EMCo=@emco and WorkOrder = @workorder

    vspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOItemsDeleteVal] TO [public]
GO
