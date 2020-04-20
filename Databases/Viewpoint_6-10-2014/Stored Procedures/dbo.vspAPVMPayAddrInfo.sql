SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPVMPayAddrInfo]
  /***********************************************************
   * CREATED BY: MV 01/23/07
   * MODIFIED By :  TJL 03/26/08 - Issue #127347, International Addresses
   *              
   *
   * USAGE:
   * Gets APVM Pay Address info and returns it to APPayWorkfile
   * 
   * INPUT PARAMETERS
   *   Vendor and VendorGroup
   * 
   * OUTPUT PARAMETERS
   *	@payname, @payaddlinfo,@payaddress,@paycity, @paystate, @payzip, @paycountry
   *    @msg If Error
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@vendorgroup bGroup, @vendor bVendor,@payname varchar(60) output,
	 @payaddlinfo varchar(60) output, @payaddress varchar(60) output, @paycity varchar(30) output,
	 @paystate varchar(4) output, @payzip bZip output, @paycountry char(2) output, @msg varchar(255)=null output)
  as
  
  set nocount on
    
  declare @rcode int
  select @rcode = 0
  	
 if @vendorgroup is null
  	begin
  	select @msg = 'Missing vendorgroup', @rcode = 1
  	goto bspexit
  	end

if @vendor is null
  	begin
  	select @msg = 'Missing vendor', @rcode = 1
  	goto bspexit
  	end
  
  select @payname=Name,@payaddlinfo = Address2, @payaddress = Address, @paycity = City,
	 @paystate = State, @payzip = Zip, @paycountry = Country from APVM with (nolock) where VendorGroup=@vendorgroup
	 and Vendor=@vendor
	if @@rowcount = 0
		begin
		select @msg = 'Cannot get address info from Vendor Master.', @rcode = 1
  		goto bspexit
		end


  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPVMPayAddrInfo] TO [public]
GO
