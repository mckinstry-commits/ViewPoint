SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPORBExpValEquip    Script Date: 8/28/99 9:36:00 AM ******/
   CREATE procedure [dbo].[bspPORBExpValEquip]
   /*********************************************
    * Created: DANF 04/23/01
    * Modified: TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    * Usage:
    *  Called from the PO Receiving Batch validation procedure (bspPORBVal)
    *  to validate Equipment information.
    *
    * Input:
    *  @emco       EM Co#
    *  @equip      Equipment
    *  @emgroup    EM Group
    *  @costcode   Cost Code
    *  @emctype    EM Cost Type
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
       @component bEquip, @matlgroup bGroup, @material bMatl, @um bUM, @units bUnits,
       @emum bUM output, @emunits bUnits output, @msg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int, @umconv bUnitCost, @stdum bUM, @emumconv bUnitCost, @type char(1),
   @status char(1), @compofequip bEquip
   
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
       select @msg = 'Equipment: ' + @equip + ' is invalid!', @rcode = 1
       goto bspexit
       end
   if @type <> 'E'
       begin
       select @msg = 'Equipment: ' + @equip + ' must be type E!', @rcode = 1
       goto bspexit
       end
   if @status = 'I'
       begin
       select @msg = 'Equipment: ' + @equip + ' is Inactive!', @rcode = 1
       goto bspexit
       end
   -- validate Component
   if @component is not null
       begin
       select @compofequip = CompOfEquip
       from bEMEM
       where EMCo = @emco and Equipment = @component and Type = 'C'
       if @@rowcount = 0
           begin
           select @msg = 'Component: ' + @component + ' is invalid!', @rcode = 1
           goto bspexit
           end
       if @compofequip <> @equip
           begin
           select @msg = @component + 'is a component of Equipment: ' + @compofequip, @rcode = 1
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
           select @msg = 'Cost code: ' + @costcode + ' and Cost Type: ' + convert(varchar(3),@emctype) +
               ' is invalid for Equipment: ' + @equip, @rcode = 1
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
GRANT EXECUTE ON  [dbo].[bspPORBExpValEquip] TO [public]
GO
