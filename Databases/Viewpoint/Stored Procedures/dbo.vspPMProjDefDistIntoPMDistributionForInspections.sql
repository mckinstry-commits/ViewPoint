SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForInspections]
   
   /***********************************************************
    * CREATED BY:	JG	08/10/2010 - Issue #140529
    * MODIFIED BY:	
    *
    * USAGE:
    * Pull records from project distribution defaults and add to new Inspection record
    *
    *
    * INPUT PARAMETERS
    *	@PMCo
    *	@Project
    *   @Type
    *	@Code
    *	@DateSent
    *	@RefID
    *
    * OUTPUT PARAMETERS
    *	None.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PMCo bCompany, @Project bJob, @Type bDocType, @Code bDocument, @DateSent bDate, @RefID bigint, @msg varchar(255) output)
	AS
	BEGIN
	
		SET NOCOUNT ON

		IF @PMCo IS NULL OR @Project IS NULL OR @Type IS NULL OR @Code IS NULL OR @DateSent IS NULL OR @RefID IS NULL
		BEGIN
			SET @msg = 'The Company, Project, Type, Code, DateSent, and RefID must be supplied. Please contact Viewpoint Customer Support.'
			RETURN 1
		END

		DECLARE @VendorGroup bGroup
		DECLARE @PrefMethod char
		DECLARE @LastSeq tinyint

		--Get Last Sequence
		SELECT @LastSeq = ISNULL(MAX(Seq),0) FROM PMDistribution
		WHERE PMCo = @PMCo
		AND Project = @Project
		AND InspectionType = @Type
		AND InspectionCode = @Code

		--Pull Vendor Group
		SELECT @VendorGroup = VendorGroup FROM PMCO
		WHERE PMCO.PMCo = @PMCo

		--Pull PrefMethod
		SELECT @PrefMethod = PrefMethod FROM PMPM
		WHERE VendorGroup = @VendorGroup

		INSERT INTO PMDistribution
		(PMCo, Project, InspectionType, InspectionCode, Seq, VendorGroup, SentToFirm, SentToContact
		,DateSent, InspectionLogID, [Send], PrefMethod, CC) 

		--Pull Firms and Contacts to Enter
		SELECT	@PMCo 'PMCo', @Project 'Project', @Type 'Type'
		, @Code 'Code', @LastSeq + ROW_NUMBER() OVER(ORDER BY @PMCo) 'Seq', @VendorGroup 'VendorGroup'
		, ppdd.FirmNumber 'SentToFirm', ppdd.ContactCode 'SentToContact'
		, @DateSent 'DateSent', @RefID 'RefID'
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
		AND dc.DocType = @Type
		--Ignore adding defaults that already exist in table
		AND NOT EXISTS(	SELECT TOP 1 1 FROM dbo.vPMDistribution 
						WHERE PMCo=@PMCo AND Project=@Project 
						AND VendorGroup=@VendorGroup AND SentToFirm=ppdd.FirmNumber 
						AND SentToContact=ppdd.ContactCode AND InspectionType=@Type 
						AND InspectionCode=@Code)

	END
GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMDistributionForInspections] TO [public]
GO
