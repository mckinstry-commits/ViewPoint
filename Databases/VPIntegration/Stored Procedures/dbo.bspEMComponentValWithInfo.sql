SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspEMComponentValWithInfo]
   
   /***********************************************************
    * CREATED BY: JM 9/10/99
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    *	Validates CompOfEquip vs EMCo and Equipment in EMEM.
    *	Rejects	input if parent Equipment passed in does not
    *	match the parent equipment listed in EMEM for the
    *	Component.
    *
    * INPUT PARAMETERS
    *	@emco			EM Company to be validated against
    *	@component		Component to be validated
    *	@passedparentequip	Parent Equipment to be validated
    *				against in EMEM
    *	@emgroup
    *
    * OUTPUT PARAMETERS
    *	@msg 			    Error or Description of Component
    *	@comptypecode    	ComponentTypeCode for Component if valid
    *	@costcodeout 	    Cost code for component type
    *  @comptypecodedesc   Description of ComponentTypeCode from bEMTY
    *
    * RETURN VALUE
    *	0 success
    *	1 error
    ***********************************************************/
   
   (@emco bCompany = null,
   @component bEquip = null,
   @passedparentequip bEquip = null,
   @emgroup bGroup=null,
   @comptypecode varchar(10) = null output,
   @costcodeout varchar(10) = null output,
   @comptypecodedesc bDesc = null output,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int, @ememparentequip bEquip
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @component is null
   	begin
   	select @msg = 'Missing Component!', @rcode = 1
   	goto bspexit
   	end
   if @emgroup is null
   	begin
   	select @msg = 'Missing EM Group!', @rcode = 1
   	goto bspexit
   	end
   if @passedparentequip is null
   	begin
   	select @msg = 'Missing parent Equipment for Component!', @rcode = 1
   	goto bspexit
   	end
   
   /* Basic validation of Component vs EMEM. */
   exec @rcode = bspEMEquipVal @emco, @component, @msg = @msg output
   if @rcode = 1
      begin
      goto bspexit
      end
   
   /* See if it is a component by EMEM.Type='C'; also, read desc, parent equip
      and componenttypecode. */
   select  @msg = Description,
   	@comptypecode = ComponentTypeCode,
   	@ememparentequip = CompOfEquip
   from dbo.EMEM
   where EMCo = @emco and Equipment = @component and Type='C'
   /* Reject if not a Component. */
   if @@rowcount = 0
   	begin
   	select @msg = 'Equipment is not a Component!', @rcode = 1
   	goto bspexit
   	end
   /* Reject if EMEM.Equipment doesnt match passed 'parent' Equipment. */
   if @ememparentequip <> @passedparentequip
   	begin
   	select @msg = 'Component not valid for this Equipment.', @rcode = 1
   	goto bspexit
   	end
   
   /* Find CostCode and Desc for this Component type */
   select @costcodeout=CostCode, @comptypecodedesc = Description
   From dbo.EMTY
   Where EMGroup=@emgroup and ComponentTypeCode=@comptypecode
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMComponentValWithInfo]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMComponentValWithInfo] TO [public]
GO
