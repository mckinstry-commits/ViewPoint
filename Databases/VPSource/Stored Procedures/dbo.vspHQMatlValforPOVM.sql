SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspHQMatlValforPOVM   */
   CREATE  proc [dbo].[vspHQMatlValforPOVM]
   /*************************************
   * Created by: 	DC  06/20/2007
   * Last modified by:
   *
   * Usage:  
   * validates HQ Material vs HQMT.Material and gets; 
	* Std unit cost & ECM, Std price and ECM from HQMT or HQMU
   *
   *   * Pass:
   *	HQ MatlGroup
   *	HQ Material
   *
   * Success returns:
   *    Purchase Unit Of measure
   *	Description from bHQMT
   *	Std unit cost
   *	Per E,C, or M
   *	Std price
   *	Per E,C, or M
   *
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@matlgroup bGroup = null, @material bMatl = null, @purchum bUM=null output, 
		@stdcost bUnitCost output, @stdcostecm bECM output, @stdprice bUnitCost output, 
		@stdpriceecm bECM output, @msg varchar(60) output)


   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0, @stdcost = 0, @stdcostecm = 'E', @stdprice = 0, @stdpriceecm = 'E'

   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group', @rcode = 1
   	goto vspexit
   	end
   
   if @material is null
   	begin
   	select @msg = 'Missing Material', @rcode = 1
   	goto vspexit
   	end
   
   select @msg = Description, @purchum=PurchaseUM from bHQMT where MatlGroup = @matlgroup and 
   	Material = @material
   	if @@rowcount = 0
   		begin
   		select @msg = 'Material not on file.', @rcode = 1
		goto vspexit
   		end

	select @stdcost = Cost, @stdcostecm = CostECM, @stdprice = Price, @stdpriceecm = PriceECM
	from bHQMT
	where MatlGroup = @matlgroup and Material = @material and StdUM = @purchum
		if @@rowcount = 0 
			begin
				select @stdcost = Cost, @stdcostecm = CostECM, @stdprice = Price, @stdpriceecm = PriceECM
				from bHQMU
				where MatlGroup = @matlgroup and Material = @material and UM = @purchum
			end 

   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQMatlValforPOVM] TO [public]
GO
