USE Viewpoint
go

alter PROCEDURE mspPurchaseOrderTimecardSummary
(
	@StartDate  SMALLDATETIME
,	@EndDate	SMALLDATETIME
)

AS

/*

Need to determine which Jobs and Service PM Jobs and exclude from PO List.

Exclude based on Job Department
*/

--PRINT
--	'Purchase Orders OrderedDate : '
--+	CAST(DATEADD(day,-6,@Weekending) AS VARCHAR(20))
--+	' through '
--+	CAST(@Weekending AS VARCHAR(20))
	
	
SELECT distinct
	pohd.POCo 
,	pohd.PO AS PORequisition
,	pohd.udMCKPONumber AS PONumber
,	pohd.Description AS PODescription
,	SUM(poit.TotalCost) AS POTotal
,	pohd.OrderedBy
,	pohd.udPurchaseContact AS PurchasingContact -- Join to PM Firm Contacts
,	pmpm.LastName
,	pmpm.FirstName
,	pohd.OrderDate
,	poit.POItem
,	poit.JCCo
,	poit.Job
,	poit.PhaseGroup
,	poit.Phase
,	poit.GLCo
,	poit.GLAcct
,	poit.JCCType AS CostType
,	jcjm.Contract
,	jcjp.Item AS ContractItem
,	jcci.udProjDelivery AS ContractItemDeliveryType
,	jcci.Department AS JCDept
,	jcdm.Description AS JCDeptDesc
,	glpi.Instance AS GLDepartmentNumber
,	glpi.Description AS GLDepartmentName
,	pohd.Notes AS PONotes
FROM 
	HQCO hqco join
	POHD pohd ON
		pohd.POCo=hqco.HQCo
	AND hqco.udTESTCo <> 'Y' LEFT OUTER JOIN
	POIT poit ON
		pohd.POCo=poit.POCo
	AND pohd.PO=poit.PO JOIN
	JCCH jcch ON
		poit.JCCo=jcch.JCCo
	AND poit.Job=jcch.Job
	AND poit.PhaseGroup=jcch.PhaseGroup
	AND poit.JCCType=jcch.CostType LEFT OUTER JOIN	
	JCJP jcjp ON
		jcjp.JCCo=jcch.JCCo
	AND jcjp.Job=jcch.Job 
	AND jcjp.PhaseGroup = jcch.PhaseGroup 
	AND jcjp.Phase = jcch.Phase 
	AND jcjp.JCCo=poit.JCCo
	AND jcjp.PhaseGroup = poit.PhaseGroup
	AND jcjp.Phase = poit.Phase LEFT OUTER JOIN	
	JCJM jcjm ON
		jcjm.JCCo=jcjp.JCCo
	AND jcjm.Job=jcjp.Job LEFT OUTER JOIN
	JCCI jcci ON
		jcci.JCCo=jcch.JCCo
	AND jcci.Contract=jcjp.Contract
	AND jcci.Item=jcjp.Item	
	AND jcjp.JCCo=jcci.JCCo
	AND jcjp.Contract=jcci.Contract
	AND jcjp.Item=jcci.Item LEFT OUTER JOIN
	JCDM jcdm ON
		jcci.JCCo=jcdm.JCCo
	AND jcci.Department=jcdm.Department LEFT OUTER JOIN
	GLPI glpi ON
		jcdm.GLCo=glpi.GLCo
	AND glpi.PartNo=3
	AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) JOIN
	PMCO pmco ON 
		pohd.POCo=pmco.PMCo	LEFT OUTER JOIN
	PMPM1 pmpm ON
		pohd.udPurchaseContact=pmpm.ContactCode
	AND pmco.VendorGroup=pmpm.VendorGroup
WHERE
	pohd.OrderDate >= @StartDate AND pohd.OrderDate < DATEADD(day,1,@EndDate)
--AND poit.SMWorkOrder IS NULL
--AND poit.Job IS NOT null
GROUP BY
	pohd.POCo 
,	pohd.PO 
,	pohd.udMCKPONumber 
,	pohd.OrderedBy
,	pohd.udPurchaseContact -- Join to PM Firm Contacts
,	pmpm.LastName
,	pmpm.FirstName
,	pohd.OrderDate
,	poit.POItem
,	poit.JCCo
,	poit.Job
,	poit.PhaseGroup
,	poit.Phase
,	poit.GLCo
,	poit.GLAcct
,	poit.JCCType 
,	jcjm.Contract
,	jcjp.Item 
,	jcci.udProjDelivery 
,	jcci.Department
,	jcdm.Description 
,	glpi.Instance 
,	glpi.Description 
,	pohd.Description 
,	pohd.Notes 
ORDER BY 
	pohd.POCo
,	glpi.Instance
,	pohd.udMCKPONumber

go


--EXEC mspPurchaseOrderTimecardSummary @Weekending='10/26/2014'
--EXEC mspPurchaseOrderTimecardSummary @Weekending='11/2/2014'


SELECT * FROM dbo.mvwRLBARExport WHERE InvoiceNumber IS NOT null