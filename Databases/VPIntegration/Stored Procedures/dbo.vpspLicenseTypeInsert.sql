SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************
* CREATED:     Tom J - 2/17/2010
* MODIFIED:    
*
* USAGE:
*   Inserts a LicenseType record into the database with the passed in fields. No values can be null.
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*   LicenseTypeID: int - Id/Primary Key of the table
*	LicenseType: varchar(60) - String decsription of the Type
*	LicenseCount: varchar(60) - Encrypted representation of the value
*	LicenseChecksum: int - integer value to verify portal license data hasn't been modified
************************************************************/
CREATE        PROCEDURE [dbo].[vpspLicenseTypeInsert]
(
	@LicenseTypeID int,
	@LicenseType varchar(60),
	@LicenseCount varchar(60),
	@LicenseChecksum int,
	@Abbreviation varchar(10)
)
AS
	SET NOCOUNT OFF;

INSERT INTO pLicenseType(LicenseTypeID, LicenseType, LicenseCount, LicenseChecksum, Abbreviation) VALUES (@LicenseTypeID, @LicenseType, @LicenseCount, @LicenseChecksum, @Abbreviation );


GO
GRANT EXECUTE ON  [dbo].[vpspLicenseTypeInsert] TO [VCSPortal]
GO
