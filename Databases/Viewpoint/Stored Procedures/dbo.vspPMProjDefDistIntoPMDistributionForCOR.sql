SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
--CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForCOR]
CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForCOR]
/***********************************************************
* CREATED BY:	DAN SO	03/19/2011
* MODIFIED BY:	
*
* USAGE:
* Pull records from project distribution defaults and add to new COR record
*
*
* INPUT PARAMETERS
* @CORID	- Change Order Request IF
*
* OUTPUT PARAMETERS
* None
*
* RETURN VALUE
*   0         Success
*   1         Failure or nothing to format
*****************************************************/
(@CORID BIGINT = NULL, @msg varchar(255) output)
AS
BEGIN

SET NOCOUNT ON

declare @rcode INT

SET @rcode = 0

IF @CORID IS NULL
	BEGIN
	SELECT @msg = 'Missing Change Order Request record ID, cannot add project distribution defaults.', @rcode = 1
	RETURN
	END

---- insert distribtuion records
INSERT INTO dbo.PMDistribution (PMCo, Project, CORContract, COR, Seq, VendorGroup,
				SentToFirm, SentToContact, DateSent, CORID, Send, PrefMethod, CC) 
select cor.PMCo, jc.Project, cor.Contract, cor.COR,
		(0 + ROW_NUMBER() OVER(ORDER BY cor.PMCo ASC, cor.Contract ASC, cor.COR)),
		cor.VendorGroup, ppdd.FirmNumber, ppdd.ContactCode,
		ISNULL(cor.Date, dbo.vfDateOnly()), @CORID, 'Y', PMPM.PrefMethod,
		CASE WHEN PMPF.EmailOption <> 'N' THEN PMPF.EmailOption ELSE 'C' end
FROM dbo.PMProjDefDistDocType dc
INNER JOIN dbo.PMDT PMDT ON PMDT.DocCategory = 'COR'
INNER JOIN dbo.PMChangeOrderRequest cor ON cor.KeyID = @CORID
LEFT JOIN dbo.JCJMPM jc ON cor.PMCo=jc.PMCo and cor.Contract=jc.Contract
LEFT JOIN dbo.PMProjectDefaultDistributions ppdd ON ppdd.KeyID = dc.DefaultKeyID 
LEFT JOIN PMPM ON PMPM.VendorGroup = cor.VendorGroup
		AND PMPM.FirmNumber = ppdd.FirmNumber AND PMPM.ContactCode = ppdd.ContactCode
LEFT JOIN dbo.PMPF ON PMPF.PMCo = cor.PMCo AND PMPF.Project = jc.Project
		AND PMPF.VendorGroup = cor.VendorGroup AND PMPF.FirmNumber = ppdd.FirmNumber
		AND PMPF.ContactCode = ppdd.ContactCode
WHERE ppdd.PMCo = cor.PMCo AND ppdd.Project = jc.Project AND dc.DocType = PMDT.DocType
AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=cor.PMCo
					AND dist.Project=jc.Project AND dist.VendorGroup=cor.VendorGroup
					AND dist.SentToFirm=ppdd.FirmNumber AND dist.SentToContact=ppdd.ContactCode
					AND dist.CORContract=cor.Contract AND dist.COR = cor.COR)
GROUP BY ppdd.FirmNumber, ppdd.ContactCode, PMPM.PrefMethod, PMPF.EmailOption,
		 cor.PMCo, jc.Project, cor.Contract, cor.COR, cor.VendorGroup,
		 cor.Date



END

GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMDistributionForCOR] TO [public]
GO
