SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMFirmInitialize    Script Date: 8/28/99 9:35:11 AM ******/
CREATE procedure [dbo].[mckspPMFirmInitialize]
/*******************************************************************
* Created By:
* Modified By:	GF 07/19/2000
*				GF 03/12/2008 - issue #127076 mail and ship country
*
*
* Used to initialize PM Firms from APVM
*
* Pass in VendorGroup, Beginning and Ending Vendor number
*
* Sets up Firms with info from APVM  The Firm will get the same nuber
* as the Vendor. If the firm number(or sort name) already exists in PMFM then it will skip
* that vendor.
*
* Returns 0 and message if successful
* Returns 1 and error message if error
********************************************************************/
(@vendorgroup bGroup, @vendor bVendor, @firmtype bFirmType, @rcode int,
 @ReturnMessage varchar(255) output)
as
set nocount on
   


select @rcode=0, @ReturnMessage='Valid'

if isnull(@firmtype,'') = '' set @firmtype = null

IF NOT EXISTS(SELECT * FROM PMFM f WHERE @vendor = f.Vendor AND @vendorgroup = f.VendorGroup)--check for existing firm
BEGIN
	IF NOT EXISTS(SELECT 1 FROM APVM WHERE @vendorgroup = VendorGroup AND @vendor = Vendor AND udEmployeeYN = 'Y')--check for Employee on Vendor
	BEGIN
		insert into PMFM(VendorGroup, FirmNumber, FirmName, FirmType, Vendor, SortName, ContactName,
						   MailAddress, MailCity, MailState, MailZip, MailAddress2, ShipAddress, ShipCity,
						   ShipState, ShipZip, ShipAddress2, Phone, Fax, EMail, URL, MailCountry, ShipCountry)
		select VendorGroup, Vendor, Name, @firmtype, Vendor, SortName, Contact,
					   Address, City, State, Zip, Address2, POAddress, POCity, POState, POZip, POAddress2,
					   Phone, Fax, EMail, URL, Country, POCountry
		from APVM v with (nolock)
		where VendorGroup=@vendorgroup and Vendor =@vendor 
		and not exists (select top 1 1 from PMFM f with (nolock) where f.VendorGroup=v.VendorGroup
					and (f.FirmNumber=v.Vendor or f.SortName=v.SortName))

		select @ReturnMessage = 'Firm initialized: ' + isnull(convert(varchar(8),@vendor),'') + ' !', @rcode=0
		goto bspexit
	END
	ELSE
	BEGIN
		SELECT @ReturnMessage = 'Cannot initialize Vendor/Employee as Firm.', @rcode=1
		GOTO bspexit
	END
END
ELSE
BEGIN
	SELECT @ReturnMessage = 'Firm already exists', @rcode = 1
END


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[mckspPMFirmInitialize] TO [public]
GO
