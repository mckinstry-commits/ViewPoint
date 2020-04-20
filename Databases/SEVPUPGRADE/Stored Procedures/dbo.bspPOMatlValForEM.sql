SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[bspPOMatlValForEM]
/********************************************************
* CREATED BY: 	MV 04/19/04
* MODIFIED BY:	MV 10/22/04 - #25778 return Purch UM from HQMT
*							 and VendMatlId from POVM 
*		MV 01/19/05 - #25936 return first Vendor Matl# combination regardless of UM 
*		TJL 01/29/08 - Issue #126814, Return Matl/Part Last Used Date to forms.			
*				
*
* USAGE:
*	Validates against EMEP,POVM and/or HQMT. 
* 	Retrieves the StandardUM from bHQMT or bEMEP for
*	a valid Material
*
* INPUT PARAMETERS:
*   	EM Company
*   	Equipment
*   	HQ Material Group
*	Material (either HQ or EM equip no)
*	Default UM
*
* OUTPUT PARAMETERS:
*	Valid UM  (bEMWP.UM, bHQMT.PurchaseUM or bEMEP.UM)
*	Taxable Flag
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
@vendorgroup bGroup, @vendor bVendor,@emco bCompany,@equipment bEquip,
@matlgroup bGroup=0,@material varchar(30),@wo bWO = null, @woitem bItem = null, @defum bUM, 
@um bUM output,@matldesc varchar(255) output,@taxcodeflag char(1) output, @vendmatid varchar(30) output,
@matllastuseddate bDate output, @msg varchar(255) output
as
set nocount on

declare @numrows int, @rcode int, @hqmatl varchar(30), @hqmatlgrp bGroup
	
select @rcode=0, @vendmatid = ''
if @vendorgroup is null
	begin
	select @msg='Missing Vendor Group', @rcode=1
	goto bspexit
	end
if @vendor is null
	begin
	select @msg='Missing Vendor', @rcode=1
	goto bspexit
	end
if @emco is null
	begin
	select @msg='Missing EM Company', @rcode=1
	goto bspexit
	end

if @equipment is null
	begin
	select @msg='Missing Equipment', @rcode=1
	goto bspexit
	end

if @matlgroup= 0
	begin
	select @msg='Missing HQ Material Group', @rcode=1
	goto bspexit
	end

if @material is null
	begin
	select @msg='Missing Material or Part No', @rcode=1
	goto bspexit
	end
   
/* Validate material in EMWP */
if @wo is not null and @woitem is not null
	begin
	select @hqmatl = @material
	select @matldesc = Description, @um = UM 
	from bEMWP with (nolock) where EMCo = @emco and WorkOrder=@wo and WOItem=@woitem and
	MatlGroup = @matlgroup and Material = @material	and Equipment = @equipment
	if @@rowcount > 0 goto End_Validation
	end

/* Validate material in bEMEP */
select @matldesc = Description, @um = UM, @hqmatlgrp = MatlGroup, @hqmatl=HQMatl 
from bEMEP with (nolock) where EMCo = @emco and Equipment = @equipment and PartNo = @material
if @@rowcount > 0
	begin
	if @hqmatlgrp is not null and @hqmatl is not null
		begin
		select @um=PurchaseUM from bHQMT with (nolock)
			where MatlGroup = @hqmatlgrp and Material = @hqmatl
		end
		goto End_Validation
	end
   
/* Validate material in bPOVM */
--return Vendor Matl# if POVM UM matches HQMT PurchaseUM
select @vendmatid=VendMatId, @um = h.PurchaseUM, @matldesc = p.Description
from bPOVM p with (nolock)
join bHQMT h with (nolock) on p.MatlGroup=h.MatlGroup and p.Material=h.Material and p.UM=h.PurchaseUM
where p.MatlGroup=@matlgroup and p.Material=@material and p.VendorGroup=@vendorgroup and p.Vendor=@vendor
if @@rowcount = 0 
	begin 
	-- return first Vendor Matl# combination regardless of UM - #25936
	select @um = min(UM) from bPOVM where Vendor = @vendor and VendorGroup = @vendorgroup
	and MatlGroup = @matlgroup and Material = @material
	if @um is not null
		begin
		select @vendmatid=VendMatId, @matldesc = Description from bPOVM with (nolock)
		    where Vendor = @vendor and VendorGroup=@vendorgroup and
	  	  	MatlGroup = @matlgroup and Material = @material and UM = @um
		goto End_Validation
		end
	end
else
	goto End_Validation
  	 
/* Validate material in bHQMT */
select @matldesc = Description, @um = PurchaseUM, @taxcodeflag=Taxable
from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0 
/* If material Id not in bEMEP, bPOVM, bHQMT, return desc */
   begin
   	select @matldesc = 'Not in Material File'
   	goto bspexit 
   end
   
End_Validation:

-- If no taxcode flag found return 'Y'
if @taxcodeflag is null and @hqmatl is not null
	begin
	select @taxcodeflag=Taxable
	from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @hqmatl
	if @@rowcount = 0
		begin
		select @taxcodeflag = 'Y'
		end
	end
	if @taxcodeflag is null and @hqmatl is null
	begin
	select @taxcodeflag = 'Y'
	end
   	
/* Material validation has been successful at this point.  We will now retrieve a "Matl/Part last 
   used date" from EMCD.  This value is display/informational only and there is no need to error
   if for some reason the value cannot be retrieved.  This value will sometimes be displayed on
   forms APEntry, APUnapproved, POEntry, and EMWOPartsPosting. */
select @matllastuseddate = max(ActualDate) 
from EMCD with (nolock) 
where EMCo = @emco and Equipment = @equipment and Material = @material
     
bspexit:
if @rcode<>0 select isnull(@msg, '') + ' [bspPOMatlValForEM]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOMatlValForEM] TO [public]
GO
