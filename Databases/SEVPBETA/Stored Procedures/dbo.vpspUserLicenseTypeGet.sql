SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tom J
-- Create date: 1/28/2010
-- Description:	Special get method to provide all the data for the pUserLicenseType table
-- =============================================
CREATE PROCEDURE [dbo].[vpspUserLicenseTypeGet]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT LicenseTypeID, UserID FROM dbo.pUserLicenseType
END


GO
GRANT EXECUTE ON  [dbo].[vpspUserLicenseTypeGet] TO [VCSPortal]
GO
