SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSQDMatlVal]
   /*************************************
   * Created By:   GF 12/19/2000
   * Modified By:	GG 08/12/02 - #17811 - old/new template prices, added @quotedate param
   *				GF 03/18/2004 - #24038 - pricing by phase enhancment
   *				GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
   *				GF 09/05/2010 - changed to use function vfDateOnly
   *
   * validates Material to HQMT.Material from MSQD
   *
   * Pass:
   *   MS Company, FromLoc, MatlGroup, Material, PriceTemplate, SaleType, MatlUM,
   *   PriceTemplate, SaleType, CustGroup, Customer, JCCo, Job, INCo, ToLoc, Quote,
   *	QuoteDate, PhaseGroup, Phase
   *
   * Success returns:
   *   Standard UM
   *   Standard Unit Price
   *   Standard ECM
   *   Sales UM
   *   Unit Price
   *   ECM
   *	0 and Description from bHQMT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @fromloc bLoc = null, @matlgroup bGroup = null,
    @material bMatl = null, @pricetemplate smallint = null, @saletype char(1) = null,
    @custgroup bGroup = null, @customer bCustomer = null, @tojcco bCompany = null,
    @job bJob = null, @toinco bCompany = null, @toloc bLoc = null, @quote varchar(10) = null,
    @quotedate bDate = null, @phasegroup bGroup = null, @phase bPhase = null,
    @stdum bUM output, @stdup bUnitCost output, @stdecm bECM output,
    @salesum bUM output, @unitprice bUnitCost output, @ecm bECM output, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @retcode int, @validcnt int, @category varchar(10), @custpriceopt tinyint,
           @jobpriceopt tinyint, @invpriceopt tinyint, @hqstdum bUM, @priceopt tinyint,
           @stocked bYN, @minamt bDollar, @locgroup bGroup, @tmpmsg varchar(255), 
		   @MatlVendor bVendor, @VendorGroup bGroup
   
   select @rcode = 0, @retcode = 0
   
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
   
   if @fromloc is null
       begin
       select @msg = 'Missing From Location!', @rcode = 1
       goto bspexit
       end
   
   -- #17811 - if Quote Date is null, use system date, passed to bspMSTicMatlPriceGet
   ----#141031
   if @quotedate is null set @quotedate = dbo.vfDateOnly()
   
   select @locgroup=LocGroup from bINLM where INCo=@msco and Loc=@fromloc
   
   -- get IN company pricing options
   select @custpriceopt=CustPriceOpt, @jobpriceopt=JobPriceOpt, @invpriceopt=InvPriceOpt
   from bINCO where INCo=@msco
   if @@rowcount = 0
       begin
       select @msg = 'Unable to get IN Company parameters!', @rcode = 1
       goto bspexit
       end
   
   if @saletype = 'J' select @priceopt = @jobpriceopt
   if @saletype = 'C' select @priceopt = @custpriceopt
   if @saletype = 'I' select @priceopt = @invpriceopt
   
   select @msg=Description, @category=Category, @stocked=Stocked, @stdum=StdUM,
          @stdup=Price, @stdecm=PriceECM, @salesum=SalesUM
   from bHQMT where MatlGroup=@matlgroup and Material=@material
   if @@rowcount = 0
       begin
       select @msg = 'Invalid Material!', @rcode = 1
       goto bspexit
       end
   
   -- get material unit price defaults 
   exec @retcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @material, @locgroup, @fromloc, @salesum, @quote,
           @pricetemplate, @quotedate, @tojcco, @job, @custgroup, @customer, @toinco, @toloc, @priceopt, @saletype,
           @phasegroup, @phase, @MatlVendor, @VendorGroup, 
		   @unitprice output, @ecm output, @minamt output, @tmpmsg output
   if @retcode <> 0
       begin
       select @unitprice = 0, @ecm = 'E'
       end
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQDMatlVal] TO [public]
GO
