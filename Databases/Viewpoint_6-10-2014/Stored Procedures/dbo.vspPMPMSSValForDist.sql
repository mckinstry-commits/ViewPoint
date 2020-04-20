SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPMValForDist    Script Date: 04/12/2005 ******/
CREATE  proc [dbo].[vspPMPMSSValForDist]
/*************************************
 * Created By:	AW 09/23/2013 TFS - 62011 Only allow one to contact belonging to vendor on SL
 * Modified By:	
 *
 *
 * validates PM Firm Contact, used in various PM forms to validate, check if exists in
 * PM Project Firms and returns some information.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * SLCo			SL Company
 * SL			Subcontact
 * VendorGroup	AP Vendor Group
 * Firm			PM Firm
 * ContactSort  Contact or contact sort name to validate
 *
 * Returns:
 * ContactOut	Validated contact number
 * PrefMethod	Contact preferred method of contact
 * Email		Contact email address
 * Fax			Contact fax number
 * CC			Default CC for contact
 * Exists		Flag to signify if firm/contact exists for project in PMPF
 *
 * Success returns:
 * ContactNumber and Contact Name
 *
 * Error returns:
 *  
 *	1 and error message
  **************************************/
(@pmco bCompany, @project bJob, @slco bCompany, @sl varchar(30), @vendorgroup bGroup, @firm bFirm, @contactsort bSortName,
 @contactout bEmployee=null output, @prefmethod varchar(1) output, @email varchar(60) output, 
 @fax varchar(20) output, @exists bYN output, @EmailOption char(1) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int,@vendor bVendor,@CC char(1)

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

if @slco is null
	begin
	select @msg = 'Missing SL Company!', @rcode = 1
  	goto bspexit
	end

if @sl is null
	begin
	select @msg = 'Missing Subcontract!', @rcode = 1
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


-- -- check PMPF to see if firm/contact exists for project there can be only one TO for PMSS
select @EmailOption=case when s.CC is not null or dbo.vfToString(h.Vendor)<>dbo.vfToString(z.Vendor) then 'C' else 'N' end
from dbo.SLHDPM h 
join dbo.PMFM z with (nolock)  on z.VendorGroup = @vendorgroup AND z.FirmNumber = @firm
left join dbo.PMSS s on s.PMCo=h.PMCo and s.Project=h.Project and s.SLCo=h.SLCo and s.SL=h.SL and s.CC='N'
where h.PMCo=@pmco and h.Project=@project and h.SLCo=@slco and h.SL=@sl

select @EmailOption = COALESCE(@EmailOption,f.EmailOption,'N') 
from dbo.PMPF f with (nolock) 
where f.PMCo = @pmco and f.Project = @project and f.VendorGroup = @vendorgroup AND f.FirmNumber = @firm 
	AND f.ContactCode = dbo.vfToString(@contactout)
if @@rowcount > 0
begin
	select @exists = 'Y'
end	


bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPMSSValForDist] TO [public]
GO
