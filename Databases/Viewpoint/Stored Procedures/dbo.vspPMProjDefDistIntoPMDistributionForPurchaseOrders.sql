SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE proc [dbo].[vspPMProjDefDistIntoPMDistributionForPurchaseOrders]
/***********************************************************
* CREATED BY:	TRL	01/02/2013  TK-20499  Created stored procedure
* MODIFIED BY:	
*
* USAGE:
* Pull records from project distribution defaults and add to new Purchase Order record
*
*
* INPUT PARAMETERS
* @PurchaseOrder_ID 
*
* OUTPUT PARAMETERS
* None
*
* RETURN VALUE
*   0         Success
*   1         Failure or nothing to format
*****************************************************/
(@PurchaseOrder_ID BIGINT = NULL, @msg varchar(255) output)
AS

SET NOCOUNT ON

IF @PurchaseOrder_ID IS NULL
BEGIN
	SELECT @msg = 'Missing Purchase Order record ID, cannot add project distribution defaults.'
	RETURN 1
END

INSERT INTO PMDistribution (PurchaseOrderID,PMCo, Project, POCo, PO, Seq, VendorGroup, SentToFirm, SentToContact, [Send], PrefMethod, CC, DateSent) 
SELECT @PurchaseOrder_ID 'PurchaseOrderID', POHDPM.PMCo 'PMCo', POHDPM.Project 'Project', 
POHDPM.POCo 'POCo',POHDPM.PO 'PO', (0 + ROW_NUMBER() OVER(ORDER BY POHDPM.PMCo, POHDPM.Project, POHDPM.POCo,POHDPM.PO)) 'Seq', 
POHDPM.VendorGroup 'VendorGroup', ppdd.FirmNumber 'SentToFirm', ppdd.ContactCode 'SentToContact','Y' 'Send', PMPM.PrefMethod, 
CASE WHEN PMPF.EmailOption <> 'N' THEN PMPF.EmailOption ELSE 'C' end, ISNULL(POHDPM.OrderDate, dbo.vfDateOnly()) 'DateSent'
FROM dbo.PMProjDefDistDocType dc
/*Why the join statement to PMDT.DocCategory is hard coded .
1.  Stored procedure vspPMCTInitialize initializes PM Document Categories "PO" and "PURCHASE".
2.  PM Document Type Form;  Doc Category column value validates "PO".  This value comes from 
DD Combo Box "PMDocCategory" which has combox item Purchase Order Change Order with a value of "PO".
3.  PM PO Change Order form Doc Category value is hard coded = "PURCHASE".   
4.  PM Projects (Firm Tab)/(Task Button (Assign Distribution Defaults) program which updates 
PMProjDefDistDocType Doc Category with a Value of "PO".
5.  The hard code value links the two values together and allows the distribution records to be created.
6.  Doc Category Valiation procedures will always validate "PO" and "PURCHASE" has valid document types.
7.  PM Send Search Documents, PMSendDocuments, PM Create and Send Settings are coded to use "PURCHASE".
8.  Currently (1/2/2013), any customer that has created a custom template using PO or POCO from PM Create and Send Settings
will not be listed using the new PM Send Message forms.  The customer should change the template to use PURCHASE.*/
INNER JOIN dbo.PMDT ON PMDT.DocCategory = 'PO'
INNER JOIN dbo.POHDPM ON POHDPM.KeyID = @PurchaseOrder_ID
INNER JOIN dbo.PMProjectDefaultDistributions ppdd ON ppdd.KeyID = dc.DefaultKeyID
LEFT JOIN dbo.PMPM ON PMPM.VendorGroup = POHDPM.VendorGroup AND PMPM.FirmNumber = ppdd.FirmNumber AND PMPM.ContactCode = ppdd.ContactCode
LEFT JOIN dbo.PMPF ON PMPF.PMCo = POHDPM.PMCo AND PMPF.Project = POHDPM.Project 	AND PMPF.VendorGroup = POHDPM.VendorGroup 
				AND PMPF.FirmNumber = ppdd.FirmNumber	AND PMPF.ContactCode = ppdd.ContactCode
WHERE  ppdd.PMCo = POHDPM.PMCo AND ppdd.Project = POHDPM.Project AND dc.DocType = PMDT.DocType
AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE 
					dist.PMCo=POHDPM.PMCo AND dist.Project=POHDPM.Project  AND
					dist.POCo=POHDPM.POCo AND dist.PO = POHDPM.PO AND dist.VendorGroup=POHDPM.VendorGroup AND 
					dist.SentToFirm=ppdd.FirmNumber AND 	dist.SentToContact=ppdd.ContactCode)
GROUP BY POHDPM.PMCo, POHDPM.Project, POHDPM.POCo, POHDPM.PO, POHDPM.VendorGroup,
		ppdd.FirmNumber, ppdd.ContactCode, PMPM.PrefMethod, PMPF.EmailOption, POHDPM.OrderDate

GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistIntoPMDistributionForPurchaseOrders] TO [public]
GO
