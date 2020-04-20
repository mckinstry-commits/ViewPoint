SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE procedure [dbo].[vspPMProjectFirmsGet]
/********************************************************
 * Created By:	GF 06/06/2005    
 * Modified By:    
 *
 * Purpose of Stored Procedure
 * Get Project Firms for copying called from PMProjectFirmsCopy form.
 *    
 *           
 * Notes about Stored Procedure
 * 
 *
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 ********************************************************/
(@pmco bCompany, @project bProject, @dest_project bProject, @vendorgroup bGroup, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if @pmco is null
  	begin
  	select @msg = 'Missing PM Company!', @rcode = 1
  	goto bspexit
  	end

if @project is null
  	begin
  	select @msg = 'Missing Project!', @rcode = 1
  	goto bspexit
  	end

if @vendorgroup is null
  	begin
  	select @msg = 'Missing Vendor Group!', @rcode = 1
  	goto bspexit
  	end


-- -- -- get firm information
Select a.FirmNumber as [Firm], PMFM.FirmName as [Firm Name], a.ContactCode as [Contact], 
		isnull(PMPM.FirstName,'') + ' ' + isnull(PMPM.MiddleInit,'') + ' ' + isnull(PMPM.LastName,'') as [Contact Name],
		a.Description as [Description]
from PMPF a with (nolock)
left join PMFM with (nolock) on PMFM.VendorGroup=a.VendorGroup and PMFM.FirmNumber=a.FirmNumber
left join PMPM with (nolock) on PMPM.VendorGroup=a.VendorGroup and PMPM.FirmNumber=a.FirmNumber and PMPM.ContactCode=a.ContactCode
where a.PMCo= @pmco and a.Project=@project AND a.VendorGroup=@vendorgroup
and not exists(select * from PMPF p with (nolock) where p.PMCo=@pmco and p.Project=@dest_project
			and p.VendorGroup=a.VendorGroup and p.FirmNumber=a.FirmNumber and p.ContactCode=a.ContactCode)
order by a.PMCo, a.Project, a.FirmNumber, a.ContactCode



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMProjectFirmsGet] TO [public]
GO
