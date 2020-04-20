SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[vpspPMInspectionLogDistributionInsert]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/14/09
-- Modified By: GF 09/21/2011 TK-08626 changed to use standard PM Distribution view
--
--
-- Description:	Inserts into the inspection log distribution list
-- =============================================
(@KeyID BIGINT = NULL, @Seq BIGINT, @VendorGroup bVendor, @SentToFirm bFirm, @SentToContact bEmployee, @Send CHAR, @PrefMethod CHAR, @CC CHAR, @DateSent bDate, @DateSigned bDate, @InspectionLogID BIGINT, @PMCo bCompany, @Project bJob, @InspectionType bDocType, @InspectionCode bDocument, @Notes VARCHAR(MAX), @UniqueAttchID UNIQUEIDENTIFIER)
AS
BEGIN
	SET NOCOUNT ON;
	
	
	-- Validate that this firm/contact doesnt already exist in this inspection log distribution
	IF EXISTS(SELECT 1 FROM [PMDistribution] WHERE [PMCo] = @PMCo AND [Project] = @Project AND [InspectionType] = @InspectionType AND [InspectionCode] = @InspectionCode AND [SentToFirm] = @SentToFirm AND [SentToContact] = @SentToContact)
		BEGIN
			DECLARE @msg VARCHAR(255)
			SELECT @msg = 'Firm ' + CAST(@SentToFirm as VARCHAR(10)) + ', Contact ' + CAST(@SentToContact as VARCHAR(10)) + ' already exists in the distribution list for this inspection log.'
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	
	-- Set the seq number
	SELECT @Seq = ISNULL(MAX(Seq), 0) + 1 FROM PMDistribution WHERE InspectionLogID = @InspectionLogID

	INSERT INTO PMDistribution
	(
		[Seq]
		,[VendorGroup]
		,[SentToFirm]
		,[SentToContact]
		,[Send]
		,[PrefMethod]
		,[CC]
		,[DateSent]
		,[DateSigned]
		,[InspectionLogID]
		,[PMCo]
		,[Project]
		,[InspectionType]
		,[InspectionCode]
		,[Notes]
	) 
	VALUES (@Seq, @VendorGroup, @SentToFirm, @SentToContact, @Send, @PrefMethod, @CC, @DateSent, @DateSigned, @InspectionLogID, @PMCo, @Project, @InspectionType, @InspectionCode, @Notes);

	SET @KeyID = SCOPE_IDENTITY()
	EXEC vpspPMInspectionLogDistributionGet @InspectionLogID, @KeyID

	vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspPMInspectionLogDistributionInsert] TO [VCSPortal]
GO
