SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************/
CREATE proc [dbo].[vspPMAPUpdateCheck]
/****************************************
 * Created By:	GF 05/02/2005
 * Modified By:	GF 03/12/2008 - issue #127076 Mail, Ship Country checks
 *
 *
 * Called from PMFirmMaster before rec update to check PM fields to AP fields. Returns message
 * with changes if applicable. Following fields are check: FirmName, SortName, Contact, Phone,
 * Fax, EMail, URL, MailAddress, ShipAddress
 *
 *
 * Pass:
 * VendorGroup		PM-AP VendorGroup
 * FirmNumber		PM Firm
 * Vendor			AP Vendor
 * FirmName			
 * SortName
 * ContactName
 * Phone
 * Fax
 * EMail
 * URL
 * MailAddress, MailAddress2, MailCity, MailState, MailZip
 * ShipAddress, ShipAddress2, ShipCity, ShipState, ShipZip
 * MailCountry, ShipCountry
 *
 * Returns:
 * updateyn flag
 * Message with list of PM-AP changes
 *
 *
 **************************************/
(@vendorgroup bGroup, @firm bVendor, @vendor bVendor, @firmname varchar(60), @sortname bSortName,
 @contactname varchar(30), @phone bPhone, @fax bPhone, @email varchar(30), @url varchar(60),
 @mailaddress varchar(60), @mailaddress2 varchar(60), @mailcity varchar(30), @mailstate varchar(4),
 @mailzip bZip, @shipaddress varchar(60), @shipaddress2 varchar(60), @shipcity varchar(30),
 @shipstate varchar(4), @shipzip bZip, @mailcountry varchar(2), @shipcountry varchar(2),
 @update varchar(1) output, @msg varchar(1000) = null output)
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
		@chrlf varchar(2), @pmfm_mailcountry varchar(2), @pmfm_shipcountry varchar(2),
		@apvm_country varchar(2), @apvm_pocountry varchar(2)
		

select @rcode = 0, @update = 'N', @chrlf = char(13) + char(10)
select @msg = 'Would you like to update AP Vendor Master fields to match PM?' + @chrlf + @chrlf
select @msg = @msg + 'PM Field(Updated Value)  to  AP Field(Current Value)' + @chrlf

-- -- -- get old PM firm data
select @pmfm_firmname=FirmName, @pmfm_sortname=SortName, @pmfm_contactname=ContactName, @pmfm_phone=Phone,
		@pmfm_fax=Fax, @pmfm_email=EMail, @pmfm_url=URL, @pmfm_mailaddress=MailAddress,
		@pmfm_mailaddress2=MailAddress2, @pmfm_mailcity=MailCity, @pmfm_mailstate=MailState,
		@pmfm_mailzip=MailZip, @pmfm_shipaddress=ShipAddress, @pmfm_shipaddress2=ShipAddress2,
		@pmfm_shipcity=ShipCity, @pmfm_shipstate=ShipState, @pmfm_shipzip=ShipZip,
		@pmfm_mailcountry=MailCountry, @pmfm_shipcountry=ShipCountry
from PMFM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@firm
if @@rowcount = 0 goto bspexit

-- -- -- get old AP vendor data
select @apvm_name=Name, @apvm_sortname=SortName, @apvm_contactname=Contact, @apvm_phone=Phone,
		@apvm_fax=Fax, @apvm_email=EMail, @apvm_url=URL, @apvm_address=Address,
		@apvm_address2=Address2, @apvm_city=City, @apvm_state=State, @apvm_zip=Zip,
		@apvm_poaddress=POAddress, @apvm_poaddress2=POAddress2, @apvm_pocity=POCity,
		@apvm_postate=POState, @apvm_pozip=POZip, @apvm_country=Country, @apvm_pocountry=POCountry
from APVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
if @@rowcount = 0 goto bspexit


---- check each pm field for a change, if changed then check to AP field
---- firm name
if isnull(@pmfm_firmname,'') <> isnull(@firmname,'')
	begin
	if @apvm_name is null
		begin
		select @msg = @msg + 'FirmName: ' + isnull(@firmname,'') + '  Name: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_firmname,'') = @apvm_name
			begin
			select @msg = @msg + 'FirmName: ' + isnull(@firmname,'') + '  Name: ' + isnull(@apvm_name,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- sort name
if isnull(@pmfm_sortname,'') <> isnull(@sortname,'')
	begin
	if @apvm_sortname is null
		begin
		select @msg = @msg + 'SortName: ' + isnull(@sortname,'') + '  SortName: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_sortname,'') = @apvm_sortname
			begin
			select @msg = @msg + 'SortName: ' + isnull(@sortname,'') + '  SortName: ' + isnull(@apvm_sortname,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- contact name
if isnull(@pmfm_contactname,'') <> isnull(@contactname,'')
	begin
	if @apvm_contactname is null
		begin
		select @msg = @msg + 'Contact: ' + isnull(@contactname,'') + '  Contact: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_contactname,'') = @apvm_contactname
			begin
			select @msg = @msg + 'Contact: ' + isnull(@contactname,'') + '  Contact: ' + isnull(@apvm_contactname,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- phone
if isnull(@pmfm_phone,'') <> isnull(@phone,'')
	begin
	if @apvm_phone is null
		begin
		select @msg = @msg + 'Phone: ' + isnull(@phone,'') + '  Phone: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_phone,'') = @apvm_phone
			begin
			select @msg = @msg + 'Phone: ' + isnull(@phone,'') + '  Phone: ' + isnull(@apvm_phone,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- fax
if isnull(@pmfm_fax,'') <> isnull(@fax,'')
	begin
	if @apvm_fax is null
		begin
		select @msg = @msg + 'Fax: ' + isnull(@fax,'') + '  Fax: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_fax,'') = @apvm_fax
			begin
			select @msg = @msg + 'Fax: ' + isnull(@fax,'') + '  Fax: ' + isnull(@apvm_fax,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end


---- email
if isnull(@pmfm_email,'') <> isnull(@email,'')
	begin
	if @apvm_email is null
		begin
		select @msg = @msg + 'EMail: ' + isnull(@email,'') + '  EMail: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_email,'') = @apvm_email
			begin
			select @msg = @msg + 'Email: ' + isnull(@email,'') + '  EMail: ' + isnull(@apvm_email,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- url
if isnull(@pmfm_url,'') <> isnull(@url,'')
	begin
	if @apvm_url is null
		begin
		select @msg = @msg + 'URL: ' + isnull(@url,'') + '  URL: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_url,'') = @apvm_url
			begin
			select @msg = @msg + 'URL: ' + isnull(@url,'') + '  URL: ' + isnull(@apvm_url,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- mail address
if isnull(@pmfm_mailaddress,'') <> isnull(@mailaddress,'')
	begin
	if @apvm_address is null
		begin
		select @msg = @msg + 'MailAddress: ' + isnull(@mailaddress,'') + '  Address: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_mailaddress,'') = @apvm_address
			begin
			select @msg = @msg + 'MailAddress: ' + isnull(@mailaddress,'') + '  Address: ' + isnull(@apvm_address,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- mail address 2
if isnull(@pmfm_mailaddress2,'') <> isnull(@mailaddress2,'')
	begin
	if @apvm_address2 is null
		begin
		select @msg = @msg + 'MailAddress2: ' + isnull(@mailaddress2,'') + '  Address2: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_mailaddress2,'') = @apvm_address2
			begin
			select @msg = @msg + 'MailAddress2: ' + isnull(@mailaddress2,'') + '  Address2: ' + isnull(@apvm_address2,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- mail city
if isnull(@pmfm_mailcity,'') <> isnull(@mailcity,'')
	begin
	if @apvm_city is null
		begin
		select @msg = @msg + 'MailCity: ' + isnull(@mailcity,'') + '  City: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_mailcity,'') = @apvm_city
			begin
			select @msg = @msg + 'MailCity: ' + isnull(@mailcity,'') + '  City: ' + isnull(@apvm_city,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- mail state
if isnull(@pmfm_mailstate,'') <> isnull(@mailstate,'')
	begin
	if @apvm_state is null
		begin
		select @msg = @msg + 'MailState: ' + isnull(@mailstate,'') + '  State: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_mailstate,'') = @apvm_state
			begin
			select @msg = @msg + 'MailState: ' + isnull(@mailstate,'') + '  State: ' + isnull(@apvm_state,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- mail zip
if isnull(@pmfm_mailzip,'') <> isnull(@mailzip,'')
	begin
	if @apvm_zip is null
		begin
		select @msg = @msg + 'MailZip: ' + isnull(@mailzip,'') + '  Zip: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_mailzip,'') = @apvm_zip
			begin
			select @msg = @msg + 'MailZip: ' + isnull(@mailzip,'') + '  Zip: ' + isnull(@apvm_zip,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- ship address
if isnull(@pmfm_shipaddress,'') <> isnull(@shipaddress,'')
	begin
	if @apvm_poaddress is null
		begin
		select @msg = @msg + 'ShipAddress: ' + isnull(@shipaddress,'') + '  POAddress: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_shipaddress,'') = @apvm_poaddress
			begin
			select @msg = @msg + 'ShipAddress: ' + isnull(@shipaddress,'') + '  POAddress: ' + isnull(@apvm_poaddress,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- ship address 2
if isnull(@pmfm_shipaddress2,'') <> isnull(@shipaddress2,'')
	begin
	if @apvm_poaddress2 is null
		begin
		select @msg = @msg + 'ShipAddress2: ' + isnull(@shipaddress2,'') + '  POAddress2: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_shipaddress2,'') = @apvm_poaddress2
			begin
			select @msg = @msg + 'ShipAddress2: ' + isnull(@shipaddress2,'') + '  POAddress2: ' + isnull(@apvm_poaddress2,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- ship city
if isnull(@pmfm_shipcity,'') <> isnull(@shipcity,'')
	begin
	if @apvm_pocity is null
		begin
		select @msg = @msg + 'ShipCity: ' + isnull(@shipcity,'') + '  POCity: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_shipcity,'') = @apvm_pocity
			begin
			select @msg = @msg + 'ShipCity: ' + isnull(@shipcity,'') + '  POCity: ' + isnull(@apvm_pocity,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- ship state
if isnull(@pmfm_shipstate,'') <> isnull(@shipstate,'')
	begin
	if @apvm_postate is null
		begin
		select @msg = @msg + 'ShipState: ' + isnull(@shipstate,'') + '  POState: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_shipstate,'') = @apvm_postate
			begin
			select @msg = @msg + 'ShipState: ' + isnull(@shipstate,'') + '  POState: ' + isnull(@apvm_postate,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- ship zip
if isnull(@pmfm_shipzip,'') <> isnull(@shipzip,'')
	begin
	if @apvm_pozip is null
		begin
		select @msg = @msg + 'ShipZip: ' + isnull(@shipzip,'') + '  POZip: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_shipzip,'') = @apvm_pozip
			begin
			select @msg = @msg + 'ShipZip: ' + isnull(@shipzip,'') + '  POZip: ' + isnull(@apvm_pozip,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- mail country
if isnull(@pmfm_mailcountry,'') <> isnull(@mailcountry,'')
	begin
	if @apvm_country is null
		begin
		select @msg = @msg + 'MailCountry: ' + isnull(@mailcountry,'') + '  Country: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_mailcountry,'') = @apvm_country
			begin
			select @msg = @msg + 'MailCountry: ' + isnull(@mailcountry,'') + '  Country: ' + isnull(@apvm_country,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end

---- ship country
if isnull(@pmfm_shipcountry,'') <> isnull(@shipcountry,'')
	begin
	if @apvm_pocountry is null
		begin
		select @msg = @msg + 'ShipCountry: ' + isnull(@shipcountry,'') + '  POCountry: [Empty]' + @chrlf
		select @rcode = 1, @update = 'Y'
		end
	else
		if isnull(@pmfm_shipcountry,'') = @apvm_pocountry
			begin
			select @msg = @msg + 'ShipCountry: ' + isnull(@shipcountry,'') + '  POCountry: ' + isnull(@apvm_pocountry,'') + @chrlf
			select @rcode = 1, @update = 'Y'
			end
	end




bspexit:
  	if @rcode <> 0 
		begin
		select @msg = isnull(@msg,'')
		end
	else
		begin
		select @msg = ''
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMAPUpdateCheck] TO [public]
GO
