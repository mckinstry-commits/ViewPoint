SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspAPAAMasterVendorCheck]
  
  /***********************************************************
   * CREATED BY: MV 02/03/05
   * MODIFIED By : 
   *		
   *
   * Usage:
   *	Used by Addtional Addresses in APVM to check if the vendor
   *	is a master vendor for sub vendor update 
   *
   * Input params:
   *	@vendgroup	Vendor Group
   *	@vendorr	Vendor number
   *
   * Output params:
   *	@yn			a Yes/No flag indicating whether the vendor 
   *				is a master vendor or not
   *	@msg		error message
   *
   * Return code:
   *	0 = success, 1 = failure
   *****************************************************/
  (@vendgroup bGroup = null,@vendor bVendor = null, @yn bYN output,@msg varchar(255)=null output)
  as
  set nocount on
  declare @rcode int
  select @rcode = 0, @yn='N'
  /* check required input params */
  if @vendgroup is null
  	begin
  	select @msg = 'Missing Vendor Group.', @rcode = 1
  	goto bspexit
  	end
  
  if @vendor is null
  	begin
  	select @msg = 'Missing Master Vendor.', @rcode = 1
  	goto bspexit
  	end
 
  
  --check if the vendor has any subvendors
  if exists (select 1 from bAPVM with (nolock) where VendorGroup=@vendgroup and MasterVendor= @vendor)
  	begin
  	select @yn='Y'
  	goto bspexit
  	end
 
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPAAMasterVendorCheck] TO [public]
GO
