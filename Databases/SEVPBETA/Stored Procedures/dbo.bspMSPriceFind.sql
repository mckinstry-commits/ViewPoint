SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSPriceFind]
   /****************************************************************************
   * Created By:   GF 11/07/2000
   * Modified By:  GF 08/02/2001 - fix for zero discount
   *				GG 08/12/02 - #17811 - old/new template prices, added @date param
   *				GF 03/19/2004 - issue #24038 - haul rates by phase
   *				GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup 
   *									as input params. For MSPriceFind form and bspMSTicMatlPriceGet.
   *				GF 09/05/2010 - issue #141031 use vfDateOnly
   *
   *
   * USAGE:
   * 	Finds pricing information using parameters passed in from MSPriceFind.
   *
   * INPUT PARAMETERS:
   *   MS Company, CustType, CustGroup, Customer, CustJob, CustPO, JCCo, Job
   *   INCo, ToLoc, Quote, PriceTemplate, DiscTemplate, FromLoc, MatlGroup,
   *   Material, UM, HaulCode, TruckType, HaulZone, DiscType, JCCo, PhaseGroup,
   *	MatlPhase, HaulPhase
   *
   * OUTPUT PARAMETERS:
   *   Pricing information
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@msco bCompany = null, @custtype char(1) = null, @custgroup bGroup = null,
    @customer bCustomer = null, @custjob varchar(20) = null, @custpo varchar(20) = null,
    @jcco bCompany = null, @job bJob = null, @inco bCompany = null, @toloc bLoc = null,
    @quote varchar(10) = null, @pricetemp smallint = null, @disctemp smallint = null,
    @fromloc bLoc = null, @matlgroup bGroup = null, @material bMatl = null, @matlum bUM = null,
    @haulcode bHaulCode = null, @trucktype varchar(10) = null, @haulzone varchar(10) = null,
    @paydisctype char(1) = null, @pricedate bDate = null, @phasegroup bGroup = null, 
    @matlphase bPhase = null, @haulphase bPhase = null, 
	@MatlVendor bVendor = null, @VendorGroup bGroup = null,
    @stdup bUnitCost output, @stdecm bECM output, @tmpup bUnitCost output, @tmpecm bECM output, 
    @ovrup bUnitCost output, @ovrecm bECM output, @stdhaul bUnitCost output, 
    @tmphaul bUnitCost output, @ovrhaul bUnitCost output, @stddisc bUnitCost output,
    @tmpdisc bUnitCost output, @ovrdisc bUnitCost output, @stdtotal bUnitCost output,
    @tmptotal bUnitCost output, @ovrtotal bUnitCost output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @retcode int, @validcnt int, @tmppaydiscrate bUnitCost, @rate bRate,
           @stdum bUM, @tmpmsg varchar(255), @category varchar(10), @matlumconv bUnitCost,
           @custpriceopt tinyint, @jobpriceopt tinyint, @invpriceopt tinyint, @stocked bYN,
           @hqstdum bUM, @priceopt tinyint, @locgroup bGroup, @paydiscrate bRate,
           @unitprice bUnitCost, @ecm bECM, @minamt bDollar, @haulbasis tinyint, @found tinyint 
		   
   
   select @rcode = 0, @found = 0
   
   -- #17811 - price date for template prices, use system date if null
   if @pricedate is null select @pricedate = dbo.vfDateOnly()	
   
   -- get location group for from location
   select @locgroup=LocGroup from bINLM where INCo=@msco and Loc=@fromloc
   if @@rowcount = 0 select @locgroup=null
   
   -- get IN company pricing options
   select @custpriceopt=CustPriceOpt, @jobpriceopt=JobPriceOpt, @invpriceopt=InvPriceOpt
   from bINCO where INCo=@msco
   if @@rowcount = 0
       begin
       select @msg = 'Unable to get IN Company parameters', @rcode = 1
       goto bspexit
       end
   
   if @custtype = 'J' select @priceopt = @jobpriceopt
   if @custtype = 'C' select @priceopt = @custpriceopt
   if @custtype = 'I' select @priceopt = @invpriceopt
   
   -- get material information from HQMT
   select @category=Category, @paydiscrate=PayDiscRate, @stocked=Stocked, @hqstdum=StdUM
   from bHQMT where MatlGroup=@matlgroup and Material=@material
   if @@rowcount = 0
       begin
   	select @hqstdum=@matlum, @paydiscrate=0, @stocked='N', @category=null
       goto bspexit
   	end
   else
       if @matlum <> @hqstdum
           begin
           select @paydiscrate=PayDiscRate
           from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@matlum
           if @@rowcount = 0 select @paydiscrate=0
           end
   
   -- get material um conversion factor
   if @matlum is null
       begin
       select @matlumconv = 0
       end
   else
       if @matlum=@hqstdum
           begin
           select @matlumconv = 1
           end
       else
           begin
           select @matlumconv=Conversion from bINMU
           where MatlGroup=@matlgroup and INCo=@msco and Material=@material and Loc=@fromloc and UM=@matlum
           if @@rowcount = 0
               begin
               exec @retcode = bspHQStdUMGet @matlgroup,@material,@matlum,@matlumconv output,@stdum output,@tmpmsg output
               end
           end
   
   -- get standard unit pricing
   select @retcode=0
   exec @retcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @material, @locgroup, @fromloc, @matlum,
           		null, null, @pricedate, @jcco, @job, @custgroup, @customer, @inco, @toloc, @priceopt, 
   				@custtype, null, null, @MatlVendor, @VendorGroup, 
				@stdup output, @stdecm output, @minamt output, @tmpmsg output
   if @retcode <> 0
       begin
       select @stdup=0, @stdecm='E'
       end
   
   -- get template unit pricing
   if @pricetemp is not null
       begin
       select @retcode=0
       exec @retcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @material, @locgroup, @fromloc, @matlum,
               	null, @pricetemp, @pricedate, @jcco, @job, @custgroup, @customer, @inco, @toloc, @priceopt,
   				@custtype, null, null, @MatlVendor, @VendorGroup, 
				@tmpup output,@tmpecm output,@minamt output,@tmpmsg output
       end
   if @pricetemp is null or @retcode <> 0
       begin
       -- set template pricing to standard pricing
       select @tmpup=@stdup, @tmpecm=@stdecm
       end
   
   -- get override unit pricing (quote)
   if @quote is not null
       begin
       exec @retcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @material, @locgroup, @fromloc, @matlum,
               	@quote,null, @pricedate, @jcco, @job, @custgroup, @customer, @inco, @toloc, @priceopt,
   				@custtype, @phasegroup, @matlphase, @MatlVendor, @VendorGroup, 
				@ovrup output,@ovrecm output,@minamt output,@tmpmsg output
       end
   if @quote is null or @retcode <> 0
       begin
       -- set override pricing to template pricing
       select @ovrup=@tmpup, @ovrecm=@tmpecm
       end
   
   if @ovrup=@stdup and @tmpup<>@stdup
       begin
       select @ovrup=@tmpup, @ovrecm=@tmpecm
       end
   
   
   -- initialize haul rates
   if @haulcode is null
       begin
       select @stdhaul=null, @tmphaul=null, @ovrhaul=null, @haulbasis=1
       end
   
   -- get haul rates
   if @haulcode is not null
       begin
       select @haulbasis=HaulBasis
       from bMSHC where MSCo=@msco and HaulCode=@haulcode
       -- get standard haul rate
       exec @retcode = dbo.bspMSTicHaulRateGet @msco, @haulcode, @matlgroup, @material, @category, @locgroup,
               	@fromloc, @trucktype, @matlum, null, @haulzone, @haulbasis, @jcco, null, null,
   				@stdhaul output,@minamt output, @tmpmsg output
       if @stdhaul is null select @stdhaul = 0
       -- get template haul rate
       select @tmphaul=@stdhaul
       -- get override haul rate (quote)
       exec @retcode = dbo.bspMSTicHaulRateGet @msco, @haulcode, @matlgroup, @material, @category, @locgroup,
               	@fromloc, @trucktype, @matlum, @quote, @haulzone, @haulbasis, @jcco, @phasegroup, @haulphase,
   				@ovrhaul output,@minamt output, @tmpmsg output
       if @ovrhaul is null select @ovrhaul = 0
       if @ovrhaul = 0 select @ovrhaul=@tmphaul
       end
   
   -- get payment discount rate - applies only to customer sales
   if @custtype = 'C'
       begin
       -- get standard discount rate
       select @stddisc = @paydiscrate
       -- get template discount rate
       if @disctemp is not null
           begin
           exec @retcode = dbo.bspMSTicMatlDiscGet @msco,@matlgroup,@material,@category,@locgroup,
                           @fromloc,@matlum,null,@disctemp,@tmppaydiscrate output,@found output, @tmpmsg output
           if @found = 0
               select @tmpdisc=@stddisc
           else
               select @tmpdisc=@tmppaydiscrate
           end
       else
           select @tmpdisc = @stddisc
       -- get override discount rate
       if @quote is not null
           begin
           exec @retcode = dbo.bspMSTicMatlDiscGet @msco,@matlgroup,@material,@category,@locgroup,
                           @fromloc,@matlum,@quote,null,@tmppaydiscrate output,@found output, @tmpmsg output
           if @found = 0
               select @ovrdisc=@tmpdisc
           else
               select @ovrdisc=@tmppaydiscrate
           end
       else
           select @tmpdisc = @tmpdisc
       end
   else
       begin
       select @stddisc = null, @tmpdisc = null, @ovrdisc = null
       end
   
   -- accumulate totals
   select @stdtotal=isnull(@stdup,0), @tmptotal=isnull(@tmpup,0), @ovrtotal=isnull(@ovrup,0)
   if @haulbasis = 1
   
       begin
       select @stdtotal=@stdtotal + isnull(@stdhaul,0),
              @tmptotal=@tmptotal + isnull(@tmphaul,0),
              @ovrtotal=@ovrtotal + isnull(@ovrhaul,0)
       end
   if @paydisctype = 'U'
       begin
       select @stdtotal=@stdtotal - isnull(@stddisc,0),
              @tmptotal=@tmptotal - isnull(@tmpdisc,0),
              @ovrtotal=@ovrtotal - isnull(@ovrhaul,0)
       end
   
   if @haulbasis <> 1 or @paydisctype <> 'U'
       begin
       select @stdtotal=null, @tmptotal=null, @ovrtotal=null
       end
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPriceFind] TO [public]
GO
