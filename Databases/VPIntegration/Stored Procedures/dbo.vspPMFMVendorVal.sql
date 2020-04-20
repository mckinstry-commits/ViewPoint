SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMFMVendorVal    Script Date: 05/31/2005 ******/
CREATE   proc [dbo].[vspPMFMVendorVal]
/***********************************************************
 * Created By:	GF 05/31/2005
 * Modified By:	GF 03/12/2008 - issue #127076 international address changes
 *
 *
 *
 * Usage:
 * Used by PM Firm Master to validate the entry of the AP vendor.
 * Checks the allow add vendor flag from APCo, if true then new vendor is allowed.
 * Currently the active and type flags are 'X' for the AP Vendor Validation.
 * If the APCO.PMVendAddYN flag is 'Y', then a vendor number that does not exist
 * in APVM is allowed. Will be added on PMFM Update/Add.
 *
 *
 * @activeopt	Controls validation based on Active flag
 *			'Y' = must be an active
 *			'N' = must be inactive
 *			'X' = can be any value
 *
 * @typeopt		Controls validation based on Vendor Type
 *			'R' = must be Regular
 *			'S' = must be Supplier
 *			'X' = can be any value
 *
 * Input params:
 * @apco		AP company
 * @vendorgroup	Vendor Group
 * @vendor		Vendor sort name or number
 *
 * Output params:
 * @vendorout	Vendor number
 * @msg		Vendor Name or error message
 *
 * Return code:
 * 0 = success, 1 = failure
 *****************************************************/
(@apco bCompany, @vendorgroup bGroup = null, @vendor varchar(15) = null,
 @vendorout bVendor = null output, @newvendor bYN = 'N' output, @mailaddress varchar(60) = null output,
 @mailcity varchar(30) = null output,@mailstate varchar(4) = null output, @mailzip bZip = null output, 
 @mailaddress2 varchar(60) = null output, @shipaddress varchar(60) = null output,
 @shipcity varchar(30) = null output,@shipstate varchar(4) = null output, @shipzip bZip = null output, 
 @shipaddress2 varchar(60) = null output, @phone bPhone = null output, @fax bPhone = null output,
 @contact varchar(30) = null output, @firmname varchar(60) = null output, @sortname bSortName = null output,
 @email varchar(60) = null output, @url varchar(60) = null output, @mailcountry varchar(2) = null output,
 @shipcountry varchar(2) = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @type char(1), @active bYN, @activeopt varchar(1), @typeopt varchar(1),
		@pmvendaddyn bYN

select @rcode = 0, @activeopt = 'X', @typeopt = 'X', @pmvendaddyn = 'N', @newvendor = 'N'

if @vendorout = 0 set @vendorout = null

if @apco is null
	begin
	select @msg = 'Missing AP Company.', @rcode = 1
	goto bspexit
	end

if @vendorgroup is null
	begin
   	select @msg = 'Missing Vendor Group.', @rcode = 1
   	goto bspexit
   	end

if @vendor is null
   	begin
   	select @msg = 'Missing Vendor.', @rcode = 1
   	goto bspexit
   	end

-- -- -- get APCO.PMVendAddYN
select @pmvendaddyn=PMVendAddYN from APCO where APCo=@apco
set rowcount 0


-- if vendor is not numeric then assume a SortName
if dbo.bfIsInteger(@vendor) = 1
	begin
  	if len(@vendor) < 7
  		begin
   		select @vendorout=Vendor, @msg=Name, @active=ActiveYN, @type=Type, @firmname=Name,
			@sortname=SortName, @contact=Contact, @phone=Phone, @fax=Fax, @email=EMail, @url=URL,
			@mailaddress=Address, @mailcity=City, @mailstate=State, @mailzip=Zip, @mailaddress2=Address2,
			@shipaddress=POAddress, @shipcity=POCity, @shipstate=POState, @shipzip=POZip,
			@shipaddress2=POAddress2, @mailcountry=Country, @shipcountry=POCountry
   		from APVM with (nolock)
   		where VendorGroup = @vendorgroup and Vendor = convert(int,convert(float, @vendor))
  		end
	end

-- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @vendorout=Vendor, @msg=Name,  @active=ActiveYN, @type=Type, @firmname=Name,
			@sortname=SortName, @contact=Contact, @phone=Phone, @fax=Fax, @email=EMail, @url=URL,
			@mailaddress=Address, @mailcity=City, @mailstate=State, @mailzip=Zip, @mailaddress2=Address2,
			@shipaddress=POAddress, @shipcity=POCity, @shipstate=POState, @shipzip=POZip,
			@shipaddress2=POAddress2, @mailcountry=Country, @shipcountry=POCountry
	from APVM with (nolock)
	where VendorGroup = @vendorgroup and SortName = @vendor
	-- -- -- if not found, try to find closest
	if @@rowcount = 0
		begin
		set rowcount 1
		select @vendorout=Vendor, @msg=Name, @active=ActiveYN, @type=Type, @firmname=Name,
			@sortname=SortName, @contact=Contact, @phone=Phone, @fax=Fax, @email=EMail, @url=URL,
			@mailaddress=Address, @mailcity=City, @mailstate=State, @mailzip=Zip, @mailaddress2=Address2,
			@shipaddress=POAddress, @shipcity=POCity, @shipstate=POState, @shipzip=POZip,
			@shipaddress2=POAddress2, @mailcountry=Country, @shipcountry=POCountry
		from APVM with (nolock)
		where VendorGroup = @vendorgroup and SortName like @vendor + '%'
		if @@rowcount <> 0 goto bspexit
		if @pmvendaddyn = 'N'
			begin
	   	    select @msg = 'Not a valid Vendor', @rcode = 1
			goto bspexit
			end
		else
			if isnumeric(@vendor) = 1
				begin
				select @vendorout = convert(integer,@vendor), @msg = 'New Vendor', @newvendor = 'Y', @rcode = 0
				goto bspexit
				end
			else
				begin
				select @msg = 'Not a valid Vendor', @rcode = 1
				goto bspexit
				end
		end
	end










bspexit:
  	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMFMVendorVal] TO [public]
GO
