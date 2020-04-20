SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************/
CREATE  proc [dbo].[bspJCMatlUseUnitsVal]
/*****************************************
 * Created By:	GF 01/20/2008 issue #28488
 * Modified By:
 *
 *
 * Usage: Validates that units in JC Material Usage do not exceed on-hand units
 * when the transaction type is 'IN'
 *
 *   	
 *   
 ******************************************/
(@inco bCompany, @loc bLoc, @matlgroup bGroup, @material bMatl, @um bUM,
 @units bUnits, @jctranstype varchar(2), @msg varchar(255) output)
as

declare @rcode int, @negwarn bYN, @onhandunits bUnits, @conv bUnitCost

select @rcode = 0, @msg = ''

---- exit if JC Transaction Type is anything other than 'IN'
if isnull(@jctranstype,'MI') <> 'IN' goto bspexit

---- exit if no units
if isnull(@units,0) = 0 goto bspexit

---- get negative warning flag from INCO
select @negwarn = NegWarn
from INCO with (nolock) where INCo=@inco
if @@rowcount = 0 or @negwarn = 'N' goto bspexit

---- get on hand units from location materials
select @onhandunits = OnHand 
from INMT with (nolock)
where INCo=@inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material

---- exec in material um validation
exec @rcode = bspINMOMatlUMVal @inco, @loc, @material, @matlgroup, @um, null, null, @conv output, null, null, @msg output
if @rcode = 1 goto bspexit

---- set message when units times conversion exceeds on hand
if (@units * @conv) > @onhandunits
	begin
	select @msg = 'Units exceeds On Hand Qty.',@rcode = 1
	goto bspexit
    end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCMatlUseUnitsVal] TO [public]
GO
