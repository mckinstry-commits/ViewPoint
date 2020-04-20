SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMFirmAndContactBuilder]
/*************************************
 * Created By:	GP 03/04/2011
 * Modified By:
 * Code Review:	JG 03/04/2011
 *
 * Validates PM Firm Contact, used to return contact name and firm.
 *
 * Pass:
 * VendorGroup	AP Vendor Group
 * Firm			PM Firm
 * Contact		Contact
 *
 * Returns:
 * Contact and firm string
 *
 * Error returns:
 *	1 and error message
  **************************************/
(@VendorGroup bGroup, @Firm bFirm, @Contact bEmployee, @ContactAndFirm varchar(125) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0, @msg = ''



--VALIDATION--
if @VendorGroup is null
begin
  	select @msg = 'Missing VendorGroup.', @rcode = 1
  	goto vspexit
end

if @Firm is null
begin
  	select @msg = 'Missing Firm.', @rcode = 1
  	goto vspexit
end

if @Contact is null
begin
  	select @msg = 'Missing Contact.', @rcode = 1
  	goto vspexit
end

--BUILD STRING--
select @ContactAndFirm = isnull(PMPM.FirstName,'') + ' ' + isnull(PMPM.LastName,'') + ' - ' + isnull(PMFM.FirmName,'')
from dbo.PMPM
join dbo.PMFM on PMFM.VendorGroup = PMPM.VendorGroup and PMFM.FirmNumber = PMPM.FirmNumber
where PMPM.VendorGroup = @VendorGroup and PMPM.FirmNumber = @Firm and PMPM.ContactCode = @Contact



vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMFirmAndContactBuilder] TO [public]
GO
