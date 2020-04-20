SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPMValForDist    Script Date: 04/12/2005 ******/
CREATE  proc [dbo].[vspPMPMValForDist]
/*************************************
 * Created By:	GF 06/14/2005
 * Modified By:	GP 09/15/2009 - 133966 added @EmailOption and select statement
 *
 *
 * validates PM Firm Contact, used in various PM forms to validate, check if exists in
 * PM Project Firms and returns some information.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * VendorGroup	AP Vendor Group
 * Firm			PM Firm
 * ContactSort  Contact or contact sort name to validate
 *
 * Returns:
 * ContactOut	Validated contact number
 * PrefMethod	Contact preferred method of contact
 * Email		Contact email address
 * Fax			Contact fax number
 * Exists		Flag to signify if firm/contact exists for project in PMPF
 *
 * Success returns:
 * ContactNumber and Contact Name
 *
 * Error returns:
 *  
 *	1 and error message
  **************************************/
(@pmco bCompany, @project bJob, @vendorgroup bGroup, @firm bFirm, @contactsort bSortName,
 @contactout bEmployee=null output, @prefmethod varchar(1) output, @email varchar(60) output, 
 @fax varchar(20) output, @exists bYN output, @EmailOption char(1) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @exists = 'N'

if @pmco is null
  	begin
  	select @msg = 'Missing PM Company!', @rcode = 1
  	goto bspexit
  	end

if @project is null
  	begin
  	select @msg = 'Missing PM Project!', @rcode = 1
  	goto bspexit
  	end

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
  		select @contactout = ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax,
				@msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
  		from PMPM with (nolock) 
		where VendorGroup = @vendorgroup and FirmNumber = @firm and ContactCode = convert(int,convert(float, @contactsort))
  		end
  	end

-- -- -- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @contactout=ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax,
			@msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
	from PMPM with (nolock) 
	where VendorGroup = @vendorgroup and FirmNumber = @firm and SortName = @contactsort
	-- -- -- if not found,  try to find closest
	if @@rowcount = 0
		begin
		set rowcount 1
		select @contactout=ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax,
				@msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
		from PMPM with (nolock) 
  		where VendorGroup = @vendorgroup and FirmNumber = @firm and SortName like @contactsort + '%'
		if @@rowcount = 0
			begin
			select @msg = 'Firm Contact ' + convert(varchar(15),isnull(@contactsort,'')) + ' not on file!', @rcode = 1
			goto bspexit
			end
		end
	end

-- -- check PMPF to see if firm/contact exists for project
select @EmailOption = EmailOption from dbo.PMPF with (nolock) where PMCo=@pmco and Project=@project
	and VendorGroup=@vendorgroup and FirmNumber=@firm and ContactCode=@contactout
if @@rowcount > 0
begin
	select @exists = 'Y'
end	




bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPMValForDist] TO [public]
GO
