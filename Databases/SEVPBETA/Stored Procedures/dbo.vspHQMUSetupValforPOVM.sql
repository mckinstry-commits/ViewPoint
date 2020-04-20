SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspHQMUSetupValforPOVM    Script Date: 6/20/2007 9:32:47 AM ******/
   CREATE  proc [dbo].[vspHQMUSetupValforPOVM]
   /*************************************
   * Created by:  DC  6/20/07
   * MODIFIED BY: 
   * validates HQMT Purchase/Sales UM vs HQMU.UM and gets; 
   * Std unit cost & ECM, Std price and ECM from HQMT or HQMU
   *
   * Pass:
   *	HQMT.MatlGroup
   *	HQMT.Material
   *	HQMT.PurchaseUM or HQMT.SalesUM
   *
   * Success returns:
   *	Std unit cost
   *	Per E,C, or M
   *	Std price
   *	Per E,C, or M
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@matlgroup tinyint = null, @matl bMatl = null, @um bUM = null, 
		@stdcost bUnitCost output, @stdcostecm bECM output, @stdprice bUnitCost output, 
		@stdpriceecm bECM output, @msg varchar(60) output)

   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0, @stdcost = 0, @stdcostecm = 'E', @stdprice = 0, @stdpriceecm = 'E'
   	declare @hqmucount int
   	declare @hqmtcount int
   	
   	
   if @um is null
   	begin
   	select @msg = 'Missing Unit of Measure', @rcode = 1
   	goto vspexit
   	end
   
   select @hqmucount = count(*) from HQMU where MatlGroup = @matlgroup and Material = @matl and UM = @um
   	if @hqmucount=0
   		begin
   		select @hqmtcount = count(*) from HQMT 
   
   		where MatlGroup=@matlgroup and Material = @matl and StdUM=@um
   			if @hqmtcount=0
   			begin
   				select @msg = 'UM not setup in Material Units of Measure', @rcode = 1
				goto vspexit
   			end
   		end
   
	select @stdcost = Cost, @stdcostecm = CostECM, @stdprice = Price, @stdpriceecm = PriceECM
	from bHQMT
	where MatlGroup = @matlgroup and Material = @matl and StdUM = @um
		if @@rowcount = 0 
			begin
				select @stdcost = Cost, @stdcostecm = CostECM, @stdprice = Price, @stdpriceecm = PriceECM
				from bHQMU
				where MatlGroup = @matlgroup and Material = @matl and UM = @um
			end 

   vspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQMUSetupValforPOVM] TO [public]
GO
