SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatPriceGet    Script Date: 8/28/99 9:34:52 AM ******/
   CREATE  proc [dbo].[bspHQMatPriceGet]
   /********************************************************
   * Created by: 	GG 06/20/97
   * Last modified by:
   *
   * Usage:
   * 	Used by POVM to get Standard Unit Cost and Price for a HQ Material
   *
   * Input params:
   *	@matlgroup	Material Group
   *	@material	Material
   *	@um		Unit of measure
   *
   * Returns:
   *	Std unit cost
   *	Per E,C, or M
   *	Std price
   *	Per E,C, or M
   *
   **********************************************************/
   	(@matlgroup bGroup=0, @material bMatl=null, @um bUM=null)
   
   as
   set nocount on
   declare @stdcost bUnitCost, @stdcostecm bECM, @stdprice bUnitCost, @stdpriceecm bECM
   select @stdcost = 0, @stdcostecm = 'E', @stdprice = 0, @stdpriceecm = 'E'
   
   select @stdcost = Cost, @stdcostecm = CostECM, @stdprice = Price, @stdpriceecm = PriceECM
   	from bHQMT
   	where MatlGroup = @matlgroup and Material = @material and StdUM = @um
   if @@rowcount = 0 
   	begin
         	select @stdcost = Cost, @stdcostecm = CostECM, @stdprice = Price, @stdpriceecm = PriceECM
   	from bHQMU
      	where MatlGroup = @matlgroup and Material = @material and UM = @um
     	end 
   
   /* return */
   select 'StdCost' = @stdcost, 'StdCostECM' = @stdcostecm, 'StdPrice' = @stdprice, 'StdPriceECM' = @stdpriceecm

GO
GRANT EXECUTE ON  [dbo].[bspHQMatPriceGet] TO [public]
GO
