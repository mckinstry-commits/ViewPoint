SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[bspEMStdMaintItemValForWOEdit]
   
   /***********************************************************
    * CREATED BY: JM 6/18/02 - Adapted from bspEMStdMaintItemVal
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    * USAGE: Validates EM Std Maint Item vs bEMSI by EMCo, Component if passed it or 
    *	WO header Equipment if not, and StdMaintGroup.
    *
    * 	Error returned if any of the following occurs
    *
    * 	No EMCo passed
    *	No Equipment passed
    *	No StdMaintGroup passed
    *	No StdMaintItem passed
    *	StdMaintItem not found in EMSI
    *
    * INPUT PARAMETERS
    *	EMCo		EMCo to validate against
    *	Equipment	WO Header Equipment to validate against
    *	Component	WOItem Component to validate against
    *	StdMaintGroup  	StdMaintGroup to validate against
    *	StdMaintItem  	StdMaintItem to validate
    *
    * OUTPUT PARAMETERS
    *   	@msg	Error message if error occurs, otherwise
    *    	@costcode
    *	Description of StdMaintItem from EMSI
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   
   (@emco bCompany = null,@equipment bEquip = null, @component bEquip = null, @stdmaintgroup varchar(10) = null,
   @stdmaintitem bItem, @defcostcode varchar(10) =null output, @defrepairtype varchar(10)=null output,@msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @stdmaintitem is null and @stdmaintgroup is null
       begin
       goto bspexit --No validation needed if both are null
       end
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @equipment is null 
   	begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
   	end
   if isnull(@stdmaintgroup,'') = '' and isnull(@stdmaintitem, '') <> ''
   	begin
   	select @msg = 'Missing Std Maint Group!', @rcode = 1
   	goto bspexit
   	end
   if isnull(@stdmaintgroup,'') <> '' and isnull(@stdmaintitem, '') = ''
   	begin
   	select @msg = 'Missing Std Maint Group Item!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   select @msg = Description from bEMSH where EMCo = @emco and Equipment = isnull(@component,@equipment) and StdMaintGroup = @stdmaintgroup
   if @@rowcount = 0
   	begin
   	select @msg = 'Std Maint Group not on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   --Check SMG item and Get default Repair Type. OK to return null if in neither file.
   select @msg = Description, @defrepairtype = RepairType, @defcostcode = CostCode from bEMSI
   where EMCo = @emco and Equipment = isnull(@component,@equipment) and StdMaintGroup = @stdmaintgroup and StdMaintItem = @stdmaintitem
   if @@rowcount = 0
   	begin
   	select @msg = 'Std Maint Item not on file!', @rcode = 1
   	goto bspexit
   	end
   if @defrepairtype is null
       select @defrepairtype = WODefaultRepType from bEMCO where EMCo = @emco
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMStdMaintItemValForWOEdit]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStdMaintItemValForWOEdit] TO [public]
GO
