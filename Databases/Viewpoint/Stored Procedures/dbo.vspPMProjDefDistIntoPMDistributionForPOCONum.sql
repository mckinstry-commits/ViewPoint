SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForPOCONum]
/***********************************************************
* CREATED BY:	TRL	04/04/2011
* MODIFIED BY:	TRL  01/03/2013  TK-20499 Updated and hooked up code
*
* USAGE:
* Pull records from project distribution defaults and add to new Purchase Order CO record
*
*
* INPUT PARAMETERS
* @POCONumID
*
* OUTPUT PARAMETERS
* None
*
* RETURN VALUE
*   0         Success
*   1         Failure or nothing to format
*****************************************************/
(@POCOID BIGINT = NULL, @msg varchar(255) output)

AS

SET NOCOUNT ON

IF @POCOID IS NULL
BEGIN
	SELECT @msg = 'Missing Purchase Order CO record ID, cannot add project distribution defaults.'
	RETURN 1
END

---- insert distribtuion records
INSERT INTO dbo.PMDistribution(POCOID,PMCo, Project, POCo, PO, POCONum, Seq, VendorGroup,SentToFirm, SentToContact, [Send], PrefMethod, CC, DateSent) 
SELECT @POCOID 'POCOID',  PMPOCO.PMCo, PMPOCO.Project, PMPOCO.POCo, PMPOCO.PO, PMPOCO.POCONum, 
(0 + ROW_NUMBER() OVER(ORDER BY PMPOCO.PMCo, PMPOCO.Project, PMPOCO.POCo,PMPOCO.PO, PMPOCO.POCONum))'Seq',
POHD.VendorGroup, ppdd.FirmNumber'SentToFirm', ppdd.ContactCode'SentToContact', 'Y' 'Send', PMPM.PrefMethod, 
CASE WHEN PMPF.EmailOption <> 'N' THEN PMPF.EmailOption ELSE 'C' end,ISNULL(PMPOCO.[Date], dbo.vfDateOnly())'DateSent' 
FROM dbo.PMProjDefDistDocType dc
/*Why the join statement to PMDT.DocCategory is hard coded .
1.  Stored procedure vspPMCTInitialize initializes PM Document Categories "POCO" and "PURCHASECO".
2.  PM Document Type Form;  Doc Category column value validates "POCO".  This value comes from 
DD Combo Box "PMDocCategory" which has combox item Purchase Order Change Order with a value of "POCO".
3.  PM PO Change Order form Doc Category value is hard coded = "PURCHASECO".   
4.  PM Projects (Firm Tab)/(Task Button (Assign Distribution Defaults) program which updates 
PMProjDefDistDocType Doc Category with a Value of "POCO".
5.  The hard code value links the two values together and allows the distribution records to be created.
6.  Doc Category Valiation procedures will always validate "POCO" and "PURCHASECO" has valid document types.
7.  PM Send Search Documents, PMSendDocuments, PM Create and Send Settings are coded to use "PURCHASECO".
8.  Currently (1/2/2013), any customer that has created a custom template using PO or POCO from PM Create and Send Settings
will not be listed using the new PM Send Search Documents Message forms.  The customer should change the template to use PURCHASECO.*/
INNER JOIN dbo.PMDT ON PMDT.DocCategory = 'POCO'
INNER JOIN dbo.PMPOCO  ON PMPOCO.KeyID = @POCOID
INNER JOIN dbo.POHD ON POHD.POCo = PMPOCO.POCo AND POHD.PO = PMPOCO.PO
INNER JOIN dbo.PMProjectDefaultDistributions ppdd ON ppdd.KeyID = dc.DefaultKeyID
LEFT JOIN dbo.PMPM ON PMPM.VendorGroup = POHD.VendorGroup AND PMPM.FirmNumber = ppdd.FirmNumber AND PMPM.ContactCode = ppdd.ContactCode
LEFT JOIN dbo.PMPF ON PMPF.PMCo = PMPOCO.PMCo AND PMPF.Project = PMPOCO.Project AND PMPF.VendorGroup = POHD.VendorGroup 
				AND PMPF.FirmNumber = ppdd.FirmNumber AND PMPF.ContactCode = ppdd.ContactCode
WHERE ppdd.PMCo = PMPOCO.PMCo AND ppdd.Project = PMPOCO.Project AND dc.DocType = PMDT.DocType
AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE 
					dist.PMCo=PMPOCO.PMCo AND dist.Project=PMPOCO.Project AND 
					dist.POCo=PMPOCO.POCo AND dist.PO = PMPOCO.PO AND dist.POCONum = PMPOCO.POCONum AND
					dist.VendorGroup=POHD.VendorGroup AND dist.SentToFirm=ppdd.FirmNumber AND dist.SentToContact=ppdd.ContactCode)
GROUP BY  PMPOCO.PMCo,PMPOCO.Project, PMPOCO.POCo, PMPOCO.PO, PMPOCO.POCONum, POHD.VendorGroup,
			ppdd.FirmNumber, ppdd.ContactCode, PMPM.PrefMethod, PMPF.EmailOption,PMPOCO.[Date]


GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMDistributionForPOCONum] TO [public]
GO
