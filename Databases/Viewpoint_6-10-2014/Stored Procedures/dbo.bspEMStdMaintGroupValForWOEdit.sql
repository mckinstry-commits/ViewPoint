SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMStdMaintGroupValForWOEdit]
   
   /***********************************************************
    * CREATED BY: JM 6/18/02 - Adapted from bspEMStdMaintGroupValWithInfo for EMWOEditItems
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:Adapted from bspEMStdMaintGroupValWithInfo to validate EM StdMaintGroup vs bEMSH
    * 	by EMCo, Equipment and StdMaintGroup by Component if passed in or WO header Equipment 
    *	if not. Also  returns default RepairType and CostCodefrom either bEMSI for associated 
    *	StdMaintItem or bEMCO.WODefaultRepType, or returns null if null in both files.)
    *
    *  Error returned if any of the following occurs
    *	No EMCo passed
    *	No Equipment passed
    *	No StdMaintGroup passed
    *	StdMaintGroup not found in EMSH
    *
    * INPUT PARAMETERS
    *	EMCo			EMCo to validate against
    *	HeaderEquipment	Equipment on WO header to validate against if Component not passed in
    *	Component		Component on WOEditItem line - can be null
    *	StdMaintGroup  		StdMaintGroup to validate
    * 	StdMaintItem    		Item associated with StdMaintGroup - can be null
    *
    * OUTPUT PARAMETERS
    *   	Error message if error occurs, otherwise
    *	Description of StdMaintGroup from EMSH
    *    	Default RepairType as per USAGE above.
    *    	Default CostCode as per USAGE above.
    *
    * RETURN VALUE
    *   	0 = success
    *   	1 = failure
    *****************************************************/
   
   (@emco bCompany = null,@equipment bEquip = null, @component bEquip = null, @stdmaintgroup varchar(10) = null,
   @stdmaintitem bItem, @defcostcode varchar(10) output, @defrepairtype varchar(10) output,@msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
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
   if @stdmaintgroup is null
   	begin
   	select @msg = 'Missing Std Maint Group!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from dbo.EMSH where EMCo = @emco and Equipment = isnull(@component,@equipment) and StdMaintGroup = @stdmaintgroup
   if @@rowcount = 0
   	begin
   	select @msg = 'Std Maint Group not on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMStdMaintGroupValForWOEdit]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStdMaintGroupValForWOEdit] TO [public]
GO
