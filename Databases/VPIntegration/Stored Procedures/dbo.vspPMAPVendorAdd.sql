SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************/
CREATE proc [dbo].[vspPMAPVendorAdd]
/****************************************
 * Created By:	GF 06/01/2005
 * Modified By: GF 03/12/2008 - issue #127076 added mail, ship country
 *				GF 01/03/2010 - issue #142658 tax group
 *				GP 07/13/2011 - issue #144023 & TK-05528 check for 1099 Type of MISC before insert
 *
 * Called from PMFirmMaster after rec update or add to add vendor to APVM if a new vendor and
 * APCO.PMVendAddYN flag is 'Y'.
 *
 *
 * Pass:
 * APCo				AP Company
 * VendorGroup		PM-AP VendorGroup
 * Vendor			AP Vendor
 * Name			
 * SortName
 * Contact
 * Phone
 * Fax
 * EMail
 * URL
 * MailAddress, MailAddress2, MailCity, MailState, MailZip
 * ShipAddress, ShipAddress2, ShipCity, ShipState, ShipZip
 * MailCountry, ShipCountry
 *
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *
 **************************************/
(@apco bCompany, @vendorgroup bGroup, @vendor bVendor, @name varchar(60), @sortname bSortName,
 @contact varchar(30), @phone bPhone, @fax bPhone, @email varchar(30), @url varchar(60),
 @mailaddress varchar(60), @mailaddress2 varchar(60), @mailcity varchar(30), @mailstate varchar(4),
 @mailzip bZip, @shipaddress varchar(60), @shipaddress2 varchar(60), @shipcity varchar(30),
 @shipstate varchar(4), @shipzip bZip, @mailcountry varchar(2), @shipcountry varchar(2),
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @glco bCompany, @vendor_note varchar(500), @currdate varchar(25),
		@TaxGroup bGroup, @1099Type varchar(10)

select @rcode = 0, @currdate = convert(varchar(25),Getdate())

select @vendor_note = 'Vendor added from PM Firm Master on ' + @currdate + ' by ' + SUSER_SNAME() + '.'

if @vendorgroup is null
	begin
	select @msg = 'Missing Vendor Group', @rcode = 1
	goto bspexit
	end

if @vendor is null
	begin
	select @msg = 'Missing Vendor', @rcode = 1
	goto bspexit
	end

-- -- -- get AP GLCO
select @glco=GLCo from bAPCO with (nolock) where APCo=@apco
if @@rowcount = 0
	begin
	select @msg = 'Invalid AP Company.', @rcode = 1
	goto bspexit
	END
	
---- get tax group for AP Company - #142658
select @TaxGroup = TaxGroup from bHQCO where HQCo = @apco

---- make sure 1099 type MISC exists, otherwise get the first type
if exists (select top 1 1 from dbo.APTT where V1099Type = 'MISC')
begin
	set @1099Type = 'MISC'
end
else
begin
	select top 1 @1099Type = V1099Type from dbo.APTT
end	

-- -- -- insert APVM Vendor
insert into APVM (VendorGroup,Vendor,GLCo,Type,TempYN,Purge,V1099YN,V1099Type,V1099Box,ActiveYN,EFT,
		AuditYN,SeparatePayInvYN,OverrideMinAmtYN,APRefUnqOvr,Notes,Name,SortName,Contact,Address,
		City,State,Zip,Address2,Phone,Fax,EMail,URL,POAddress,POCity,POState,POZip,POAddress2,
		----#142658
		Country, POCountry, TaxGroup)
select @vendorgroup, @vendor, @glco, 'R', 'N', 'N', 'Y', @1099Type, 7, 'Y', 'N', 'N', 'N', 'N', 0,
		@vendor_note, @name, @sortname, @contact, @mailaddress, @mailcity, @mailstate, @mailzip,
		@mailaddress2, @phone, @fax, @email, @url, @shipaddress, @shipcity, @shipstate, @shipzip,
		----#142658
		@shipaddress2, @mailcountry, @shipcountry, @TaxGroup
if @@rowcount <> 1
	begin
	select @msg = 'Error has occurred adding vendor to APVM.', @rcode = 1
	goto bspexit
	end






bspexit:
  	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMAPVendorAdd] TO [public]
GO
