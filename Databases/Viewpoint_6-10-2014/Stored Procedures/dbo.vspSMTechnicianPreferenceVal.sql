SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/11/11
-- Modified:  
-- Description:	SM Technician Preference validation on the Technician field. Validates that the 
--			technician is the primary technician.
--			Wraps the SMTechnicianVal.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTechnicianPreferenceVal]
	@SMCo bCompany, @CustomerGroup bGroup, @Customer bCustomer, @ServiceSite varchar(20), @Technician varchar(15), @msg varchar(255) OUTPUT
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
	
	IF (EXISTS(
		SELECT 1 FROM dbo.SMCustomer WHERE SMCo = @SMCo AND CustGroup = @CustomerGroup AND Customer = @Customer AND PrimaryTechnician = @Technician
		UNION
		SELECT 1 FROM dbo.SMServiceSite WHERE SMCo = @SMCo AND ServiceSite = @ServiceSite AND PrimaryTechnician = @Technician)
		)
	BEGIN
		SET @msg = 'This techncian is already as set as the Primary Technician.  Please unassign it as the primary technician before adding it here.'
		RETURN 1
	END 
		
	RETURN 0
END





GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianPreferenceVal] TO [public]
GO
