SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMTestLogDistributionUpdate]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/11/09
-- Modified By: GF 09/21/2011 TK-08626 changed to use standard PM Distribution view
--
-- Description:	Updates the test log distribution list
-- =============================================
(@KeyID BIGINT, @Seq BIGINT, @VendorGroup bVendor, @SentToFirm bFirm, @SentToContact bEmployee, @Send CHAR, @PrefMethod CHAR, @CC CHAR, @DateSent bDate, @DateSigned bDate, @TestLogID BIGINT, @PMCo bCompany, @Project bJob, @TestType bDocType, @TestCode bDocument, @Notes VARCHAR(MAX), @UniqueAttchID UNIQUEIDENTIFIER,
@Original_KeyID BIGINT, @Original_Seq BIGINT, @Original_VendorGroup bVendor, @Original_SentToFirm bFirm, @Original_SentToContact bEmployee, @Original_Send CHAR, @Original_PrefMethod CHAR, @Original_CC CHAR, @Original_DateSent bDate, @Original_DateSigned bDate, @Original_TestLogID BIGINT, @Original_PMCo bCompany, @Original_Project bJob, @Original_TestType bDocType, @Original_TestCode bDocument, @Original_Notes VARCHAR(MAX), @Original_UniqueAttchID UNIQUEIDENTIFIER
)
AS
BEGIN
	SET NOCOUNT ON;
	
	-- Validate that this firm/contact if it has been changed doesnt already exist in this test log distribution
	IF @Original_SentToFirm != @SentToFirm OR @Original_SentToContact != @SentToContact
		BEGIN
			IF EXISTS(SELECT 1 FROM [PMDistribution] WHERE [PMCo] = @PMCo AND [Project] = @Project AND [TestType] = @TestType AND [TestCode] = @TestCode AND [SentToFirm] = @SentToFirm AND [SentToContact] = @SentToContact AND KeyID != @Original_KeyID)
			BEGIN
				DECLARE @msg VARCHAR(255)
				SELECT @msg = 'Firm ' + CAST(@SentToFirm as VARCHAR(10)) + ', Contact ' + CAST(@SentToContact as VARCHAR(10)) + ' already exists in the distribution list for this test log.'
				RAISERROR(@msg, 16, 1)
				GOTO vspExit
			END
		END
	


	UPDATE PMDistribution
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
	
	EXEC vpspPMTestLogDistributionGet @TestLogID, @KeyID
	
	vspExit:
END
GO
GRANT EXECUTE ON  [dbo].[vpspPMTestLogDistributionUpdate] TO [VCSPortal]
GO
