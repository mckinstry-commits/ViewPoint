SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- ================================================
-- Author:		Chris G
-- Create date: 2/04/2010
-- Description:	
--		Procedure to update user licenses for a single user.
-- Inputs:
--	@userId			Portal User or null for all
--	@licenseType1	Corresponds to License Type 1
--	@licenseType2	Corresponds to License Type 2
--	@licenseType3	Corresponds to License Type 3
--
-- Outputs:
--	@msg				Error message
--
-- Return code:
--	0 = success, 1 = error w/messsge
-- ================================================
CREATE PROCEDURE [dbo].[vspUserLicenseAssignmentsUpdate] 
	(@userId integer, @licenseType1 bit, @licenseType2 bit, @licenseType3 bit, @msg varchar(255) output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- validate inputs variables
	IF @userId is null 
		BEGIN
		SELECT @msg = 'UserID Required'
		RETURN 1
		END
	IF @licenseType1 is null 
		BEGIN
		SELECT @msg = 'HR License Required (0 or 1)'
		RETURN 1
		END
	IF @licenseType2 is null 
		BEGIN
		SELECT @msg = 'PR License Required (0 or 1)'
		RETURN 1
		END
	IF @licenseType3 is null 
		BEGIN
		SELECT @msg = 'PM License Required (0 or 1)'
		RETURN 1
		END

	DECLARE @licenseType1Exists BIT
	DECLARE @licenseType2Exists BIT
	DECLARE @licenseType3Exists BIT
	
	-- Check whether the user already has licenses
	SELECT @licenseType1Exists = 1 FROM pUserLicenseType WHERE UserID = @userId AND LicenseTypeID = 1;
	SELECT @licenseType2Exists = 1 FROM pUserLicenseType WHERE UserID = @userId AND LicenseTypeID = 2;
	SELECT @licenseType3Exists = 1 FROM pUserLicenseType WHERE UserID = @userId AND LicenseTypeID = 3;
	
	-- HR
    IF @licenseType1 = 1 AND @licenseType1Exists IS NULL
		BEGIN
		INSERT INTO pUserLicenseType (UserID, LicenseTypeID) VALUES (@userId, 1);		
		END
	IF @licenseType1 = 0 AND @licenseType1Exists IS NOT NULL
		BEGIN
		DELETE FROM pUserLicenseType WHERE UserID = @userId AND LicenseTypeID = 1;		
		END

	-- PR
	IF @licenseType2 = 1 AND @licenseType2Exists IS NULL
		BEGIN
		INSERT INTO pUserLicenseType (UserID, LicenseTypeID) VALUES (@userId, 2);
		END
	IF @licenseType2 = 0 AND @licenseType2Exists IS NOT NULL
		BEGIN
		DELETE FROM pUserLicenseType WHERE UserID = @userId AND LicenseTypeID = 2;
		END
		
	-- PM
	IF @licenseType3 = 1 AND @licenseType3Exists IS NULL
		BEGIN		
		INSERT INTO pUserLicenseType (UserID, LicenseTypeID) VALUES (@userId, 3 );
		END
	IF @licenseType3 = 0 AND @licenseType3Exists IS NOT NULL
		BEGIN
		DELETE FROM pUserLicenseType WHERE UserID = @userId AND LicenseTypeID = 3;
		END
END

GO
GRANT EXECUTE ON  [dbo].[vspUserLicenseAssignmentsUpdate] TO [public]
GO
