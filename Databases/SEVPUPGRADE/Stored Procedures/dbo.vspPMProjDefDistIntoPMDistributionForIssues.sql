SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForIssues]
   
   /***********************************************************
    * CREATED BY:	GF	10/01/2010 - issue #141553 - TFS#791
    * MODIFIED BY:	
    *
    * USAGE:
    * Pull records from project distribution defaults and add to new Project Issue record.
    * Called from code in PM Project Issues.
    *
    *
    * INPUT PARAMETERS
    *	@IssueID		project issue key id to pull info - required
    *
    * OUTPUT PARAMETERS
    *	None.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
*****************************************************/
(@IssueID BIGINT = null, @msg varchar(255) output)
AS
BEGIN

	SET NOCOUNT ON

		IF @IssueID IS NULL
		BEGIN
			SET @msg = 'Missing Project Issue Record ID.'
			RETURN 1
		END


		DECLARE @PMCo bCompany, @Project bJob, @IssueType bDocType, @Issue bIssue,
				@DateSent bDate, @VendorGroup bGroup
		
		----get project issue info
		SELECT @PMCo=PMCo, @Project=Project, @IssueType=Type,
				@Issue=Issue, @DateSent=DateInitiated,
				@VendorGroup=VendorGroup
		FROM dbo.PMIM
		WHERE KeyID = @IssueID
		IF @@ROWCOUNT = 0
			BEGIN
			SET @msg = 'Project Issue Record not found.'
			RETURN 1
			END
		
		---- must have an issue type
		IF ISNULL(@IssueType,'') = ''
			BEGIN
			SET @msg = 'Missing Issue Type.'
			RETURN 1
			END
		
		----use system date for date sent
		SET @DateSent = dbo.vfDateOnly()
			
		INSERT INTO dbo.PMDistribution (Seq, VendorGroup, SentToFirm, SentToContact, Send,
				PrefMethod, CC, DateSent, PMCo, Project, IssueType, Issue, IssueID)

		SELECT isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY h.IssueID ASC),
				@VendorGroup, ppdd.FirmNumber, ppdd.ContactCode, 'Y',
				isnull(PMPM.PrefMethod, 'E'), ISNULL(PMPF.EmailOption,'N'),
				@DateSent, @PMCo, @Project, @IssueType, @Issue, @IssueID
		FROM dbo.PMProjDefDistDocType dc
		LEFT JOIN dbo.PMProjectDefaultDistributions ppdd ON ppdd.KeyID = dc.DefaultKeyID
		LEFT JOIN dbo.PMPM PMPM ON PMPM.VendorGroup = @VendorGroup
		AND PMPM.FirmNumber = ppdd.FirmNumber AND PMPM.ContactCode = ppdd.ContactCode
		LEFT JOIN dbo.PMPF PMPF ON PMPF.PMCo = @PMCo AND PMPF.Project = @Project
		AND PMPF.VendorGroup = @VendorGroup AND PMPF.FirmNumber = ppdd.FirmNumber
		AND PMPF.ContactCode = ppdd.ContactCode
		LEFT JOIN dbo.PMDistribution h ON h.IssueID = @IssueID
		WHERE ppdd.PMCo = @PMCo AND ppdd.Project = @Project
		AND dc.DocType = @IssueType
		----Ignore adding defaults that already exist in table
		AND NOT EXISTS(	SELECT TOP 1 1 FROM dbo.vPMDistribution 
						WHERE PMCo=@PMCo AND Project=@Project 
						AND VendorGroup=@VendorGroup AND SentToFirm=ppdd.FirmNumber 
						AND SentToContact=ppdd.ContactCode
						AND Issue=@Issue)
		GROUP BY h.IssueID, ppdd.FirmNumber, ppdd.ContactCode, PMPF.EmailOption, PMPM.PrefMethod

	END
GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMDistributionForIssues] TO [public]
GO
