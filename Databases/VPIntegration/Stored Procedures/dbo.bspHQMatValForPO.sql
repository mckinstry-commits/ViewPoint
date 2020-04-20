SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatValForPO    Script Date: 8/28/99 9:34:52 AM ******/
CREATE proc [dbo].[bspHQMatValForPO]
/*************************************
*MODIFIED BY: kb 2/9/00
*		MV 01/20/05 #25936 return VendMatlId from POVM where UM=HQMT.PurchaseUM
*				GF 04/29/2009 - issue #131939 material description expanded to 60-characters
*
*
* Material is option on all PO Types, except Inventory.
* If one is entered that exists in HQMT it's description
* Purchasing UM, Material Phase, Cost Type, Tax Flag and Unit Cost
* Will be used for defaults.
*
* USED IN
*   PO Entry
*   AP Entry
*
* Pass:
*	AP Company   used to get APGroup, etc.
*       MatlGroup    Material Group, Comes from Post to Co
*	Material
*	PO Type, 1-Job, 2-Inv, 3-Exp, 4-Eqpmt, 5-WO,  Type only needs to know weather Inv or not
*       Vendor    vendor entered on PO, used to get some defaults
*
* returns:
*       Description
*       Vend Material Number
*       PurchasingUM
*       Material Phase
*       Cost Type
*       Taxable
*
* Error returns:
*	1 and error message
**************************************/
(@poco bCompany, @matlgroup bGroup, @material bMatl, @potype smallint, @vendor bVendor, 
	@description bItemDesc output, @vendmatid varchar(30) output,
	@purchaseum bUM output, @matphase bPhase output, @matcosttype bJCCType output, @taxable bYN output,
	@msg varchar(60) output)
as
set nocount on
declare @rcode int, @vendorgroup bGroup, @stocked bYN,@um bUM
select @rcode = 0, @description ='Not in this material file.', @vendmatid = '', @matphase = '',
	@matcosttype = null, @taxable = 'Y', @stocked='N'
   
/* get Vendor and Material group from HQCO for this company */
select @vendorgroup=VendorGroup from bHQCO where HQCo=@poco

if @matlgroup is null
	begin
	select @msg = 'Material Group not setup in Headquarters', @rcode = 1
	goto bspexit
	end

if @vendorgroup is null
	begin
	select @msg = 'Vendor Group not setup in Headquarters', @rcode = 1
	goto bspexit
	end

/* General Material validation */   
select @purchaseum=PurchaseUM, @matphase=MatlPhase, @matcosttype=MatlJCCostType, @description=Description,
	@taxable=Taxable,  @stocked=Stocked, @msg = Description
from HQMT where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0
	begin
	select @msg = 'Material not on file.', @rcode = 0
	if @potype=2
	select @rcode = 1
	goto bspexit
	end
  
/* Specific to PO: Validate material in bPOVM */
--return Vendor Matl# if POVM UM matches HQMT PurchaseUM --#25936
select @vendmatid=VendMatId, @purchaseum = h.PurchaseUM, @description = p.Description
from bPOVM p with (nolock)
join bHQMT h with (nolock) on p.MatlGroup=h.MatlGroup and p.Material=h.Material and p.UM=h.PurchaseUM
where p.MatlGroup=@matlgroup and p.Material=@material and p.VendorGroup=@vendorgroup and p.Vendor=@vendor
if @@rowcount = 0 
	begin 
	 /*Get the first Vend Mat combination regardless of UM */
	 select @um = min(UM) from bPOVM where Vendor = @vendor and VendorGroup = @vendorgroup and MatlGroup = @matlgroup and Material = @material
	 if @um is not null
	 	begin
	 	select @vendmatid=VendMatId, @description = Description , @purchaseum = UM 
		from bPOVM
		where Vendor = @vendor and VendorGroup=@vendorgroup and
			MatlGroup = @matlgroup and Material = @material and UM = @um
	 	end
	end
   
if @stocked='N' and @potype=2
	begin
	select @msg = 'Material must be stocked for inventory items.', @rcode = 1
	goto bspexit
	end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatValForPO] TO [public]
GO
