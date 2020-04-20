SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnGetWIPContractData_BillO](@JCCo tinyint,@Contract varchar(10))
RETURNS TABLE 
AS

RETURN
SELECT 
	jccm.JCCo
,	jccm.Contract
,	jccm.Description AS ContractDesc
,	jccm.udPOC AS ContractPOC
,	jcmp.Name AS ContractPOCName
,	jccm.Department AS ContractDepartment
,	cmdept.Description AS ContractDepartmentName
,	cmglpi.Instance AS ContractGLDepartment
,	cmglpi.Description AS ContractGLDepartmentName
,	jcci.Item AS ContractItem
,	jcci.Description AS ContractItemDescription
,	jcci.Department AS ContractItemDepartment
,	cidept.Description AS ContractItemDepartmentName
,	ciglpi.Instance AS ContractItemGLDepartment
,	ciglpi.Description AS ContractItemGLDepartmentName
,	jcci.OrigContractAmt
,	jcci.ContractAmt
,   jcci.BillOriginalAmt
,   jcci.BillCurrentAmt
,	jcci.CurrentRetainAmt
,	jcci.ReceivedAmt
--,	jcip.Mth AS ProjectionMonth
,	COALESCE(SUM(jcip.OrigContractAmt),0) AS ProjectedOrigContractAmount
,	COALESCE(SUM(jcip.BilledAmt),0) AS ProjectedBilledAmt
,	COALESCE(SUM(jcip.ContractAmt),0) AS ProjectedContractAmt
,	COALESCE(SUM(jcip.CurrentRetainAmt),0) AS ProjectedCurrentRetainAmt
,	COALESCE(SUM(jcip.ProjDollars),0) AS ProjectedProjDollars
,	COALESCE(SUM(jcip.ReceivedAmt),0) AS ProjectedReceivedAmt

FROM 
	JCCM jccm LEFT JOIN
	JCCI jcci ON
		jccm.JCCo=jcci.JCCo
	AND jccm.Contract=jcci.Contract LEFT JOIN
	JCDM cmdept ON
		jccm.JCCo=cmdept.JCCo
	AND jccm.Department=cmdept.Department LEFT JOIN
	JCDM cidept ON
		jcci.JCCo=cidept.JCCo
	AND jcci.Department=cidept.Department LEFT JOIN
	JCMP jcmp ON
		jccm.JCCo=jcmp.JCCo
	AND jccm.udPOC=jcmp.ProjectMgr LEFT JOIN
	GLPI cmglpi ON
		jccm.JCCo=cmglpi.GLCo
	AND cmglpi.PartNo=3
	AND cmglpi.Instance=SUBSTRING(cmdept.OpenRevAcct,10,4)  LEFT JOIN
	GLPI ciglpi ON
		jcci.JCCo=ciglpi.GLCo
	AND ciglpi.PartNo=3
	AND ciglpi.Instance=SUBSTRING(cidept.OpenRevAcct,10,4)  LEFT JOIN
	--dbo.mfnGetContractProjection(@JCCo,@Contract) jcip ON
	JCIP jcip ON
		jcip.JCCo=jcci.JCCo
	AND jcip.Contract=jcci.Contract	
	AND jcip.Item=jcci.Item	
WHERE
	(jccm.JCCo=@JCCo OR @JCCo IS NULL)
AND (LTRIM(RTRIM(jccm.Contract))=LTRIM(RTRIM(@Contract)) OR @Contract IS NULL)
GROUP BY
	jccm.JCCo
,	jccm.Contract
,	jccm.Description
,	jccm.udPOC 
,	jcmp.Name 
,	jccm.Department 
,	cmdept.Description 
,	cmglpi.Instance 
,	cmglpi.Description 
,	jcci.Item 
,	jcci.Description 
,	jcci.Department 
,	cidept.Description 
,	ciglpi.Instance 
,	ciglpi.Description 
,	jcci.OrigContractAmt
,	jcci.ContractAmt
,   jcci.BillOriginalAmt
,   jcci.BillCurrentAmt
,	jcci.CurrentRetainAmt
,	jcci.ReceivedAmt
--ORDER BY 
--	jcip.Mth

GO
