SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnWIPRevenueAndCostByDept]
(
	@Company				bCompany
,	@Month					bMonth
,	@Contract				bContract
,	@ExcludeWorkstreams		VARCHAR(255) = '''Sales'',''Internal'''
)
RETURNS TABLE
AS 
RETURN (

SELECT
	COALESCE(rev.JCCo, cost.JCCo) AS JCCo
,	COALESCE(rev.Contract, cost.Contract) AS Contract	
,	COALESCE(rev.ContractDescription, cost.ContractDescription) AS ContractDescription	
,	jccm.Customer
,	arcm.Name AS CustomerName
,	jccm.ContractStatus
,	CASE jccm.ContractStatus 
		WHEN 0 THEN CAST(jccm.ContractStatus AS VARCHAR(4)) + '-Pending'
		ELSE vddci.DisplayValue 
	END AS ContractStatusDesc
,	COALESCE(rev.ContractPOC, cost.ContractPOC) AS ContractPOC	
,	COALESCE(rev.ContractPOCName, cost.ContractPOCName) AS ContractPOCName	
,	COALESCE(rev.GLDept, cost.GLDept) AS GLDept	
,	COALESCE(rev.GLDeptName, cost.GLDeptName) AS GLDeptName	
--,	COALESCE(cost.WorkStream,'Undefined') AS Workstream
,	COALESCE(rev.ThroughMonth, cost.ThroughMonth) AS ThroughMonth	
,	COALESCE(rev.RevenueType, cost.RevenueType) AS RevenueType
,	COALESCE(rev.IsLocked, cost.IsLocked) AS IsLocked
,	COALESCE(rev.OriginalContractAmount,0) AS OriginalContractAmount
,	COALESCE(rev.CurrentContractAmount,0) AS CurrentContractAmount
,	COALESCE(rev.ProjectedContractAmount,0) AS ProjectedContractAmount
,	COALESCE(rev.CurrentBilledAmount,0) AS CurrentBilledAmount
,	COALESCE(cost.OriginalCost,0) AS OriginalCost
,	COALESCE(cost.CurrentCost,0) AS CurrentCost
,	COALESCE(cost.ProjectedCost,0) AS ProjectedCost
,	CAST(CASE 
		WHEN COALESCE(cost.ProjectedCost,0)=0 AND COALESCE(cost.ProjectedCost,0)=COALESCE(cost.CurrentCost,0) THEN 1
		WHEN COALESCE(cost.ProjectedCost,0)=0 AND COALESCE(cost.ProjectedCost,0)<>COALESCE(cost.CurrentCost,0) THEN 0
		ELSE ( COALESCE(cost.CurrentCost,0) / COALESCE(cost.ProjectedCost,0) ) 
	END AS DECIMAL(8,3)) AS RevenuePercentComplete
,	COALESCE(cost.ProjectedCost,0) - COALESCE(cost.CurrentCost,0) AS EstimatedCostToComplete	
,	COALESCE(rev.ProjectedContractAmount,0) - COALESCE(cost.ProjectedCost,0) AS EstimagedGrossMargin
,	CAST(CASE
		WHEN COALESCE(cost.ProjectedCost,0)=0 THEN 0
		ELSE (COALESCE(rev.ProjectedContractAmount,0) - COALESCE(cost.ProjectedCost,0))/COALESCE(cost.ProjectedCost,0)
	END AS DECIMAL(8,3)) AS EstimatedGrossMarginPct
,	CAST((COALESCE(cost.CurrentCost,0) * 
	CAST(
		CASE
			WHEN COALESCE(cost.ProjectedCost,0)=0 THEN 0
			ELSE (COALESCE(rev.ProjectedContractAmount,0) - COALESCE(cost.ProjectedCost,0))/COALESCE(cost.ProjectedCost,0)
		END 
	AS DECIMAL(8,3))) AS decimal(18,2)) AS JTDRevenueEarned
,	(CAST((COALESCE(cost.CurrentCost,0) * 
	CAST(
		CASE
			WHEN COALESCE(cost.ProjectedCost,0)=0 THEN 0
			ELSE (COALESCE(rev.ProjectedContractAmount,0) - COALESCE(cost.ProjectedCost,0))/COALESCE(cost.ProjectedCost,0)
		END 
	AS DECIMAL(8,3))) AS decimal(18,2))  - COALESCE(cost.CurrentCost,0)) AS JTDGrossMarginEarned
,	@ExcludeWorkstreams AS ExcludeWorkstreams
FROM 
	dbo.mfnWIPRevenue(@Company,@Month,@Contract) rev FULL join
	dbo.mfnWIPCost(@Company,@Month,@Contract,@ExcludeWorkstreams) cost ON
		rev.JCCo=cost.JCCo
	AND rev.Contract=cost.Contract
	AND rev.GLDept=cost.GLDept JOIN
	JCCM jccm ON
		jccm.JCCo=rev.JCCo
	AND LTRIM(RTRIM(jccm.Contract))=LTRIM(RTRIM(COALESCE(rev.Contract, cost.Contract))) JOIN
	ARCM arcm ON
		arcm.CustGroup=jccm.CustGroup
	AND arcm.Customer=jccm.Customer LEFT OUTER JOIN
	vDDCI vddci ON
		vddci.ComboType='JCContractStatus'
	AND vddci.DatabaseValue=jccm.ContractStatus	
)
GO
