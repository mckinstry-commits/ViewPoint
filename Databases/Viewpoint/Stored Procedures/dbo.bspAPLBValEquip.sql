SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPLBValEquip    Script Date: 8/28/99 9:36:00 AM ******/
   CREATE  procedure [dbo].[bspAPLBValEquip]
   /*********************************************
    * Created: GG 6/25/99
    * Modified: GG 7/15/99 Fixed Component validation
    *           GG 07/26/01 - added Componment Type validation
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *		ES 03/11/04 - #23061 - isnull wrapping
	*			TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    * Usage:
    *  Called from the AP Transaction Batch validation procedure (bspAPLBVal)
    *  to validate Equipment information.
    *
    * Input:
    *  @emco       EM Co#
    *  @equip      Equipment
    *  @emgroup    EM Group
    *  @costcode   Cost Code
    *  @emctype    EM Cost Type
    *  @comptype   Component Type
    *  @component  Component
    *  @matlgroup  Material Group
    *  @material   Material
    *  @um         Posted unit of measure
    *  @units      Posted units
    *
    * Output:
    *  @emum       Unit of Measure tracked for the Equipment, Cost Code, and Cost Type
    *  @emunits    Units expressed in EM unit of measure.  0.00 if not convertable.
    *  @msg        Error message
    *
    * Return:
    *  0           success
    *  1           error
    *************************************************/
   
       @emco bCompany, @equip bEquip, @emgroup bGroup, @costcode bCostCode, @emctype bEMCType,
       @comptype varchar(10), @component bEquip, @matlgroup bGroup, @material bMatl, @um bUM, @units bUnits,
       @emum bUM output, @emunits bUnits output, @msg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int, @umconv bUnitCost, @stdum bUM, @emumconv bUnitCost, @type char(1),
   @status char(1), @compofequip bEquip, @emcomptype varchar(10)
   
   select @rcode = 0, @emunits = 0
   
   if not exists(select * from bEMCO where EMCo = @emco)
       begin
       select @msg = 'Invalid EM Co#!', @rcode = 1
       goto bspexit
       end
   

	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

   -- validate Equipment
   select @type = Type, @status = Status
   from bEMEM
   where EMCo = @emco and Equipment = @equip
   if @@rowcount = 0
       begin
       select @msg = 'Equipment: ' + isnull(@equip, '') + ' is invalid!', @rcode = 1 --#23061
       goto bspexit
       end
   if @type <> 'E'
       begin
       select @msg = 'Equipment: ' + isnull(@equip, '') + ' must be type (E)!', @rcode = 1  --#23061
       goto bspexit
       end
   if @status = 'I'
       begin
       select @msg = 'Equipment: ' + isnull(@equip, '') + ' is Inactive!', @rcode = 1  --#23061
       goto bspexit
       end
   
   --validate Component Type
   if @comptype is not null
       begin
    	if not exists (select * from bEMTY where EMGroup = @emgroup and ComponentTypeCode = @comptype)
           begin
           select @msg = 'Component type: ' + isnull(@comptype, '') + ' is invalid!', @rcode = 1 --#23061
    		goto bspexit
    		end
    	end
   -- validate Component
   if @component is not null
       begin
       select @compofequip = CompOfEquip, @emcomptype = ComponentTypeCode
       from bEMEM
       where EMCo = @emco and Equipment = @component and Type = 'C'
       if @@rowcount = 0
           begin
           select @msg = 'Component: ' + isnull(@component, '') + ' is invalid!', @rcode = 1  --#23061
           goto bspexit
           end
       if @compofequip <> @equip
           begin
           select @msg = @component + 'is a component of Equipment: ' + isnull(@compofequip, ''), @rcode = 1  --#23061
           goto bspexit
           end
       if isnull(@emcomptype,'') <> isnull(@comptype,'')
           begin
           select @msg = 'Posted Component Type does not match the type assigned to this component.', @rcode = 1
           goto bspexit
           end
       end
   
   -- validate Cost Code and Cost Type - get EM unit of measure
   select @emum = UM
   from bEMCH
   where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
   and CostCode = @costcode and CostType = @emctype
   if @@rowcount = 0
       begin
       select @emum = UM
       from bEMCX
       where EMGroup = @emgroup and CostCode = @costcode and CostType = @emctype
       if @@rowcount = 0
           begin
           select @msg = 'Cost code: ' + isnull(@costcode, '') + ' and Cost Type: ' + 
   		isnull(convert(varchar(3),@emctype), '') +
               ' is invalid for Equipment: ' + isnull(@equip, ''), @rcode = 1  --#23061
           goto bspexit
           end
       end
   
   -- if EM unit of measure equals posted unit of measure, set EM units equal to posted
   if @emum = @um
       begin
       select @emunits = @units
       goto bspexit
       end
   
   if @matlgroup is null or @material is null or @units = 0 goto bspexit
   
   -- get conversion for posted unit of measure
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto bspexit
   
   -- get conversion for EM unit of measure
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @emum, @emumconv output, @stdum output, @msg output
   if @rcode <> 0 goto bspexit
   
   if @emumconv <> 0 select @emunits = @units * (@umconv / @emumconv)
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPLBValEquip] TO [public]
GO
