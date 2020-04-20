SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPMVal    Script Date: 04/12/2005 ******/
CREATE proc [dbo].[vspPMPMVal]
/*************************************
 * Created By:	GF 04/12/2005
 * Modified By:
 *
 *
 * validates PM Firm Contact, used in PMFirmContacts to return contact name
 *
 *
 * Pass:
 * VendorGroup	AP Vendor Group
 * Firm			PM Firm
 * ContactSort  Contact or contact sort name to validate
 *
 * Returns:
 * ContactOut   the contact number validated
 * Success returns:
 * ContactNumber and Contact Name
 *
 * Error returns:
 *  
 *	1 and error message
  **************************************/
(@vendorgroup bGroup, @firm bFirm, @contactsort bSortName,
 @contactout bEmployee=null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if @firm is null
  	begin
  	select @msg = 'Missing Firm!', @rcode = 1
  	goto bspexit
  	end

if @contactsort is null
  	begin
  	select @msg = 'Missing Contact!', @rcode = 1
  	goto bspexit
  	end

-- if contact is not numeric then assume a SortName
if dbo.bfIsInteger(@contactsort) = 1
	begin
  	if len(@contactsort) < 7
  		begin
  		-- validate firm to make sure it is valid to use
  		select @contactout = ContactCode, @msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
  		from PMPM with (nolock) 
		where VendorGroup = @vendorgroup and FirmNumber = @firm
		and ContactCode = convert(int,convert(float, @contactsort))
		if @@rowcount = 0 select @contactout = @contactsort
		goto bspexit
  		end
-- -- --   	else
-- -- --   		begin
-- -- --   		select @msg = 'Invalid contact code, length must be 6 digits or less.', @rcode = 1
-- -- --   		goto bspexit
-- -- --   		end
  	end


-- -- -- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @contactout=ContactCode, @msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
	from PMPM with (nolock) 
	where VendorGroup = @vendorgroup and FirmNumber = @firm and SortName = @contactsort
	-- -- -- if not found,  try to find closest
	if @@rowcount = 0
		begin
		set rowcount 1
		select @contactout=ContactCode, @msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
		from PMPM with (nolock) 
  		where VendorGroup = @vendorgroup and FirmNumber = @firm and SortName like @contactsort + '%'
		end
	end




bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPMVal] TO [public]
GO
