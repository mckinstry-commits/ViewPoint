SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsLegalUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @QBankruptsNotes VARCHAR(MAX), @QIndictedNotes VARCHAR(MAX), @QDisbarredNotes VARCHAR(MAX), @QComplianceNotes VARCHAR(MAX), @QLitigationNotes VARCHAR(MAX), @QJudgementNotes VARCHAR(MAX), @QLaborNotes VARCHAR(MAX))
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCQualifications
	SET
		QBankrupt = CASE WHEN dbo.vpfIsNullOrEmpty(@QBankruptsNotes) = 1 THEN 'N' ELSE 'Y' END,
		QBankruptsNotes = @QBankruptsNotes,
		QIndicted = CASE WHEN dbo.vpfIsNullOrEmpty(@QIndictedNotes) = 1 THEN 'N' ELSE 'Y' END,
		QIndictedNotes = @QIndictedNotes,
		QDisbarred = CASE WHEN dbo.vpfIsNullOrEmpty(@QDisbarredNotes) = 1 THEN 'N' ELSE 'Y' END,
		QDisbarredNotes = @QDisbarredNotes,
		QCompliance = CASE WHEN dbo.vpfIsNullOrEmpty(@QComplianceNotes) = 1 THEN 'N' ELSE 'Y' END,
		QComplianceNotes = @QComplianceNotes,
		QLitigation = CASE WHEN dbo.vpfIsNullOrEmpty(@QLitigationNotes) = 1 THEN 'N' ELSE 'Y' END,
		QLitigationNotes = @QLitigationNotes,
		QJudgements = CASE WHEN dbo.vpfIsNullOrEmpty(@QJudgementNotes) = 1 THEN 'N' ELSE 'Y' END,
		QJudgementNotes = @QJudgementNotes,
		QLabor = CASE WHEN dbo.vpfIsNullOrEmpty(@QLaborNotes) = 1 THEN 'N' ELSE 'Y' END,
		QLaborNotes = @QLaborNotes
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsLegalUpdate] TO [VCSPortal]
GO
