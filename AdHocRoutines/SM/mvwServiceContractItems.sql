USE Viewpoint
go

DROP VIEW mers.mvwServiceContractItems
go

CREATE VIEW mers.mvwServiceContractItems
as
SELECT distinct
	jcci.JCCo
,	jcci.Contract
,	jccm.Description AS ContractDesc
,	CASE jccm.ContractStatus
		WHEN 0 THEN '0-Pending'
		WHEN 1 THEN '1-Open'
		WHEN 2 THEN '2-Soft Close'
		WHEN 3 THEN '3-Hard Close'
		ELSE CAST(jccm.ContractStatus AS VARCHAR(5)) + '-Unknown'
	END AS ContractStatus
,	jccm.StartMonth
,	jccm.ProjCloseDate
,	jcci.Item
,	jcci.Department
,	jcjm.Job
,	jcjm.udCGCJob
,	jcjm.Description AS JobDesc
,	CASE jcjm.JobStatus
		WHEN 0 THEN '0-Pending'
		WHEN 1 THEN '1-Open'
		WHEN 2 THEN '2-Soft Close'
		WHEN 3 THEN '3-Hard Close'
		ELSE CAST(jcjm.JobStatus AS VARCHAR(5)) + '-Unknown'
	END AS JobStatus
,	SUBSTRING(jcdm.OpenRevAcct,10,4) AS GLDepartment
,	jcci.udRevType
,	jcci.udProjDelivery
,	SUM(jcci.OrigContractAmt) AS ContractItemOriginal
,	SUM(jcci.ContractAmt) AS ContractItemAmount
,	SUM(jcci.BilledAmt) AS ContractItemBilledAmt
,	SUM(jccd.EstCost) AS JobEstCost
,	SUM(jccd.TotalCmtdCost) AS JobTotalCmtdCost
,	SUM(jccd.ActualCost) AS JobActualCost
,	SUM(jccd.ProjCost) AS JobProjCost
FROM
	dbo.SMWorkOrderScope scope
JOIN SMWorkOrder wo ON
	scope.SMCo=wo.SMCo
AND scope.WorkOrder=wo.WorkOrder
JOIN JCJP jcjp ON
	jcjp.JCCo=scope.JCCo
AND jcjp.Job=scope.Job
AND jcjp.PhaseGroup=scope.PhaseGroup
AND jcjp.Phase=scope.Phase
JOIN JCJM jcjm ON
	jcjp.JCCo=jcjm.JCCo
AND jcjp.Job=jcjm.Job
JOIN JCCI jcci ON
	jcjp.JCCo=jcci.JCCo
AND jcjp.Contract=jcci.Contract
AND jcjp.Item=jcci.Item
JOIN JCCM jccm ON
	jccm.JCCo=jcci.JCCo
AND jccm.Contract=jcci.Contract
JOIN JCDM jcdm ON
	jcdm.JCCo=jcci.JCCo
AND jcdm.Department=jcci.Department
JOIN JCCH jcch ON
	jcjp.JCCo=jcch.JCCo
AND jcjp.Job=jcch.Job
AND jcjp.PhaseGroup=jcch.PhaseGroup
AND jcjp.Phase=jcch.Phase
JOIN JCCD jccd ON
	jccd.JCCo=jcch.JCCo
AND jccd.Job=jcch.Job
AND jccd.PhaseGroup=jcch.PhaseGroup
AND jccd.Phase=jcch.Phase
AND jccd.CostType=jcch.CostType
WHERE
	jcci.JCCo=1
AND jccm.ContractStatus < 2
AND SUBSTRING(jcdm.OpenRevAcct,10,4) IN ('0520','0521','0522')
GROUP BY
	jcci.JCCo
,	jcci.Contract
,	jccm.Description 
,	jccm.ContractStatus
,	jccm.StartMonth
,	jccm.ProjCloseDate
,	jcci.Item
,	jcci.Department
,	jcjm.Job
,	jcjm.udCGCJob
,	jcjm.Description
,	jcjm.JobStatus
,	SUBSTRING(jcdm.OpenRevAcct,10,4)
,	jcci.udRevType
,	jcci.udProjDelivery
--ORDER BY
--	jcci.JCCo
--,	jcci.Contract
--,	jcci.Item
--,	jcjm.Job
go

GRANT SELECT ON mers.mvwServiceContractItems TO PUBLIC
go

SELECT * FROM mers.mvwServiceContractItems