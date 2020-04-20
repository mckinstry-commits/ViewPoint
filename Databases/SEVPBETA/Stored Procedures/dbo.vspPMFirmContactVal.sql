SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMFirmContactVal    Script Date: 40/29/2005 ******/
CREATE   proc [dbo].[vspPMFirmContactVal]
/*************************************
 * Created By:	GF 04/30/2005 
 * Modified By:
 *
 * validates PM Firm contact
 *
 * Pass:
 * VendorGroup
 * Firm			Firm to validate contact in
 * ContactSort  Contact or contact sort name to validate
 *
 * Returns:
 *       ContactOut   the contact number validated
 * Success returns:
 *      ContactNumber and Contact Name
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@vendorgroup bGroup, @firm bFirm, @contactsort bSortName,
 @contactout bEmployee=null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0

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
		where VendorGroup = @vendorgroup and FirmNumber = @firm and ContactCode = convert(int,convert(float, @contactsort))
  		end
	end

-- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @contactout=ContactCode, @msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
	from PMPM with (nolock) 
	where VendorGroup = @vendorgroup and FirmNumber=@firm and SortName = @contactsort
	-- -- -- if not found,  try to find closest
	if @@rowcount = 0
		begin
		set rowcount 1
		select @contactout=ContactCode, @msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
  		from PMPM with (nolock) 
  		where VendorGroup = @vendorgroup and FirmNumber=@firm and SortName like @contactsort + '%'
  		if @@rowcount = 0
			begin
			select @msg = 'PM Contact ' + convert(varchar(15),isnull(@contactsort,'')) + ' not on file!', @rcode = 1
			goto bspexit
			end
		end
	end





bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMFirmContactVal] TO [public]
GO
