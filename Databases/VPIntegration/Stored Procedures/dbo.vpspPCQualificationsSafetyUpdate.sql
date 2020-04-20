SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsSafetyUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @SafetyExecutiveName VARCHAR(60), @SafetyExecutiveTitle VARCHAR(60), @SafetyExecutivePhone bPhone, @SafetyExecutiveEmail VARCHAR(60), @SafetyExecutiveFax bPhone, @SafetyExecutiveCertifications VARCHAR(60), @SafetyMeetingsNewFrequency TINYINT, @SafetyMeetingsFieldFrequency TINYINT, @SafetyMeetingsEmployeesFrequency TINYINT, @SafetyMeetingsSubsFrequency TINYINT, @SafetyInspections bYN, @SafetyFallProtection bYN, @SafetySiteProgram bYN, @SafetyTrainingNew bYN, @SafetyRecognitionProgram bYN, @SafetyDisciplinaryProgram bYN, @SafetyInvestigations bYN, @SafetyReturnToWorkProgram bYN, @SafetyReviews bYN, @SafetySexualHarassment bYN, @SafetyAffirmativeActionPlan bYN, @SafetyPolicy bYN, @SafetyDisciplinaryPolicy bYN, @SafetyAnnualGoals bYN, @DrugScreeningRequired bYN, @DrugScreeningPreEmployment bYN, @DrugScreeningRandom bYN, @DrugScreeningPeriodic bYN, @DrugScreeningPostAccident bYN, @DrugScreeningOnSuspicion bYN)
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCQualifications
	SET
		SafetyExecutiveName = @SafetyExecutiveName,
		SafetyExecutiveTitle = @SafetyExecutiveTitle,
		SafetyExecutivePhone = @SafetyExecutivePhone,
		SafetyExecutiveEmail = @SafetyExecutiveEmail,
		SafetyExecutiveFax = @SafetyExecutiveFax,
		SafetyExecutiveCertifications = @SafetyExecutiveCertifications,
		SafetyMeetingsNew = CASE WHEN dbo.vpfIsNullOrEmpty(@SafetyMeetingsNewFrequency) = 1 THEN 'N' ELSE 'Y' END,
		SafetyMeetingsNewFrequency = @SafetyMeetingsNewFrequency,
		SafetyMeetingsField = CASE WHEN dbo.vpfIsNullOrEmpty(@SafetyMeetingsFieldFrequency) = 1 THEN 'N' ELSE 'Y' END,
		SafetyMeetingsFieldFrequency = @SafetyMeetingsFieldFrequency,
		SafetyMeetingsEmployees = CASE WHEN dbo.vpfIsNullOrEmpty(@SafetyMeetingsEmployeesFrequency) = 1 THEN 'N' ELSE 'Y' END,
		SafetyMeetingsEmployeesFrequency = @SafetyMeetingsEmployeesFrequency,
		SafetyMeetingsSubs = CASE WHEN dbo.vpfIsNullOrEmpty(@SafetyMeetingsSubsFrequency) = 1 THEN 'N' ELSE 'Y' END,
		SafetyMeetingsSubsFrequency = @SafetyMeetingsSubsFrequency,
		SafetyInspections = @SafetyInspections,
		SafetyFallProtection = @SafetyFallProtection,
		SafetySiteProgram = @SafetySiteProgram,
		SafetyTrainingNew = @SafetyTrainingNew,
		SafetyRecognitionProgram = @SafetyRecognitionProgram,
		SafetyDisciplinaryProgram = @SafetyDisciplinaryProgram,
		SafetyInvestigations = @SafetyInvestigations,
		SafetyReturnToWorkProgram = @SafetyReturnToWorkProgram,
		SafetyReviews = @SafetyReviews,
		SafetySexualHarassment = @SafetySexualHarassment,
		SafetyAffirmativeActionPlan = @SafetyAffirmativeActionPlan,
		SafetyPolicy = @SafetyPolicy,
		SafetyDisciplinaryPolicy = @SafetyDisciplinaryPolicy,
		SafetyAnnualGoals = @SafetyAnnualGoals,
		DrugScreeningRequired = @DrugScreeningRequired,
		DrugScreeningPreEmployment = @DrugScreeningPreEmployment,
		DrugScreeningRandom = @DrugScreeningRandom,
		DrugScreeningPeriodic = @DrugScreeningPeriodic,
		DrugScreeningPostAccident = @DrugScreeningPostAccident,
		DrugScreeningOnSuspicion = @DrugScreeningOnSuspicion
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsSafetyUpdate] TO [VCSPortal]
GO
