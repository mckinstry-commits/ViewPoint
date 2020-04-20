SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForDrawings]
   
   /***********************************************************
    * CREATED BY:	JG	08/10/2010 - Issue #140529
    * MODIFIED BY:	
    *
    * USAGE:
    * Pull records from project distribution defaults and add to new Drawing record
    *
    *
    * INPUT PARAMETERS
    *	@PMCo
    *	@Project
    *   @DrawingType
    *	@Drawing
    *	@DateSent
    *	@DrawingLogID
    *
    * OUTPUT PARAMETERS
    *	None.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PMCo bCompany, @Project bJob, @DrawingType bDocType, @Drawing bDocument, @DateSent bDate, @DrawingLogID bigint, @msg varchar(255) output)
	AS
	BEGIN
	
		SET NOCOUNT ON

		IF @PMCo IS NULL OR @Project IS NULL OR @DrawingType IS NULL OR @Drawing IS NULL OR @DateSent IS NULL OR @DrawingLogID IS NULL
		BEGIN
			SET @msg = 'The Company, Project, DrawingType, Drawing, DateSent, and DrawingLogID must be supplied. Please contact Viewpoint Customer Support.'
			RETURN 1
		END

		DECLARE @VendorGroup bGroup
		DECLARE @PrefMethod char
		DECLARE @LastSeq tinyint

		--Get Last Sequence
		SELECT @LastSeq = ISNULL(MAX(Seq),0) FROM PMDistribution
		WHERE PMCo = @PMCo
		AND Project = @Project
		AND DrawingType = @DrawingType
		AND Drawing = @Drawing

		--Pull Vendor Group
		SELECT @VendorGroup = VendorGroup FROM PMCO
		WHERE PMCO.PMCo = @PMCo

		--Pull PrefMethod
		SELECT @PrefMethod = PrefMethod FROM PMPM
		WHERE VendorGroup = @VendorGroup

		INSERT INTO PMDistribution
		(PMCo, Project, DrawingType, Drawing, Seq, VendorGroup, SentToFirm, SentToContact
		,DateSent, DrawingLogID, [Send], PrefMethod, CC) 

		--Pull Firms and Contacts to Enter
		SELECT	@PMCo 'PMCo', @Project 'Project', @DrawingType 'DrawingType'
		, @Drawing 'Drawing', @LastSeq + ROW_NUMBER() OVER(ORDER BY @PMCo) 'Seq', @VendorGroup 'VendorGroup'
		, ppdd.FirmNumber 'SentToFirm', ppdd.ContactCode 'SentToContact'
		, @DateSent 'DateSent', @DrawingLogID 'DrawingLogID'
		, 'Y' 'Send', PMPM.PrefMethod, PMPF.EmailOption 'CC'
		FROM	PMProjDefDistDocType dc
			LEFT JOIN PMProjectDefaultDistributions ppdd
				ON ppdd.KeyID = dc.DefaultKeyID
			LEFT JOIN PMPM
				ON	PMPM.VendorGroup = @VendorGroup
				AND PMPM.FirmNumber = ppdd.FirmNumber
				AND PMPM.ContactCode = ppdd.ContactCode
			LEFT JOIN PMPF
				ON PMPF.PMCo = @PMCo
				AND PMPF.Project = @Project
				AND PMPF.VendorGroup = @VendorGroup
				AND PMPF.FirmNumber = ppdd.FirmNumber
				AND PMPF.ContactCode = ppdd.ContactCode
		WHERE ppdd.PMCo = @PMCo
		AND ppdd.Project = @Project
		AND dc.DocType = @DrawingType
		--Ignore adding defaults that already exist in table
		AND NOT EXISTS(	SELECT TOP 1 1 FROM dbo.vPMDistribution 
						WHERE PMCo=@PMCo AND Project=@Project 
						AND VendorGroup=@VendorGroup AND SentToFirm=ppdd.FirmNumber 
						AND SentToContact=ppdd.ContactCode AND DrawingType=@DrawingType 
						AND Drawing=@Drawing)

	END
GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMDistributionForDrawings] TO [public]
GO
