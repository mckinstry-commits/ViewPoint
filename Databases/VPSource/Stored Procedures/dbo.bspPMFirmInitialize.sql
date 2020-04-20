SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMFirmInitialize    Script Date: 8/28/99 9:35:11 AM ******/
CREATE procedure [dbo].[bspPMFirmInitialize]
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
(@vendorgroup bGroup, @beginvendor bVendor, @endvendor bVendor, @firmtype bFirmType,
 @msg varchar(255) output)
as
set nocount on
   
declare @rcode int

select @rcode=0, @msg='Valid'

if isnull(@firmtype,'') = '' set @firmtype = null

insert into PMFM(VendorGroup, FirmNumber, FirmName, FirmType, Vendor, SortName, ContactName,
                   MailAddress, MailCity, MailState, MailZip, MailAddress2, ShipAddress, ShipCity,
                   ShipState, ShipZip, ShipAddress2, Phone, Fax, EMail, URL, MailCountry, ShipCountry)
select VendorGroup, Vendor, Name, @firmtype, Vendor, SortName, Contact,
               Address, City, State, Zip, Address2, POAddress, POCity, POState, POZip, POAddress2,
               Phone, Fax, EMail, URL, Country, POCountry
from APVM v with (nolock)
where VendorGroup=@vendorgroup and Vendor >=@beginvendor and Vendor <= @endvendor
and not exists (select top 1 1 from PMFM f with (nolock) where f.VendorGroup=v.VendorGroup
			and (f.FirmNumber=v.Vendor or f.SortName=v.SortName))



select @msg = 'Number of firms initialized: ' + isnull(convert(varchar(8),@@rowcount),'') + ' !', @rcode=0



bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmInitialize] TO [public]
GO
