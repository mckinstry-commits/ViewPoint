SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMProjectDefaultDistributionsFill]
   
   /***********************************************************
    * CREATED BY:	JG	07/28/2010 - Issue #140529
    * MODIFIED BY:	JG	05/17/2011 - TK-05263 - Added Doc Category
	*               AW  01/03/2013 - TK-20502 - Ignore SBMTL & SBMTLPCKG types no distribution tables
    *
    * USAGE:
    * Return dataset to fill list view in PMProjectDefaultDistributions
    *
    *
    * INPUT PARAMETERS
    *	@PCCo
    *	@Project
    *   @FirmNumber
    *	@ContactCode
    *
    * OUTPUT PARAMETERS
    *	Dataset containing DocTypes, Descriptions, and Defaults.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PMCo bCompany, @Project bJob, @FirmNumber bFirm, @ContactCode bEmployee, @msg varchar(255) output)
	AS
	BEGIN
	
		SET NOCOUNT ON

		IF @PMCo IS NULL OR @Project IS NULL OR @FirmNumber IS NULL OR @ContactCode IS NULL
		BEGIN
			SET @msg = 'The company, project, firm, and contact must be supplied'
			RETURN 1
		END

		SELECT ss.KeyID, PMDT.DocCategory, PMDT.DocType, PMDT.[Description]
		FROM PMDT
			LEFT JOIN 
					(SELECT * 
					FROM dbo.vPMProjectDefaultDistributions AS dd
						LEFT JOIN dbo.vPMProjDefDistDocType
						ON KeyID = DefaultKeyID
							WHERE PMCo = @PMCo
							AND Project = @Project
							AND FirmNumber = @FirmNumber
							AND ContactCode = @ContactCode) AS ss
			ON PMDT.DocType = ss.DocType
		-- Ignore new doc types for submittals and submittal packages they don't have distribution tables predefined.
		WHERE PMDT.DocCategory not in ('SBMTLPCKG','SBMTL')
		ORDER BY PMDT.DocCategory			
	END
GO
GRANT EXECUTE ON  [dbo].[vspPMProjectDefaultDistributionsFill] TO [public]
GO
