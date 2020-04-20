SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************/
   CREATE proc [dbo].[bspPMMFLocMatlUMVal]
   /************************************************
   * Created By:   GF 02/11/2002
   * Modified By:	GF 07/22/2002 - Issue #18032 added output params for OnHand, OnOrder, Allocated.
   *				GG 08/12/02 - #17811 - old/new templat prices, added @date param to bspMSTicMatlPriceGet
   *				GF 12/11/2003 - issue #23259 - when material assigned to IN location without unit cost, get price from IN
   *				GF 03/16/2004 - #24038 - pricing by quote phase - pass in phase group and phase
   *				GF 08/23/2004 - issue #25482 - added check for 'R' material option requisitions (RQ module)
   *				GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
   *				GF 10/26/2010 - issue #141031 change to use vfDateOnly function
   *
   *
   * validates Location, Material, and UM from PMMF PM Material form
   *
   * Pass:
   *   MS Company, FromLoc, MatlGroup, Material, MatlUM, JCCo, Job, Quote, PQM, INCo, MO, MOItem, PhaseGroup, Phase
   *
   * Success returns:
   *   Standard UM
   *   Standard Unit Price
   *   Standard ECM
   *   Sales UM
   *   Unit Price
   *   ECM
   *	Quote Status description
   *	MSQD.UM
   *	MSQD.UnitPrice
   *	MSQD.ECM
   *	MSQD.Status
   *	Quantity On Hand
   *	Quantity On Order
   *	Quantity Allocated
   *	0 and Description from bHQUM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @fromloc bLoc = null, @matlgroup bGroup = null, @material bMatl = null,
    @matlum bUM, @pmco bCompany = null, @project bJob = null, @quote varchar(10) = null,
    @pqmr char(1) = null, @inco bCompany = null, @phasegroup bGroup = null, @phase bPhase = null,
    @stdum bUM output, @stdup bUnitCost output,
    @stdecm bECM output, @salesum bUM output, @unitprice bUnitCost output, @ecm bECM output,
    @statusdesc varchar(20) output, @detailum bUM output, @detailup bUnitCost output,
    @detailecm bECM output, @status tinyint output, @onhand bUnits output, @onorder bUnits output,
    @alloc bUnits output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int, @category varchar(10), @custpriceopt tinyint,
           @jobpriceopt tinyint, @invpriceopt tinyint, @hqstdum bUM, @priceopt tinyint,
           @umdesc bDesc, @stocked bYN, @minamt bDollar, @locgroup bGroup, @tmpmsg varchar(255),
           @retcode int, @saletype char(1), @toinco bCompany, @toloc bLoc, @custgroup bGroup,
   		@customer bCustomer, @pricetemplate smallint, @pricedate bDate,
   		@pphase bPhase, @validphasechars int, @MatlVendor bVendor, @VendorGroup bGroup
   
   select @rcode = 0, @retcode = 0, @saletype = 'J', @detailup = 0, @status = 0, @statusdesc = 'Bid'
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @matlum is null
       begin
       select @msg = 'Missing Unit of Measure!', @rcode = 1
       goto bspexit
       end
   
   if @pqmr is null
   	begin
   	select @msg = 'Missing material type', @rcode = 1
   	goto bspexit
   	end
   
   if @pmco is null
   	begin
   	select @msg = 'Missing PM Company', @rcode = 1
   	goto bspexit
   	end
   
   if @project is null
   	begin
   	select @msg = 'Missing PM Project', @rcode = 1
   	goto bspexit
   	end
   
   -- validate unit of measure
   select @msg = Description from bHQUM with (nolock) where UM=@matlum
   if @@rowcount = 0
   	begin
       select @msg = 'Unit of Measure not setup!', @rcode = 1
   	goto bspexit
       end
   
   -- validate JC Company -  get valid portion of phase code
   select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo=@pmco
   if @@rowcount = 0 set @validphasechars = len(@phase)
   
   -- format valid portion of Phase
   if isnull(@phase,'') <> ''
   	begin
   	if @validphasechars > 0
   		set @pphase = substring(@phase,1,@validphasechars) + '%'
   	else
   		set @pphase = @phase
   	end
   else
   	set @pphase = null
   
   
   -- validate for material type 'P','R' - purchase orders
   if @pqmr in ('P','R')
   BEGIN
   	select @stdum = StdUM from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
   	-- If Material exists in bHQMT then must be in HQMU or STDUM
   	if @@rowcount <> 0
   		begin
       	if @stdum <> @matlum
   			if not exists (select top 1 1 from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@matlum)
     	       		begin
   
   	       		select @msg = 'Unit of Measure not setup for material: ' + isnull(@material,''), @rcode = 1
   	       		goto bspexit
   	       		end
   		end
   
   	select @stdecm=CostECM, @stdum=StdUM, @stdup=isnull(Cost,0), @salesum=SalesUM
    	from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
   
   	select @ecm=@stdecm, @unitprice=@stdup
   	-- get the converted price if the UM is different
   	if @salesum <> @stdum
       	begin
       	select @unitprice=Cost from bHQMU with (nolock) 
       	where MatlGroup=@matlgroup and Material=@material and UM=@salesum
       	end
   
   	if @matlum=@salesum goto bspexit
   	if @matlum=@stdum goto bspexit
   
   	-- check HQMU for price
   	select @unitprice=Cost, @ecm=CostECM
   	from bHQMU with (nolock) where MatlGroup=@matlgroup and Material=@material and UM=@matlum
   
   	goto bspexit
   END
   
   if @material is null
       begin
       select @msg = 'Missing Material!', @rcode = 1
       goto bspexit
       end
   
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
   
   
   if @pqmr = 'Q'
   BEGIN
   	if @msco is null or @fromloc is null
   		begin
   		select @ecm=@stdecm, @unitprice=@stdup
   		-- get the converted price if the UM is different
   		if @salesum <> @stdum
       		begin
       		select @unitprice=Cost from bHQMU with (nolock) 
       		where MatlGroup=@matlgroup and Material=@material and UM=@salesum
       		end
   
   		if @matlum=@salesum goto bspexit
   		if @matlum=@stdum goto bspexit
   
   		-- check HQMU for price
   		select @unitprice=Price, @ecm=PriceECM
   		from bHQMU with (nolock) where MatlGroup=@matlgroup and Material=@material and UM=@matlum
   
   		goto bspexit
   		end
   END
   
   if @pqmr = 'M'
   BEGIN
   	if @inco is null or @fromloc is null
   		begin
   		select @ecm=@stdecm, @unitprice=@stdup
   		-- get the converted price if the UM is different
   		if @salesum <> @stdum
       		begin
       		select @unitprice=Cost from bHQMU with (nolock) 
       		where MatlGroup=@matlgroup and Material=@material and UM=@salesum
       		end
   
   		if @matlum=@salesum goto bspexit
   		if @matlum=@stdum goto bspexit
   
   		-- check HQMU for price
   		select @unitprice=Price, @ecm=PriceECM
   		from bHQMU with (nolock) where MatlGroup=@matlgroup and Material=@material and UM=@matlum
   
   		goto bspexit
   		end
   END
   
   -- quote material
   if @pqmr = 'Q'
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
   
   	-- get location group for location
   	select @locgroup=LocGroup from bINLM with (nolock) where INCo=@msco and Loc=@fromloc
   
   	-- get IN company pricing options
   	select @priceopt=JobPriceOpt
   	from bINCO with (nolock) where INCo=@msco
   	if @@rowcount = 0
       	begin
       	select @msg = 'Unable to get IN Company parameters!', @rcode = 1
       	goto bspexit
       	end
   
   	-- get material unit price defaults
   	select @pricedate = dbo.vfDateOnly()	-- #17811 and #141031 use system date for price lookup
   	exec @retcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @material, @locgroup, @fromloc, @matlum, @quote,
           	@pricetemplate, @pricedate, @pmco, @project, @custgroup, @customer, @toinco, @toloc, @priceopt, @saletype,
           	@phasegroup, @phase, @MatlVendor, @VendorGroup,
			@unitprice output, @ecm output, @minamt output, @tmpmsg output
   	if @retcode <> 0
       	begin
       	select @unitprice = 0, @ecm = 'E'
       	end
   
   	-- get quote detail pricing and status from bMSQD if exists
   	-- #24038 added phase group and phase to MSQD check
   	select @status=Status, @detailum=UM, @detailecm=ECM, @detailup=UnitPrice
   	from bMSQD with (nolock) where MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup 
   	and Material=@material and UM=@matlum and PhaseGroup=@phasegroup and Phase=@phase
   	if @@rowcount = 0
   		begin
   		select Top 1 @status=Status, @detailum=UM, @detailecm=ECM, @detailup=UnitPrice
   		from bMSQD with (nolock) where MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup 
   		and Material=@material and UM=@matlum and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, FromLoc, MatlGroup, Material, UM, PhaseGroup, Phase, Status, UM, ECM, UnitPrice
   		if @@rowcount = 0
   			begin
   			select @status=Status, @detailum=UM, @detailecm=ECM, @detailup=UnitPrice
   			from bMSQD with (nolock) where MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup 
   			and Material=@material and UM=@matlum
   			if @@rowcount = 0
   				begin
				select @status = 0, @detailup = 0
				---- check PMMF as last resort
				select @detailum=UM, @detailecm=ECM, @detailup=UnitCost
				from bPMMF with (nolock) where PMCo=@pmco and Project=@project and MSCo=@msco and Quote=@quote and
				Location=@fromloc and MaterialGroup=@matlgroup and MaterialCode=@material
   				end
   			end
   		end
   
   	-- set status description
	select @statusdesc = ''
--   	select @statusdesc = case 
--   			when @status=0 then 'Bid' when @status=1 then 'Ordered' when @status=2 then 'Completed' else '' end
   	goto bspexit
   END
   
   
   if @pqmr = 'M'
   BEGIN
   	-- get location group for location
   	select @locgroup=LocGroup from bINLM with (nolock) where INCo=@inco and Loc=@fromloc
   
   	-- get IN company pricing options
   	select @priceopt=JobPriceOpt
   	from bINCO with (nolock) where INCo=@inco
   	if @@rowcount = 0
       	begin
       	select @msg = 'Unable to get IN Company parameters!', @rcode = 1
       	goto bspexit
       	end
   
   	-- get info from IN Location Materials
   	select @onhand=OnHand, @onorder=OnOrder, @alloc=Alloc
   	from bINMT with (nolock) where INCo=@inco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 0
   		begin
   		select @onhand=0, @onorder=0, @alloc=0
   		end
   
   	-- get material unit price defaults
   	select @pricedate = dbo.vfDateOnly()	-- #17811 and #141031 use system date for price lookup
   	exec @retcode = dbo.bspPMMOItemMatlVal @pmco, @project, @inco, @fromloc, @matlgroup, @material, @matlum, 'Y', 
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
GRANT EXECUTE ON  [dbo].[bspPMMFLocMatlUMVal] TO [public]
GO
