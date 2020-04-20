SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[vpspPMDrawingLogDistributionInsert]
-- =============================================
-- Created By:	GF 11/10/2011 TK-00000
-- Modified By: 
--
--
-- Description:	Inserts into the drawing log distribution list
-- =============================================
(@KeyID BIGINT = NULL, @Seq BIGINT, @VendorGroup bVendor, @SentToFirm bFirm,
 @SentToContact bEmployee, @Send CHAR, @PrefMethod CHAR, @CC CHAR, @DateSent bDate, 
 @DateSigned bDate, @DrawingLogID BIGINT, @PMCo bCompany, @Project bJob, 
 @DrawingType bDocType, @Drawing bDocument, @Notes VARCHAR(MAX),
 @UniqueAttchID UNIQUEIDENTIFIER)
AS
BEGIN
SET NOCOUNT ON;


---- Validate that this firm/contact doesnt already exist in this drawing log distribution
IF EXISTS(SELECT 1 FROM [PMDistribution] WHERE [PMCo] = @PMCo AND [Project] = @Project 
				AND [DrawingType] = @DrawingType AND [Drawing] = @Drawing 
				AND [SentToFirm] = @SentToFirm AND [SentToContact] = @SentToContact)
	BEGIN
		DECLARE @msg VARCHAR(255)
		SELECT @msg = 'Firm ' + dbo.vfToString(@SentToFirm) + ', Contact ' + dbo.vfToString(@SentToContact) + ' already exists in the distribution list for this drawing log.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	
---- Set the seq number
SELECT @Seq = ISNULL(MAX(Seq), 0) + 1 FROM PMDistribution WHERE DrawingLogID = @DrawingLogID

---- insert record
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
	,[PMCo]
	,[Project]
	,[DrawingLogID]
	,[DrawingType]
	,[Drawing]
	,[Notes]
) 
VALUES (@Seq, @VendorGroup, @SentToFirm, @SentToContact, @Send, @PrefMethod, @CC, @DateSent, @DateSigned,
		@DrawingLogID, @PMCo, @Project, @DrawingType, @Drawing, @Notes);

---- get identity 
SET @KeyID = SCOPE_IDENTITY()
EXEC vpspPMDrawingLogDistributionGet @DrawingLogID, @KeyID


vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogDistributionInsert] TO [VCSPortal]
GO
