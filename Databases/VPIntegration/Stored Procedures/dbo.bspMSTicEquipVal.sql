SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE procedure [dbo].[bspMSTicEquipVal]
/***********************************************************
 * Created By:  GF 06/28/2000
    * Modified By: GG 01/24/01 - initialized output parameters to null
    *				GF 09/08/2004 - issue #25449 validate equipment type = 'E' only
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    *
    * USAGE:
    *	Validates EMEM.Equipment for MSTicEntry
    *
    * INPUT PARAMETERS
    *	@emco		EM Company
    *	@equip		Equipment to be validated
    *
    * OUTPUT PARAMETERS
    *  @prco           Default PR Company
    *  @operator       Default Equipment operator/employee
    *  @tare           Equipment Tare Weight
    *  @category       EM Equipment Category
    *  @trucktype      Default Truck Type
    *  @revcode        Default EM Revenue Code
    *	@msg 		    Equipment description or error message
    *
    * RETURN VALUE
    *	0 success
    *	1 error
    ***********************************************************/
(@emco bCompany = null, @equip bEquip = null, @prco bCompany = null output,
 @operator bEmployee = null output, @tare bUnits = null output, @weightum bUM = null output,
 @category bCat = null output, @trucktype varchar(10) = null output, @revcode bRevCode = null output,
 @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @status char(1), @type varchar(1)

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

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
begin
	  goto bspexit
end

select @msg=Description, @status=Status, @prco=PRCo, @operator=Operator, @tare=TareWeight,
          @weightum=WeightUM, @trucktype=MSTruckType, @revcode=RevenueCode, @category=Category, @type=Type
from EMEM with (nolock) where EMCo = @emco and Equipment = @equip
if @@rowcount = 0
   	begin
   	select @msg = 'Equipment invalid!', @rcode = 1
   	goto bspexit
   	end

---- reject if type = 'C' component
if @type <> 'E'
   	begin
   	select @msg = 'Equipment Type must be (E) for equipment!', @rcode = 1
   	goto bspexit
   	end

---- Reject if Status inactive.
if @status = 'I'
   	begin
   	select @msg = 'Equipment Status is Inactive!', @rcode = 1
   	goto bspexit
   	end



bspexit:
   	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicEquipVal] TO [public]
GO
