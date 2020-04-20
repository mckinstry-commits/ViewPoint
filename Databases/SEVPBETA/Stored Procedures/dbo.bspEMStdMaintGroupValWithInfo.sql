SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMStdMaintGroupValWithInfo]
   
   /***********************************************************
    * CREATED BY: JM 1/18/00
    * MODIFIED By : JM 2/16/00 - Removed return of defrepairtype.
    *             JM 4/11/00 - Reinstated return of default RepairType and added
    *             return of default CostCode.
    *				TV 02/11/04 - 23061 added isnulls
    * USAGE:Adapted from bspEMStdMaintGroupVal to validate EM StdMaintGroup vs bEMSH
    *  by EMCo, Equipment and StdMaintGroup and to return default RepairType and CostCode
    *  from either bEMSI for associated StdMaintItem or bEMCO.WODefaultRepType, or returns
    *  null if null in both files.)
    *
    *  Error returned if any of the following occurs
    *
    *	No EMCo passed
    *	No Equipment passed
    *	No StdMaintGroup passed
    *	StdMaintGroup not found in EMSH
    *
    * INPUT PARAMETERS
    *	EMCo		EMCo to validate against
    *	Equipment	Equipment to validate against
    *	StdMaintGroup  	StdMaintGroup to validate
    * StdMaintItem    Item associated with StdMaintGroup - can be null
    *
    * OUTPUT PARAMETERS
    *   	@msg	Error message if error occurs, otherwise
    *		Description of StdMaintGroup from EMSH
    *    Default RepairType as per USAGE above.
    *    Default CostCode as per USAGE above.
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   
   (@emco bCompany = null, 
   @equipment bEquip = null, 
   @stdmaintgroup varchar(10) = null,
   @stdmaintitem bItem, 
   @defcostcode varchar(10) output, 
   @defrepairtype varchar(10) output,
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
   /* @stdmaintitem can be null */
   
   select @msg = Description
   from bEMSH
   where EMCo = @emco and Equipment = @equipment and StdMaintGroup = @stdmaintgroup
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Std Maint Group not on file!', @rcode = 1
   	goto bspexit
   	end
   
   /* Get default Repair Type. OK to return null if in neither file. */
   select @defrepairtype = RepairType, @defcostcode = CostCode
   from bEMSI
   where EMCo = @emco and Equipment = @equipment
       and StdMaintGroup = @stdmaintgroup and StdMaintItem = @stdmaintitem
   if @defrepairtype is null
       select @defrepairtype = WODefaultRepType
       from bEMCO
       where EMCo = @emco
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMStdMaintGroupValWithInfo]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStdMaintGroupValWithInfo] TO [public]
GO
