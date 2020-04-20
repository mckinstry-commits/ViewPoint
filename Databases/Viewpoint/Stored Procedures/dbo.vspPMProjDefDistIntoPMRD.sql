SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMProjDefDistIntoPMRD]
   
   /***********************************************************
    * CREATED BY:	JG	08/09/2010 - Issue #140529
    * MODIFIED BY:	
    *
    * USAGE:
    * Pull records from project distribution defaults and add to new RFI record
    *
    *
    * INPUT PARAMETERS
    *	@PCCo
    *	@Project
    *   @RFIType
    *	@RFI
    *	@DateSent
    *	@DateReqd
    *
    * OUTPUT PARAMETERS
    *	None.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PMCo bCompany, @Project bJob, @RFIType bDocType, @RFI bPCO, @DateSent bDate, @DateReqd bDate = null, @msg varchar(255) output)
	AS
	BEGIN
	
		SET NOCOUNT ON

		IF @PMCo IS NULL OR @Project IS NULL OR @RFIType IS NULL OR @RFI IS NULL OR @DateSent IS NULL
		BEGIN
			SET @msg = 'The Company, Project, RFIType, RFI, and Date Sent must be supplied. Please contact Viewpoint Customer Support.'
			RETURN 1
		END

		DECLARE @VendorGroup bGroup
		DECLARE @PrefMethod char
		DECLARE @LastSeq tinyint

		--Get Last Sequence
		SELECT @LastSeq = ISNULL(MAX(RFISeq),0) FROM PMRD
		WHERE PMCo = @PMCo
		AND Project = @Project
		AND RFIType = @RFIType
		AND RFI = @RFI

		--Pull Vendor Group
		SELECT @VendorGroup = VendorGroup FROM PMCO
		WHERE PMCO.PMCo = @PMCo

		--Pull PrefMethod
		SELECT @PrefMethod = PrefMethod FROM PMPM
		WHERE VendorGroup = @VendorGroup

		INSERT INTO PMRD
		(PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm, SentToContact
		, DateSent, DateReqd, [Send], PrefMethod, CC)
		
		--Pull Firms and Contacts to Enter
		SELECT	@PMCo 'PMCo', @Project 'Project', @RFIType 'RFIType'
		, @RFI 'RFI', @LastSeq + ROW_NUMBER() OVER(ORDER BY @PMCo) 'RFISeq', @VendorGroup 'VendorGroup'
		, ppdd.FirmNumber 'SentToFirm', ppdd.ContactCode 'SentToContact'
		, @DateSent 'DateSent', @DateReqd 'DateReqd'
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
		AND dc.DocType = @RFIType
		--Ignore adding defaults that already exist in table
		AND NOT EXISTS(	SELECT TOP 1 1 FROM dbo.PMRD
						WHERE PMCo=@PMCo AND Project=@Project 
						AND VendorGroup=@VendorGroup AND SentToFirm=ppdd.FirmNumber 
						AND SentToContact=ppdd.ContactCode AND RFIType=@RFIType 
						AND RFI=@RFI)

	END
GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMRD] TO [public]
GO
