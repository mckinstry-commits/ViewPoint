SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPMPreferredMethodContactVal    Script Date: 01/14/2008 ******/
CREATE   proc [dbo].[vspPMPreferredMethodContactVal]
/*************************************
 *
 * Created By:	SCOTTP 04/30/2012
 * Modified by:
 *
 * Validates whether selected Preferred Method of Send is valid for the Contact.
 *
 * Example: if Email is selected and Contact does not have an email address,
 * it would not be valid preferred method of send
 *
 * Input:
 * VendorGroup, Firm, Contact Code, Preferred Method
 * 
 * Output:
 * Success - 0 
 * Failure - 1 and Error Message
 *
 **************************************/
(@vendorGroup tinyint, @firmNumber int, @contactCode int, @preferredMethod char(1), @errmsg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0
select @errmsg = ''

if (dbo.vfToString(@vendorGroup) = '') 
begin
  select @errmsg = 'No Vendor Group Supplied', @rcode = 3
  goto vspexit
end

if (dbo.vfToString(@firmNumber) = '') 
begin
  select @errmsg = 'No Firm Number Supplied', @rcode = 3
  goto vspexit
end

if (dbo.vfToString(@contactCode) = '') 
begin
  select @errmsg = 'No Contact Code Supplied', @rcode = 3
  goto vspexit
end

if (@preferredMethod = '') 
begin
  select @errmsg = 'No Preferred Method Supplied', @rcode = 3
  goto vspexit
end

-- check for Print
if @preferredMethod = 'M'
begin
	-- Print is always valid
	goto vspexit
end

declare @email varchar(60)
declare @fax varchar(20)

select @email = EMail, @fax = Fax from PMPM
where VendorGroup = dbo.vfToString(@vendorGroup)
	and FirmNumber = dbo.vfToString(@firmNumber)
	and ContactCode = dbo.vfToString(@contactCode)
		
-- check for Email
if @preferredMethod = 'E'
begin
	if @email is null or LTRIM(RTRIM(@email)) = ''
	begin
		select @errmsg = 'Invalid Option: No email is setup for this contact'
		select @rcode = 1
	end
	goto vspexit
end

-- check for Fax
if @preferredMethod = 'F'
begin
	if @fax is null or LTRIM(RTRIM(@fax)) = ''
	begin
		select @errmsg = 'Invalid Option: No fax number is setup for this contact'
		select @rcode = 1
	end	
	goto vspexit
end

-- invalid preferred method
select @errmsg = 'Invalid Preferred Method of Send'
select @rcode = 2

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPreferredMethodContactVal] TO [public]
GO
