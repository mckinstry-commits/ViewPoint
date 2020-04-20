SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMStdMaintItemVal]
   
   /***********************************************************
    * CREATED BY: JM 9/20/98
    * MODIFIED By : JM 12/17/99 - Added output of bEMSI.RepairType to overwrite
    *  bEMCO.WODefaultRepType on EMWOEdit form if Work Order is tied to a SMG and
    *  the SMI has a RepairType.
    *    JM 2/16/00 - Delete @formrepairtype input
    *    JM 2/28/00 - Added return of default CostCode; ref Issue 6430
    *	  TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    * Validates EM Std Maint Item vs bEMSI by EMCo, Equipment and StdMaintGroup.
    * Error returned if any of the following occurs
    *
    * 	No EMCo passed
    *	No Equipment passed
    *	No StdMaintGroup passed
    *	No StdMaintItem passed
    *	StdMaintItem not found in EMSI
    *
    * INPUT PARAMETERS
    *	EMCo		EMCo to validate against
    *	Equipment	Equipment to validate against
    *	StdMaintGroup  	StdMaintGroup to validate against
    *	StdMaintItem  	StdMaintItem to validate
    *
    * OUTPUT PARAMETERS
    *   	@msg	Error message if error occurs, otherwise
    *    @costcode
    *		Description of StdMaintItem from EMSI
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   
   (@emco bCompany = null, @equip bEquip = null, @stdmaintgroup varchar(10) = null,
   @stdmaintitem smallint = null, @repairtype varchar(10) output, @costcode varchar(10) output,
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
   
   if @equip is null
   	begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
   	end
   
   if @stdmaintgroup is null
   	begin
   	select @msg = 'Missing Std Maint Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @stdmaintitem is null
   	begin
   	select @msg = 'Missing Std Maint Item!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @repairtype = RepairType, @costcode = CostCode
   from bEMSI
   where EMCo = @emco and Equipment = @equip and StdMaintGroup = @stdmaintgroup
   	and StdMaintItem = @stdmaintitem
   if @@rowcount = 0
   	begin
   	select @msg = 'Std Maint Item not on file!', @rcode = 1
   	goto bspexit
   	end
   /* If null get std default from bEMCO. */
   if @repairtype is null
       select @repairtype = WODefaultRepType
       from bEMCO
       where EMCo = @emco
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMStdMaintItemVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStdMaintItemVal] TO [public]
GO
