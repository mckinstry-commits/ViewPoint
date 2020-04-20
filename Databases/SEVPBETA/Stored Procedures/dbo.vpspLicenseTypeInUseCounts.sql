SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris G
-- Create date: 2/03/2010
-- Description:	Procesure to return the number of licenses in use by type
-- =============================================
CREATE PROCEDURE [dbo].[vpspLicenseTypeInUseCounts] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT 
		l.LicenseTypeID, 
		l.LicenseType, 
		ISNULL(c.Used, 0) FROM pLicenseType l
	LEFT JOIN (SELECT LicenseTypeID, COUNT(*) AS Used FROM pUserLicenseType GROUP BY LicenseTypeID) c
	ON l.LicenseTypeID = c.LicenseTypeID 
	ORDER BY l.LicenseTypeID;
END

GO
GRANT EXECUTE ON  [dbo].[vpspLicenseTypeInUseCounts] TO [VCSPortal]
GO
