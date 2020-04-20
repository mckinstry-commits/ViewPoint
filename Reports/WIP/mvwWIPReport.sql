alter VIEW dbo.mvwWIPReport
AS

SELECT [ThroughMonth]
      ,[JCCo]
	  ,[WorkOrder]
      ,[Contract]
	  ,[CGCJobNumber]
      ,[ContractDesc] AS [Contract Description]
      ,[IsLocked]
      ,[RevenueType]
      ,[RevenueTypeName]
      ,[ContractStatus]
      ,[ContractStatusDesc]
	  ,[Department]
      ,[GLDepartment]
      ,[GLDepartmentName]
      ,[POC]
      ,[POCName]
      ,[OrigContractAmt]
      ,[CurrContractAmt]
      ,[ProjContractAmt]
      ,[RevenueIsOverride]
      ,[OverrideRevenueTotal] AS RevenueOverrideTotal
      ,[RevenueOverridePercent]
      ,[RevenueOverrideAmount]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE([RevenueWIPAmount],0) END AS [Projected Final Contract Value]
      ,COALESCE([JTDBilled],0) AS [JTD Billed]
      ,COALESCE([OriginalCost],0) AS [Original Cost Budget]
	  ,COALESCE([JTDActualCost],0) AS [JTD Actual Cost]
	  ,COALESCE([CurrentEstCost],0) AS [Estimated Cost]
      ,COALESCE([ProjectedCost],0) AS [ProjectedCost]
      ,[CostIsOverride] 
      ,COALESCE([OverrideCostTotal],0) AS [CostOverrideTotal]
      ,COALESCE([CostOverridePercent],0) AS [CostOverridePercent]
      ,COALESCE([OverrideCost],0) AS [CostOverrideAmount]
	  ,COALESCE([CommittedCost],0) AS [CommittedCostAmount]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE([CostWIPAmount],0) END AS [Projected Final Cost]
	  ,ContractIsPositive
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(EstimatedCostToComplete,0) END AS [EstimatedCostToComplete]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(PercentComplete,0) END AS [Percent Complete]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(ProjFinalGM,0) END AS [Projected Final Gross Margin]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(ProjFinalGMPerc,0) END AS [Projected Final Gross Margin %]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(JTDEarnedRev,0) END AS [JTD Earned Revenue]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(JTDEarnedGM,0) END AS [JTD Earned Gross Margin]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(Overbilled,0) END AS [Overbilled]
      ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(Underbilled,0) END AS [Underbilled]
	  ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(MTDEarnedRev,0) END AS [MTD Earned Revenue]
	  ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(MTDActualCost,0) END AS [MTD Actual Cost]
	  ,CASE [IsLocked] 
		WHEN 'N' THEN 0 
		ELSE 
			--CASE WHEN ([RevenueType]='M' AND [JTDActualCost]<=0) THEN COALESCE(JTDEarnedGM,0) - (COALESCE(PrevEarnedRevenue, 0)-COALESCE(PrevCost,0))
			--ELSE 
			COALESCE(MTDEarnedRev,0)-COALESCE(MTDActualCost,0) 
			--END 
		END AS [MTD Earned Gross Margin]
	  ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(YTDEarnedRev,0) END AS [YTD Earned Revenue]
	  ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(YTDActualCost,0) END AS [YTD Actual Cost]
	  ,CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(YTDEarnedRev,0)-COALESCE(YTDActualCost,0) END AS [YTD Earned Gross Margin]
	  ,SalesPersonID
	  ,SalesPerson
	  ,VerticalMarket
	  ,MarkUpRate AS [Markup]
	  ,StrLineTermStart AS [Straight Line Term Start]
	  ,StrLineTerm AS [Straight Line Term Months]
	  ,RevenueProcessedOn AS [Batch Processed On]
  FROM [dbo].[mckWipArchive]
GO

GRANT SELECT ON dbo.mvwWIPReport TO [public]
GO