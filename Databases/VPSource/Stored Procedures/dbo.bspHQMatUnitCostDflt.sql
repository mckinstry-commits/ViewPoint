SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatUnitCostDflt    Script Date: 8/28/99 9:34:52 AM ******/
CREATE proc [dbo].[bspHQMatUnitCostDflt]
/*************************************
    * CREATED BY:  SE 4/16/97
    * MODIFIED BY: GG 6/12/97
    *            : GR 3/17/00  added an output param to return
    *              vendor description from PO Vendor Master
    *            : GR 1/26/01 added two input params inco and loc to
    *              default unit cost from INMT instead of HQMT, if non stdum then
    *              from bINMU only if the material is not the vendor material
    *				MV 05/05/05 - #27765 - add '= null' to jcco and job input params for 6x recode
    *				GF 07/07/2010 - issue #137272 expanded vendor descr for 60 characters.
    *
    * This procedure is called from APEntry, APRecurInv, APUnappInv, PMMaterial,
    * PMPOItems, PMSLItems, POEntry
    * Usage:
    * Searches through HQ and PO tables using Material, UM, Vendor, Category, and Job to find
    * a default unit cost.
    
    * Returns 0.00E unit cost if the Material and UM combination does not exist in HQ.
    *
    * Input Params:
    *	@vendgroup	Group to qualify Vendor - optional
    *	@vend		Vendor the material is being purchased from - optional
    *	@matlgroup	Group to qualify Material - required
    *	@material	Material being purchased - required
    *	@um		    Unit of measure in which the material is being purchased - required.
    *	@jcco		Job Cost company to qualify job - optional
    *	@job		Job the material is being purchased for - optional
    *   @inco       Inventory company - optional
    *   @loc        Location of the material - optional
    
    *
    *Return Params:
    *	@unitcost	Default Unit Cost
    *	@ecm		Unit Cost per Each, Hundred, or Thousand
    *	@errmsg		Error message if error occurs
    * Return Code:
    *	@rcode 		0 = success, 1 = error
    **************************************/
(@vendgroup bGroup, @vend bVendor, @matlgroup bGroup, @material bMatl,
 @um bUM, @jcco bCompany = null, @job bJob = null, @inco bCompany = null, @loc bLoc = null,
 @unitcost bUnitCost = 0 output, @ecm bECM = null output,
 ----#137272
 @venddescrip bItemDesc = null output, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @category varchar(10), @stdum bUM, @stdcost bUnitCost, @stdprice bUnitCost,
    	@pricedisc bPct, @stdpecm bECM, @stdcecm bECM, @jobcostopt tinyint,
    	@vendcostopt tinyint, @vendcost bUnitCost, @vendcecm bECM, @vendprice bUnitCost,
    	@vendpecm bECM, @venddisc bPct, @disc bPct, @lastcost bUnitCost, @lastecm bECM

---- initialize return params
select @unitcost = 0.00, @ecm = 'E', @rcode = 0, @errmsg = ''

---- Material Group, Material, and UM are required
if @matlgroup is null
    	begin
    	select @errmsg = 'Missing Material Group.', @rcode = 1
    	goto bspexit
    	end

if @material is null
    	begin
    	select @errmsg = 'Missing Material.', @rcode = 1
    	goto bspexit
    	end

if @um is null
    	begin
    	select @errmsg = 'Missing Unit of Measure', @rcode = 1
    	goto bspexit
    	end

---- get standard info from bHQMT
select @stdum = StdUM, @stdprice = Price, @stdcost = Cost,
    	@category = Category, @stdcecm = CostECM, @stdpecm = PriceECM
from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0 goto bspexit

---- if non-std UM, get unit cost and price from bHQMU
if @um <> @stdum
    	begin
    	select @stdcost= Cost, @stdcecm = CostECM, @stdprice = Price, @stdpecm = PriceECM
    	from bHQMU with (nolock)
		where MatlGroup = @matlgroup and Material = @material and UM = @um
    	if @@rowcount = 0 goto bspexit
    	end

---- get unit cost from bINMT, if non stdum from bINMU for inventory type lines
if @inco is not null and @loc is not null
	begin
	select @lastcost=LastCost, @lastecm=LastECM
	from bINMT with (nolock)
	where INCo=@inco and Loc=@loc and Material=@material and MatlGroup=@matlgroup
	if @@rowcount = 0 goto bspexit
    
	if @um <> @stdum
		begin
		select @lastcost=LastCost, @lastecm=LastECM
		from bINMU with (nolock)
		where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material and UM=@um
		end
	end


---- check for Vendor pricing in bPOVM
select @vendcostopt = 0, @vendprice = 0.00
if @vendgroup is not null and @vend is not null
	begin
	select @vendcostopt = CostOpt, @vendcost = isnull(UnitCost,0), @vendcecm = isnull(CostECM,'E'),
   			@vendprice = isnull(BookPrice,0), @vendpecm = isnull(PriceECM,'E'), @venddisc = PriceDisc,
   			@venddescrip=Description
	from bPOVM with (nolock)
	where VendorGroup=@vendgroup and Vendor=@vend and MatlGroup=@matlgroup
	and Material = @material and UM = @um

	---- check for Job Material pricing in bPOJM
	if @jcco is not null and @job is not null
		begin
		select @jobcostopt = 0,  @disc = null
		select @jobcostopt = CostOpt, @unitcost = isnull(UnitCost,0), @ecm = isnull(CostECM,'E'), @disc = PriceDisc
		from bPOJM with (nolock)
		where VendorGroup=@vendgroup and Vendor=@vend and MatlGroup=@matlgroup and Material=@material
		and UM=@um and JCCo=@jcco and Job=@job
		if @@rowcount = 0
			begin
			---- check for Job Category discounts in bPOJC
			select @disc = PriceDisc
			from bPOJC with (nolock)
			where VendorGroup = @vendgroup and Vendor = @vend and MatlGroup = @matlgroup
			and Category = @category and JCCo = @jcco and Job = @job
			end

		---- use bPOJM unit cost
		if @jobcostopt = 1 goto bspexit

		---- discount from bPOVM price
		if @disc is not null
			begin
			if @vendprice <> 0.00			
				begin
				select @unitcost = @vendprice * (1-@disc), @ecm = @vendpecm
				goto bspexit
				end
			---- discount from HQ price
			select @unitcost = @stdprice * (1-@disc), @ecm = @stdpecm	 
			goto bspexit
			end
		end

	---- if Vendor Cost Option has been set (bPOVM exists) use it to determine unit cost
	if @vendcostopt = 1
    		begin
    		select @unitcost = @stdcost, @ecm = @stdcecm	/* use std HQ unit cost */
    		goto bspexit
    		end
	if @vendcostopt = 2
    		begin
    		select @unitcost = @vendcost, @ecm = @vendcecm	/* use bPOVM unit cost */
    		goto bspexit
    		end
	if @vendcostopt = 3
    		begin
    		select @unitcost = @stdprice * (1-isnull(@venddisc,0)), @ecm = @stdpecm	/* bPOVM discount off HQ price */
    		goto bspexit
    		end
	if @vendcostopt = 4
    		begin
    		select @unitcost = @vendprice * (1-isnull(@venddisc,0)), @ecm = @vendpecm	/* bPOVM discount off bPOVM price */
    		goto bspexit
    		end
    
	---- was not in bPOJM, bPOJC, or bPOVM, check bPOVC for discount off HQ price
	select @disc = isnull(PriceDisc,0)
	from bPOVC with (nolock)
	where VendorGroup=@vendgroup and Vendor=@vend and MatlGroup=@matlgroup and Category=@category
	if @@rowcount = 1
		begin
		---- bPOVC discount off HQ price
		select @unitcost = @stdprice * (1-@disc), @ecm = @stdpecm
		goto bspexit
		end
	end


---- no Vendor overrides exist, if inventory type use IN Last cost else use HQ unit cost
if @inco is not null and @loc is not null
	begin
	select @unitcost = @lastcost, @ecm = @lastecm
	end
else
	begin
	select @unitcost = @stdcost, @ecm = @stdcecm
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatUnitCostDflt] TO [public]
GO
