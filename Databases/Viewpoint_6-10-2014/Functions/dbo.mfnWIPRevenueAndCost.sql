SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnWIPRevenueAndCost]
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
	JCCo
,	Contract	
,	ContractDescription	
,	Customer
,	CustomerName
,	ContractPOC	
,	ContractPOCName	
,	RevenueType
,	IsLocked
--,	Workstream
,	ThroughMonth	
,	ContractStatus
,	ContractStatusDesc
,	COUNT(GLDept) AS GLDeptCount
,	SUM(OriginalContractAmount) AS OriginalContractAmount
,	SUM(CurrentContractAmount) AS CurrentContractAmount
,	SUM(ProjectedContractAmount) AS ProjectedContractAmount
,	SUM(CurrentBilledAmount) AS CurrentBilledAmount
,	SUM(OriginalCost) AS OriginalCost
,	SUM(CurrentCost) AS CurrentCost
,	SUM(ProjectedCost) AS ProjectedCost
,	CAST(CASE 
		WHEN SUM(ProjectedCost)=0 AND SUM(ProjectedCost)=SUM(CurrentCost) THEN 1
		WHEN SUM(ProjectedCost)=0 AND SUM(ProjectedCost)<>SUM(CurrentCost) THEN 0
		ELSE (SUM(CurrentCost) / SUM(ProjectedCost)) 
	END AS decimal(8,3)) AS RevenuePercentComplete
,	SUM(ProjectedCost) - SUM(CurrentCost) AS EstimatedCostToComplete	
,	SUM(ProjectedContractAmount) - SUM(ProjectedCost) AS EstimagedGrossMargin
,	CAST(case
		WHEN SUM(ProjectedCost)=0 THEN 0
		ELSE (SUM(ProjectedContractAmount) - SUM(ProjectedCost))/SUM(ProjectedCost)
	END AS decimal(8,3)) AS EstimatedGrossMarginPct
,	CAST((SUM(CurrentCost) *
	CAST(case
		WHEN SUM(ProjectedCost)=0 THEN 0
		ELSE (SUM(ProjectedContractAmount) - SUM(ProjectedCost))/SUM(ProjectedCost)
	END AS decimal(8,3))
	) AS DECIMAL(18,2)) AS JTDRevenueEarned
,	CAST((SUM(CurrentCost) *
	CAST(case
		WHEN SUM(ProjectedCost)=0 THEN 0
		ELSE (SUM(ProjectedContractAmount) - SUM(ProjectedCost))/SUM(ProjectedCost)
	END AS decimal(8,3))
	) AS DECIMAL(18,2)) - SUM(CurrentCost)
	 AS JTDGrossMarginEarned
,	@ExcludeWorkstreams AS ExcludeWorkstreams
FROM 
	dbo.mfnWIPRevenueAndCostByDept(@Company,@Month,@Contract,@ExcludeWorkstreams)
GROUP BY
	JCCo
,	Contract	
,	ContractDescription	
,	Customer
,	CustomerName
,	ContractPOC	
,	ContractPOCName	
,	RevenueType
,	IsLocked
--,	Workstream
,	ThroughMonth
,	ContractStatus
,	ContractStatusDesc
)
GO
