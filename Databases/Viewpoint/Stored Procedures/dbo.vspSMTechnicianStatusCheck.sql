SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 9/21/11
-- Modified:  
-- Description:	Check the status of a technician for a specific Service Site or Customer
--              and return a warning or error if needed.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTechnicianStatusCheck]
	@SMCo bCompany, @CustGroup bGroup, @Customer bCustomer, @ServiceSite varchar(20), @Technician varchar(15), @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Return a value of 0 if no warning exists.
	-- Return a value of 1 and a message in @msg to display a warning message.
	DECLARE @rcode int, @Status char(1), @DoNotUseMsg varchar(50)
	
	SELECT @DoNotUseMsg=SUBSTRING(DisplayValue,3,99) FROM DDCI WHERE ComboType='SMTechnicianPreferen' AND DatabaseValue='D'

	EXEC @rcode = dbo.vspSMTechnicianVal @SMCo = @SMCo, @Technician = @Technician, @msg = @msg OUTPUT
	
	IF (@rcode <> 0)
	BEGIN
		RETURN @rcode
	END

	IF (@ServiceSite IS NOT NULL)
	BEGIN
		-- Check for the status of this technician for this site.
		SELECT @Status=Status FROM SMTechnicianPreferences
		WHERE SMCo = @SMCo 
		AND Technician = @Technician
		AND ServiceSite = @ServiceSite
		IF (@Status='D')
		BEGIN
			SET @msg = 'This technician has been flagged as '+@DoNotUseMsg+' for this site.'
			RETURN 1
		END
	END

	IF (@CustGroup IS NOT NULL AND @Customer IS NOT NULL)
	BEGIN
		-- Check for the status of this technician for this site.
		SELECT @Status=Status FROM SMTechnicianPreferences
		WHERE SMCo = @SMCo 
		AND Technician = @Technician
		AND CustGroup = @CustGroup
		AND Customer = @Customer
		IF (@Status='D')
		BEGIN
			SET @msg = 'This technician has been flagged as '+@DoNotUseMsg+' for this customer.'
			RETURN 1
		END
	END
	RETURN 0
END





GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianStatusCheck] TO [public]
GO
