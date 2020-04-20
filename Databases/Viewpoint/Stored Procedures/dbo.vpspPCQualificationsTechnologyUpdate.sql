SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsTechnologyUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @AccountingSoftwareName VARCHAR(60), @AccountingSoftwareRevision VARCHAR(10), @AccountingSoftwareInstallationDate bDate, @AccountingSoftwareOS VARCHAR(30), @AccountingSoftwareDatabase VARCHAR(30), @PMSoftwareName VARCHAR(60), @PMSoftwareRevision VARCHAR(10), @PMSoftwareInstallationDate bDate, @PMSoftwareOS VARCHAR(30), @PMSoftwareDatabase VARCHAR(30), @PSSoftwareName VARCHAR(60), @PSSoftwareRevision VARCHAR(10), @PSSoftwareInstallationDate bDate, @PSSoftwareOS VARCHAR(30), @PSSoftwareDatabase VARCHAR(30), @DMSoftwareName VARCHAR(60), @DMSoftwareRevision VARCHAR(10), @DMSoftwareInstallationDate bDate, @DMSoftwareOS VARCHAR(30), @DMSoftwareDatabase VARCHAR(30), @JobSiteConnectionType CHAR(1))
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCQualifications
	SET
		AccountingSoftwareName = @AccountingSoftwareName,
		AccountingSoftwareRevision = @AccountingSoftwareRevision,
		AccountingSoftwareInstallationDate = @AccountingSoftwareInstallationDate,
		AccountingSoftwareOS = @AccountingSoftwareOS,
		AccountingSoftwareDatabase = @AccountingSoftwareDatabase,
		PMSoftwareName = @PMSoftwareName,
		PMSoftwareRevision = @PMSoftwareRevision,
		PMSoftwareInstallationDate = @PMSoftwareInstallationDate,
		PMSoftwareOS = @PMSoftwareOS,
		PMSoftwareDatabase = @PMSoftwareDatabase,
		PSSoftwareName = @PSSoftwareName,
		PSSoftwareRevision = @PSSoftwareRevision,
		PSSoftwareInstallationDate = @PSSoftwareInstallationDate,
		PSSoftwareOS = @PSSoftwareOS,
		PSSoftwareDatabase = @PSSoftwareDatabase,
		DMSoftwareName = @DMSoftwareName,
		DMSoftwareRevision = @DMSoftwareRevision,
		DMSoftwareInstallationDate = @DMSoftwareInstallationDate,
		DMSoftwareOS = @DMSoftwareOS,
		DMSoftwareDatabase = @DMSoftwareDatabase,
		JobSiteConnectionType = @JobSiteConnectionType
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsTechnologyUpdate] TO [VCSPortal]
GO
