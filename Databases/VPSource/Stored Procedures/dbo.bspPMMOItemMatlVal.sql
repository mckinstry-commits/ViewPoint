SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************/
CREATE  proc [dbo].[bspPMMOItemMatlVal]
/*****************************************
   * Created By:   GF 02/18/2002
   * Modified By: 	GG 08/12/02 - #17811 - old/new templat prices, added @date param to bspMSTicMatlPriceGet
   *				GF 12/11/2003 - issue #23259 - when material assigned to IN location without unit cost, get price from IN
   *				GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
   *
   * validates Material to HQMT.Material from PM MO Items
   *
   * Pass:
   *   IN Company, Location, MatlGroup, Material, MatlUM, UMVal, JCCo, Job
   *
   * Success returns:
   *   Standard UM
   *   Standard Unit Price
   *   Standard ECM
   *	Purchase UM
   *	Purchase Unit Price
   *   Sales UM
   *   Unit Price
   *   ECM
   *	Matl Phase
   *	Matl CostType
   *	Quantity On Hand
   *	Quantity On Order
   *	Quantity Allocated
   *	Material Taxable Flag
   *	0 and Description from bHQMT
   *
   * Error returns:
   *	1 and error message
 **************************************/
(@pmco bCompany = null, @job bJob = null, @inco bCompany = null, @loc bLoc = null,
 @matlgroup bGroup = null, @material bMatl = null, @matlum bUM = null, @umval bYN = 'N',
 @stdum bUM output, @stdup bUnitCost output, @stdecm bECM output, @salesum bUM output,
 @unitprice bUnitCost = 0 output, @ecm bECM = 'E' output, @phase bPhase = null output, @costtype bJCCType = null output,
 @onhand bUnits = 0 output, @onorder bUnits = 0 output, @alloc bUnits = 0 output, @taxable bYN = 'N' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @validcnt int, @category varchar(10), @saletype char(1),
		@jobpriceopt tinyint, @hqstdum bUM, @priceopt tinyint, @stocked bYN, @minamt bDollar,
   		@locgroup bGroup, @tmpmsg varchar(255), @salesecm bECM, @stdunitcost bUnitCost,
   		@salesunitcost bUnitCost, @inmtwgtconv bUnits, @matlumconv bUnitCost, @pricedate bDate,
		@MatlVendor bVendor, @VendorGroup bGroup


select @rcode = 0, @retcode = 0, @saletype = 'J', @onhand = 0, @onorder = 0, @alloc = 0, @taxable = 'N'

if @inco is null
	begin
	select @msg = 'Missing IN Company!', @rcode = 1
	goto bspexit
	end

if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end

if @material is null
	begin
	select @msg = 'Missing Material!', @rcode = 1
	goto bspexit
	end

if @loc is null
	begin
	select @msg = 'Missing Location!', @rcode = 1
	goto bspexit
	end

---- get location group
select @locgroup=LocGroup from bINLM with (nolock) where INCo=@inco and Loc=@loc

---- get IN company pricing options
select @priceopt=JobPriceOpt from bINCO with (nolock) where INCo=@inco
if @@rowcount = 0
	begin
	select @msg = 'Unable to get IN Company parameters!', @rcode = 1
	goto bspexit
	end

---- validate material
select @msg=Description, @category=Category, @stocked=Stocked, @stdum=StdUM,
		@stdup=Price, @stdecm=PriceECM, @salesum=SalesUM, @phase=MatlPhase,
		@costtype=MatlJCCostType, @taxable=Taxable, @hqstdum=StdUM, @stdunitcost=Cost,
		@salesunitcost=Price, @salesecm=PriceECM
from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0
	begin
	select @msg = 'Invalid Material!', @rcode = 1
	goto bspexit
	end
if @stocked <> 'Y'
	begin
	select @msg = 'Invalid, not a stocked material!', @rcode = 1
	goto bspexit
	end


---- material validation only
if @umval = 'N'
	BEGIN
----   	select @msg=Description, @category=Category, @stocked=Stocked, @stdum=StdUM,
----   		   @stdup=Price, @stdecm=PriceECM, @salesum=SalesUM, @phase=MatlPhase,
----   		   @costtype=MatlJCCostType, @taxable=Taxable, @hqstum=StdUM, @stdunitcost=Cost,
----		@salesunitcost=Price, @salesecm=PriceECM
----   	from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
----   	if @@rowcount = 0
----       	begin
----       	select @msg = 'Invalid Material!', @rcode = 1
----       	goto bspexit
----       	end
----   	if @stocked <> 'Y'
----   		begin
----   		select @msg = 'Invalid, not a stocked material!', @rcode = 1
----   		goto bspexit
----   		end
   
   	---- validate IN Location Materials
   	select @onhand=OnHand, @onorder=OnOrder, @alloc=Alloc
   	from bINMT with (nolock) where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 0
   		begin
   		select @msg = 'Invalid material, not set up for location ' + @loc + '!', @rcode = 1
   		goto bspexit
   		end
   
   	exec @retcode = dbo.bspINMOMatlUMVal @inco, @loc, @material, @matlgroup, @salesum, @pmco, @job, 
   			null, @ecm output, @unitprice output, @tmpmsg output
   	if @retcode <> 0
       	begin
       	select @unitprice = 0, @ecm = 'E', @minamt = 0
       	end
   
   	goto bspexit
   END
   
   
   -- material & UM validation
   if @umval = 'Y'
   BEGIN
   	if @matlum is null
   		begin
   		select @msg = 'Missing Unit of Measure!', @rcode = 1
   		goto bspexit
   		end
   
   	-- validate UM
   	select @msg=Description from bHQUM with (nolock) where UM=@matlum
   	if @@rowcount = 0
   		begin
   		select @msg = 'Invalid unit of measure', @rcode = 1
   		goto bspexit
   		end
   
----   	select @category=Category, @stocked=Stocked, @hqstdum=StdUM, @salesum=SalesUM,
----   		   @stdunitcost=Cost, @stdecm=CostECM, @salesunitcost=Price, @salesecm=PriceECM,
----   		   @taxable=Taxable
----   	from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
----   	if @@rowcount = 0
----       	begin
----   		select @msg = 'Material not on file.', @rcode = 1
----       	goto bspexit
----   		end
----   	if @stocked <> 'Y'
----   		begin
----   		select @msg = 'Invalid, not a stocked material!', @rcode = 1
----   		goto bspexit
----   		end
   
   	if @matlum <> @hqstdum
       	begin
       	select @validcnt=count(*) from bINMU with (nolock) 
       	where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material and UM=@matlum
       	if @validcnt = 0
           	begin
           	select @msg = 'Material UM is not set up for the IN Location', @rcode = 1
           	goto bspexit
       		end
       	end
   
   	-- get UM weight conversion
   	select @inmtwgtconv=isnull(WeightConv,0) from bINMT with (nolock) 
   	where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
   
   	-- get material um conversion factor
   	if @matlum = @hqstdum
   		begin
       	if @matlum = 'LBS'
       		select @matlumconv = @inmtwgtconv
       	else
           	select @matlumconv = 1
       	end
   	else
   		begin
       	select @matlumconv=Conversion from bINMU with (nolock) 
       	where MatlGroup=@matlgroup and INCo=@inco and Material=@material and Loc=@loc and UM=@matlum
       	if @@rowcount = 0
   			begin
           	exec @retcode = dbo.bspHQStdUMGet @matlgroup, @material, @matlum, @matlumconv output, @stdum output, @tmpmsg output
           	end
       	end
   
   
   	exec @retcode = dbo.bspINMOMatlUMVal @inco, @loc, @material, @matlgroup, @matlum, @pmco, @job, 
   			null, @ecm output, @unitprice output, @tmpmsg output
   	if @retcode <> 0
       	begin
       	select @unitprice = 0, @ecm = 'E', @minamt = 0
       	end
   	goto bspexit
   END





bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMOItemMatlVal] TO [public]
GO
