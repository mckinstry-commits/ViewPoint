SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportVDGet    Script Date: 8/28/99 9:35:14 AM ******/
   CREATE proc [dbo].[bspPMImportVDGet]
   /****************************************************************************
   * CREATED BY: 	GF  06/02/99
   * MODIFIED BY:	GF 06/01/2006 - issue #27997 6.x changes
   *
   * USAGE:
   * 	Gets valid Vendor for import vendor.     
   *
   * INPUT PARAMETERS:
   *	Template, VendorGroup, ImportVendor, PMCo, Override, StdTemplate
   *
   * OUTPUT PARAMETERS:
   *	Vendor
   *       
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
(@template varchar(10), @vendorgroup bGroup, @importvendor varchar(30),
 @pmco bCompany, @override bYN = 'N', @stdtemplate varchar(10) = '',
 @vendor bVendor output)
as
set nocount on

declare @rcode int, @ivendor bVendor

select @rcode = 0, @ivendor = null

if IsNumeric(@importvendor) = 1
	begin
	select @ivendor = convert(int,@importvendor)
	end

if isnull(@importvendor,'') <> ''
	begin
	select @vendor=Vendor from PMUX with (nolock) where Template=@template and XrefType=4 and XrefCode=@importvendor
	if @@rowcount = 0 and @override = 'Y'
		begin
		select @vendor = Vendor from PMUX with (nolock) where Template=@stdtemplate and XrefType=4 and XrefCode=@importvendor
		if @@rowcount = 0 select @vendor = null
		end
	end

--	begin	
--	select @vendor = isnull(Vendor,0)
--	from bPMUX with (nolock) where Template=@template and XrefType=@xreftype and XrefCode=@importvendor and VendorGroup=@vendorgroup
--	if @@rowcount = 0
--		begin
--		select @vendor = isnull(Vendor,0)
--		from bPMUX with (nolock) where Template=@template and XrefType=@xreftype and XrefCode=@importvendor -- -- -- and VendorGroup=@vendorgroup
--		if @@rowcount = 0 and @override = 'Y'
--			begin
--			select @vendor = isnull(Vendor,0)
--			from bPMUX with (nolock) where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importvendor and VendorGroup=@vendorgroup
--			if @@rowcount = 0 
--				begin
--                select @vendor = isnull(Vendor,0)
--                from bPMUX with (nolock) where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importvendor and VendorGroup=@vendorgroup
--                end
--			end
--		end
--	end


if isnull(@vendor,0) = 0
	begin
	select @vendor = Vendor from APVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@ivendor
	if @@rowcount = 0 select @vendor = null
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportVDGet] TO [public]
GO
