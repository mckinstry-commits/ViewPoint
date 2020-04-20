SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForCCO]
/***********************************************************
* CREATED BY:	JG	05/16/2011
* MODIFIED BY:	TRL 07/29/2008 TK-07037 rename ContractCO to ID
*
* USAGE:
* Pull records from project distribution defaults and add to new CCO record
*
*
* INPUT PARAMETERS
* @ContractCOID	- Contract Change Order IF
*
* OUTPUT PARAMETERS
* None
*
* RETURN VALUE
*   0         Success
*   1         Failure or nothing to format
*****************************************************/
(@ContractCOID BIGINT = NULL, @msg varchar(255) output)
AS
BEGIN

SET NOCOUNT ON

declare @rcode INT

SET @rcode = 0

IF @ContractCOID IS NULL
	BEGIN
	SELECT @msg = 'Missing Contract Change Order record ID, cannot add project distribution defaults.', @rcode = 1
	RETURN
	END

---- insert distribtuion records
INSERT INTO dbo.PMDistribution (PMCo, Project, [Contract], ID, Seq, VendorGroup,
				SentToFirm, SentToContact, DateSent, ContractCOID, Send, PrefMethod, CC) 
select cco.PMCo, jc.Project, cco.Contract, cco.ID,
		(0 + ROW_NUMBER() OVER(ORDER BY cco.PMCo ASC, cco.Contract ASC, cco.ID)),
		cco.VendorGroup, ppdd.FirmNumber, ppdd.ContactCode,
		ISNULL(cco.Date, dbo.vfDateOnly()), @ContractCOID, 'Y', PMPM.PrefMethod,
		CASE WHEN PMPF.EmailOption <> 'N' THEN PMPF.EmailOption ELSE 'C' end
FROM dbo.PMProjDefDistDocType dc
INNER JOIN dbo.PMDT PMDT ON PMDT.DocCategory = 'CCO'
INNER JOIN dbo.PMContractChangeOrder cco ON cco.KeyID = @ContractCOID
LEFT JOIN dbo.JCJMPM jc ON cco.PMCo=jc.PMCo and cco.Contract=jc.Contract
LEFT JOIN dbo.PMProjectDefaultDistributions ppdd ON ppdd.KeyID = dc.DefaultKeyID 
LEFT JOIN PMPM ON PMPM.VendorGroup = cco.VendorGroup
		AND PMPM.FirmNumber = ppdd.FirmNumber AND PMPM.ContactCode = ppdd.ContactCode
LEFT JOIN dbo.PMPF ON PMPF.PMCo = cco.PMCo AND PMPF.Project = jc.Project
		AND PMPF.VendorGroup = cco.VendorGroup AND PMPF.FirmNumber = ppdd.FirmNumber
		AND PMPF.ContactCode = ppdd.ContactCode
WHERE ppdd.PMCo = cco.PMCo AND ppdd.Project = jc.Project AND dc.DocType = PMDT.DocType
AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=cco.PMCo
					AND dist.Project=jc.Project AND dist.VendorGroup=cco.VendorGroup
					AND dist.SentToFirm=ppdd.FirmNumber AND dist.SentToContact=ppdd.ContactCode
					AND dist.Contract=cco.Contract AND dist.ID = cco.ID)
GROUP BY ppdd.FirmNumber, ppdd.ContactCode, PMPM.PrefMethod, PMPF.EmailOption,
		 cco.PMCo, jc.Project, cco.Contract, cco.ID, cco.VendorGroup,
		 cco.Date



END

GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMDistributionForCCO] TO [public]
GO
