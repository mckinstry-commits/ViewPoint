SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMWOItemDeleteVal]
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
	@woitem smallint =null,
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
      if @woitem is null
    	begin
    	select @errmsg = 'Missing WO Item!', @rcode = 1
    	goto vspexit
    	end
     
  --Check to see if any WO Items are Complete
   if exists(select top 1 1 from dbo.EMWI with (nolock) where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem and
   	StatusCode in (select StatusCode from dbo.EMWS with (nolock) where EMGroup = @emgroup and StatusType = 'F'))
   	begin
   	select @errmsg = 'Cannot delete Item: ' + Convert(varchar,@woitem) + ' on Work Order: ' + @workorder + Char(10) + 'because item is flagged has complete.' ,@rcode = 1
   	goto vspexit
   	end
   
  --Check EMCD for costs.
   if exists(select top 1 1 from dbo.EMCD with (nolock) where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem)
       begin
   		select @errmsg = 'Cost detail records exist in EMCD on' + char(10)+	' WorkOrder: ' + @workorder +' / Item: ' + convert(varchar,@woitem) + '.', @rcode=1
   		goto vspexit
   	   end

    vspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOItemDeleteVal] TO [public]
GO
