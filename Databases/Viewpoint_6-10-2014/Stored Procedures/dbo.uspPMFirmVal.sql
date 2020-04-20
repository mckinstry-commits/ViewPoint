SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspPMFirmVal] /** User Defined Validation Procedure **/
(@PMCo bCompany, @FirmNumber varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
	if exists(select 1 
	from [PMFM] with (nolock) 
		INNER JOIN HQCO ON dbo.HQCO.VendorGroup = dbo.PMFM.VendorGroup
	WHERE @PMCo = HQCO.HQCo AND @FirmNumber = [FirmNumber] )
	begin
		select @msg = isnull([FirmName],@msg) 
			from [PMFM] with (nolock) 
				INNER JOIN HQCO ON dbo.HQCO.VendorGroup = dbo.PMFM.VendorGroup
			WHERE @PMCo = HQCO.HQCo AND @FirmNumber = [FirmNumber] 
	end
	else
	begin
		select @msg = 'Not a valid PM Firm', @rcode = 1
		goto spexit
	end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMFirmVal] TO [public]
GO
