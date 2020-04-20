SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForSCO]
/***********************************************************
* CREATED BY:	GF	03/01/2011
* MODIFIED BY:	
*
* USAGE:
* Pull records from project distribution defaults and add to new SubcontractCO record
*
*
* INPUT PARAMETERS
* @SubcontractCOID
*
* OUTPUT PARAMETERS
* None
*
* RETURN VALUE
*   0         Success
*   1         Failure or nothing to format
*****************************************************/
(@SubcontractCOID BIGINT = NULL, @msg varchar(255) output)
AS
BEGIN

SET NOCOUNT ON

declare @rcode INT

SET @rcode = 0

IF @SubcontractCOID IS NULL
	BEGIN
	SELECT @msg = 'Missing Subcontract CO record ID, cannot add project distribution defaults.', @rcode = 1
	RETURN
	END

---- insert distribtuion records
INSERT INTO dbo.PMDistribution (PMCo, Project, SLCo, SL, SubCO, Seq, VendorGroup,
				SentToFirm, SentToContact,DateSent, SubcontractCOID, Send, PrefMethod, CC) 
SELECT	subco.PMCo, subco.Project, subco.SLCo, subco.SL, subco.SubCO, 
		(0 + ROW_NUMBER() OVER(ORDER BY subco.PMCo ASC, subco.Project ASC, subco.SLCo, subco.SL)),
		--(0 + ROW_NUMBER() OVER(ORDER BY subco.PMCo)) 'Seq',
		SLHD.VendorGroup, ppdd.FirmNumber, ppdd.ContactCode,
		ISNULL(subco.Date, dbo.vfDateOnly()), @SubcontractCOID, 'Y', PMPM.PrefMethod,
		CASE WHEN PMPF.EmailOption <> 'N' THEN PMPF.EmailOption ELSE 'C' end
FROM dbo.PMProjDefDistDocType dc
INNER JOIN dbo.PMDT PMDT ON PMDT.DocCategory = 'SUBCO'
INNER JOIN dbo.PMSubcontractCO subco ON subco.KeyID = @SubcontractCOID
INNER JOIN dbo.SLHD SLHD ON SLHD.SLCo = subco.SLCo AND SLHD.SL = subco.SL
LEFT JOIN dbo.PMProjectDefaultDistributions ppdd ON ppdd.KeyID = dc.DefaultKeyID
LEFT JOIN PMPM ON PMPM.VendorGroup = SLHD.VendorGroup
		AND PMPM.FirmNumber = ppdd.FirmNumber AND PMPM.ContactCode = ppdd.ContactCode
LEFT JOIN dbo.PMPF ON PMPF.PMCo = subco.PMCo AND PMPF.Project = subco.Project
		AND PMPF.VendorGroup = SLHD.VendorGroup AND PMPF.FirmNumber = ppdd.FirmNumber
		AND PMPF.ContactCode = ppdd.ContactCode
WHERE ppdd.PMCo = subco.PMCo AND ppdd.Project = subco.Project AND dc.DocType = PMDT.DocType
AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=subco.PMCo
					AND dist.Project=subco.Project AND dist.VendorGroup=SLHD.VendorGroup
					AND dist.SentToFirm=ppdd.FirmNumber AND dist.SentToContact=ppdd.ContactCode
					AND dist.SLCo=subco.SLCo AND dist.SL = subco.SL AND dist.SubCO = subco.SubCO)
GROUP BY ppdd.FirmNumber, ppdd.ContactCode, PMPM.PrefMethod, PMPF.EmailOption,
		 subco.PMCo, subco.Project, subco.SLCo, subco.SL, subco.SubCO, SLHD.VendorGroup,
		 subco.Date



END

GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMDistributionForSCO] TO [public]
GO
