SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/11/11
-- Modified:	8/15/11 LDG - Added default NULLs to parameters
-- Description:	Primary technician validation.  Validates that the 
--			primary technician is not in the preferred technician list.
--			Wraps the SMTechnicianVal.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMPrimaryTechnicianVal]
	@SMCo bCompany, @CustomerGroup bGroup = NULL, @Customer bCustomer = NULL, @ServiceSite varchar(20) = NULL, @Technician varchar(15), @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int

	EXEC @rcode = dbo.vspSMTechnicianVal @SMCo = @SMCo, @Technician = @Technician, @msg = @msg OUTPUT
	
	IF (@rcode <> 0)
	BEGIN
		RETURN @rcode
	END

	IF ((@CustomerGroup IS NULL OR @Customer IS NULL) AND @ServiceSite IS NULL)
	BEGIN
		SET @msg = 'Invalid Customer Group/Customer or Service Site.'
		RETURN 1
	END
	
	IF (EXISTS(SELECT 1 FROM dbo.SMTechnicianPreferences WHERE SMCo = @SMCo AND ((CustGroup = @CustomerGroup AND Customer = @Customer) OR ServiceSite = @ServiceSite) AND Technician = @Technician))
	BEGIN
		SET @msg = 'This techncian is already set in SM Technician Preferences.  Please remove it from there before setting it as the primary technician.'
		RETURN 1
	END 
		
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMPrimaryTechnicianVal] TO [public]
GO
