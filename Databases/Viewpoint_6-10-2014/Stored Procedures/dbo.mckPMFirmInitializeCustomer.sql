SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[mckPMFirmInitializeCustomer]
/*******************************************************************
* Created By:  TRL 03/26/09 Issue 132109
* Modified By: Eric Shafer
*
* Used to initialize PM Firms from ARCM
*
* Pass in CustomerGroup, Beginning and Ending Vendor number
*
* Sets up Customers with info from ARCM  The Firm will get the same nuber
* as the Customer. If the firm number(or sort name) already exists in PMFM then it will skip
* that Customer.
*
* Returns 0 and message if successful
* Returns 1 and error message if error
********************************************************************/
(@vendorgroup bGroup,@custgroup bGroup, @customer bCustomer, 
@firmtype bFirmType, @copybilladdrtoshipaddr bYN, @rcode INT, @ReturnMessage varchar(255) output)

as
set nocount on
   
--declare @rcode int

select @rcode=0, @ReturnMessage='Valid'

if isnull(@firmtype,'') = '' 
begin
	set @firmtype = null
end

IF @copybilladdrtoshipaddr = 'Y'
	BEGIN
		Insert Into PMFM(VendorGroup, FirmNumber, FirmName, FirmType, Vendor, SortName, ContactName,
		MailAddress, MailCity, MailState, MailZip, MailAddress2,ShipAddress, ShipCity,ShipState, ShipZip, ShipAddress2, 
		Phone, Fax, EMail, URL, MailCountry, ShipCountry)

		Select @vendorgroup, Customer, Name, @firmtype, null, SortName, Contact,
		Address, City, State, Zip, Address2, BillAddress, BillCity, BillState, BillZip, BillAddress2,
		Phone, Fax, EMail, URL, Country, BillCountry
		from ARCM c with (nolock)
		where CustGroup=@custgroup and Customer = @customer
		and not exists (select top 1 1 from PMFM f with (nolock) where VendorGroup=@vendorgroup and (LTrim(RTrim(f.FirmNumber))=LTrim(RTrim(c.Customer)) or f.SortName=c.SortName))

		select @ReturnMessage = 'Firm Initialized: ' + isnull(convert(varchar(8),@customer),'') + ' !', @rcode=0
	END
ELSE
	BEGIN
		Insert Into PMFM(VendorGroup, FirmNumber, FirmName, FirmType, Vendor, SortName, ContactName,
		MailAddress, MailCity, MailState, MailZip, MailAddress2,Phone, Fax, EMail, URL, MailCountry )

		Select @vendorgroup, Customer, Name, @firmtype, null, SortName, Contact,
		Address, City, State, Zip, Address2, Phone, Fax, EMail, URL, Country
		from ARCM c with (nolock)
		where CustGroup=@custgroup and Customer =@customer
		and not exists (select top 1 1 from PMFM f with (nolock) where VendorGroup=@vendorgroup and (LTrim(RTrim(f.FirmNumber))=LTrim(RTrim(c.Customer)) or f.SortName=c.SortName))

		select @ReturnMessage = 'Firm Initialized: ' + isnull(convert(varchar(8),@customer),'') + ' !', @rcode=0
	END

vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[mckPMFirmInitializeCustomer] TO [public]
GO
