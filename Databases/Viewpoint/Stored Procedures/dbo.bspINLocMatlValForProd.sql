SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE  procedure [dbo].[bspINLocMatlValForProd]
/***********************************************************************************
 * Created By:	GF 01/21/2008 - issue #124899
 * Modified By: GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
 *
 *
 * USAGE: used in IN Production Entry Components to validate material using bspINLocMatlVal.
 * Then tries to find an override unit price in MS Quotes.
 * validates Material stocked at the production Location in IN Materital(INMT)
 *
 * Pass:
 * @inco           IN Company
 * @location       IN Location
 * @material       Material
 * @matlgrp        Material Group
 * @activeopt      Active option - Y = must be active, N = may be inactive
 * @prodmatlYN     Y- only if it is a finished i.e produnction material used in Production Posting program
 *                   and in all other programs it will be N
 *                   (this parameter is hardcoded from wherever the procedure is called)
 * @prodloc			IN Production Location
 * @proddate		IN Production Date
 *
 *
 * Success returns:
 * UM            Std Unit of Measure
 * UnitCost      Unit Cost
 * ECM           Unit Cost ECM
 * UnitPrice	 Unit Price
 * PECM			 Unit Price ECM
 * Error returns:
 *	1 and error message
 ************************************************************************************/
(@inco bCompany = null, @location bLoc = null, @material bMatl = null, @matlgrp bGroup = null,
 @activeopt bYN = null, @prodloc bLoc = null, @proddate bDate = null,
 @um bUM = null output, @unitcost bUnitCost = null output, @ecm bECM = null output,
 @unitprice bUnitCost = null output, @pecm bECM = null output, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @active bYN, @locgroup bGroup, @validcnt int, @stocked bYN, 
   		@category varchar(10), @invpriceopt int, @loccostmethod int, @locadjglacct bGLAcct,
   		@loctaxcode bTaxCode, @incocostmethod int, @usageopt varchar(1), @costmethod int,
		@locpricetemplate smallint, @pricetemplate smallint, @quote varchar(10), @minamt bDollar,
		@prodlocgroup bGroup, @qunitprice bUnitCost, @qpecm bECM, @MatlVendor bVendor, @VendorGroup bGroup

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

---- get inventory sales price option from IN Company
select @invpriceopt=InvPriceOpt, @incocostmethod=CostMethod, @usageopt=UsageOpt
from dbo.INCO with (nolock) where INCo=@inco

---- get component location data
select @locgroup=LocGroup, @loccostmethod=CostMethod
from dbo.INLM with (nolock) where INCo=@inco and Loc=@location

---- #14689 - look for MS Price Template assigned to Production Location
select @locpricetemplate = PriceTemplate, @prodlocgroup=LocGroup
from dbo.bINLM (nolock) where INCo=@inco and Loc=@prodloc

---- #14689 - look for MS Quote overrides
select @quote = Quote, @pricetemplate = PriceTemplate
from dbo.bMSQH (nolock)
where MSCo = @inco and QuoteType = 'I' and INCo = @inco and Loc = @prodloc and Active = 'Y'

-- Price Template in Quote overrides Location
if @pricetemplate is null set @pricetemplate = @locpricetemplate

---- get category and material description
select @category=Category, @msg = Description, @um = StdUM, @stocked = Stocked
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

---- Get cost method
select @costmethod=CostMethod
from dbo.INLO with (nolock)
where INCo=@inco and Loc=@location and MatlGroup=@matlgrp and Category=@category
if @costmethod is null or @costmethod=0
	begin
	select @costmethod=@loccostmethod
	if @costmethod is null or @costmethod = 0
		begin
		select @costmethod=@incocostmethod
		end
	end

---- validate material in INMT
select @active = i.Active,
		@unitcost=case @costmethod when 1 then i.AvgCost when 2 then i.LastCost when 3 then i.StdCost end,
		@ecm=case @costmethod when 1 then i.AvgECM when 2 then i.LastECM when 3 then i.StdECM end,
		@unitprice=case @invpriceopt when 1 then i.AvgCost + (i.AvgCost * i.InvRate)
		when 2 then i.LastCost + (i.LastCost * i.InvRate)
		when 3 then i.StdCost + (i.StdCost * i.InvRate)
		when 4 then i.StdPrice - (i.StdPrice * i.InvRate) end,
		@pecm = case @invpriceopt when 1 then i.AvgECM when 2 then i.LastECM
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


---- if component is 'sold' to production location get unit price and ecm from source location
if @usageopt = 'S' and @prodloc <> @location
	begin
	---- #14689 - use MS pricing hierarchy to determine unit price
	exec @rcode = bspMSTicMatlPriceGet @inco, @matlgrp, @material, @locgroup, @location,
			@um, @quote, @pricetemplate, @proddate, null, null, null, null, @inco, @prodloc, 
			@invpriceopt, 'I', null, null, @MatlVendor, @VendorGroup,
			@qunitprice output, @qpecm output, @minamt output, @msg output
	if @rcode = 0 
		begin
		select @unitprice = @qunitprice, @pecm=@qpecm
		end
	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINLocMatlValForProd] TO [public]
GO
