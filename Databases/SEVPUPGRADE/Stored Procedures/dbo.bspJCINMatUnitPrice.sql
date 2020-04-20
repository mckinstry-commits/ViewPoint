SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCINMatUnitPrice    Script Date: 8/28/99 9:34:52 AM ******/
   CREATE    proc [dbo].[bspJCINMatUnitPrice]
   /*************************************
   * CREATED BY:  DANF 06/06/2000
   * Modified By: TV - 23061 added isnulls
   *			   DANF 02/28/2005 - Issue 27255 Changed Data type of conversion values from bUnits to bUnitCost.
   *
   *
   *
   * This procedure is called from JCMatUse
   *
   * Usage:
   * Searches through HQ and JC AND IN tables using Material, UM and Job to find
   * a default unit price.
   
   * Returns 0.00E unit cost if the Material and UM combination does not exist in HQ.
   *
   * Input Params:
   *	@matlgroup	Group to qualify Material - required
   *   @inco       Inventory company - not required
   *   @loc        Inventory location - not required
   *	@material	Material being purchased - required
   *	@um		    Unit of measure in which the material is being sold - required.
   *	@jcco		Job Cost company to qualify job - optional
   *	@job		Job the material is being sold to - optional
   
   *
   *Return Params:
   *	@unitcost	Default Unit Cost
   *	@ecm		Unit Cost per Each, Hundred, or Thousand
   *	@msg		Error message if error occurs
   * Return Code:
   *	@rcode 		0 = success, 1 = error
   **************************************/
   	(@matlgrp bGroup, @inco bCompany, @loc bLoc, @material bMatl, @um bUM, @jcco bCompany, @job bJob,
        @salunitcost bUnitCost output, @salecm bECM output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int,
       @stdum bUM, @stdunitcost bUnitCost, @stdecm bECM, @salum bUM,
       @mphase bPhase, @mcosttype bJCCType, @taxable bYN,
       @jobsalesacct bGLAcct, @onhand bUnits, @available bUnits,
       @valid bYN, @stocked bYN, @jobprice as tinyint,
       @injobrate as bRate, @jcjobrate as bRate, @jobrate as bRate,
       @lastcost bUnitCost, @lastcostecm bECM,
       @avgcost bUnitCost, @avgcostecm bECM,
       @stdprice bUnitCost, @stdpriceecm bECM,
       @category varchar(10), @validmat bYN,
       @inumconv bUnitCost, @incost bUnitCost,
       @incostecm bECM, @inprice bUnitCost,
       @inpriceecm bECM,
       @hqumconv bUnitCost, @hqcost bUnitCost,
       @hqcostecm bECM, @hqprice bUnitCost,
       @hqpriceecm bECM, @inlastcost bUnitCost
   
   select @rcode = 0, @salunitcost = 0, @salecm = 'E'
   
   if @material is null
       begin
       select @msg='Missing Material', @rcode=1
       goto bspexit
       end
   
   select @valid = 'Y'
   
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
     from bHQMT with (nolock)
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
               from HQMU with (nolock)
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
     from bHQMT with (nolock)
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
   
     select @jcjobrate = 0
   
    if @job is not null and @job <> ''
     begin
       select @jcjobrate=MarkUpDiscRate
       from bJCJM with (nolock)
       where JCCo=@jcco and Job = @job
    end
   
     select @jobprice=JobPriceOpt
     from bINCO with (nolock)
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
            @injobrate=JobRate
     from bINMT with (nolock)
     where INCo= @inco and Loc=@loc and Material=@material and MatlGroup=@matlgrp
     if @@rowcount = 0
       begin
       select @msg='Not set up in IN Materials', @rcode=1
       goto bspexit
       end
   
    -- select @salum=@stdum
      select @jobrate =0
   
      if @jcjobrate <> 0  select @jobrate=@jcjobrate
      if @jobrate = 0 and @injobrate <>0  select @jobrate = @injobrate
   
        if @um <> @stdum
          begin
           select @inumconv = Conversion, @incost = StdCost, @incostecm = StdCostECM,
                  @inprice = Price, @inpriceecm = PriceECM, @inlastcost = LastCost
           from INMU with (nolock)
           Where INCo = @inco and Material=@material and MatlGroup=@matlgrp and Loc = @loc and UM = @um
           if @@rowcount <> 0
              begin
              select @avgcost = @avgcost * @inumconv,
                     @stdunitcost = @incost, @stdprice = @inprice,
                     @stdecm = @incostecm, @stdpriceecm = @inpriceecm,
   				  @lastcost = @lastcost * @inumconv
   				  -- @lastcost= case when @inlastcost = 0 then @lastcost * @inumconv else @inlastcost end
              end
           else
              begin
              select @hqumconv = Conversion, @hqcost = Cost, @hqcostecm = CostECM,
                      @hqprice = Price, @hqpriceecm = PriceECM
              from HQMU with (nolock)
              Where Material=@material and MatlGroup=@matlgrp and UM = @um
              if @@rowcount <> 0
                  begin
                  select @avgcost = @avgcost * @hqumconv, @lastcost = @lastcost * @hqumconv,
                         @stdunitcost = @hqcost, @stdprice = @hqprice,
                         @stdecm = @hqcostecm, @stdpriceecm = @hqpriceecm
                  end
   
              end
          end
   
   
     If @jobprice = 1
       begin
       select  @salunitcost=@avgcost+(@avgcost*@jobrate), @salecm=@avgcostecm
       end
   
     If @jobprice = 2
       begin
       select  @salunitcost=@lastcost+(@lastcost*@jobrate), @salecm=@lastcostecm
       end
   
      If @jobprice = 3
       begin
       select  @salunitcost=@stdunitcost+(@stdunitcost*@jobrate), @salecm=@stdecm
       end
   
      If @jobprice = 4
       begin
       select  @salunitcost=@stdprice-(@stdprice*@jobrate), @salecm=@stdpriceecm
       end
   
   end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCINMatUnitPrice] TO [public]
GO
