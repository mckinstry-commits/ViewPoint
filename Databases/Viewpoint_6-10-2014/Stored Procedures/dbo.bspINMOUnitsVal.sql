SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspINMOUnitsVal]
    /*****************************************
    Created: RM 03/08/02
	Modified TRL  02/17/10 Issue 134532  vairable and exit for AllNegWarnMSTickets
    
    	Usage: Validates that units in INMOEntry do not exceed on-hand units
    
    *****************************************/
    (@inco bCompany,@loc bLoc,@matlgroup bGroup,@material bMatl,@um bUM,@units bUnits,@msg varchar(255) output)
    as
    
    declare @rcode int, @negwarn bYN,@onhandunits bUnits,@conv bUnitCost, @allownegwarnmstickets bYN
    select @rcode = 0
    
    select @negwarn = NegWarn from INCO where INCo=@inco
    
    if @negwarn='N' goto bspexit
    
	if isnull(@units,0) = 0 goto bspexit
      
    select @onhandunits = OnHand, @allownegwarnmstickets=AllowNegWarnMSTickets from dbo.INMT with(nolock)
    where INCo=@inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   
   if @allownegwarnmstickets = 'N' goto bspexit 
       
    exec @rcode = bspINMOMatlUMVal @inco,@loc,@material,@matlgroup,@um,null,null,@conv output, null,null,@msg output
    
    if @rcode = 1 goto bspexit
    
    select @msg = ''
    
    if (@units * @conv) > @onhandunits
    begin
		select @msg = 'Units exceeds On Hand Qty.',@rcode = 1
		goto bspexit
    end
    
    -------------------------
    bspexit:
  --   if @rcode = 1 select @msg = @msg + ' [bspINMOUnitsVal]'
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOUnitsVal] TO [public]
GO
