SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMTestLogDistributionInsert]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/11/09
-- Modified By: GF 09/21/2011 TK-08626 changed to use standard PM Distribution view
--
-- Description:	Inserts into the test log distribution list
-- =============================================
(@KeyID BIGINT = NULL, @Seq BIGINT, @VendorGroup bVendor, @SentToFirm bFirm,
 @SentToContact bEmployee, @Send CHAR, @PrefMethod CHAR, @CC CHAR, @DateSent bDate, 
 @DateSigned bDate, @TestLogID BIGINT,  @PMCo bCompany, @Project bJob, @TestType bDocType, 
 @TestCode bDocument, @Notes VARCHAR(MAX), @UniqueAttchID UNIQUEIDENTIFIER)
AS
BEGIN
SET NOCOUNT ON;

	
---- Validate that this firm/contact doesnt already exist in this test log distribution
IF EXISTS(SELECT 1 FROM [dbo].[PMDistribution] WHERE [PMCo] = @PMCo AND [Project] = @Project
				AND [TestType] = @TestType AND [TestCode] = @TestCode 
				AND [SentToFirm] = @SentToFirm AND [SentToContact] = @SentToContact)
	BEGIN
	DECLARE @msg VARCHAR(255)
	SELECT @msg = 'Firm ' + CAST(@SentToFirm as VARCHAR(10)) + ', Contact ' + CAST(@SentToContact as VARCHAR(10)) + ' already exists in the distribution list for this test log.'
	RAISERROR(@msg, 16, 1)
	GOTO vspExit
	END

---- Set the seq number
SELECT @Seq = ISNULL(MAX(Seq), 0) + 1 FROM dbo.PMDistribution WHERE TestLogID = @TestLogID

---- insert test log distribution record
INSERT INTO dbo.PMDistribution
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
		,[TestLogID]
		,[PMCo]
		,[Project]
		,[TestType]
		,[TestCode]
		,[Notes]
	) 
VALUES (@Seq, @VendorGroup, @SentToFirm, @SentToContact, @Send, @PrefMethod, @CC, @DateSent,
		@DateSigned, @TestLogID, @PMCo, @Project, @TestType, @TestCode, @Notes);

SET @KeyID = SCOPE_IDENTITY()
EXEC vpspPMTestLogDistributionGet @TestLogID, @KeyID

vspExit:

END
GO
GRANT EXECUTE ON  [dbo].[vpspPMTestLogDistributionInsert] TO [VCSPortal]
GO
