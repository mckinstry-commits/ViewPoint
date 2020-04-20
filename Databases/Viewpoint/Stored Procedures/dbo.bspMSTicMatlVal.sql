SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************/
CREATE   proc [dbo].[bspMSTicMatlVal]
/*************************************
 * Created By:   GF 07/18/2000
 * Modified By:  GG 01/24/01 - initialized output params as null
 *               GF 03/15/2001 - fix for weight conversion factors
 *               GF 08/02/2001 - fix for zero discount rate
 *               DANF 09/27/2001 - fix / by zero issue 14714
 *				 GF 02/06/02 - issue #16085, validate material using matlgroup for sell to company for interco inv sale
 *				 allenn 05/28/02 - issue 17381 specify to use the metric um instead of the sales um from the material based on flag 'UseUMMetricYN' in bMSQH
 *				 GG 08/12/02 - #17811 - old/new template pricing, added @saledate input
 *				 RM 08/14/02 - issue# 16039, Return OnHand value to form so that it can check for negative flag
 *				 GF 11/06/2003 - issue #18762 - use MSQH.PayTerms if not null else ARCM.PayTerms
 *				 GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
 *				 DAN SO 11/11/2008 - Issue #130957 - modified IF to get bspMSTicMatlPriceGet to fire - MinAmt was not getting set properly
 *				 DAN SO 01/21/2010 - Issue #129350 - Made @category an output parameter 
 *				
 * USAGE:   Validate material and unit of measure
 *          entered in MS TicEntry and MS HaulEntry
 *
 *
 * INPUT PARAMETERS
 *  @msco           MS Company
 *  @matlgroup      Material Group
 *  @material       Material
 *  @matlvendor     Material Vendor
 *  @fromloc        Sold from IN Location
 *  @saletype       Sale Type (C/J/I)
 *  @toinco         Sold To IN Company
 *  @toloc          Sold To Location
 *  @locgroup       Location Group - sold from
 *  @phasegroup     Phase Group - job sales
 *  @quote          Quote #
 *  @disctemplate   Discount Template - customer sales
 *  @pricetemplate  Price Template
 *  @netum          Weight U/M
 *  @matlum         Material U/M - sold
 *  @custgroup      Customer Group - customer sales
 *  @customer       Customer # - customer sales
 *  @tojcco         Sold To JC Co# - job sales
 *  @job            Sold To Job - job sales
 *	@saledate		Sale Date
 *
 * OUTPUT PARAMETERS
 *  @salesum            Default Material Sales U/M
 *  @paydisctype        Discount Type
 *  @paydiscrate        Default Discount Rate
 *  @matlphase          Default JC Phase for material
 *  @matlct             Default JC Cost Type for material
 *  @haulphase          Default JC Phase for hauling
 *  @haulct             Default JC Cost Type for hauling
 *  @netumconv          Conversion factor for Weight U/M to Std
 *  @matlumconv         Conversion factor for posted U/M to Std
 *  @taxable            Material taxable flag
 *  @unitprice          Default Unit Price
 *  @ecm                Default ECM
 *  @minamt             Minimum Amount for material charge
 *  @haulcode           Default Haul Code
 *	@pricetooltip       Material info including material unit price
 *  @totaltooltip       Material info including minimum amount
 *  @category			Material Category
 *  @msg                Material description or error message if error occurs
 *
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *
 **************************************/
(@msco bCompany = null, @umval bYN = 'N', @matlgroup bGroup = null, @material bMatl = null,
 @matlvendor bVendor = null, @fromloc bLoc = null, @saletype varchar(1) = null,
 @toinco bCompany = null, @toloc bLoc = null, @locgroup bGroup = null, @phasegroup bGroup = null,
 @quote varchar(10) = null, @disctemplate smallint = null, @pricetemplate smallint = null,
 @netum bUM = null, @matlum bUM = null, @custgroup bGroup = null, @customer bCustomer = null,
 @tojcco bCompany = null, @job bJob = null, @saledate bDate = null,
 @salesum bUM = null output, @paydisctype char(1) = null output,
 @paydiscrate bUnitCost = null output, @matlphase bPhase = null output, @matlct bJCCType = null output,
 @haulphase bPhase = null output, @haulct bJCCType = null output, @netumconv bUnitCost = null output,
 @matlumconv bUnitCost = null output, @taxable bYN = null output, @unitprice bUnitCost = null output,
 @ecm bECM = null output, @minamt bDollar = null output, @haulcode bHaulCode = null output,
 @pricetooltip varchar(255) = null output, @totaltooltip varchar(255) = null output, 
 @onhand bUnits = null output, @category varchar(10) = NULL output, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @retcode int, @validcnt int, @tmppaydiscrate bUnitCost, @rate bRate,
		@tmpmatlphase bPhase, @tmpmatlct bJCCType, @tmphaulphase bPhase, @tmphaulct bJCCType,
		@stdum bUM, @tmpmsg varchar(255), @umdesc bDesc,  
		@custpriceopt tinyint, @jobpriceopt tinyint, @invpriceopt tinyint, @stocked bYN,
		@hqstdum bUM, @priceopt tinyint, @hqmtwgtconv bUnits, @inmtwgtconv bUnits, @payterms bPayTerms,
		@matldisc bYN, @found tinyint, @stdunitcost bUnitCost, @salesunitcost bUnitCost, @stdecm bECM,
   		@salesecm bECM, @toinmatlgroup bGroup, @usemetflag bYN, @metricum bUM, @VendorGroup bGroup

select @rcode = 0, @retcode = 0, @found = 0, @matldisc = 'N'

if @msco is null
       begin
       select @msg = 'Missing MS Company', @rcode = 1
       goto bspexit
       end

if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group', @rcode = 1
   	goto bspexit
   	end

if @material is null
	begin
	select @salesum = null, @paydisctype = null, @paydiscrate = null, @matlphase = null,
			@matlct = null, @haulphase = null, @haulct = null, @netumconv = null,
			@matlumconv = null, @haulcode = null, @taxable = 'N', @unitprice = null,
			@ecm = 'E', @rate = null, @minamt = null
	goto bspexit
	end

if @saletype = 'C'
	begin
   	if @quote is not null
		begin
   		---- check for pay terms override by quote
   		select @payterms=PayTerms from MSQH with (nolock) where MSCo = @msco and Quote = @quote
   		if isnull(@payterms,'') = '' 
   			begin
   			select @payterms=PayTerms from ARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
   			end
   		end
	else
		begin
		---- get customer pay terms
       	select @payterms=PayTerms from ARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
   		end
	---- now get matldisc type from HQPT
	select @matldisc=MatlDisc from HQPT with (nolock) where PayTerms=@payterms
	end

---- issue 17381
if @quote is not null
	begin
   	select @usemetflag = UseUMMetricYN from MSQH with (nolock) where MSCo = @msco and Quote = @quote
   	if isnull(@usemetflag, '') = '' select @usemetflag = 'N'
	end

if @fromloc is null
   	begin
   	select @msg = 'Missing IN From Location', @rcode = 1
   	goto bspexit
   	end

if @saletype = 'I'
	begin
	if @toinco is null
		begin
		select @msg = 'Missing IN To Company', @rcode = 1
		goto bspexit
		end

	if @toloc is null
		begin
		select @msg = 'Missing IN To Location', @rcode = 1
		goto bspexit
		end
	end

---- get IN company pricing options
select @custpriceopt=CustPriceOpt, @jobpriceopt=JobPriceOpt, @invpriceopt=InvPriceOpt
from INCO with (nolock) where INCo=@msco
if @@rowcount = 0
	begin
	select @msg = 'Unable to get IN Company parameters', @rcode = 1
	goto bspexit
	end

if @saletype = 'J' select @priceopt = @jobpriceopt
if @saletype = 'C' select @priceopt = @custpriceopt
if @saletype = 'I' select @priceopt = @invpriceopt

---- validate Material UM if needed
if @umval = 'Y'
	begin
	if @matlum is null
		begin
		select @msg = 'Missing Unit of measure', @rcode = 1
		goto bspexit
		end
	select @umdesc=Description from HQUM with (nolock) where UM=@matlum
	if @@rowcount = 0
		begin
		select @msg = 'Unit of measure not on file', @rcode =1
		end
	end

select @msg=Description, @category=Category, @paydisctype=PayDiscType, @paydiscrate=PayDiscRate,
		@matlphase=MatlPhase, @matlct=MatlJCCostType, @haulphase=HaulPhase, @haulct=HaulJCCostType,
		@haulcode=HaulCode, @taxable=Taxable, @stocked=Stocked, @hqstdum=StdUM, @salesum=SalesUM,
		@metricum = MetricUM, @hqmtwgtconv=WeightConv, @stdunitcost=Cost, @stdecm=CostECM,
		@salesunitcost=Price, @salesecm=PriceECM
from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0
	begin
   	select @msg = 'Material not on file.', @rcode = 1
	goto bspexit
	end

----issue 17381
if @usemetflag = 'Y' 
	begin
	select @salesum = isnull(@metricum, @salesum)
	end

if @umval ='N'
	begin
	select @paydiscrate=PayDiscRate
	from HQMU with (nolock) where MatlGroup=@matlgroup and Material=@material and UM=@salesum
	end
else
	begin
	if @matlum <> @hqstdum
		begin
		select @paydiscrate=PayDiscRate
		from HQMU with (nolock) where MatlGroup=@matlgroup and Material=@material and UM=@matlum
		if @@rowcount = 0
			begin
			select @msg = 'UM must be either standard UM or set up in HQMU.', @rcode = 1
			goto bspexit
			end
		end
	end

if @matldisc ='N' 
	begin
	select @paydiscrate = 0
	end

if @umval = 'N' and @matlum is null
	begin
	select @matlum=@salesum
	end

if @matlvendor is null and @stocked = 'N'
	begin
	select @msg = 'This material must be a stocked material.', @rcode = 1
	goto bspexit
	end

if @matlvendor is null and @umval = 'N'
	begin
   	select @validcnt=count(*) from INMT with (nolock) 
	where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
   	if @validcnt = 0
		begin
		select @msg = 'Material is not set up for the IN Sales Location', @rcode = 1
		goto bspexit
		end
	end

if @matlvendor is null and @umval = 'Y' and @matlum <> @hqstdum
	begin
	select @validcnt=count(*) from INMU with (nolock) 
	where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material and UM=@matlum
	if @validcnt = 0
		begin
		select @msg = 'Material UM is not set up for the IN Sales Location', @rcode = 1
		goto bspexit
		end
	end

if @saletype = 'I' and @umval = 'N'
	begin
   	select @toinmatlgroup=MatlGroup from HQCO with (nolock) where HQCo=@toinco
   	select @validcnt=count(*) from INMT with (nolock) 
	where INCo=@toinco and Loc=@toloc and MatlGroup=@toinmatlgroup and Material=@material
	if @validcnt = 0
		begin
		select @msg = 'Material is not set up for the IN To Location', @rcode = 1
		goto bspexit
		end
	end

if @matlvendor is null
	begin
	select @inmtwgtconv=isnull(WeightConv,0) from INMT with (nolock) 
	where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
	end
else
	begin
	select @inmtwgtconv=@hqmtwgtconv
	end

---- get net um conversion factor
if @netum is null
	begin
	select @netumconv = 0
	end
else
	begin
	---- issue #14714
	If isnull(@inmtwgtconv,0) <> 0 
		begin
		select @netumconv = 1/@inmtwgtconv
		end
	else
		begin
		select @netumconv = 0
		end
	end

-- get material um conversion factor
if @matlum is null
	begin
	select @matlumconv = 0
	end
else
	begin
	if @matlum = @hqstdum
		begin
		if @matlum = 'LBS'
			select @matlumconv = @inmtwgtconv
		else
			select @matlumconv = 1
		end
	else
		begin
		select @matlumconv=Conversion from INMU with (nolock) 
		where MatlGroup=@matlgroup and INCo=@msco and Material=@material and Loc=@fromloc and UM=@matlum
		if @@rowcount = 0
			begin
			exec @retcode = bspHQStdUMGet @matlgroup,@material, @matlum, @matlumconv output,@stdum output,@tmpmsg output
			end
		end
	end

if @umval = 'Y' and @rcode = 0 select @msg = @umdesc

---- get payment discount rate
if @saletype = 'C' and @matldisc='Y'
   BEGIN
	if @quote is not null or @disctemplate is not null
		begin
		exec @retcode = dbo.bspMSTicMatlDiscGet @msco,@matlgroup,@material,@category,@locgroup,@fromloc,
                           @matlum,@quote,@disctemplate, @tmppaydiscrate output, @found output, @tmpmsg output
		if @found = 1 select @paydiscrate=@tmppaydiscrate
		end
   END

---- get material phase/cost type and haul phase/cost type from quote for Sales Type = (J)ob
if @quote is not null and @saletype = 'J'
	BEGIN
	if @locgroup is not null and @category is not null and @phasegroup is not null
		begin
		exec @retcode = dbo.bspMSTicMatlPhaseGet @msco,@matlgroup,@material,@category,@locgroup,
                           @fromloc,@phasegroup,@quote,@tmpmatlphase output,@tmpmatlct output,
                           @tmphaulphase output,@tmphaulct output, @tmpmsg output
		if @retcode = 0
			begin
			select @matlphase=@tmpmatlphase, @matlct=@tmpmatlct,
                      @haulphase=@tmphaulphase, @haulct=@tmphaulct
			end
		end
	END


---- issue# 16039, Return OnHand value to form so that it can check for negative flag
select @onhand = (OnHand * @matlumconv) from INMT with (nolock) 
where Loc=@fromloc and MatlGroup=@matlgroup and Material=@material

-- ************* --
-- Issue #130957 --
-- ************* --
-- BROKE IF STATEMENT INTO @ PARTS --
--if @matlum is null or @umval = 'N' goto bspexit
if @matlum is null goto bspexit

---- get material unit price defaults.
exec @retcode = dbo.bspMSTicMatlPriceGet @msco,@matlgroup,@material,@locgroup,@fromloc,@matlum,
           @quote,@pricetemplate,@saledate,@tojcco,@job,@custgroup,@customer,@toinco,@toloc,@priceopt,
           @saletype, @phasegroup, @matlphase, @matlvendor, @VendorGroup, 
		   @unitprice output,@ecm output, @minamt output,@tmpmsg output
if @retcode <> 0
	begin
	select @unitprice = 0, @ecm = 'E', @minamt = 0
	end

-- ************* --
-- Issue #130957 --
-- ************* --
if @umval = 'N' goto bspexit

if @stocked='Y' and @matlvendor is not null and @unitprice = 0
	begin
   	if @matlum=@stdum select @unitprice=@stdunitcost, @ecm=@stdecm
   	if @matlum=@salesum select @unitprice=@salesunitcost, @ecm=@salesecm
   	end

---- set tool tips description
select @totaltooltip = 'Minimum Amount is ' + convert(varchar(13),@minamt)
if @priceopt = 1 select @pricetooltip = 'Pricing Option is average cost plus markup:  '
if @priceopt = 2 select @pricetooltip = 'Pricing Option is last cost plus markup:  '
if @priceopt = 3 select @pricetooltip = 'Pricing Option is standard cost plus markup:  '
if @priceopt = 4 select @pricetooltip = 'Pricing Option is standard price less discount:  '
select @pricetooltip = @pricetooltip + 'Default Unit Price is ' + convert(varchar(13),@unitprice) + @ecm




bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicMatlVal] TO [public]
GO
