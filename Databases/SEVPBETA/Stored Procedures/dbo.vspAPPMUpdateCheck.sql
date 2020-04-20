SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************/
CREATE      proc [dbo].[vspAPPMUpdateCheck]
/****************************************
 * Created By:	MV 06/16/2005
 * Modified By:	MV 03/26/2008 - #127347 - add countries 
 *
 * Called from APVendorMaster before rec update to check AP fields to PM fields. Returns message
 * with changes if applicable. Following fields are checked: Name, SortName, Contact, Phone,
 * Fax, EMail, URL, PayAddress, POAddress
 *
 *
 * Pass:
 * VendorGroup		PM-AP VendorGroup
 * Vendor			AP Vendor
 * Name			
 * SortName
 * Contact
 * Phone
 * Fax
 * EMail
 * URL
 * Address, Address2, City, State, Zip
 * POAddress, POAddress2, POCity, POState, POZip
 *
 *
 * Returns:
 * updateyn flag
 * Message with list of AP-PM changes
 *
 *
 **************************************/
(@vendorgroup bGroup, @vendor bVendor, @name varchar(60), @sortname bSortName,
 @contact varchar(30), @phone bPhone, @fax bPhone, @email varchar(30), @url varchar(60),
 @address varchar(60), @address2 varchar(60), @city varchar(30), @state varchar(4),
 @zip bZip, @poaddress varchar(60), @poaddress2 varchar(60), @pocity varchar(30),
 @postate varchar(4), @pozip bZip, @country char(2),@pocountry char(2), @msg varchar(1000) = null output)
as
set nocount on

declare @rcode int, @pmfm_firmname varchar(60), @pmfm_sortname bSortName, @pmfm_contactname varchar(30),
		@pmfm_phone bPhone, @pmfm_fax bPhone, @pmfm_email varchar(60), @pmfm_url varchar(60),
		@pmfm_mailaddress varchar(60), @pmfm_mailaddress2 varchar(60), @pmfm_mailcity varchar(30),
		@pmfm_mailstate varchar(4), @pmfm_mailzip bZip, @pmfm_shipaddress varchar(60), @pmfm_shipaddress2 varchar(60),
		@pmfm_shipcity varchar(30), @pmfm_shipstate varchar(4), @pmfm_shipzip bZip, @apvm_name varchar(60),
		@apvm_sortname bSortName, @apvm_contactname varchar(30), @apvm_phone bPhone, @apvm_fax bPhone,
		@apvm_email varchar(60), @apvm_url varchar(60), @apvm_address varchar(60), @apvm_address2 varchar(60),
		@apvm_city varchar(30), @apvm_state varchar(4), @apvm_zip bZip, @apvm_poaddress varchar(60), 
		@apvm_poaddress2 varchar(60), @apvm_pocity varchar(30), @apvm_postate varchar(4), @apvm_pozip bZip,
		@chrlf varchar(2),@spaces varchar(3),@pmfm_mailcountry char(2),@pmfm_shipcountry char(2),@apvm_country char(2),
		@apvm_pocountry char(2)

select @rcode = 0, @chrlf = char(13) + char(10), @spaces = ''
select @msg = 'Would you like to update PM Firm Master fields to match AP?' + @chrlf + @chrlf
select @msg = @msg + 'AP Field(Updated Value) - to - PM Field(Current Value)' + @chrlf

-- -- -- get old AP vendor data
select @apvm_name=Name, @apvm_sortname=SortName, @apvm_contactname=Contact, @apvm_phone=Phone,
		@apvm_fax=Fax, @apvm_email=EMail, @apvm_url=URL, @apvm_address=Address,
		@apvm_address2=Address2, @apvm_city=City, @apvm_state=State, @apvm_zip=Zip,
		@apvm_poaddress=POAddress, @apvm_poaddress2=POAddress2, @apvm_pocity=POCity,
		@apvm_postate=POState, @apvm_pozip=POZip,@apvm_country=Country,@apvm_pocountry=POCountry
from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
if @@rowcount = 0 goto bspexit


-- -- -- Check each AP field for change then check against PM
-- -- -- Name 
if isnull(@apvm_name,'') <> isnull(@name,'')
	begin
	select distinct @pmfm_firmname = FirmName from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.FirmName=@apvm_name) or (f.FirmName is null))
	if @@rowcount > 0
		begin
		select @msg = @msg + 'Name: ' + isnull(@name,'[Empty]') + '  -  FirmName: ' + isnull(@pmfm_firmname,'[Empty]') + @chrlf
		select @rcode = 1
		end
	end

-- -- -- sort name
if isnull(@apvm_sortname,'') <> isnull(@sortname,'')
	begin
	select distinct @pmfm_sortname = f.SortName from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.SortName=@apvm_sortname) or (f.SortName is null))
	if @@rowcount > 0
		begin
		select @msg = @msg + 'SortName: ' + isnull(@sortname,'[Empty]') + '  -  SortName: ' + isnull(@pmfm_sortname,'[Empty]') + @chrlf
		select @rcode = 1
		end
	end

-- -- -- contact name
if isnull(@apvm_contactname,'') <> isnull(@contact,'')
	begin
	select distinct @pmfm_contactname = ContactName from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.ContactName=@apvm_contactname) or (f.ContactName is null))
	if @@rowcount > 0
		begin
		select @msg = @msg + 'Contact: ' + isnull(@contact,'[Empty]') + '  -  Contact: ' + isnull(@pmfm_contactname,'[Empty]') + @chrlf
		select @rcode = 1
		end
	end

-- -- -- phone
if isnull(@apvm_phone,'') <> isnull(@phone,'')
	begin
	select distinct @pmfm_phone = f.Phone from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.Phone=@apvm_phone) or (f.Phone is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'Phone: ' + isnull(@phone,'[Empty]') + '  -  Phone: ' + isnull(@pmfm_phone,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- fax
if isnull(@apvm_fax,'') <> isnull(@fax,'')
	Begin
	select distinct @pmfm_fax = f.Fax from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.Fax=@apvm_fax) or (f.Fax is null))
	if @@rowcount > 0
		begin
		select @msg = @msg + 'Fax: ' + isnull(@fax,'[Empty]') + '  -  Fax: ' + isnull(@pmfm_fax,'[Empty]') + @chrlf
		select @rcode = 1
		end
	end


-- -- -- email
if isnull(@apvm_email,'') <> isnull(@email,'')
	Begin
	select distinct @pmfm_email = f.EMail from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.EMail=@apvm_email) or (f.EMail is null))
	if @@rowcount > 0
		begin
		select @msg = @msg + 'Email: ' + isnull(@email,'[Empty]') + '  -  EMail: ' + isnull(@pmfm_email,'[Empty]') + @chrlf
		select @rcode = 1
		end
	end

-- -- -- url
if isnull(@apvm_url,'') <> isnull(@url,'')
	begin
	select distinct @pmfm_url = f.URL from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.URL=@apvm_url) or (f.URL is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'URL: ' + isnull(@url,'[Empty]') + '  -  URL: ' + isnull(@pmfm_url,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- --  address
if isnull(@apvm_address,'') <> isnull(@address,'')
	begin
	select distinct @pmfm_mailaddress = f.MailAddress from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.MailAddress=@apvm_address) or (f.MailAddress is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'Address: ' + isnull(@address,'[Empty]') + '  -  MailAddress: ' + isnull(@pmfm_mailaddress,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- address 2
if isnull(@apvm_address2,'') <> isnull(@address2,'')
	begin
	select distinct @pmfm_mailaddress2 =f.MailAddress2 from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.MailAddress2=@apvm_address2) or (f.MailAddress2 is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'Address2: ' + isnull(@address2,'[Empty]') + '  -  MailAddress2: ' + isnull(@pmfm_mailaddress2,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- city
if isnull(@apvm_city,'') <> isnull(@city,'')
	begin
	select distinct @pmfm_mailcity = f.MailCity from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.MailCity=@apvm_city) or (f.MailCity is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'City: ' + isnull(@city,'[Empty]') + '  -  MailCity: ' + isnull(@pmfm_mailcity,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- state
if isnull(@apvm_state,'') <> isnull(@state,'')
	begin
	select distinct @pmfm_mailstate = f.MailState from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.MailState=@apvm_state) or (f.MailState is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'State: ' + isnull(@state,'[Empty]') + '  -  MailState: ' + isnull(@pmfm_mailstate,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- zip
if isnull(@apvm_zip,'') <> isnull(@zip,'')
	begin
	select distinct @pmfm_mailzip = f.MailZip from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.MailZip=@apvm_zip) or (f.MailZip is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'Zip: ' + isnull(@zip,'[Empty]') + '  -  MailZip: ' + isnull(@pmfm_mailzip,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- country
if isnull(@apvm_country,'') <> isnull(@country,'')
	begin
	select distinct @pmfm_mailcountry = f.MailCountry from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.MailCountry=@apvm_country) or (f.MailCountry is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'Country: ' + isnull(@country,'[Empty]') + '  -  MailCountry: ' + isnull(@pmfm_mailcountry,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- purchase address
if isnull(@apvm_poaddress,'') <> isnull(@poaddress,'')
	begin
	select distinct @pmfm_shipaddress = f.ShipAddress from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.ShipAddress=@apvm_poaddress) or (f.ShipAddress is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'POAddress: ' + isnull(@poaddress,'[Empty]') + '  -  ShipAddress: ' + isnull(@pmfm_shipaddress,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- purchase address 2
if isnull(@apvm_poaddress2,'') <> isnull(@poaddress2,'')
	begin
	select distinct @pmfm_shipaddress2 = f.ShipAddress2 from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.ShipAddress2=@apvm_poaddress2) or (f.ShipAddress2 is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'POAddress2: ' + isnull(@poaddress2,'[Empty]') + '  -  ShipAddress2: ' + isnull(@pmfm_shipaddress2,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- purchase city
if isnull(@apvm_pocity,'') <> isnull(@pocity,'')
	begin
	select distinct @pmfm_shipcity = f.ShipCity from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.ShipCity=@apvm_pocity) or (f.ShipCity is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'POCity: ' + isnull(@pocity,'[Empty]') + '  -  ShipCity: ' + isnull(@pmfm_shipcity,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- Purchase state
if isnull(@apvm_postate,'') <> isnull(@postate,'')
	begin
	select distinct @pmfm_shipstate = f.ShipState from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.ShipState=@apvm_postate) or (f.ShipState is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'POState: ' + isnull(@postate,'[Empty]') + '  -  ShipState: ' + isnull(@pmfm_shipstate,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- Purchase zip
if isnull(@apvm_pozip,'') <> isnull(@pozip,'')
	begin
	select distinct @pmfm_shipzip = f.ShipZip from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.ShipZip=@apvm_pozip) or (f.ShipZip is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'POZip: ' + isnull(@pozip,'[Empty]') + '  -  ShipZip: ' + isnull(@pmfm_shipzip,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end

-- -- -- country
if isnull(@apvm_pocountry,'') <> isnull(@pocountry,'')
	begin
	select distinct @pmfm_shipcountry = f.ShipCountry from PMFM f join APVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
	where f.VendorGroup=@vendorgroup and f.Vendor=@vendor and ((f.ShipCountry=@apvm_pocountry) or (f.ShipCountry is null))
	if @@rowcount > 0
			begin
			select @msg = @msg + 'POCountry: ' + isnull(@pocountry,'[Empty]') + '  -  ShipCountry: ' + isnull(@pmfm_shipcountry,'[Empty]') + @chrlf
			select @rcode = 1
			end
	end







bspexit:
  	if @rcode <> 0 
		select @msg = isnull(@msg,'') + char(13) + char(10) + '[vspAPPMUpdateCheck]'
	else
		select @msg = ''
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPMUpdateCheck] TO [public]
GO
