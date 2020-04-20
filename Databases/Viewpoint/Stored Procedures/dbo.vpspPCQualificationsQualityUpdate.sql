SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsQualityUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @QualityExecutiveName VARCHAR(60), @QualityExecutiveTitle VARCHAR(30), @QualityExecutivePhone bPhone, @QualityExecutiveEmail VARCHAR(60), @QualityExecutiveFax bPhone, @QualityExecutiveCertifications VARCHAR(60), @QualityPolicy bYN, @QualityTQM bYN, @QualityLEEDProjects TINYINT, @QualityLEEDProfessionals TINYINT)
AS
/* Modified:   TRL 11/15/2011 TK-10041 fixed QualityLeedsCertified and QualityLeedsExperience updates
*/
SET NOCOUNT ON;

BEGIN
	UPDATE PCQualifications
	SET
		QualityExecutiveName = @QualityExecutiveName,
		QualityExecutiveTitle = @QualityExecutiveTitle,
		QualityExecutivePhone = @QualityExecutivePhone,
		QualityExecutiveEmail = @QualityExecutiveEmail,
		QualityExecutiveFax = @QualityExecutiveFax,
		QualityExecutiveCertifications = @QualityExecutiveCertifications,
		QualityPolicy = @QualityPolicy,
		QualityTQM = @QualityTQM,
		QualityLeedsCertified = CASE WHEN dbo.vpfIsNullOrEmpty(@QualityLEEDProfessionals) = 1 THEN 'N' ELSE 'Y' END,
		QualityLEEDProjects = @QualityLEEDProjects,
		QualityLeedsExperience = CASE WHEN dbo.vpfIsNullOrEmpty(@QualityLEEDProjects) = 1 THEN 'N' ELSE 'Y' END,
		QualityLEEDProfessionals = @QualityLEEDProfessionals
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsQualityUpdate] TO [VCSPortal]
GO
