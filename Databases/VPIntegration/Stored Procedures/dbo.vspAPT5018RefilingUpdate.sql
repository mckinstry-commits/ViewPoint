SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPT5018RefilingUpdate]
  /***********************************************************
   * CREATED BY: MV 06/15/09 - #127230
   * MODIFIED By : 
   *              
   *
   * USAGE:
   * called from APT5018, updates bAPT5.Type,Amount,Report Date for refiling
   * 
   * INPUT PARAMETERS
   *   

   * OUTPUT PARAMETERS
   *    @msg If Error

   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@apco bCompany, @perenddate bDate,@vendorgroup bGroup,@vendor bVendor, @refiling bYN,
		@amount bDollar,@type char(1), @reportdate bDate,@msg varchar(200)output)
  as
 set nocount on
  
  
  declare @rcode int
  select @rcode = 0
  	
 if @perenddate is null
  	begin
  	select @msg = 'Missing End Date - cannot update APT5.', @rcode = 1
  	goto vspexit
  	end
if @vendorgroup is null
  	begin
  	select @msg = 'Missing VendorGroup - cannot update APT5.', @rcode = 1
  	goto vspexit
  	end
if @vendor is null
  	begin
  	select @msg = 'Missing Vendor - cannot update APT5.', @rcode = 1
  	goto vspexit
  	end
if @refiling is null
  	begin
  	select @msg = 'Missing Refiling - cannot update APT5.', @rcode = 1
  	goto vspexit
  	end
if @amount is null
  	begin
  	select @msg = 'Missing Amount - cannot update APT5.', @rcode = 1
  	goto vspexit
  	end
if @type is null
  	begin
  	select @msg = 'Missing Type - cannot update APT5.', @rcode = 1
  	goto vspexit
  	end
if @reportdate is null
  	begin
  	select @msg = 'Missing Report Date - cannot update APT5.', @rcode = 1
  	goto vspexit
  	end

  if @refiling = 'Y'
	begin
	Update APT5 set RefilingYN= 'Y',Amount=@amount,Type=@type,ReportDate=@reportdate
	where APCo=@apco and PeriodEndDate=@perenddate and VendorGroup=@vendorgroup and Vendor=@vendor
	if @@rowcount = 0
  		begin
  		select @msg = 'APT5 was not updated for Vendor: ' + convert(varchar(10),@vendor), @rcode = 1
  		end
	end
  	

  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPT5018RefilingUpdate] TO [public]
GO
