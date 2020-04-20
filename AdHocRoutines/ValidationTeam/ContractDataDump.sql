USE Viewpoint
go

DECLARE @Contract bContract
--SET @Contract = '100710-'
--SET @Contract = '200223-'
SET @Contract = ' 22896-'

select
	'Contract' AS Type
,	jccm.JCCo
,	jccm.Contract
,	jccm.Description AS ContractDesc
,	jccm.StartDate
,	jccm.ProjCloseDate
,	jccm.Department AS ContractDepartment
,	jcdm.Description AS ContractDepartmentName
,	jccm.DefaultBillType
,	jccm.udPrimeYN
,	jccm.udSubstantiation
,	jccm.OrigContractAmt
,	jccm.ContractAmt
,	jccm.udPOC
,	jcmp.Name AS POCName
from
	JCCM jccm LEFT OUTER JOIN
	JCDM jcdm ON
		jccm.JCCo=jcdm.JCCo
	AND jccm.Department=jcdm.Department LEFT OUTER JOIN
	JCMP jcmp ON
		jccm.JCCo=jcmp.JCCo
	and	jccm.udPOC=jcmp.ProjectMgr
WHERE
	Contract=@Contract

SELECT 
	'ContractAdmin' AS Type
,	*
FROM 
	udContractAdminLeg
WHERE
	Contract=@Contract

SELECT 
	'ContractItem' AS Type
,	jcci.JCCo
,	jcci.Contract
,	jcci.Item
,	jcci.Description AS ContractItemDesc
,	jcci.StartMonth
,	jcci.Department AS ContractDepartment
,	jcdm.Description AS ContractDepartmentName
,	jcci.udProjDelivery
,	jcci.udRevType
,	jcci.OrigContractAmt
,	jcci.ContractAmt
FROM 
	JCCI jcci JOIN
	JCDM jcdm ON
		jcci.JCCo=jcdm.JCCo
	AND jcci.Department=jcdm.Department
WHERE
	jcci.Contract=@Contract

SELECT
	'Project' AS Type
,	jcjm.JCCo
,	jcjm.Contract
,	jcjm.Job
,	jcjm.Description AS JobDesc
,	jcjm.udProjSummary
,	jcjm.udHardcardYN
,	jcjm.udProjStart
,	jcjm.udProjEnd
,	jcjm.ShipAddress
,	jcjm.ShipAddress2
,	jcjm.ShipCity
,	jcjm.ShipState
,	jcjm.ShipZip
,	jcjm.OurFirm
,	pmfm.FirmName
,	jcjm.udCRMNum
,	jcjm.udProjWrkstrm
,	jcjm.ProjectMgr
,	jcmp.Name AS POCName
from 
	JCJM jcjm LEFT OUTER JOIN
	dbo.PMFM pmfm ON
		jcjm.OurFirm=pmfm.FirmNumber
	AND jcjm.VendorGroup=pmfm.VendorGroup LEFT OUTER JOIN
	JCMP jcmp ON
		jcjm.JCCo=jcmp.JCCo
	and	jcjm.ProjectMgr=jcmp.ProjectMgr
WHERE
	jcjm.Contract=@Contract


SELECT
	'ProjectReviewer' AS Type
,	jcjm.JCCo
,	jcjm.Contract
,	jcjm.Job
,	jcjm.Description AS JobDesc
,	jcjr.*
FROM
	JCJM jcjm JOIN
	JCJR jcjr ON
		jcjm.JCCo=jcjr.JCCo
	AND jcjm.Job=jcjr.Job
WHERE
	jcjm.Contract=@Contract