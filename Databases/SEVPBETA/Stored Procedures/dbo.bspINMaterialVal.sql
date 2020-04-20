SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         procedure [dbo].[bspINMaterialVal]
   /*****************************************************************************
   * Created By: GR 10/26/99
   * Modified by:  GR 04/06/00 - added output params to return cost costecm, price and priceecm
   *				RM 12/23/02 Cleanup Double Quotes
   * Modified by:  TRL 03/16/05 - Issuse #25568 add Category/Description for INLocation Materials
   *		 TRL 02/20/06 - Add IsNull function around Weight Conversion, Price, Cost
   *
   * validates Material
   *
   * Pass:
   *	Material, MaterialGroup
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   *******************************************************************************/
   	(@material bMatl = null, @matlgrp bGroup = null,
       @um bUM output, @stdcost bUnitCost output, @ecm bECM output, @price bUnitCost output, @priceecm bECM output,
       @wtconv bUnits output, @category varchar(40) output ,@msg varchar(60) output )
   as
   	set nocount on
   	declare @rcode int, @stocked bYN
   	select @rcode = 0
   
   if @material is null
       begin
       select @msg='Missing Material', @rcode=1
       goto bspexit
       end
   
   if @matlgrp is null
       begin
       select @msg='Missing Material Group', @rcode=1
       goto bspexit
       end
   
   --check whether material exists in HQMT
   select @msg=HQMT.Description, @um=StdUM, @stdcost=IsNull(Cost,0), @ecm = CostECM, @wtconv= IsNull(WeightConv,0), 
   @stocked = Stocked, @price=IsNull(Price,0), @priceecm=PriceECM, @category=HQMT.Category + ' ' + HQMC.Description
   from dbo.HQMT with (nolock)
   left Join dbo.HQMC on dbo.HQMT.MatlGroup=HQMC.MatlGroup and HQMT.Category=HQMC.Category
   where Material=@material and HQMT.MatlGroup=@matlgrp 
   
   if @@rowcount = 0
       begin
       select @msg='Not set up in HQ Material', @rcode=1
       goto bspexit
       end
   if @stocked <> 'Y'
       begin
       select @msg='Not setup as stocked in HQ Material.', @rcode=1
       goto bspexit
       end
   
   bspexit:
      -- if @rcode<>0 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMaterialVal] TO [public]
GO
