SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlUPriceGet    Script Date: 8/28/99 9:34:53 AM ******/
CREATE  proc [dbo].[vspHQMatlUCostGet]
/**************************************************************************************
* CREATED BY: 	ScottAlvey 04/30/2013 - copy from bspHQMatlUPriceGet
* MODIFIED BY:	
*
* USAGE:
* 	Retrieves the Standard Unit cost for a Material from bHQMT
*	or from HQMU (if a different UM then the Standard)
*
* INPUT PARAMETERS:
*	HQ Material Group
*	HQ Material
*	HQ UM
*
* OUTPUT PARAMETERS:
*	Unit cost from HQMT or HQMU (if a different UM then the Standard)
*	ECM for that UM
*	Error Message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
******************************************************************************************/
(@matlgroup bGroup = null, @material bMatl = null, @um bUM = null,
	@cost bUnitCost = 0 output, @ecm bECM = null output, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0

declare @stdprice bUnitCost, @count integer
   
if @matlgroup is null
	begin
	select @msg = 'Missing HQ Material Group', @rcode = 1
	goto bspexit
	end

/* Validate UM */
If not exists(select 1 from bHQUM with (nolock) where UM = @um)
	begin
	select @msg = 'Not a valid unit of measure.', @rcode = 1
	goto bspexit
	end
   
/* If the unit of measure is not 'LS' the the material may be left blank */
if @material is null and @um <> 'LS' goto bspexit
   
/* Get Price.  Material must be present at this point to continue. */
if @material is null
	begin
	select @msg = 'Missing HQ Material Code.', @rcode = 1
	goto bspexit
	end
   
select @cost = isNull(Cost,0), @ecm = CostECM 
from bHQMT with (nolock)
where MatlGroup = @matlgroup and Material = @material and StdUM = @um
   
if @@rowcount = 0
	/* UM not relative in HQMT, Check HQMU. */
	begin
	select @cost = isNull(Cost,0), @ecm = CostECM 
	from bHQMU with (nolock)
	where MatlGroup = @matlgroup and Material = @material and UM = @um
	if @@rowcount = 0 and exists(select 1 from bHQMT where MatlGroup = @matlgroup and Material = @material)
		begin
		select @msg = 'Invalid UM for this Material.', @rcode=1
		goto bspexit
		end
	end
   
bspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQMatlUCostGet] TO [public]
GO
