alter VIEW dbo.mvwWIPJoin
as
---------------
-- CONTRACTS --
---------------
SELECT 
   rev.[JCCo]
  ,rev.[WorkOrder]
  ,rev.[Contract]
  ,rev.[CGCJobNumber]
  ,rev.[ThroughMonth]
  ,rev.[ContractDesc]
  ,rev.[IsLocked]
  ,rev.[RevenueType]
  ,rev.[RevenueTypeName]
  ,rev.[ContractStatus]
  ,rev.[ContractStatusDesc]
  ,rev.[Department]
  ,rev.[GLDepartment]
  ,rev.[GLDepartmentName]
  ,rev.[POC]
  ,rev.[POCName]
  ,rev.[OrigContractAmt]
  ,rev.[CurrContractAmt]
  ,rev.[ProjContractAmt]
  ,rev.[RevenueIsOverride]
  ,rev.[OverrideRevenueTotal]
  ,rev.[RevenueOverridePercent]
  ,rev.[RevenueOverrideAmount]
  ,CASE rev.[RevenueType]
	    WHEN 'M' THEN 
			(CASE rev.[ContractStatus] 
				WHEN 1 THEN 
					CASE WHEN ((cost.[CurrentCost] + cost.[CommittedCost]) < 0) THEN 0
					     ELSE (cost.[CurrentCost] + cost.[CommittedCost]) * (1 + COALESCE(rev.[MarkUpRate], 0))
					END
				ELSE COALESCE(rev.[CurrentBilledAmount],0)
			 END) 
		ELSE rev.[RevenueWIPAmount]
   END as [RevenueWIPAmount]
  ,rev.[CurrentBilledAmount]
  ,rev.[SalesPersonID]
  ,rev.[SalesPerson]
  ,rev.[VerticalMarket]
  ,rev.[MarkUpRate]
  ,rev.[StrLineTermStart]
  ,rev.[StrLineTerm] 
  ,rev.[StrLineMTDEarnedRev]
  ,rev.[StrLinePrevJTDEarnedRev]
  ,rev.[CurrEarnedRevenue]
  ,rev.[PrevEarnedRevenue]
  ,rev.[ProcessedOn] as RevenueProcessedOn
  ,cost.[OriginalCost]
  ,cost.[CurrentEstCost]
  ,cost.[CurrentCost]
  ,cost.[ProjectedCost]
  ,cost.[CostIsOverride]
  ,cost.[OverrideCostTotal]
  ,rev.[RevenueOverridePercent] as [CostOverridePercent] --cost.[CostOverridePercent]
  ,cost.[OverrideCostTotal] * rev.[RevenueOverridePercent] as [OverrideCost] --cost.[OverrideCost]
  ,cost.[CommittedCost]
  ,CASE rev.[ContractStatus]
   WHEN 1 THEN
    CASE rev.[RevenueType]
		WHEN 'C' THEN
			(CASE cost.[CostIsOverride]
				WHEN 'N' THEN
					CASE WHEN cost.[CurrentCost] < 0 THEN cost.[CurrentCost]
					ELSE
						(CASE when (cost.[ProjectedCost] is NULL OR cost.[ProjectedCost] = 0 ) 
						THEN cost.[CurrentEstCost] ELSE cost.[ProjectedCost] END)
					END
				ELSE cost.[OverrideCostTotal] * rev.[RevenueOverridePercent] --cost.OverrideCost
			END)
		WHEN 'M' THEN (cost.[CurrentCost] + cost.[CommittedCost])
		ELSE
			(CASE cost.[CostIsOverride]
				WHEN 'N' THEN 
					(CASE when (cost.[ProjectedCost] is NULL OR cost.[ProjectedCost] = 0 ) 
					THEN cost.[CurrentEstCost] ELSE cost.[ProjectedCost] END)
				ELSE cost.[OverrideCostTotal] * rev.[RevenueOverridePercent] --cost.OverrideCost
			END)
		END
   ELSE cost.[CurrentCost]
   END AS [CostWIPAmount]
  ,cost.[CurrMonthCost]
  ,cost.[PrevCost]
  ,cost.[ProcessedOn] as CostProcessedOn
  FROM 
	[dbo].[mckWipRevenueData] rev LEFT JOIN
	[dbo].[mckWipCostData] cost ON
		rev.JCCo=cost.JCCo
	AND rev.Contract=cost.Contract
	AND rev.GLDepartment=cost.GLDepartment
	AND rev.[ThroughMonth]=cost.[ThroughMonth]
	AND rev.[IsLocked]=cost.[IsLocked]
	AND rev.[RevenueType]=cost.[RevenueType]
WHERE	rev.WorkOrder IS NULL
	AND cost.WorkOrder IS NULL

UNION ALL

-------------------------
-- SERVICE WORK-ORDERS --
-------------------------

(SELECT 
   COALESCE(cost.[JCCo], rev.[JCCo]) AS JCCo
  ,COALESCE(cost.[WorkOrder], rev.[WorkOrder]) AS WorkOrder
  ,NULL AS Contract
  ,ISNULL(rev.[CGCJobNumber], '') AS CGCJobNumber
  ,COALESCE(cost.[ThroughMonth], rev.[ThroughMonth]) AS ThroughMonth
  ,COALESCE(cost.[ContractDesc], rev.[ContractDesc]) AS ContractDesc
  ,NULL AS IsLocked
  ,cost.[RevenueType]
  ,COALESCE(cost.[RevenueTypeName], rev.[RevenueTypeName]) AS RevenueTypeName
  ,COALESCE(cost.[ContractStatus], rev.[ContractStatus]) AS ContractStatus
  ,COALESCE(cost.[ContractStatusDesc], rev.[ContractStatusDesc]) AS ContractStatusDesc
  ,NULL AS Department
  ,COALESCE(cost.[GLDepartment], rev.[GLDepartment]) AS GLDepartment
  ,COALESCE(cost.[GLDepartmentName], rev.[GLDepartmentName]) AS GLDepartmentName
  ,NULL AS POC
  ,COALESCE(cost.[POCName], rev.[POCName]) AS POCName
  ,ISNULL(rev.[OrigContractAmt], 0) AS [OrigContractAmt]
  ,ISNULL(rev.[CurrContractAmt], 0) AS [CurrContractAmt]
  ,ISNULL(rev.[ProjContractAmt], 0) AS [ProjContractAmt]
  ,ISNULL(rev.[RevenueIsOverride], 'N') AS [RevenueIsOverride]
  ,ISNULL(rev.[OverrideRevenueTotal], 0) AS [OverrideRevenueTotal]
  ,ISNULL(rev.[RevenueOverridePercent], 0) AS [RevenueOverridePercent]
  ,ISNULL(rev.[RevenueOverrideAmount], 0) AS [RevenueOverrideAmount]
  ,CASE ISNULL(rev.[RevenueType], 'M')
	    WHEN 'M' THEN (ISNULL(cost.[CurrentCost], 0) + ISNULL(cost.[CommittedCost], 0)) * (1 + ISNULL(rev.[MarkUpRate], 0))
		ELSE ISNULL(rev.[RevenueWIPAmount], 0)
   END as [RevenueWIPAmount]
  ,ISNULL(rev.[CurrentBilledAmount], 0) AS [CurrentBilledAmount]
  ,ISNULL(rev.[SalesPersonID], 0) AS [SalesPersonID]
  ,ISNULL(rev.[SalesPerson], '') AS [SalesPerson]
  ,ISNULL(rev.[VerticalMarket], '') AS [VerticalMarket]
  ,ISNULL(rev.[MarkUpRate], 0) AS [MarkUpRate]
  ,ISNULL(rev.[StrLineTermStart], 0) AS [StrLineTermStart]
  ,ISNULL(rev.[StrLineTerm], 0) AS [StrLineTerm]
  ,ISNULL(rev.[StrLineMTDEarnedRev], 0) AS [StrLineMTDEarnedRev]
  ,ISNULL(rev.[StrLinePrevJTDEarnedRev], 0) AS [StrLinePrevJTDEarnedRev]
  ,ISNULL(rev.[CurrEarnedRevenue], 0) AS [CurrEarnedRevenue]
  ,ISNULL(rev.[PrevEarnedRevenue], 0) AS [PrevEarnedRevenue]
  ,rev.[ProcessedOn] AS RevenueProcessedOn
  ,ISNULL(cost.[OriginalCost], 0) AS OriginalCost
  ,ISNULL(cost.[CurrentEstCost], 0) AS CurrentEstCost
  ,ISNULL(cost.[CurrentCost], 0) AS CurrentCost
  ,ISNULL(cost.[ProjectedCost], 0) AS ProjectedCost
  ,ISNULL(cost.[CostIsOverride], 0) AS CostIsOverride
  ,ISNULL(cost.[OverrideCostTotal], 0) AS OverrideCostTotal
  ,ISNULL(cost.[CostOverridePercent], 0) AS CostOVerridePercent
  ,ISNULL(cost.[OverrideCost], 0) AS OverrideCost
  ,ISNULL(cost.[CommittedCost], 0) AS CommittedCost
  ,CASE ISNULL(rev.[ContractStatus], 1)
		WHEN 1 THEN (ISNULL(cost.[CurrentCost], 0) + ISNULL(cost.[CommittedCost], 0))
		ELSE cost.[CurrentCost]
   END AS [CostWIPAmount]
  ,ISNULL(cost.[CurrMonthCost], 0) AS CurrMonthCost
  ,ISNULL(cost.[PrevCost], 0) AS PrevCost
  ,cost.[ProcessedOn] AS CostProcessedOn
FROM 
	[dbo].[mckWipCostData] cost LEFT JOIN
	[dbo].[mckWipRevenueData] rev ON
		rev.[ThroughMonth]=cost.[ThroughMonth]
	AND rev.JCCo=cost.JCCo
	AND rev.WorkOrder=cost.WorkOrder
WHERE	rev.Contract IS NULL
	AND cost.Contract IS NULL

UNION

SELECT 
   COALESCE(cost.[JCCo], rev.[JCCo]) AS JCCo
  ,COALESCE(cost.[WorkOrder], rev.[WorkOrder]) AS WorkOrder
  ,NULL AS Contract
  ,ISNULL(rev.[CGCJobNumber], '') AS CGCJobNumber
  ,COALESCE(cost.[ThroughMonth], rev.[ThroughMonth]) AS ThroughMonth
  ,COALESCE(cost.[ContractDesc], rev.[ContractDesc]) AS ContractDesc
  ,NULL AS IsLocked
  ,cost.[RevenueType]
  ,COALESCE(cost.[RevenueTypeName], rev.[RevenueTypeName]) AS RevenueTypeName
  ,COALESCE(cost.[ContractStatus], rev.[ContractStatus]) AS ContractStatus
  ,COALESCE(cost.[ContractStatusDesc], rev.[ContractStatusDesc]) AS ContractStatusDesc
  ,NULL AS Department
  ,COALESCE(cost.[GLDepartment], rev.[GLDepartment]) AS GLDepartment
  ,COALESCE(cost.[GLDepartmentName], rev.[GLDepartmentName]) AS GLDepartmentName
  ,NULL AS POC
  ,COALESCE(cost.[POCName], rev.[POCName]) AS POCName
  ,ISNULL(rev.[OrigContractAmt], 0) AS [OrigContractAmt]
  ,ISNULL(rev.[CurrContractAmt], 0) AS [CurrContractAmt]
  ,ISNULL(rev.[ProjContractAmt], 0) AS [ProjContractAmt]
  ,ISNULL(rev.[RevenueIsOverride], 'N') AS [RevenueIsOverride]
  ,ISNULL(rev.[OverrideRevenueTotal], 0) AS [OverrideRevenueTotal]
  ,ISNULL(rev.[RevenueOverridePercent], 0) AS [RevenueOverridePercent]
  ,ISNULL(rev.[RevenueOverrideAmount], 0) AS [RevenueOverrideAmount]
  ,CASE ISNULL(rev.[RevenueType], 'M')
	    WHEN 'M' THEN (ISNULL(cost.[CurrentCost], 0) + ISNULL(cost.[CommittedCost], 0)) * (1 + ISNULL(rev.[MarkUpRate], 0))
		ELSE ISNULL(rev.[RevenueWIPAmount], 0)
   END as [RevenueWIPAmount]
  ,ISNULL(rev.[CurrentBilledAmount], 0) AS [CurrentBilledAmount]
  ,ISNULL(rev.[SalesPersonID], 0) AS [SalesPersonID]
  ,ISNULL(rev.[SalesPerson], '') AS [SalesPerson]
  ,ISNULL(rev.[VerticalMarket], '') AS [VerticalMarket]
  ,ISNULL(rev.[MarkUpRate], 0) AS [MarkUpRate]
  ,ISNULL(rev.[StrLineTermStart], 0) AS [StrLineTermStart]
  ,ISNULL(rev.[StrLineTerm], 0) AS [StrLineTerm]
  ,ISNULL(rev.[StrLineMTDEarnedRev], 0) AS [StrLineMTDEarnedRev]
  ,ISNULL(rev.[StrLinePrevJTDEarnedRev], 0) AS [StrLinePrevJTDEarnedRev]
  ,ISNULL(rev.[CurrEarnedRevenue], 0) AS [CurrEarnedRevenue]
  ,ISNULL(rev.[PrevEarnedRevenue], 0) AS [PrevEarnedRevenue]
  ,rev.[ProcessedOn] AS RevenueProcessedOn
  ,ISNULL(cost.[OriginalCost], 0) AS OriginalCost
  ,ISNULL(cost.[CurrentEstCost], 0) AS CurrentEstCost
  ,ISNULL(cost.[CurrentCost], 0) AS CurrentCost
  ,ISNULL(cost.[ProjectedCost], 0) AS ProjectedCost
  ,ISNULL(cost.[CostIsOverride], 0) AS CostIsOverride
  ,ISNULL(cost.[OverrideCostTotal], 0) AS OverrideCostTotal
  ,ISNULL(cost.[CostOverridePercent], 0) AS CostOVerridePercent
  ,ISNULL(cost.[OverrideCost], 0) AS OverrideCost
  ,ISNULL(cost.[CommittedCost], 0) AS CommittedCost
  ,CASE ISNULL(rev.[ContractStatus], 1)
		WHEN 1 THEN (ISNULL(cost.[CurrentCost], 0) + ISNULL(cost.[CommittedCost], 0))
		ELSE cost.[CurrentCost]
   END AS [CostWIPAmount]
  ,ISNULL(cost.[CurrMonthCost], 0) AS CurrMonthCost
  ,ISNULL(cost.[PrevCost], 0) AS PrevCost
  ,cost.[ProcessedOn] AS CostProcessedOn
FROM 
	[dbo].[mckWipCostData] cost RIGHT JOIN
	[dbo].[mckWipRevenueData] rev ON
		rev.[ThroughMonth]=cost.[ThroughMonth]
	AND rev.JCCo=cost.JCCo
	AND rev.WorkOrder=cost.WorkOrder
WHERE	rev.Contract IS NULL
	AND cost.Contract IS NULL
)

go

GRANT SELECT ON dbo.mvwWIPJoin TO [public]
GO

-- TEST SCRIPT
-- select count(*), sum(CurrentCost), Sum(CurrentBilledAmount) from mvwWIPJoin where Contract is null and ThroughMonth='12/1/2014'