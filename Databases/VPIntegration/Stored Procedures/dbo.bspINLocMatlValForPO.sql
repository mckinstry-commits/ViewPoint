SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspINLocMatlValForPO]
   /*******************************************************************************
   *Created    GR 03/21/00
   *Modified	MV 01/20/05 - #25936 return VendMatlId from POVM where UM=HQMT.PurchaseUM 
	*			DC 01/25/08 - #29156 Display on hand and on order amounts from IN when 
	*								entering a PO item with inventory
	*			DC 4/03/08 - #127682 - Changed the error message for inactive IN materials
	*			GP 05/06/09 - Modified @description bItemDesc
   *
   * validates Material stocked at the production Location in IN Materital(INMT)
   * it's description, Purchasing UM will be used for defaults.
   *
   * Pass:
   *	@inco           IN Company
   *   @location       IN Location
   *   @material       Material
   *   @matlgrp        Material Group
   *
   * USED IN
   *   PO Entry
   *   AP Entry
   *
   * returns:
   *       Description
   *       Vend Material Number
   *       PurchasingUM
   *       Taxable
   *       Taxcode
   *       Unitcost
   *       ECM
   *
   * Error returns:
   *	1 and error message
   *********************************************************************************/
   
   	(@inco bCompany = null, @location bLoc = null, @material bMatl = null,
       @matlgroup bGroup = null, @vendor bVendor = null, @description bItemDesc output,
       @vendmatid varchar(30) output,  @purchaseum bUM output, @taxable bYN output,
       @taxcode bTaxCode output, 
		@onhand bUnits output, @onorder bUnits output, --DC #29156
		@msg varchar(60) output)
   
   as
   	set nocount on
   	declare @rcode int, @vendorgroup bGroup, @stocked bYN, @um bUM, @active bYN
   
   	select @rcode = 0
   
   if @inco is null
       begin
       select @msg = 'Missing IN Company', @rcode=1
       goto bspexit
       end
   
   if @location is null
       begin
       select @msg = 'Missing Location', @rcode=1
       goto bspexit
       end
   
   if @material is null
       begin
       select @msg = 'Missing Material', @rcode=1
       goto bspexit
       end
   
   if @matlgroup is null
   	begin
   	select @msg = 'Material Group not setup in Headquarters', @rcode = 1
   	goto bspexit
   	end
   
   --get Vendor group from HQCO for this company
   select @vendorgroup=VendorGroup from bHQCO where HQCo=@inco
   
   if @vendorgroup is null
   	begin
   	select @msg = 'Vendor Group not setup in Headquarters', @rcode = 1
   	goto bspexit
   	end
   
   
   select @purchaseum=PurchaseUM, @description=Description,
          @taxable=Taxable,  @stocked=Stocked, @msg = Description
         from bHQMT where MatlGroup = @matlgroup and Material = @material
   
   if @@rowcount = 0
       begin
       select @msg = 'Material not setup in Headquarters', @rcode = 1
       goto bspexit
       end
   
   if @stocked = 'N'
       begin
       select @msg = 'Material must be stocked for inventory items.', @rcode = 1
       goto bspexit
       end
   
   --get tax code
   if @taxable = 'Y'
       begin
       select @taxcode = TaxCode from bINLM
       where INCo=@inco and Loc = @location
       end
   
   --validate material in INMT
   select @active = Active, @onhand = OnHand, @onorder = OnOrder
   from bINMT
   where INCo = @inco and Loc = @location and Material=@material and MatlGroup=@matlgroup
   if @@rowcount = 0
       begin
       select @msg='Material not set up in IN Location Materials', @rcode=1
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Must be an active Inventory Material.', @rcode = 1  --DC #127682
       goto bspexit
       end
   
   /* Validate material in bPOVM */
    --return Vendor Matl# if POVM UM matches HQMT PurchaseUM --#25936
   select @vendmatid=VendMatId, @purchaseum = h.PurchaseUM, @description = p.Description
   	from bPOVM p with (nolock)
   	join bHQMT h with (nolock) on p.MatlGroup=h.MatlGroup and p.Material=h.Material and p.UM=h.PurchaseUM
   	where p.MatlGroup=@matlgroup and p.Material=@material and p.VendorGroup=@vendorgroup and p.Vendor=@vendor
   	if @@rowcount = 0 
   		begin 
   		--return the first Vend Mat combination regardless of UM
   		select @um = min(UM) from bPOVM where Vendor = @vendor and VendorGroup = @vendorgroup
   		and MatlGroup = @matlgroup and Material = @material
   		if @um is not null
   			begin
   			select @vendmatid=VendMatId, @description = Description , @purchaseum = UM from bPOVM
   			    where Vendor = @vendor and VendorGroup=@vendorgroup and
   		  	  MatlGroup = @matlgroup and Material = @material and UM = @um
   			end
   		end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINLocMatlValForPO] TO [public]
GO
