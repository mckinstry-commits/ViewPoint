SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspHQMUMatlInfoGet]
   /********************************************************
   * CREATED BY: 	trl 05/08/06
   * MODIFIED BY:	trl 05/08/06
   *
   * USAGE:
   * 	Retrieves the Std Price, Price ECM, Std Cost, Std ECM, WeightConver, PayDiscRate for a Material from bHQMT
   *
   * INPUT PARAMETERS:
   *	HQ Material Group
   *	HQ Material
   *	
   * OUTPUT PARAMETERS:
   *	Unit price from HQMT 
   *	PriceUM, PriceECM, StdUM, StdCost, WieghtConv, PayDiscRate
     *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   	(@matlgroup bGroup=0, @material bMatl=null, @price bUnitCost = 0 output, @PriceECM bECM=null output, 
	@dfltpaydiscrate bRate = 0  output,   @paydisc varchar(1) output, @stdum bUM output, 	  @cost bUnitCost = 0 output, @costECM bECM output,  
	@wtconv bUnitCost = 0 output,  @paydiscrate bUnitCost = 0 output, @msg varchar(60) output)
   
   as
   	set nocount on
   	declare @rcode int
   	select @rcode=0
   	declare @stdcost bUnitCost	
   
   if @matlgroup= 0 
   	begin
   	select @msg='Missing HQ Material Group', @rcode=1
   	goto vspexit
   	end
   if @material is null
   	begin
   	select @msg='Missing HQ Material#', @rcode=1
   	goto vspexit
   	end
   
   /*Need to first validate Material using other stored procedure */
   exec @rcode=bspHQMatlVal @matlgroup, @material, @msg=@msg output
   if @rcode=1 goto vspexit
   
   select @price=isNull(Price,0), @PriceECM=PriceECM, @stdum=StdUM, @cost=isNull(Cost,0), 
   		@wtconv = IsNull(WeightConv,0), @dfltpaydiscrate=IsNull(PayDiscRate,0),@paydisc = PayDiscType,
		@costECM = CostECM, @paydiscrate=IsNull(PayDiscRate,0)
	from bHQMT
   where MatlGroup=@matlgroup and Material=@material
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQMUMatlInfoGet] TO [public]
GO
