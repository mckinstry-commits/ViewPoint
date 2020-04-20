SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPFContactVal    Script Date: 12/14/2005 ******/
CREATE  proc [dbo].[vspPMPFContactVal]
/*************************************
 * Created By:	GF 12/14/2005 
 * Modified By:
 *
 * validates PM Firm contact and checks for existance in
 * in PM Project Firms. Used in PMProjectFirms form.
 *
 * Pass:
 * VendorGroup
 * Firm			Firm to validate contact in
 * ContactSort  Contact or contact sort name to validate
 * PMCo			PM Company
 * Project		PM Project
 *
 * Returns:
 * ContactOut   the contact number validated
 * Exists_PMPF	firm contact exists in PMPF for project
 *
 * Success returns:
 * ContactNumber and Contact Name
 *
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany = 0, @vendorgroup bGroup, @firm bFirm, @contactsort bSortName, @project bJob = null,
 @contactout bEmployee=null output, @exists_pmpf bYN = 'N' output, @phone bPhone = null output,
 @title bDesc = null output, @email bItemDesc = null output, @fax bPhone = null output,
 @excludeyn bYN = 'N' output, @mobile bPhone = null output, @allowportalaccess bYN = 'N' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @exists_pmpf = 'N'

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

---- if contact is not numeric then assume a SortName
if dbo.bfIsInteger(@contactsort) = 1
	begin
  	if len(@contactsort) < 7
  		begin
  		-- validate firm to make sure it is valid to use
  		select @contactout = ContactCode, @msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,''),
				@phone=Phone, @fax=Fax, @title=Title, @email=EMail, @excludeyn=ExcludeYN,
				@mobile=MobilePhone, @allowportalaccess=AllowPortalAccess
  		from PMPM with (nolock) 
		where VendorGroup = @vendorgroup and FirmNumber = @firm and ContactCode = convert(int,convert(float, @contactsort))
  		end
	end

---- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @contactout=ContactCode, @msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,''),
			@phone=Phone, @fax=Fax, @title=Title, @email=EMail, @excludeyn=ExcludeYN,
			@mobile=MobilePhone, @allowportalaccess=AllowPortalAccess
	from PMPM with (nolock) 
	where VendorGroup = @vendorgroup and FirmNumber=@firm and SortName = @contactsort
	---- if not found,  try to find closest
	if @@rowcount = 0
		begin
		set rowcount 1
		select @contactout=ContactCode, @msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,''),
				@phone=Phone, @fax=Fax, @title=Title, @email=EMail, @excludeyn=ExcludeYN,
				@mobile=MobilePhone, @allowportalaccess=AllowPortalAccess
  		from PMPM with (nolock) 
  		where VendorGroup = @vendorgroup and FirmNumber=@firm and SortName like @contactsort + '%'
  		if @@rowcount = 0
			begin
			select @msg = 'PM Contact ' + convert(varchar(15),isnull(@contactsort,'')) + ' not on file!', @rcode = 1
			goto bspexit
			end
		end
	end

---- call vspPMFirmContactVal SP to validate firm and contact
---- exec @rcode = dbo.vspPMFirmContactVal @vendorgroup, @firm, @contactsort, @contactout output, @msg output
---- if @rcode = 0
----   	begin
	-- -- -- check PMPF project firms to see if contact already exists
	if isnull(@project,'') <> ''
		begin
		if exists(select top 1 1 from PMPF where PMCo=@pmco and Project=@project
				and VendorGroup=@vendorgroup and FirmNumber=@firm and ContactCode=@contactout)
			begin
			select @exists_pmpf = 'Y'
			----select @msg = 'Firm and Contact already exists in Project Firms for this project.', @rcode = 1
			goto bspexit
			end
		else
			begin
			select @exists_pmpf = 'N'
			end
		end
------	end






bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPFContactVal] TO [public]
GO
