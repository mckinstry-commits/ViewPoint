SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMInspectionLogDistributionUpdate]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/14/09
-- Modified By: GF 09/21/2011 TK-08626 changed to use standard PM Distribution view
--
-- Description:	Updates the inspection log distribution list
-- =============================================
(@KeyID BIGINT, @Seq BIGINT, @VendorGroup bVendor, @SentToFirm bFirm, @SentToContact bEmployee, 
 @Send bYN, @PrefMethod CHAR(1), @CC CHAR(1), @DateSent bDate, @DateSigned bDate, 
 @InspectionLogID BIGINT, @PMCo bCompany, @Project bJob, @InspectionType bDocType, 
 @InspectionCode bDocument, @Notes VARCHAR(MAX), @UniqueAttchID UNIQUEIDENTIFIER,
 @Original_KeyID BIGINT, @Original_Seq BIGINT, @Original_VendorGroup bVendor, 
 @Original_SentToFirm bFirm, @Original_SentToContact bEmployee, @Original_Send bYN, 
 @Original_PrefMethod CHAR(1), @Original_CC CHAR(1), @Original_DateSent bDate, 
 @Original_DateSigned bDate, @Original_InspectionLogID BIGINT, @Original_PMCo bCompany, 
 @Original_Project bJob, @Original_InspectionType bDocType, @Original_InspectionCode bDocument, 
 @Original_Notes VARCHAR(MAX), @Original_UniqueAttchID UNIQUEIDENTIFIER
)
AS
BEGIN
	SET NOCOUNT ON;
	
	-- Validate that this firm/contact if it has been changed doesnt already exist in this inspection log distribution
	IF @Original_SentToFirm != @SentToFirm OR @Original_SentToContact != @SentToContact
		BEGIN
			IF EXISTS(SELECT 1 FROM [PMDistribution] WHERE [PMCo] = @PMCo AND [Project] = @Project AND [InspectionType] = @InspectionType AND [InspectionCode] = @InspectionCode AND [SentToFirm] = @SentToFirm AND [SentToContact] = @SentToContact AND KeyID != @Original_KeyID)
			BEGIN
				DECLARE @msg VARCHAR(255)
				SELECT @msg = 'Firm ' + CAST(@SentToFirm as VARCHAR(10)) + ', Contact ' + CAST(@SentToContact as VARCHAR(10)) + ' already exists in the distribution list for this inspection log.'
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
	
	EXEC vpspPMInspectionLogDistributionGet @InspectionLogID, @KeyID
		
	vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspPMInspectionLogDistributionUpdate] TO [VCSPortal]
GO
