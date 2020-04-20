SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Chris G
-- Create date: 2/11/2010
-- Description:	
--		Updates a Portal Control belonging to the given License Assignment.  This is mainly used by the stand along in-house
--		app that allows VP staff to view and update license assignments.
-- Inputs:
--	@PortalControlID   	Portal Control ID
--	@licenseType1		Corresponds to License Type 1
--	@licenseType2		Corresponds to License Type 2
--	@licenseType3		Corresponds to License Type 3
--
-- Return code:
--	0 = success, 1 = error (no message)
-- =============================================
CREATE PROCEDURE [dbo].[vpspUpdatePortalControlLicenseAssignment] 
	(@PortalControlID int, @licenseType1 bit, @licenseType2 bit, @licenseType3 bit, @msg varchar(255) output)
AS
BEGIN

	-- validate inputs variables
	IF @PortalControlID is null 
		BEGIN
		SELECT @msg = 'Portal Control ID Required'
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

	-- Set constants for LicenseTypeIDs
	DECLARE @licenseType1Exists BIT
	DECLARE @licenseType2Exists BIT
	DECLARE @licenseType3Exists BIT
	
	-- Check whether the user already has licenses
	SELECT @licenseType1Exists = 1 FROM pPortalControlLicenseType WHERE PortalControlID = @PortalControlID AND LicenseTypeID = 1;
	SELECT @licenseType2Exists = 1 FROM pPortalControlLicenseType WHERE PortalControlID = @PortalControlID AND LicenseTypeID = 2;
	SELECT @licenseType3Exists = 1 FROM pPortalControlLicenseType WHERE PortalControlID = @PortalControlID AND LicenseTypeID = 3;
	
	-- LICENSE TYPE 1
    IF @licenseType1 = 1 AND @licenseType1Exists IS NULL
		BEGIN
		INSERT INTO pPortalControlLicenseType (PortalControlID, LicenseTypeID) VALUES (@PortalControlID, 1);		
		END
	IF @licenseType1 = 0 AND @licenseType1Exists IS NOT NULL
		BEGIN
		DELETE FROM pPortalControlLicenseType WHERE PortalControlID = @PortalControlID AND LicenseTypeID = 1;		
		END

	-- LICENSE TYPE 2
	IF @licenseType2 = 1 AND @licenseType2Exists IS NULL
		BEGIN
		INSERT INTO pPortalControlLicenseType (PortalControlID, LicenseTypeID) VALUES (@PortalControlID, 2);
		END
	IF @licenseType2 = 0 AND @licenseType2Exists IS NOT NULL
		BEGIN
		DELETE FROM pPortalControlLicenseType WHERE PortalControlID = @PortalControlID AND LicenseTypeID = 2;
		END
		
	-- LICENSE TYPE 3
	IF @licenseType3 = 1 AND @licenseType3Exists IS NULL
		BEGIN		
		INSERT INTO pPortalControlLicenseType (PortalControlID, LicenseTypeID) VALUES (@PortalControlID, 3 );
		END
	IF @licenseType3 = 0 AND @licenseType3Exists IS NOT NULL
		BEGIN
		DELETE FROM pPortalControlLicenseType WHERE PortalControlID = @PortalControlID AND LicenseTypeID = 3;
		END
END



GO
GRANT EXECUTE ON  [dbo].[vpspUpdatePortalControlLicenseAssignment] TO [VCSPortal]
GO
