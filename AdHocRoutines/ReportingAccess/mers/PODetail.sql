use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME='mers')
BEGIN
	print 'SCHEMA ''mers'' already exists  -- McKinstry Enterprise Reporting Schema'
END
ELSE
BEGIN
	print 'CREATE SCHEMA ''mers'' -- McKinstry Enterprise Reporting Schema'
	EXEC sp_executesql N'CREATE SCHEMA mers AUTHORIZATION dbo'
END
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnPODetail')
begin
	print 'DROP FUNCTION mers.mfnPODetail'
	DROP FUNCTION mers.mfnPODetail
end
go

print 'CREATE FUNCTION mers.mfnPODetail'
GO


CREATE FUNCTION mers.mfnPODetail 
(	
	-- Declare Input Parameters
	@Company	bCompany = NULL
 ,	@POItemType	INT= NULL
 ,	@StartDate	SMALLDATETIME = null
 ,	@EndDate	SMALLDATETIME = null
)
RETURNS @retTable TABLE
(
	[POCo] [dbo].[bCompany]  NULL,
	[PO] [varchar](30)  NULL,
	[McKPO] [varchar](30) NULL,
	[PODesc] [dbo].[bItemDesc] NULL,
	[VendorGroup] [dbo].[bGroup]  NULL,
	[Vendor] [dbo].[bVendor]  NULL,
	[VendorName] [varchar](60) NULL,
	[OrderedBy] [int] NULL,
	[OrderedByName] [varchar](62) NULL,
	[PurchasingContact] [int] NULL,
	[PurchasingContactName] [varchar](62) NULL,
	[OrderDate] [dbo].[bDate] NULL,
	[OrderYear] AS  YEAR(OrderDate) ,
	[OrderMonth] AS  CAST(YEAR(OrderDate) AS VARCHAR(4)) + '-' + CAST(MONTH(OrderDate) AS VARCHAR(2)) ,
	[POGLDept] [char](20) NULL,
	[POGLDesc] [dbo].[bDesc] NULL,
	[POStatus] [varchar](13) NULL,
	[POItem] [dbo].[bItem] NULL,
	[POItemDesc] [dbo].[bItemDesc] NULL,
	[POItemType] [varchar](15) NULL,
	[GLCo] [dbo].[bCompany]  NULL,
	[GLAcct] [dbo].[bGLAcct]  NULL,
	[JCCo] [dbo].[bCompany] NULL,
	[Contract] [dbo].[bContract] NULL,
	[ContractDesc] [dbo].[bItemDesc] NULL,
	[ContractDept] [dbo].[bDept] NULL,
	[ContractGLDept] [char](20) NULL,
	[ContractGLDesc] [dbo].[bDesc] NULL,
	[ContractPOC] [dbo].[bProjectMgr] NULL,
	[ContractPOCName] [varchar](30) NULL,
	[ContractItem] [dbo].[bContractItem] NULL,
	[ContractItemDesc] [dbo].[bItemDesc] NULL,
	[ContractItemDept] [dbo].[bDept] NULL,
	[ContractItemGLDept] [char](20) NULL,
	[ContractItemGLDesc] [dbo].[bDesc] NULL,
	[Job] [dbo].[bJob] NULL,
	[CGCJob] [varchar](20) NULL,
	[JobDesc] [dbo].[bItemDesc] NULL,
	[JobProjectMgr] [int] NULL,
	[JobProjectMgrName] [varchar](30) NULL,
	[PhaseGroup] [dbo].[bGroup] NULL,
	[Phase] [dbo].[bPhase] NULL,
	[PhaseDesc] [dbo].[bItemDesc] NULL,
	[CostType] [dbo].[bJCCType] NULL,
	[SMWOType] [varchar](10) NULL,
	[SMWOTypeDesc] [varchar](8) NULL,
	[SMCo] [dbo].[bCompany] NULL,
	[SMServiceSite] [varchar](60) null,
	[SMWorkOrder] [int] NULL,
	[SMScope] [int] NULL,
	[OrigCost] [dbo].[bDollar]  NULL,
	[CurCost] [dbo].[bDollar]  NULL,
	[BOCost] [dbo].[bDollar]  NULL,
	[RecvdCost] [dbo].[bDollar]  NULL,
	[RemCost] [dbo].[bDollar]  NULL,
	[TotalCost] [dbo].[bDollar]  NULL,
	[TaxGroup] [dbo].[bGroup] NULL,
	[TaxCode] [dbo].[bTaxCode] NULL,
	[TotalTax] [dbo].[bDollar]  NULL,
	[PONotes] [varchar](max) NULL,
	[POItemNotes] [varchar](max) NULL,
	[RentalNumber] [varchar](32) NULL,
	[RentalOnDate] [dbo].[bDate] NULL,
	[RentalPlannedOffDate] [dbo].[bDate] NULL,
	[RentalActualOffDate] [dbo].[bDate] NULL
)

/*
	2015.03.03 LWO - Created

	Full enumeration of all Purchase Orders showing related information for Jobs, Contracts, Service Work Orders and GL associations.
	Does not directly address PO Item Types other than 1-Job, 3-Expense and 6-SM Work Orders.  Other types will be included by only include the related GL association.

*/
BEGIN

	IF @StartDate IS NULL
	BEGIN
		SELECT @StartDate = CAST(MIN(OrderDate) AS SMALLDATETIME) FROM POHD WHERE POCo < 100 AND ( POCo=@Company OR @Company IS NULL )
	END; 

	IF @EndDate IS NULL
	BEGIN 
		SELECT @EndDate = CAST(MAX(OrderDate) AS SMALLDATETIME) FROM POHD WHERE POCo < 100 AND ( POCo=@Company OR @Company IS NULL )
	END; 

	WITH podata AS 
	(
	SELECT
		pohd.POCo
	,	pohd.PO
	,	pohd.udMCKPONumber
	,	pohd.Description AS PODesc
	,	pohd.VendorGroup
	,	pohd.Vendor
	,	apvm.Name AS VendorName
	,	pohd.udPurchaseContact AS PurchasingContact
	,	CASE COALESCE(pmpm2.LastName + ', ','') +  COALESCE(pmpm2.FirstName,'') 
			WHEN '' THEN NULL
			ELSE COALESCE(pmpm2.LastName + ', ','') +  COALESCE(pmpm2.FirstName,'')
		END AS PurchasingContactName
	,	pohd.udOrderedBy AS OrderedBy
	,	CASE COALESCE(pmpm.LastName + ', ','') +  COALESCE(pmpm.FirstName,'') 
			WHEN '' THEN NULL
			ELSE COALESCE(pmpm.LastName + ', ','') +  COALESCE(pmpm.FirstName,'')
		END AS OrderedByName
	,	pohd.OrderDate
	,	CASE pohd.Status
			WHEN 0 THEN '0-Open'
			WHEN 1 THEN '1-Complete'
			WHEN 2 THEN '2-Closed'
			ELSE CAST(pohd.Status AS VARCHAR(5)) + '-Unknown'
		END AS POStatus
	,	poit.POItem
	,	poit.Description AS POItemDesc
	,	CASE poit.ItemType
			WHEN 1 THEN '1-Job'
			WHEN 2 THEN '2-Inventory'
			WHEN 3 THEN '3-Expense'
			WHEN 4 THEN '4-Equipment'
			WHEN 5 THEN '5-EM Work Order'
			WHEN 6 THEN '6-SM Work Order'
			ELSE CAST(poit.ItemType AS VARCHAR(5)) + '-Unknown'
		END AS POItemType
	,	smsite.Type AS SMWOType
	,	CASE
			WHEN poit.ItemType=6 AND smsite.Type='Job' THEN 'PM/SPG'
			WHEN poit.ItemType=6 AND smsite.Type<>'Job' THEN 'BreakFix'
			ELSE null
		END AS SMWOTypeDesc
	,	CASE
			WHEN smsite.Type='Job' THEN COALESCE(poit.JCCo,smsite.SMCo)
			ELSE poit.JCCo
		END AS JCCo
	,	COALESCE(poit.Job,smsite.Job) AS Job
	,	COALESCE(poit.PhaseGroup,poit.SMPhaseGroup) AS PhaseGroup
	,	COALESCE(poit.Phase,poit.SMPhase) AS Phase
	,	COALESCE(poit.JCCType,poit.SMJCCostType) AS CostType
	,	poit.SMCo AS SMCo
	,	smsite.Description AS SMServiceSite
	,	poit.SMWorkOrder AS SMWorkOrder
	,	poit.SMScope AS SMScope
	,	poit.GLCo AS GLCo
	,	poit.GLAcct AS GLAcct
	,	poit.OrigCost
	,	poit.CurCost
	,	poit.BOCost
	,	poit.RecvdCost
	,	poit.RemCost
	,	poit.TotalCost
	,	poit.TaxGroup
	,	poit.TaxCode
	,	poit.TotalTax
	,	pohd.Notes AS PONotes
	,	poit.Notes AS POItemNotes
	,	poit.udRentalNum AS RentalNumber
	,	poit.udOnDate AS RentalOnDate
	,	poit.udPlnOffDate AS RentalPlannedOffDate
	,	poit.udActOffDate AS RentalActualOffDate
	FROM 
		POHD pohd
	LEFT OUTER JOIN POIT poit ON 
		pohd.POCo=poit.POCo
	AND pohd.PO=poit.PO
	LEFT OUTER JOIN APVM apvm ON
		pohd.VendorGroup=apvm.VendorGroup
	AND pohd.Vendor=apvm.Vendor
	LEFT OUTER JOIN SMWorkCompleted smwo_wc ON
		poit.SMCo=smwo_wc.SMCo
	AND poit.SMWorkOrder=smwo_wc.WorkOrder
	AND poit.SMScope=smwo_wc.Scope
	AND poit.POItem=smwo_wc.POItem
	AND poit.POCo=smwo_wc.POCo
	AND poit.PO=smwo_wc.PO
	LEFT OUTER JOIN SMWorkOrder smwo ON
		smwo_wc.SMCo=smwo.SMCo
	AND smwo_wc.WorkOrder=smwo.WorkOrder
	LEFT OUTER JOIN SMServiceSite smsite ON
		smwo.SMCo=smsite.SMCo
	AND smwo.ServiceSite=smsite.ServiceSite
	LEFT OUTER JOIN PMPM1 pmpm ON
		pohd.udOrderedBy=pmpm.ContactCode
	AND pohd.VendorGroup=pmpm.VendorGroup
	AND pmpm.FirmNumber =  (SELECT TOP 1 PMCO.OurFirm FROM PMCO WHERE PMCo = pohd.POCo) 
	AND pmpm.ExcludeYN <> 'Y' 
	LEFT OUTER JOIN PMPM1 pmpm2 ON
		pohd.udPurchaseContact=pmpm2.ContactCode
	AND pohd.VendorGroup=pmpm2.VendorGroup
	AND pmpm2.FirmNumber =  (SELECT TOP 1 PMCO.OurFirm FROM PMCO WHERE PMCo = pohd.POCo) 
	AND pmpm2.ExcludeYN <> 'Y' 
	WHERE
		pohd.POCo<100
	AND ( pohd.POCo=@Company OR @Company IS NULL )
	AND ( poit.ItemType = @POItemType OR @POItemType IS NULL )
	--AND ( (@OpenOnlyYN IS NULL OR @OpenOnlyYN='N') OR (@OpenOnlyYN='Y' AND pohd.Status=CAST(REPLACE(@OpenOnlyYN,'Y','0') AS INT) ) )
	AND ( pohd.OrderDate >= @StartDate OR @StartDate is NULL )
	AND ( pohd.OrderDate <= @EndDate OR @EndDate is NULL )
	--AND poit.ItemType IN (1,2,3,6)
	)
	INSERT @retTable
           ([POCo]
           ,[PO]
           ,[McKPO]
           ,[PODesc]
           ,[VendorGroup]
           ,[Vendor]
           ,[VendorName]
		   ,[PurchasingContact]
		   ,[PurchasingContactName]
           ,[OrderedBy]
           ,[OrderedByName]
           ,[OrderDate]
           ,[POStatus]
           ,[POItem]
           ,[POItemDesc]
           ,[POItemType]
           ,[GLCo]
           ,[GLAcct]
           ,[POGLDept]
           ,[POGLDesc]
           ,[JCCo]
           ,[Contract]
           ,[ContractDesc]
           ,[ContractDept]
           ,[ContractGLDept]
           ,[ContractGLDesc]
           ,[ContractPOC]
           ,[ContractPOCName]
           ,[ContractItem]
           ,[ContractItemDesc]
           ,[ContractItemDept]
           ,[ContractItemGLDept]
           ,[ContractItemGLDesc]
           ,[Job]
           ,[CGCJob]
           ,[JobDesc]
           ,[JobProjectMgr]
           ,[JobProjectMgrName]
           ,[PhaseGroup]
           ,[Phase]
           ,[PhaseDesc]
           ,[CostType]
           ,[SMWOType]
           ,[SMWOTypeDesc]
           ,[SMCo]
		   ,[SMServiceSite]
           ,[SMWorkOrder]
           ,[SMScope]
           ,[OrigCost]
           ,[CurCost]
           ,[BOCost]
           ,[RecvdCost]
           ,[RemCost]
           ,[TotalCost]
           ,[TaxGroup]
           ,[TaxCode]
           ,[TotalTax]
           ,[PONotes]
           ,[POItemNotes]
           ,[RentalNumber]
           ,[RentalOnDate]
           ,[RentalPlannedOffDate]
           ,[RentalActualOffDate])
	SELECT
		podata.POCo
	,	podata.PO
	,	podata.udMCKPONumber AS McKPO
	,	podata.PODesc
	,	podata.VendorGroup
	,	podata.Vendor
	,	podata.VendorName
	,	podata.PurchasingContact
	,	podata.PurchasingContactName
	,	podata.OrderedBy
	,	podata.OrderedByName
	,	podata.OrderDate
	,	podata.POStatus
	,	podata.POItem
	,	podata.POItemDesc
	,	podata.POItemType
	,	podata.GLCo
	,	podata.GLAcct
	,	glpi_p.Instance AS POGLDept
	,	glpi_p.Description AS POGLDesc
	,	podata.JCCo
	,	jccm.Contract
	,	jccm.Description AS ContractDesc
	,	jccm.Department AS ContractDept
	,	glpi_c.Instance AS ContractGLDept
	,	glpi_c.Description AS ContractGLDesc
	,	jccm.udPOC AS ContractPOC
	,	jcmp_c.Name AS ContractPOCName
	,	jcci.Item AS ContractItem
	,	jcci.Description AS ContractItemDesc
	,	jcci.Department AS ContractItemDept
	,	glpi_i.Instance AS ContractItemGLDept
	,	glpi_i.Description AS ContractItemGLDesc
	,	podata.Job
	,	jcjm.udCGCJob AS CGCJob
	,	jcjm.Description AS JobDesc
	,	jcjm.ProjectMgr AS JobProjectMgr
	,	jcmp_j.Name AS JobProjectMgrName
	,	podata.PhaseGroup
	,	podata.Phase
	,	jcjp.Description AS PhaseDesc
	,	podata.CostType
	--,	jcct.Abbreviation AS CostTypeCode
	--,	jcct.Description AS CostTypeDesc
	,	podata.SMWOType
	,	podata.SMWOTypeDesc
	,	podata.SMCo
	,	podata.SMServiceSite
	,	podata.SMWorkOrder
	,	podata.SMScope
	,	podata.OrigCost
	,	podata.CurCost
	,	podata.BOCost
	,	podata.RecvdCost
	,	podata.RemCost
	,	podata.TotalCost
	,	podata.TaxGroup
	,	podata.TaxCode
	,	podata.TotalTax
	,	podata. PONotes
	,	podata.POItemNotes
	,	podata.RentalNumber
	,	podata.RentalOnDate
	,	podata.RentalPlannedOffDate
	,	podata.RentalActualOffDate
	FROM 
		podata podata 
	LEFT OUTER JOIN JCJP jcjp ON
		podata.JCCo=jcjp.JCCo
	AND podata.Job=jcjp.Job
	AND podata.PhaseGroup=jcjp.PhaseGroup
	AND podata.Phase=jcjp.Phase
	LEFT OUTER JOIN JCCI jcci ON
		jcjp.JCCo=jcci.JCCo
	AND jcjp.Contract=jcci.Contract
	AND jcjp.Item=jcci.Item
	LEFT OUTER JOIN JCCM jccm ON
		jcci.JCCo=jccm.JCCo
	AND jcci.Contract=jccm.Contract
	LEFT OUTER JOIN JCJM jcjm ON
		jccm.JCCo=jcjm.JCCo
	AND jccm.Contract=jcjm.Contract
	AND jcjm.JCCo=jcjp.JCCo
	AND jcjm.Job=jcjp.Job
	LEFT OUTER JOIN  JCCT jcct ON
		podata.PhaseGroup=jcct.PhaseGroup
	AND	podata.CostType=jcct.CostType
	LEFT OUTER JOIN JCMP jcmp_c ON
		jccm.JCCo=jcmp_c.JCCo
	AND jccm.udPOC=jcmp_c.ProjectMgr
	LEFT OUTER JOIN JCMP jcmp_j ON
		jcjm.JCCo=jcmp_j.JCCo
	AND jcjm.ProjectMgr=jcmp_j.ProjectMgr
	LEFT OUTER JOIN JCDM jcdm_c ON
		jccm.JCCo=jcdm_c.JCCo
	AND jccm.Department=jcdm_c.Department
	LEFT OUTER JOIN GLPI glpi_c ON
		jcdm_c.GLCo=glpi_c.GLCo
	AND glpi_c.PartNo=3
	AND glpi_c.Instance=SUBSTRING(jcdm_c.OpenRevAcct,10,4)
	LEFT OUTER JOIN JCDM jcdm_i ON
		jcci.JCCo=jcdm_i.JCCo
	AND jcci.Department=jcdm_i.Department
	LEFT OUTER JOIN GLPI glpi_i ON
		jcdm_i.GLCo=glpi_i.GLCo
	AND glpi_i.PartNo=3
	AND glpi_i.Instance=SUBSTRING(jcdm_i.OpenRevAcct,10,4)
	LEFT OUTER JOIN GLPI glpi_p ON
		podata.GLCo=glpi_p.GLCo
	AND glpi_p.PartNo=3
	AND glpi_p.Instance=SUBSTRING(podata.GLAcct,10,4);

-- Clear Phase Groups for records with no Phases
UPDATE @retTable SET PhaseGroup=NULL WHERE Phase IS NULL


	RETURN 

END

GO

GRANT SELECT ON mers.mfnPODetail TO PUBLIC
go


SELECT * FROM mers.mfnPODetail (null,null,null,null) WHERE PO LIKE '%1-11229096%' ORDER BY OrderedByName, OrderDate


SELECT * FROM POHD WHERE PO  LIKE '%1-13071068%'




