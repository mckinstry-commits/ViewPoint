SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspPMMFLocMatlVal]
   /*************************************
   * Created By:   GF 02/08/2002
   * Modified By:	GF 07/22/2002 - Issue #18032 added output params for OnHand, OnOrder, Allocated.
   *				GG 08/12/02 - #17811 - old/new templat prices, added @date param to bspMSTicMatlPriceGet
   *				GF 12/11/2003 - issue #23259 - when material assigned to IN location without unit cost, get price from IN
   *				GF 03/16/2004 - #24038 - pricing by quote phase - pass in phase group and phase
   *				GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
   *				GF 10/26/2010 - issue #141031 change to use vfDateOnly function
   *
   * validates Location and Material from PMMF PM Material form
   *
   * Pass:
   *   MatlGroup, Material, MS Company, Quote, FromLoc, PMCo, Project, MaterialOption, INCo, PhaseGroup, Phase
   *
   * Success returns:
   *   Standard UM
   *   Standard Unit Price
   *   Standard ECM
   *   Sales UM
   *   Unit Price
   *   ECM
   *	Quantity On Hand
   *	Quantity On Order
   *	Quantity Allocated
   *	0 and Description from bINLM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@matlgroup bGroup = null, @material bMatl = null, @msco bCompany = null, @quote varchar(10) = null,
    @fromloc bLoc = null, @pmco bCompany = null, @project bJob = null, @materialoption char(1), 
    @inco bCompany = null, @phasegroup bGroup = null, @phase bPhase = null,
    @stdum bUM output, @stdup bUnitCost output, @stdecm bECM output, @salesum bUM output,
    @unitprice bUnitCost output, @ecm bECM output, @onhand bUnits output, @onorder bUnits output,
    @alloc bUnits output,@msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @retcode int, @validcnt int, @category varchar(10), @saletype char(1),
           @hqstdum bUM, @priceopt tinyint, @custgroup bGroup, @customer bCustomer,
   		@toinco bCompany, @toloc bLoc, @pricetemplate smallint, @active bYN,
           @stocked bYN, @minamt bDollar, @locgroup bGroup, @tmpmsg varchar(255), @pricedate bDate,
		   @MatlVendor bVendor, @VendorGroup bGroup
   
   select @rcode = 0, @retcode = 0, @saletype = 'J'
   
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
   
   if @pmco is null
       begin
       select @msg = 'Missing PM Company!', @rcode = 1
       goto bspexit
       end
   
   if @project is null
       begin
       select @msg = 'Missing PM Project!', @rcode = 1
       goto bspexit
       end
   
   if @fromloc is null
       begin
       select @msg = 'Missing From Location!', @rcode = 1
       goto bspexit
       end
   
   if @materialoption = 'Q'
   	begin
   	if @msco is null
       	begin
       	select @msg = 'Missing MS Company!', @rcode = 1
       	goto bspexit
       	end
   	end
   else
   	begin
   	if @inco is null
       	begin
       	select @msg = 'Missing IN Company!', @rcode = 1
       	goto bspexit
       	end
   	end
   
   
   -- get information for material option 'Q' - quotes
   if @materialoption = 'Q'
   BEGIN
   	-- get price template for quote
   	select @pricetemplate=PriceTemplate from bMSQH with (nolock) where MSCo=@msco and Quote=@quote
   	if @@rowcount = 0
   		begin
   		select @pricetemplate=PriceTemplate from bJCJM with (nolock) where JCCo=@pmco and Job=@project
   		if isnull(@pricetemplate,0) <> 0
   			begin
   			select @validcnt=count(*) from bMSTH with (nolock) where MSCo=@msco and PriceTemplate=@pricetemplate
   			if @validcnt = 0 select @pricetemplate = null
   			end
   		end
   
   	-- validate location
   	select @msg=Description, @locgroup=LocGroup
   	from bINLM with (nolock) where INCo=@msco and Loc=@fromloc
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Location', @rcode=1
   		goto bspexit
   		end
   
   	-- get IN company pricing option for Job sale type
   	select @priceopt=JobPriceOpt
   	from bINCO with (nolock) where INCo=@msco
   	if @@rowcount = 0
       	begin
       	select @msg = 'Unable to get IN Company parameters!', @rcode = 1
       	goto bspexit
       	end
   
   	-- get HQ material data
   	select @category=Category, @stocked=Stocked, @stdum=StdUM,
   		   @stdup=Price, @stdecm=PriceECM, @salesum=SalesUM
   	from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 0
       	begin
       	select @msg = 'Invalid Material!', @rcode = 1
       	goto bspexit
       	end
   
   
   	if @stocked = 'N'
   		begin
   		select @msg = 'Material is not a stocked material', @rcode = 1
   		goto bspexit
   
   
   		end
   
   	-- get material unit price defaults
   	select @pricedate = dbo.vfDateOnly()	-- #17811 and #141031 use system date for price lookup
   	exec @retcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @material, @locgroup, @fromloc, @salesum, @quote,
   		 @pricetemplate, @pricedate, @pmco, @project, @custgroup, @customer, @toinco, @toloc, @priceopt, @saletype,
            @phasegroup, @phase, @MatlVendor, @VendorGroup,
			@unitprice output, @ecm output, @minamt output, @tmpmsg output
   	if @retcode <> 0
       	begin
       	select @unitprice = 0, @ecm = 'E'
       	end
   
   	goto bspexit
   END
   
   -- get information for material option 'M' - material orders
   if @materialoption = 'M'
   BEGIN
   
   	-- validate location
   	select @msg=Description, @locgroup=LocGroup, @active=Active
   	from bINLM with (nolock) where INCo=@inco and Loc=@fromloc
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Location', @rcode=1
   		goto bspexit
   		end
   	if @active = 'N'
   		begin
   		select @msg = 'Not an active Location', @rcode=1
   		goto bspexit
   		end
   
   	-- get IN company pricing option for Job sale type
   	select @priceopt=JobPriceOpt
   	from bINCO with (nolock) where INCo=@inco
   	if @@rowcount = 0
       	begin
       	select @msg = 'Unable to get IN Company parameters!', @rcode = 1
       	goto bspexit
       	end
   
   	-- get HQ material data
   	select @category=Category, @stocked=Stocked, @stdum=StdUM,
   		   @stdup=Price, @stdecm=PriceECM, @salesum=SalesUM
   	from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 0
       	begin
       	select @msg = 'Invalid Material!', @rcode = 1
       	goto bspexit
       	end
   	if @stocked = 'N'
   		begin
   		select @msg = 'Material is not a stocked material', @rcode = 1
   		goto bspexit
   		end
   
   	-- get info from IN Location Materials
   	select @onhand=OnHand, @onorder=OnOrder, @alloc=Alloc
   	from bINMT with (nolock) where INCo=@inco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 0
   		begin
   		select @onhand=0, @onorder=0, @alloc=0
   		end

	---- get material unit price defaults
	select @pricedate = dbo.vfDateOnly()	-- #17811 and #141031 use system date for price lookup
	exec @retcode = dbo.bspPMMOItemMatlVal @pmco, @project, @inco, @fromloc, @matlgroup, @material, @salesum, 'Y',
					null, null, null, null, @unitprice output, @ecm output, null, null, null, null, null, null, @tmpmsg output
   	if @retcode <> 0
       	begin
       	select @unitprice = 0, @ecm = 'E'
       	end
   
   	goto bspexit
   END
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMFLocMatlVal] TO [public]
GO
