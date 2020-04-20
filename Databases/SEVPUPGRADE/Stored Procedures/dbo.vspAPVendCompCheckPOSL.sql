SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspAPVendCompCheckPOSL]
   /***********************************************************
    * CREATED BY: MV 03/11/05
    * MODIFIED By : 
    *
    * USAGE: Called from frmAPVendComp after adding or updating
    * 	a compliance code, to check if there are any open POs or SLs
    * 	for this Vendor.
    * 
    *
    *  INPUT PARAMETERS
    *   @co	AP Company
    *   @vendgrp	Vendor group 
    *   @vendor	
    *   
    * OUTPUT PARAMETERS
	*	@updatepo	Y/N flag - indicates there are open POs for this vendor
	*	@updatesl	Y/N flag - indicates there are open SLs for this vendor
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@co bCompany,@vendorgroup bGroup, @vendor bVendor, @updatepo bYN output, @updatesl bYN output,
   	@msg varchar(255) output)

   as
   set nocount on
	declare @rcode int
  
   select @rcode=0
     
    if exists (select top 1 1 from bPOHD with (nolock)where POCo=@co and VendorGroup=@vendorgroup
   		and Vendor=@vendor)
   	begin
		select @updatepo='Y'
   	end

  	if exists (select top 1 1 from bSLHD with (nolock) where SLCo=@co and VendorGroup=@vendorgroup
   		and Vendor=@vendor)
   	begin
		select @updatesl='Y'
   	end

   bspexit:
  
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPVendCompCheckPOSL] TO [public]
GO
