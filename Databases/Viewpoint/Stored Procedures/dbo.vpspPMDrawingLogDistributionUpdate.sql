SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMDrawingLogDistributionUpdate]
-- =============================================
-- Created By:	GF 11/10/2011 TK-00000
-- Modified By:
--
-- Description:	Updates the drawing log distribution list
-- =============================================
(@KeyID BIGINT, @Seq BIGINT, @VendorGroup bVendor, @SentToFirm bFirm, @SentToContact bEmployee,
 @Send CHAR, @PrefMethod CHAR, @CC CHAR, @DateSent bDate, @DateSigned bDate,
 @DrawingLogID BIGINT, @PMCo bCompany, @Project bJob, @DrawingType bDocType,
 @Drawing bDocument, @Notes VARCHAR(MAX), @UniqueAttchID UNIQUEIDENTIFIER,
 @Original_KeyID BIGINT, @Original_Seq BIGINT, @Original_VendorGroup bVendor,
 @Original_SentToFirm bFirm, @Original_SentToContact bEmployee, @Original_Send CHAR, 
 @Original_PrefMethod CHAR, @Original_CC CHAR, @Original_DateSent bDate, 
 @Original_DateSigned bDate, @Original_DrawingLogID BIGINT, @Original_PMCo bCompany, 
 @Original_Project bJob, @Original_DrawingType bDocType, @Original_Drawing bDocument, 
 @Original_Notes VARCHAR(MAX), @Original_UniqueAttchID UNIQUEIDENTIFIER
)
AS
BEGIN
SET NOCOUNT ON;

---- Validate that this firm/contact if it has been changed doesn't already exist in this Drawing log distribution
IF @Original_SentToFirm != @SentToFirm OR @Original_SentToContact != @SentToContact
	BEGIN
	IF EXISTS(SELECT 1 FROM [PMDistribution] WHERE [PMCo] = @PMCo AND [Project] = @Project
				AND [DrawingType] = @DrawingType AND [Drawing] = @Drawing 
				AND [SentToFirm] = @SentToFirm AND [SentToContact] = @SentToContact 
				AND KeyID != @Original_KeyID)
		BEGIN
		DECLARE @msg VARCHAR(255)
		SELECT @msg = 'Firm ' + dbo.vfToString(@SentToFirm) + ', Contact ' + dbo.vfToString(@SentToContact) + ' already exists in the distribution list for this inspection log.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
		END
	END
	

---- update record
UPDATE dbo.PMDistribution
SET 	
	[SentToFirm] = @SentToFirm
	,[SentToContact] = @SentToContact
	,[Send]	= @Send
	,[PrefMethod] = @PrefMethod
	,[CC] = @CC
	,[DateSent] = @DateSent
	,[DateSigned] = @DateSigned
	,[Notes] = @Notes
	,[UniqueAttchID] = @UniqueAttchID
WHERE
	[KeyID] = @KeyID        

---- get record
EXEC vpspPMDrawingLogDistributionGet @DrawingLogID, @KeyID
		
vspExit:

END

GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogDistributionUpdate] TO [VCSPortal]
GO
