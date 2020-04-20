SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPMMSQuoteMatlVal]
   /*************************************
   * Created By:   GF 02/20/2002
   * Modified By:	GG 08/12/02 - #17811 - old/new templat prices, added @date param to bspMSTicMatlPriceGet
   *				GF 03/16/2004 - #24038 - pricing by quote phase - pass in phase group and phase
   *				GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
   *				GF 09/05/2010 - changed to use function vfDateOnly
   *
   *
   * validates Material to HQMT.Material from PM MS Quote Materials
   *
   * Pass:
   *   MS Company, Location, MatlGroup, Material, MatlUM, UMVal, JCCo, Job
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
   *	0 and Description from bHQMT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @loc bLoc = null, @matlgroup bGroup = null, @material bMatl = null,
    @matlum bUM = null, @umval bYN = 'N', @pmco bCompany = null, @job bJob = null,
    @phasegroup bGroup = null, @phase bPhase = null, @stdum bUM output, @stdup bUnitCost output, 
    @stdecm bECM output, @salesum bUM output, @unitprice bUnitCost output, @ecm bECM output, 
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @retcode int, @validcnt int, @category varchar(10), @saletype char(1),
           @jobpriceopt tinyint, @hqstdum bUM, @priceopt tinyint, @stocked bYN, @minamt bDollar,
   		@locgroup bGroup, @tmpmsg varchar(255), @salesecm bECM, @stdunitcost bUnitCost,
   		@salesunitcost bUnitCost, @inmtwgtconv bUnits, @matlumconv bUnitCost, @pricedate bDate,
		@MatlVendor bVendor, @VendorGroup bGroup
   
   
   select @rcode = 0, @retcode = 0, @saletype = 'J'
   
   if @msco is null
       begin
       select @msg = 'Missing MS Company!', @rcode = 1
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
   
   select @locgroup=LocGroup from bINLM with (nolock) where INCo=@msco and Loc=@loc
   
   -- get IN company pricing options
   select @priceopt=JobPriceOpt from bINCO with (nolock) where INCo=@msco
   if @@rowcount = 0
       begin
       select @msg = 'Unable to get IN Company parameters!', @rcode = 1
       goto bspexit
       end
   
   if @umval = 'N'
   BEGIN
   	select @msg=Description, @category=Category, @stocked=Stocked, @stdum=StdUM,
   		   @stdup=Price, @stdecm=PriceECM, @salesum=SalesUM
   	from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 0
       	begin
       	select @msg = 'Invalid Material!', @rcode = 1
       	goto bspexit
       	end
   
   	-- get material unit price defaults
   	----#141031
   	set @pricedate = dbo.vfDateOnly()	-- #17811 use system date for price lookup
   	exec @retcode = dbo.bspMSTicMatlPriceGet @msco,@matlgroup,@material,@locgroup,@loc,@salesum,null,null,@pricedate,
   		 @pmco, @job, null, null, null, null, @priceopt, @saletype, @phasegroup, @phase, @MatlVendor, @VendorGroup,
   		 @unitprice output, @ecm output, @minamt output, @tmpmsg output
   	if @retcode <> 0
       	begin
       	select @unitprice = 0, @ecm = 'E'
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
   
   	select @category=Category, @stocked=Stocked, @stdum=StdUM,
   		   @stdup=Price, @stdecm=PriceECM, @salesum=SalesUM
   	from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 0
       	begin
       	select @msg = 'Invalid Material!', @rcode = 1
       	goto bspexit
       	end
   
   	-- get material unit price defaults
   	----#141031
   	set @pricedate = dbo.vfDateOnly()	-- #17811 use system date for price lookup
   	exec @retcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @material, @locgroup, @loc, @matlum, null, null,
   			@pricedate, @pmco, @job, null, null, null, null, @priceopt, @saletype, @phasegroup, @phase,
			@MatlVendor, @VendorGroup,
   			@unitprice output, @ecm output, @minamt output, @tmpmsg output
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
GRANT EXECUTE ON  [dbo].[bspPMMSQuoteMatlVal] TO [public]
GO
