SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPMMFUnitsVal]
   /*****************************************
    * Created By:	GF 09/10/2003
    * Modified By:
    *
    *
    * Usage: Validates that units in PM Material do not exceed on-hand units. 
    *		  Valid for Material Type 'M' only. IN material orders.
    *
    *	
    *
    *****************************************/
   (@inco bCompany, @loc bLoc, @matlgroup bGroup, @material bMatl, 
    @um bUM, @units bUnits, @materialtype char(1), @msg varchar(255) output)
   as
    
   declare @rcode int, @negwarn bYN, @onhandunits bUnits, @conv bUnitCost
   
   select @rcode = 0
   
   if isnull(@materialtype,'P') <> 'M' goto bspexit
   
   -- get warning flag from INCo
   select @negwarn = NegWarn from INCO with (nolock) where INCo=@inco
   if @negwarn='N' goto bspexit
    
   select @onhandunits = OnHand from bINMT with (nolock)
   where INCo=@inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
    
   exec @rcode = dbo.bspINMOMatlUMVal @inco,@loc,@material,@matlgroup,@um,null,null,@conv output, null,null,@msg output
   if @rcode = 1 goto bspexit
    
   select @msg = ''
    
   if (@units * @conv) > @onhandunits
   	begin
    	select @msg = 'Units exceeds On Hand Qty.',@rcode = 1
    	goto bspexit
   	end
    
    
   
   
   bspexit:
   	if @rcode = 1 select @msg = isnull(@msg,'') + ' [bspINMOUnitsVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMFUnitsVal] TO [public]
GO
