SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		AW
-- Create date: 7/11/2013
-- Return default contacts for a given project / doc category / doc type
-- =============================================
CREATE FUNCTION [dbo].[vfPMProjectDefaultContacts]
(
	-- Add the parameters for the function here
	@PMCo bCompany,
	@Project bProject,
	@DocCat bDocType,
	@DocType varchar(10)
)
RETURNS TABLE 
AS
RETURN
	SELECT DISTINCT PMCO.PMCo,ppdd.Project,
		PMCO.VendorGroup, ppdd.FirmNumber, ppdd.ContactCode,
		--default print PrefMethod if null
		CASE WHEN PMPM.PrefMethod IS NULL THEN 'M' ELSE PMPM.PrefMethod END AS PrefMethod,
		--default cc if EmailOption is null
		CASE WHEN PMPF.EmailOption IS NOT NULL AND PMPF.EmailOption <> 'N' THEN PMPF.EmailOption ELSE 'C' end AS EmailOption
	FROM dbo.vPMProjectDefaultDocumentDistribution dc
		JOIN dbo.PMProjectDefaultDistributions ppdd ON ppdd.KeyID = dc.ContactKeyID
		JOIN dbo.PMCO on ppdd.PMCo = PMCO.PMCo and ppdd.PMCo = PMCO.PMCo
		LEFT JOIN PMPM ON PMPM.VendorGroup = PMCO.VendorGroup
				AND PMPM.FirmNumber = ppdd.FirmNumber AND PMPM.ContactCode = ppdd.ContactCode and ppdd.PMCo=PMCO.PMCo
		LEFT JOIN dbo.PMPF ON PMPF.PMCo = ppdd.PMCo AND PMPF.Project = ppdd.Project
				AND PMPF.VendorGroup = PMCO.VendorGroup AND PMPF.FirmNumber = ppdd.FirmNumber
				AND PMPF.ContactCode = ppdd.ContactCode
	WHERE ppdd.PMCo = @PMCo and ppdd.Project = @Project and dc.DocCategory = @DocCat and
		  (dc.DocType is null or dc.DocType = dbo.vfToString(@DocType))
GO
GRANT SELECT ON  [dbo].[vfPMProjectDefaultContacts] TO [public]
GO
