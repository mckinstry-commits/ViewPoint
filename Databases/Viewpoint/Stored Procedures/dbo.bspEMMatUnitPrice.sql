SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMMatUnitPrice    Script Date: 8/28/99 9:34:52 AM ******/
   CREATE   proc [dbo].[bspEMMatUnitPrice]
   /*************************************
   * CREATED BY:  DANF 06/19/2000
   *				TV 02/11/04 - 23061 added isnulls
   * This procedure is called from EM for defaulting the unit price
   *
   * Usage:
   * Searches through HQ and IN tables using Material, and UM to find
   * a default unit price.
   
   * Returns 0.00E unit cost if the Material and UM combination does not exist in HQ.
   *
   * Input Params:
   *	@matlgroup	Group to qualify Material - required
   *   @inco       Inventory company - not required
   *   @loc        Inventory location - not required
   *	@material	Material being purchased - required
   *	@um		    Unit of measure in which the material is being sold - required.
   *   @valid      Requires valid material
   *
   *Return Params:
   *	@unitcost	Default Unit Price
   *	@ecm		Unit Cost per Each, Hundred, or Thousand
   *	@msg		Error message if error occurs
   * Return Code:
   *	@rcode 		0 = success, 1 = error
   **************************************/
   	(@matlgrp bGroup, @inco bCompany, @loc bLoc, @material bMatl, @um bUM, @valid bYN = 'Y',
        @salunitcost bUnitCost output, @salecm bECM output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int,
       @stdum bUM, @stdunitcost bUnitCost, @stdecm bECM, @salum bUM,
       @mphase bPhase, @mcosttype bJCCType, @taxable bYN,
       @jobsalesacct bGLAcct, @onhand bUnits, @available bUnits,
       @stocked bYN, @emprice as tinyint,
       @inemrate as bRate, @jcemrate as bRate, @emrate as bRate,
       @lastcost bUnitCost, @lastcostecm bECM,
       @avgcost bUnitCost, @avgcostecm bECM,
       @stdprice bUnitCost, @stdpriceecm bECM,
       @category varchar(10), @validmat bYN,
       @inumconv bUnits, @incost bUnitCost,
       @incostecm bECM, @inprice bUnitCost,
       @inpriceecm bECM,
       @hqumconv bUnits, @hqcost bUnitCost,
       @hqcostecm bECM, @hqprice bUnitCost,
       @hqpriceecm bECM
   
   select @rcode = 0, @salunitcost = 0, @salecm = 'E'
   
   if @material is null
       begin
       select @msg='Missing Material'
       goto bspexit
       end
   
   if @matlgrp is null
       begin
       select @msg='Missing Material Group', @rcode=1
       goto bspexit
       end
   
   --check whether material exists in HQMT
   If @loc is null or @loc =''
     begin
     select @msg=Description, @stdum=StdUM, @stdunitcost=Cost, @stdecm=CostECM,
            @salum=SalesUM, @salunitcost=Price, @salecm= PriceECM
     from bHQMT
     where Material=@material and MatlGroup=@matlgrp
     IF @@rowcount =0
         begin
           select @msg = 'Miscellanous Material'
           select @valid = 'N', @salecm = 'E'
           if @validmat = 'Y' select @rcode = 1
         end
      else
       if @stdum <> @um
         begin
               select   @salunitcost = Price, @salecm =  PriceECM
               from HQMU
               Where Material=@material and MatlGroup=@matlgrp and UM = @um
          end
       goto bspexit
     end
   else
     begin
   
     select @msg=Description, @stdum=StdUM,
               @salum=SalesUM,  @salecm= PriceECM,
              @mphase=MatlPhase, @mcosttype=MatlJCCostType,
              @stocked  = Stocked, @taxable = Taxable,
              @category = Category
     from bHQMT
     where Material=@material and MatlGroup=@matlgrp
     if @@rowcount = 0
       begin
       select @msg='Not set up in HQ Material', @rcode=1
       goto bspexit
       end
   
     if @stocked = 'N'
       begin
       select @msg='Material is not flag as a stocked Item.', @rcode=1
       goto bspexit
       end
   
     select @emprice=EquipPriceOpt
     from bINCO
     where INCo=@inco
     if @@rowcount = 0
       begin
       select @msg='Missing Inventory Company.', @rcode=1
       goto bspexit
       end
   
   
     select @lastcost=LastCost, @lastcostecm=LastECM,
            @avgcost=AvgCost, @avgcostecm=AvgECM,
            @stdunitcost=StdCost, @stdecm=StdECM,
            @stdprice=StdPrice, @stdpriceecm=PriceECM,
            @emrate=EquipRate
     from bINMT
     where INCo= @inco and Loc=@loc and Material=@material and MatlGroup=@matlgrp
     if @@rowcount = 0
       begin
       select @msg='Not set up in IN Materials', @rcode=1
       goto bspexit
       end
   
        if @um <> @stdum
          begin
            select @hqumconv = Conversion, @hqcost = Cost, @hqcostecm = CostECM,
                   @hqprice = Price, @hqpriceecm = PriceECM
            from HQMU
            Where Material=@material and MatlGroup=@matlgrp and UM = @um
            if @@rowcount <> 0
               begin
                select @avgcost = @avgcost * @hqumconv, @lastcost = @lastcost * @hqumconv,
                       @stdunitcost = @hqcost, @stdprice = @hqprice,
                       @stdecm = @hqcostecm, @stdpriceecm = @hqpriceecm
               end
   
            select @inumconv = Conversion, @incost = StdCost, @incostecm = StdCostECM,
                   @inprice = Price, @inpriceecm = PriceECM
            from INMU
            Where INCo = @inco and Material=@material and MatlGroup=@matlgrp and Loc = @loc and UM = @um
            if @@rowcount <> 0
              begin
              select @avgcost = @avgcost * @inumconv, @lastcost = @lastcost * @inumconv,
                     @stdunitcost = @incost, @stdprice = @inprice,
                     @stdecm = @incostecm, @stdpriceecm = @inpriceecm
              end
          end
   
   
     If @emprice = 1
       begin
       select  @salunitcost=@avgcost+(@avgcost*@emrate), @salecm=@avgcostecm
       end
   
     If @emprice = 2
       begin
       select  @salunitcost=@lastcost+(@lastcost*@emrate), @salecm=@lastcostecm
       end
   
      If @emprice = 3
       begin
       select  @salunitcost=@stdunitcost+(@stdunitcost*@emrate), @salecm=@stdecm
       end
   
      If @emprice = 4
       begin
       select  @salunitcost=@stdprice-(@stdprice*@emrate), @salecm=@stdpriceecm
       end
   
    end
   
   bspexit:
                if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMMatUnitPrice]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMMatUnitPrice] TO [public]
GO
