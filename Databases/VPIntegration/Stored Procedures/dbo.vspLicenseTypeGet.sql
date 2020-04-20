SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tom J
-- Create date: 1/28/2010
-- Description:	Special get method to provide all the data for the pLicenseType table
-- =============================================
CREATE PROCEDURE [dbo].[vspLicenseTypeGet]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT LicenseTypeID, LicenseType, LicenseCount, LicenseChecksum, Abbreviation FROM pLicenseType 
END


GO
GRANT EXECUTE ON  [dbo].[vspLicenseTypeGet] TO [public]
GO
