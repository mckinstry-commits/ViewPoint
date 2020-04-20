SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMMatlPricesGet ******/
CREATE proc [dbo].[vspPMMatlPricesGet]
/*************************************
 * Created By:	GF 09/19/2006 6.x
 * Modified By:	GF 01/21/2008 - issue #126823 return cost not price
 *				GF 08/15/2010 - issue #135813
 *
 *
 * This procedure is called from PMPOHeader both item tabs, PMMOHeader both item tabs,
 * PMMSQuote both detail tabs, and PMMaterials. returns standard purchase, and sales
 * pricing to display in above forms. Uses different procedures depending on what type
 * of material we are getting prices for. (PO,IN,MS)
 *
 * Usage: Returns the price displays for the PM forms.
 * Searches through HQ, IN, MS, and PO tables using Material, UM, Vendor, Job, and Location.
 *
 *
 * Input Params:
 * @jcco			PM Company
 * @job				PM Project
 * @matlgroup		HQ Material Group
 * @material		PM Material
 * @um				PM Material unit of measure, may be null
 * IN PARAMS
 * @inco			IN Company - optional
 * @loc				IN Location for material - optional
 * PO PARAMS
 * @vendorgroup		AP Vendor Group
 * @vendor			AP Vendor
 * MS PARAMS
 * @msco			MS Company for quotes
 * @quote			MS Quote
 * @phasegroup		PM Phase Group for MS pricing
 * @phase			PM Phase for MS pricing
 * @matltype		PM Material detail type to lookup pricing for (MS,IN,PO)
 *
 * Return Params:
 * @stdum			Std UM
 * @stdprice		Std Unit Price
 * @stdecm			Std ECM
 * @slsum			Sales UM
 * @slsprice		Sales Unit Price
 * @slsecm			Sales ECM
 * @purum			Purchase UM
 * @purprice		Purchase Unit Price
 * @purecm			Purchase ECM
 * @unitcost		Default Unit Price
 * @ecm				Default ECM
 * @taxable			HQ Material Taxable Flag
 * @stocked			HQ Material Stocked Flag
 * @jobpriceopt		IN Job Pricing option
 * @stdtooltip		Std tooltip
 *
 *
 * Return Code:
 *	@rcode 		0 = success, 1 = error
 **************************************/
(@jcco bCompany = null, @job bJob = null, @matlgroup bGroup, @material bMatl,
 @um bUM = null, @inco bCompany = null, @loc bLoc = null, @vendorgroup bGroup = null,
 @vendor bVendor = null, @quote varchar(10) = null, @phasegroup bGroup = null,
 @phase bPhase = null, @matltype varchar(2) = 'PO',
 @stdum bUM = null output, @stdprice bUnitCost = 0 output, @stdecm bECM = null output,
 @slsum bUM = null output, @slsprice bUnitCost = 0 output, @slsecm bECM = null output,
 @purum bUM = null output, @purprice bUnitCost = 0 output, @purecm bECM = null output,
 @unitcost bUnitCost = 0 output, @ecm bECM = null output, @taxable bYN = 'N' output,
 @stocked bYN = 'N' output, @jobpriceopt tinyint = 0 output, @stdtooltip varchar(100) = null output)
as
set nocount on

declare @rcode int, @retcode int, @povmdesc bItemDesc, @msg varchar(255),
		@inmtwgtconv bUnits, @matlumconv bUnitCost

select @rcode = 0 , @unitcost=0, @ecm='E', @stdum='', @stdprice=0, @stdecm='E',
		@slsum='', @slsprice=0, @slsecm='E', @purum='', @purprice=0, @purecm='E',
		@taxable = 'N', @stocked = 'N', @jobpriceopt = 0,
		@stdtooltip = 'Std Cost will display here'

---- Material Group, Material, and UM are required
if @matlgroup is null or @material is null
	begin
	goto bspexit
	end

---- get HQ Material information
select @stdum=StdUM, @slsum=SalesUM, @purum=PurchaseUM,
		@stdprice=Cost, @purprice=Cost, @slsprice=Cost,
		@purecm=CostECM, @stdecm=CostECM, @slsecm=CostECM,
		@taxable=Taxable, @stocked=Stocked
from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0 goto bspexit

---- if purchase UM non-standard look for price in HQMU
if @purum <> @stdum
	begin
	select @purprice=Cost, @purecm=CostECM
	from bHQMU with (nolock)
	where MatlGroup=@matlgroup and Material=@material and UM=@purum
	if @@rowcount = 0
		begin
		select @purprice=0, @purecm='E'
		end
	end

---- if sales UM non-standard look for sales price in HQMU
if @slsum <> @stdum
	begin
	select @slsprice=Cost, @slsecm=CostECM
	from bHQMU with (nolock)
	where MatlGroup=@matlgroup and Material=@material and UM=@slsum
	if @@rowcount = 0
		begin
		select @slsprice = 0, @slsecm='E'
		end
	end

---- if @um is empty and we have a location get IN pricing
if isnull(@um,'') = '' and isnull(@loc,'') <> ''
	begin
   	exec @retcode = dbo.bspINMOMatlUMVal @inco, @loc, @material, @matlgroup, @slsum, @jcco, @job, null, @slsecm output, @slsprice output, @msg output
   	if @retcode <> 0
       	begin
       	select @unitcost = 0, @ecm = 'E'
       	end
	else
		begin
		select @unitcost = @slsprice, @ecm = @slsecm
		end
	end

---- if @um is empty then done. has not been entered yet. no default
if isnull(@um,'') = '' goto bspexit

---- call HQ SP to get unit price default
exec @retcode = dbo.bspHQMatUnitCostDflt @vendorgroup, @vendor, @matlgroup, @material, @um, 
			@jcco, @job, @inco, @loc, @unitcost output, @ecm output, @povmdesc output, @msg output 
if @retcode <> 0
	begin
	select @unitcost = 0, @ecm = 'E'
	end

---- if a PO material then we are done.
if @vendor is not null goto bspexit

---- if a IN material, check if UM exists in INMU
if @um <> @stdum
	begin
	if not exists(select UM from bINMU with (nolock) where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup
						and Material=@material and UM=@um)
		begin
		----select @msg = 'Material UM is not set up for the IN Location', @rcode = 1
		goto bspexit
		end
	end

---- get UM weight conversion
select @inmtwgtconv=isnull(WeightConv,0)
from bINMT with (nolock) 
where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material

---- get material um conversion factor
if @um = @stdum
	begin
	if @um = 'LBS'
		select @matlumconv = @inmtwgtconv
	else
		select @matlumconv = 1
	end
else
	begin
	select @matlumconv=Conversion from bINMU with (nolock) 
	where MatlGroup=@matlgroup and INCo=@inco and Material=@material and Loc=@loc and UM=@um
	if @@rowcount = 0
		begin
		exec @retcode = dbo.bspHQStdUMGet @matlgroup, @material, @um, @matlumconv output, @stdum output, @msg output
		end
	end

---- get IN sales price
exec @retcode = dbo.bspINMOMatlUMVal @inco, @loc, @material, @matlgroup, @slsum, @jcco, @job, null, @slsecm output, @slsprice output, @msg output
if @retcode <> 0
	begin
	select @unitcost = 0, @ecm = 'E'
	end
else
	begin
	select @unitcost = @slsprice, @ecm = @slsecm
	end

---- get IN um pricing
if @um <> @slsum
	begin
	exec @retcode = dbo.bspINMOMatlUMVal @inco, @loc, @material, @matlgroup, @um, @jcco, @job, null, @ecm output, @unitcost output, @msg output
	if @retcode <> 0
		begin
		select @unitcost = 0, @ecm = 'E'
		end
	end

goto bspexit







bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMMatlPricesGet] TO [public]
GO
