SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE  procedure [dbo].[bspINLocMatlVal]
/***********************************************************************************
    * Created By:	GR 11/12/99
    * Modified By: GR 6/02/00 - added unitprice and priceecm output params
    *				RM 12/23/02 Cleanup Double Quotes
    *				TRL 07/31/07 added dbo.viewname and with(nolock)
    *				GP 05/06/09 - Modified @descip bItemDesc
    *
    * validates Material stocked at the production Location in IN Materital(INMT)
    *
    * Pass:
    *	@inco           IN Company
    *   @location       IN Location
    *   @material       Material
    *   @matlgrp        Material Group
    *   @activeopt      Active option - Y = must be active, N = may be inactive
    *   @prodmatlYN     Y- only if it is a finished i.e produnction material used in Production Posting program
    *                   and in all other programs it will be N
    *                   (this parameter is hardcoded from wherever the procedure is called)
    *
    * Success returns:
    *	0
    *   UM            Std Unit of Measure
    *   WtConv        Weight Conversion from INMT
    *   Description   Description from HQMT
    *   OnHand        On Hand Units
    *   UnitCost      Unit Cost
    *   ECM           ECM
    *   TaxCode       TaxCode for this location
    *   Taxable       Taxable Yes/No Flag
    *   AdjGLAcct     Inventory Adjustment GL Account
    * Error returns:
    *	1 and error message
************************************************************************************/
   (@inco bCompany = null,
    @location bLoc = null,
	@material bMatl = null,
	@matlgrp bGroup = null,
    @activeopt bYN = null,
	@prodmatlYN bYN = null,
    @um bUM = null output,
    @wtconv bUnits = null output,
    @descrip bItemDesc = null output,
	@onhand bUnits = null output, 
    @unitcost bUnitCost = null output,
    @ecm bECM = null output,
	@taxcode bTaxCode = null output,
    @taxable bYN = null output,
    @adjglacct bGLAcct = null output,
    @costmethod int = null output,
    @unitprice bUnitCost = null output,
	@priceecm bECM = null output,
	@msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @active bYN, @locgroup bGroup, @validcnt int, @stocked bYN, 
   		@category varchar(10), @invpriceopt int, @loccostmethod int, @locadjglacct bGLAcct,
   		@loctaxcode bTaxCode, @incocostmethod int
   
   
   
   select @rcode = 0
    
   if @inco is null
        begin
        select @msg='Missing IN Company', @rcode=1
        goto bspexit
        end
    
   if isnull(@location,'') = ''
        begin
        select @msg='Missing Location', @rcode=1
        goto bspexit
        end
    
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
    
   -- get inventory sales price option from IN Company
   select @invpriceopt=InvPriceOpt, @incocostmethod=CostMethod
   from dbo.INCO with (nolock) where INCo=@inco
   
   -- get location data
   select @locgroup=LocGroup, @loccostmethod=CostMethod, @locadjglacct=AdjGLAcct, @loctaxcode=TaxCode
   from dbo.INLM with (nolock) where INCo=@inco and Loc=@location
    
   --get category and material description
   select @category=Category, @msg = Description, @descrip=Description,  @um = StdUM, 
   	   @stocked = Stocked, @taxable = Taxable
   from dbo.HQMT with (nolock)
   where  MatlGroup=@matlgrp and Material=@material
   if @@rowcount = 0
        begin
        select @msg='Material not set up in HQ Materials', @rcode=1
        goto bspexit
        end
    
   if @stocked = 'N'
        begin
        select @msg = 'Must be a Stocked Material.', @rcode = 1
        goto bspexit
        end
    
    --Get cost method
    select @costmethod=CostMethod, @adjglacct=AdjGLAcct 
    from dbo.INLO with (nolock)
    where INCo=@inco and Loc=@location and MatlGroup=@matlgrp and Category=@category
    if @costmethod is null or @costmethod=0
        begin
        --select @costmethod=CostMethod from bINLM with (nolock)
        --where INCo=@inco and Loc=@location
   	 select @costmethod=@loccostmethod
        if @costmethod is null or @costmethod = 0
            begin
            --select @costmethod=CostMethod from bINCO with (nolock) where INCo=@inco
   		 select @costmethod=@incocostmethod
            end
        end
    
   -- Get adjustment glacct
   if @adjglacct is null
    	--select @adjglacct=AdjGLAcct from bINLM with (nolock) where INCo=@inco and Loc=@location
   	select @adjglacct=@locadjglacct
    
   if @adjglacct is null
   	begin
   	select @msg = 'Missing Adjustment GL Account', @rcode = 1
   	goto bspexit
   	end
    
   --validate material in INMT
   select @wtconv = i.WeightConv, @active = i.Active, @onhand = IsNull(i.OnHand,0),
   	   @unitcost=case @costmethod when 1 then i.AvgCost when 2 then i.LastCost when 3 then i.StdCost end,
   	   @ecm=case @costmethod when 1 then i.AvgECM when 2 then i.LastECM when 3 then i.StdECM end,
   	   @unitprice=case @invpriceopt when 1 then i.AvgCost + (i.AvgCost * i.InvRate)
                 when 2 then i.LastCost + (i.LastCost * i.InvRate)
                 when 3 then i.StdCost + (i.StdCost * i.InvRate)
                 when 4 then i.StdPrice - (i.StdPrice * i.InvRate) end,
   	   @priceecm=case @invpriceopt when 1 then i.AvgECM when 2 then i.LastECM
                when 3 then i.StdECM when 4 then i.PriceECM end
   from dbo.INMT i with (nolock)
   where i.INCo = @inco and i.Loc = @location and i.MatlGroup=@matlgrp and i.Material=@material 
   if @@rowcount = 0
        begin
        select @msg='Material not set up in IN Location Materials', @rcode=1
        goto bspexit
        end
   if @activeopt = 'Y' and @active = 'N'
        begin
        select @msg = 'Must be an active Material.', @rcode = 1
        goto bspexit
        end
    
   --get tax code for AP and PO
   if @taxable = 'Y'
   	begin
       --select @taxcode = TaxCode from bINLM with (nolock) where INCo=@inco and Loc = @location
   	select @taxcode=@loctaxcode
   	end
    
   --this check is done only if it is a production material used in Production Posting program
   if @prodmatlYN = 'Y'
   	begin
       --check whether bill of materials setup for this material
       --select @locgroup=LocGroup from bINLM with (nolock) where INCo=@inco and Loc=@location
       select @validcnt=count(*) from dbo.INBM with (nolock)
       where INCo=@inco and LocGroup=@locgroup and MatlGroup=@matlgrp and FinMatl=@material
       if @validcnt = 0
           begin
     		select @validcnt=count(*) from dbo.INBO with (nolock)
           where INCo=@inco and Loc=@location and MatlGroup=@matlgrp and FinMatl=@material
           if @validcnt=0
           	begin
               select @msg = 'Finished Good not setup with a Bill of Materials', @rcode=1
               goto bspexit
               end
           end
       end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINLocMatlVal] TO [public]
GO
