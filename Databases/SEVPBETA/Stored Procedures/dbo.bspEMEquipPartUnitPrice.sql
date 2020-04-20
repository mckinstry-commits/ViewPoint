SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMMatUnitPrice    Script Date: 8/28/99 9:34:52 AM ******/
   CREATE      proc [dbo].[bspEMEquipPartUnitPrice]
   /*************************************
   * CREATED BY:  JM 5/30/01 - Logic to extract inventory price copied from bspEMMatlUnitPrice. Eliminated section
   *	dealing with UM coming from form since that value is not known at this time; need to revise UM validation
   *	for appropriate forms to incorporate that logic.
   *	TV 02/11/04 - 23061 added isnulls
   *	TV 09/01/05 29697 - Unit Price is not calculated correctly, Price/100, when ECM C is used.	
   * Usage: Returns default unit price to bspEMEquipPartVal when validating an EM Equip Part specified in inventory.
   *
   * Input Params:
   *	@matlgroup	Group to qualify Material - required
   *   	@inco       	Inventory company - not required
   *   	@loc        	Inventory location - not required
   *	@material	Material being purchased - required
   *
   *Return Params:
   *	@unitprice	Default Unit Price
   *	@msg		Error message if error occurs
   *
   * Return Code:
   *	@rcode 	0 = success, 1 = error
   **************************************/
   (@matlgrp bGroup, @inco bCompany, @loc bLoc, @material bMatl, @unitprice bUnitCost output, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, 
   	@stdunitcost bUnitCost, @stdecm bECM,
   	@equippriceopt tinyint,
   	@emrate bRate,
   	@lastcost bUnitCost, @lastecm bECM,
   	@avgcost bUnitCost, @avgecm bECM,
   	@stdprice bUnitCost, @priceecm bECM,
   	@ecm bECM 
   
   select @rcode = 0, @unitprice = 0
   
   if @matlgrp is null
   	begin
   	select @msg='Missing Material Group', @rcode=1
   	goto bspexit
   	end
   
   if @inco is null
   	begin
   	select @msg='Missing IN Company', @rcode=1
   	goto bspexit
   	end
   
   if @material is null
   	begin
   	select @msg='Missing Material'
   	goto bspexit
   	end
   
   select @lastcost=LastCost, @lastecm = LastECM,
   	@avgcost=AvgCost, @avgecm = AvgECM,
   	@stdunitcost=StdCost, @stdecm = StdECM,
   	@stdprice=StdPrice, @priceecm = PriceECM,
   	@emrate=EquipRate
   from bINMT
   where INCo= @inco and Loc=@loc and Material=@material and MatlGroup=@matlgrp
   if @@rowcount = 0
   	begin
   	select @msg='Part not set up in INMT', @rcode=1
   	goto bspexit
   	end
   
   --TV 09/01/05 29697 - Unit Price is not calculated correctly, Price/100, when ECM C is used.
   select 	@lastcost = (@lastcost/case @lastecm when 'C' then 100 when 'M' then 1000 else 1 end),
    			@avgcost = (@avgcost/case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end),
    			@stdunitcost = (@stdunitcost/case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end),
    			@stdprice = (@stdprice/case @priceecm when 'C' then 100 when 'M' then 1000 else 1 end)
   
   select @equippriceopt=EquipPriceOpt from bINCO where INCo=@inco
   select  @unitprice =
   	case @equippriceopt 
   		when 1 then @avgcost+(@avgcost*@emrate)
   		when 2 then @lastcost+(@lastcost*@emrate)
   		when 3 then @stdunitcost+(@stdunitcost*@emrate)
   		when 4 then @stdprice-(@stdprice*@emrate)
   	end
   
   
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMEquipPartUnitPrice]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipPartUnitPrice] TO [public]
GO
