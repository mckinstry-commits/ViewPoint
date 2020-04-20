USE Viewpoint
go

DECLARE @JCCo bCompany
DECLARE @Job bJob
DECLARE @Contract bContract

--SELECT * FROM JCJM WHERE Contract=' 10166-'
SELECT @JCCo=1, @Job=' 10166-001',@Contract=' 10166-'
SELECT @Contract=Contract FROM JCJM WHERE JCCo=@JCCo AND Job=@Job

/*
SELECT 'JCCM' AS TableName,* FROM JCCM WHERE JCCo=@JCCo AND Contract=@Contract
SELECT 'JCCI' AS TableName,* FROM JCCI WHERE JCCo=@JCCo AND Contract=@Contract
SELECT 'JCIR' AS TableName,* FROM JCIR WHERE Co=@JCCo AND Contract=@Contract
SELECT 'JCOR' AS TableName,* FROM JCIR WHERE Co=@JCCo AND Contract=@Contract
SELECT 'JCJM' AS TableName,* FROM JCJM WHERE JCCo=@JCCo AND Contract=@Contract
SELECT 'JCJP' AS TableName,* FROM JCJP WHERE JCCo=@JCCo AND Job=@Job
SELECT 'JCCH' AS TableName,* FROM JCCH  WHERE JCCo=@JCCo AND Job=@Job
SELECT 'JCCP' AS TableName,* FROM JCCP WHERE JCCo=@JCCo AND Job=@Job
SELECT 'JCOP' AS TableName,* FROM JCOP WHERE JCCo=@JCCo AND Job=@Job
SELECT 'JCPR' AS TableName,* FROM JCPR WHERE JCCo=@JCCo AND Job=@Job
SELECT 'JCCD' AS TableName,* FROM JCCP WHERE JCCo=@JCCo AND Job=@Job
SELECT 'PRTH' AS TableName,* FROM PRTH WHERE JCCo=@JCCo AND Job=@Job
SELECT 'POHD' AS TableName,* FROM POHD WHERE JCCo=@JCCo AND Job=@Job
SELECT 'SLHD' AS TableName,* FROM SLHD WHERE JCCo=@JCCo AND Job=@Job
*/
 
 SELECT
	jcjm.JCCo
,	jcjm.Job
,	jcjm.Description AS JobDesc
,	jcjm.JobStatus
,	CASE jcjm.JobStatus
		WHEN 0 THEN '0-Pending'
		WHEN 1 THEN '1-Open'
		WHEN 2 THEN '2-Soft Close'
		WHEN 3 THEN '3-HArd Close'
		ELSE CAST(jcjm.JobStatus AS VARCHAR(5)) + '-Unknown'
	END AS JobStatusDesc
,	jcmp.Name AS ProjectManager
,	jcmp.udPRCo AS ProjectManagerCo
,	jcmp.udEmployee AS ProjectManagerEmployee
,	jcdm.Department AS JCDepartment
,	jcdm.Description AS JCDepartmentDesc
,	glpi.Instance AS GLDepartment
,	glpi.Description AS GLDepartmentDesc
,	jccm.Contract
,	jccm.Description AS ContractDesc
,	jccm.ContractStatus
,	CASE jccm.ContractStatus
		WHEN 0 THEN '0-Pending'
		WHEN 1 THEN '1-Open'
		WHEN 2 THEN '2-Soft Close'
		WHEN 3 THEN '3-HArd Close'
		ELSE CAST(jccm.ContractStatus AS VARCHAR(5)) + '-Unknown'
	END AS ContractStatusDesc
,	jcci.Item
,	jcci.Description AS ContractItemDesc
,	jcci.udProjDelivery AS ContractItemProjDelivery
,	udpd.Description AS ContractItemProjDeliveryDesc
,	jcci.udRevType AS ContractItemRevType
,	CASE jcci.udRevType
		WHEN 'C' THEN 'Cost to Cost'
		WHEN 'M' THEN 'Cost + Markup'
		WHEN 'N' THEN 'Non-Revenue'
		WHEN 'A' THEN 'Straight Line'
		ELSE jcci.udRevType
	END AS  ContractItemRevTypeDesc
,	jcci.MarkUpRate AS ContractItemMarkup
,	jcjp.Phase
,	jcjp.Description AS PhaseDesc
,	jcjp.ActiveYN AS PhaseActiveYN
,	jcch.CostType
,	jcct.Abbreviation AS CostTypeAbbr
,	jcct.Description AS CostTypeDesc
,	jcch.ActiveYN AS PhaseCostTypeActiveYN
 FROM 
	JCCH jcch
JOIN JCJP jcjp ON 
	jcch.JCCo=jcjp.JCCo
AND jcch.Job=jcjp.Job
AND jcch.PhaseGroup=jcjp.PhaseGroup
AND jcch.Phase=jcjp.Phase
JOIN JCJM jcjm ON 
	jcjp.JCCo=jcjm.JCCo
AND jcjp.Job=jcjm.Job
JOIN JCCI jcci ON
	jcjp.JCCo=jcci.JCCo
AND jcjp.Contract=jcci.Contract
AND jcjp.Item=jcci.Item
JOIN JCDM jcdm ON
	jcci.JCCo=jcdm.JCCo
AND jcci.Department=jcdm.Department
JOIN GLPI glpi ON
	jcdm.GLCo=glpi.GLCo
AND glpi.PartNo=3
AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4)
LEFT OUTER JOIN JCMP jcmp ON
	jcjm.JCCo=jcmp.JCCo
AND jcjm.ProjectMgr=jcmp.ProjectMgr
JOIN JCCM jccm ON
	jcci.JCCo=jccm.JCCo
AND jcci.Contract=jccm.Contract
AND jcjm.JCCo=jccm.JCCo
AND jcjm.Contract=jccm.Contract
JOIN JCCT jcct ON
	jcch.CostType=jcct.CostType
AND jcch.PhaseGroup=jcct.PhaseGroup
LEFT OUTER JOIN udProjDelivery udpd ON
	jcci.udProjDelivery=udpd.Code
WHERE
	jcch.JCCo < 100
and	jcch.JCCo=@JCCo
AND jcch.Job=@Job
ORDER BY
	jcci.JCCo
,	jcci.Contract
,	jcci.Item
,	jcch.Job
,	jcch.Phase
,	jcch.CostType