SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspPMFirmContactbyFirmVal] /** User Defined Validation Procedure **/
(@PMCo bCompany, @FirmNumber varchar(100), @Contact bEmployee, @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * 
	from [PMPM] with (nolock)
		INNER JOIN PMFM WITH (NOLOCK) ON dbo.PMPM.VendorGroup = dbo.PMFM.VendorGroup AND dbo.PMPM.FirmNumber = dbo.PMFM.FirmNumber 
		INNER JOIN HQCO WITH (NOLOCK) ON dbo.HQCO.VendorGroup = dbo.PMFM.VendorGroup
	WHERE HQCo = @PMCo AND @FirmNumber = PMFM.[FirmNumber] AND @Contact = PMPM.ContactCode)
	begin
		select @msg = isnull(ISNULL(PMPM.FirstName,'') +' '+ ISNULL(PMPM.LastName,''),@msg) 
			from [PMPM] with (nolock)
				INNER JOIN PMFM WITH (NOLOCK) ON dbo.PMPM.VendorGroup = dbo.PMFM.VendorGroup AND dbo.PMPM.FirmNumber = dbo.PMFM.FirmNumber 
				INNER JOIN HQCO WITH (NOLOCK) ON dbo.HQCO.VendorGroup = dbo.PMFM.VendorGroup 
			where HQCO.HQCo = @PMCo AND @FirmNumber = PMFM.[FirmNumber] AND @Contact = PMPM.ContactCode
	end
	else
	begin
		select @msg = 'Not a valid PM Firm', @rcode = 1
	goto spexit
	end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMFirmContactbyFirmVal] TO [public]
GO
