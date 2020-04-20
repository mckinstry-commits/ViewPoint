SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  FUNCTION [dbo].[mfnGetWIPJobDataDetail](@JCCo tinyint,@Contract varchar(10))
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
,	jcci.OrigContractAmt / COUNT(jcjp.KeyID) AS OrigContractAmount
,	jcci.ContractAmt / COUNT(jcjp.KeyID) AS ContractAmt
,   jcci.BillOriginalAmt / COUNT(jcjp.KeyID) AS BillOriginalAmt
,   jcci.BillCurrentAmt / COUNT(jcjp.KeyID) AS BillCurrentAmt
,	jcci.CurrentRetainAmt / COUNT(jcjp.KeyID) AS CurrentRetainAmt
,	jcci.ReceivedAmt / COUNT(jcjp.KeyID) AS ReceivedAmt
,	jcjm.Job 
,	jcjm.Description AS JobDescription
,	jcjp.Phase
,	jcjp.Description AS PhaseDescription
--,	COALESCE(jcch.CostType,0) AS CostType
,	COALESCE(jcct.Abbreviation,'X') AS CostTypeAbbr
,	COALESCE(jcct.Description,'None') AS CostTypeDescrption
--,	jccp.Mth AS ProjectionMonth
--,	COALESCE(SUM(jcch.OrigCost)/COUNT(jcjp.KeyID),0) AS JCOrigCost
,	COALESCE(SUM(jccp.ActualCost)/COUNT(jcjp.KeyID),0) AS JCActualCost
,	COALESCE(SUM(jccp.CurrEstCost)/COUNT(jcjp.KeyID),0) AS JCCurrEstCost
,	COALESCE(SUM(jccp.ForecastCost)/COUNT(jcjp.KeyID),0) AS JCForecastCost
,	COALESCE(SUM(jccp.OrigEstCost)/COUNT(jcjp.KeyID),0) AS JCOrigEstCost
,	COALESCE(SUM(jccp.ProjCost)/COUNT(jcjp.KeyID),0) AS JCProjCost
,	COALESCE(SUM(jccp.RecvdNotInvcdCost)/COUNT(jcjp.KeyID),0) AS JCRecvdNotInvcdCost
,	COALESCE(SUM(jccp.RemainCmtdCost)/COUNT(jcjp.KeyID),0) AS JCRemainCmtdCost
,	COALESCE(SUM(jccp.TotalCmtdCost)/COUNT(jcjp.KeyID),0) AS JCTotalCmtdCost
--,	CASE jcip.ReceivedAmt WHEN 0 THEN jcci.ReceivedAmt ELSE jcip.ReceivedAmt END AS ProjectedReceivedAmt
FROM 
	JCJM jcjm LEFT JOIN
	JCJP jcjp ON
		jcjm.JCCo=jcjp.JCCo
	AND jcjm.Job=jcjp.Job LEFT JOIN
	JCCI jcci ON
		jcjp.JCCo=jcci.JCCo
	AND jcjp.Contract=jcci.Contract 
	AND jcjp.Item=jcci.Item LEFT JOIN
	JCCM jccm ON
		jcci.JCCo=jccm.JCCo
	AND jcci.Contract=jccm.Contract LEFT JOIN
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
	--dbo.mfnGetJobProjection(101,'080600-') jccp ON
	JCCP jccp ON
		jccp.JCCo=jcjp.JCCo
	AND jccp.Job=jcjp.Job
	AND jccp.PhaseGroup=jcjp.PhaseGroup	
	AND jccp.Phase=jcjp.Phase LEFT JOIN
	JCCT jcct ON
		jcct.PhaseGroup=jccp.PhaseGroup
	AND jcct.CostType=jccp.CostType
WHERE
	(jccm.JCCo=@JCCo OR @JCCo IS NULL)
AND	(LTRIM(RTRIM(jccm.Contract))=LTRIM(RTRIM(@Contract)) OR @Contract IS NULL ) 
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
,	jcjm.Job
,	jcjm.Description 
,	jcjp.Phase
,	jcjp.Description 
--,	jcch.CostType
,	jcct.Abbreviation
,	jcct.Description
--ORDER BY 
--	jcip.Mth
GO
