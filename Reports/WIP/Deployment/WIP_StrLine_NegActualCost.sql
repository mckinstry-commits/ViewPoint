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

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mspWIPArchive]'))
	DROP PROCEDURE [dbo].[mspWIPArchive]
GO

-- =================================================================================================================================
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 01/14/2015 Amit Mody			Authored by converting from mfnGetWIPArchive
-- 02/10/2015 Amit Mody			Updated for supporting multiple ExcludeRevenueType (so that non-rev contracts can be processed 
--								on locked months)
-- 02/22/2015 Amit Mody			Updated straight line MTD Earned Revenue calculation when in-term (or past-term) contracts have
--								negative Projected Final Gross Margin
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mspWIPArchive] 
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10)
,	@inExcludeRevenueType	varchar(255)
AS
BEGIN

DECLARE @firstOfMonth smalldatetime
SELECT @firstOfMonth = dbo.mfnFirstOfMonth(@inMonth)

IF OBJECT_ID('tempdb..#tmpWip') IS NOT NULL
    DROP TABLE #tmpWip

SELECT * INTO #tmpWip FROM dbo.mckWipArchive WHERE 1=2
INSERT #tmpWip
SELECT 
   [JCCo]
  ,[WorkOrder]
  ,[Contract]
  ,[CGCJobNumber]
  ,[ThroughMonth]
  ,[ContractDesc]
  ,[IsLocked]
  ,[RevenueType]
  ,[RevenueTypeName]
  ,[ContractStatus]
  ,[ContractStatusDesc]
  ,[GLDepartment]
  ,[GLDepartmentName]
  ,[POC]
  ,[POCName]
  ,[OrigContractAmt]
  ,[CurrContractAmt]
  ,[ProjContractAmt]
  ,[RevenueIsOverride]
  ,[OverrideRevenueTotal]
  ,[RevenueOverridePercent]
  ,[RevenueOverrideAmount]
  ,[RevenueWIPAmount]
  ,[CurrentBilledAmount] AS JTDBilled
  ,[SalesPersonID]
  ,[SalesPerson]
  ,[VerticalMarket]
  ,[MarkUpRate]
  ,[StrLineTermStart]
  ,[StrLineTerm] 
  ,[StrLineMTDEarnedRev]
  ,[StrLinePrevJTDEarnedRev]
  ,[CurrEarnedRevenue]
  ,[PrevEarnedRevenue]
  ,0 as [YTDEarnedRev]
  ,[OriginalCost]
  ,[CurrentEstCost] CurrentEstCost
  ,[CurrentCost] JTDActualCost
  ,[ProjectedCost]
  ,[CostIsOverride]
  ,[OverrideCostTotal]
  ,[CostOverridePercent]
  ,[OverrideCost]
  ,[CommittedCost]
  ,[CostWIPAmount]
  ,[CurrMonthCost]
  ,[PrevCost]
  ,0 as [YTDActualCost]
  ,[RevenueProcessedOn]
  ,[CostProcessedOn]

-- CALCULATED COLUMNS FOLLOW
  ,COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0) AS ProjFinalGM
  ,COALESCE(CostWIPAmount,0)-COALESCE(CurrentCost,0) AS EstimatedCostToComplete
  ,CASE [RevenueType]
		WHEN 'A' THEN
			CASE [ContractStatus]	
			WHEN 1 THEN													-- Open SL contract 
				(CASE WHEN COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0) < 0
					THEN COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0)+COALESCE([CurrentCost],0)
					ELSE (StrLineMTDEarnedRev + PrevEarnedRevenue)
				 END)
			ELSE COALESCE([CurrentBilledAmount],0)						-- Soft/Hard closed SL contract
			END
	    WHEN 'M' THEN 
			CASE [ContractStatus]	
			WHEN 1 THEN 
				CASE WHEN [CurrentCost] <= 0 THEN 0 ELSE (COALESCE([CurrentCost],0) * (1 + MarkUpRate)) END	-- Open C+M contract 
			ELSE COALESCE([CurrentBilledAmount],0)						-- Soft/Hard closed C+M contract
			END
	    WHEN 'C' THEN													-- Cost-to-cost contract in open or closed status
			(CASE WHEN COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0) < 0
				THEN COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0)+COALESCE([CurrentCost],0)
				ELSE [RevenueWIPAmount] * 
					 CASE [RevenueType]
	 					WHEN 'C' THEN
							CASE WHEN (([ContractStatus]=2 OR [ContractStatus]=3) AND CurrentCost=0) THEN 1.0 -- Closed Cost-to-Cost contract with JTD Actual Cost = 0: Force 100% project completion
							ELSE 
		     						CAST(CASE COALESCE(CostWIPAmount,0) 
			     					WHEN 0 THEN 0.00 
			     					ELSE COALESCE(CurrentCost,0)/CostWIPAmount 
 			     					END AS DECIMAL(18,10)) 
							END
	 				ELSE
						CAST(CASE COALESCE(CostWIPAmount,0) 
		     				WHEN 0 THEN 0.00 
		     				ELSE COALESCE(CurrentCost,0)/CostWIPAmount 
 		     				END AS DECIMAL(18,10)) 
	 				END
			 END)
		ELSE 0.0														-- Non-revenue contract in open or closed status
	   END AS JTDEarnedRev
  ,CASE [RevenueType]
	 WHEN 'C' THEN
		CASE WHEN (([ContractStatus]=2 OR [ContractStatus]=3) AND CurrentCost=0) THEN 1.0 -- Closed Cost-to-Cost contract with JTD Actual Cost = 0: Force 100% project completion
		ELSE 
		     CAST(CASE COALESCE(CostWIPAmount,0) 
			     WHEN 0 THEN 0.00 
			     ELSE COALESCE(CurrentCost,0)/CostWIPAmount 
 			     END AS DECIMAL(18,10)) 
		END
	 ELSE
		CAST(CASE COALESCE(CostWIPAmount,0) 
		     WHEN 0 THEN 0.00 
		     ELSE COALESCE(CurrentCost,0)/CostWIPAmount 
 		     END AS DECIMAL(18,10)) 
	 END AS PercentComplete
  ,0 AS MTDEarnedRev
  ,(COALESCE(CurrentCost, 0) - CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(PrevCost, 0) END) AS MTDActualCost
  ,0 AS [ContractIsPositive]
  ,0 AS [ProjFinalGMPerc]
  ,0 AS [JTDEarnedGM]
  ,0 AS [Overbilled]
  ,0 AS [Underbilled]
FROM	dbo.mvwWIPJoin CurrWIP 
WHERE 	ThroughMonth=@firstOfMonth
	AND (JCCo=@inCompany OR @inCompany IS NULL)
	AND (Contract=@inContract or @inContract is null )
	AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))

----------------------------------------------
---UPDATE PrevEarnedRevenue for Work-Orders---
----------------------------------------------
IF ('M' NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
BEGIN
	UPDATE ret
	SET  ret.PrevEarnedRevenue = COALESCE(prevMonth.JTDEarnedRev, 0.000)
	--,	 ret.PrevCost = COALESCE(prevMonth.Cost, 0.000)
	FROM #tmpWip ret JOIN
		(SELECT	JCCo, WorkOrder, /* ContractStatus,*/ GLDepartment, COALESCE(JTDEarnedRev, 0.0) AS JTDEarnedRev --, COALESCE(JTDActualCost, 0.0) AS Cost
		 FROM	dbo.mckWipArchive
		 WHERE	ThroughMonth = DATEADD(MONTH, -1, @firstOfMonth)
		  AND	WorkOrder IS NOT NULL) prevMonth
		ON	ret.JCCo=prevMonth.JCCo
		AND ret.WorkOrder=prevMonth.WorkOrder
		--AND ret.ContractStatus=prevMonth.ContractStatus
		AND ret.GLDepartment=prevMonth.GLDepartment
	WHERE	ret.WorkOrder IS NOT NULL
END

----------------
---UPDATE MTD---
----------------
UPDATE #tmpWip
SET 	StrLineMTDEarnedRev = CASE WHEN ([RevenueType]='A' AND JTDEarnedRev < 0 AND [StrLineTermStart] <= @firstOfMonth) 
  				   THEN JTDEarnedRev-COALESCE(PrevEarnedRevenue,0)
				   ELSE StrLineMTDEarnedRev
			      END
,	MTDEarnedRev = CASE [RevenueType]
			WHEN 'A' THEN 
				CASE WHEN (JTDEarnedRev < 0 AND [StrLineTermStart] <= @firstOfMonth) THEN JTDEarnedRev-COALESCE(PrevEarnedRevenue,0)
	 			     ELSE StrLineMTDEarnedRev
				END
			ELSE (COALESCE(JTDEarnedRev, 0) - CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(PrevEarnedRevenue, 0) END)
   		   END
WHERE 1=1

-------------------
---UPDATE LAST 5---
-------------------
UPDATE #tmpWip
SET YTDEarnedRev = MTDEarnedRev 
  , YTDActualCost = MTDActualCost 
  , ContractIsPositive = CASE WHEN COALESCE(ProjFinalGM,0) < 0
				THEN 0
				ELSE 1 
   			     END 
  , ProjFinalGMPerc = CAST(CASE COALESCE(RevenueWIPAmount,0) 
				WHEN 0 THEN (CASE WHEN ProjFinalGM < 0 THEN -1.00 ELSE 0.00 END)
				ELSE ProjFinalGM/RevenueWIPAmount
			   	END AS DECIMAL(18,10)) 
  , JTDEarnedGM = CASE WHEN [RevenueType] IN ('M', 'N') THEN COALESCE(JTDEarnedRev,0)-COALESCE([JTDActualCost],0)
		       ELSE -- for C and A revenue types
				CASE WHEN COALESCE(ProjFinalGM,0) < 0 
				 THEN ProjFinalGM
				 ELSE COALESCE(JTDEarnedRev,0)-COALESCE([JTDActualCost],0)
				END
		       END
  , Overbilled =  CASE WHEN (COALESCE([JTDBilled],0)-COALESCE([JTDEarnedRev],0) < 0)
			THEN 0.0
			ELSE COALESCE([JTDBilled],0)-COALESCE([JTDEarnedRev],0)
		  END
  , Underbilled = CASE WHEN (COALESCE([JTDEarnedRev],0)-COALESCE([JTDBilled],0) < 0)
			THEN 0.0
			ELSE COALESCE([JTDEarnedRev],0)-COALESCE([JTDBilled],0)
  		  END

WHERE 1=1

----------------
---UPDATE YTD---
----------------
DECLARE @startYear smalldatetime
SET @startYear=DATEADD(yy, DATEDIFF(yy,0,@firstOfMonth), 0)

UPDATE ret
SET    	ret.YTDEarnedRev = ret.YTDEarnedRev + COALESCE(wip.YTDEarnedRev, 0)
,	ret.YTDActualCost = ret.YTDActualCost + COALESCE(wip.YTDActualCost, 0)
FROM   	#tmpWip ret JOIN 
   	(SELECT @firstOfMonth as ThroughMonth, JCCo, Contract, IsLocked, RevenueType, ContractStatus, GLDepartment, sum(MTDEarnedRev) as YTDEarnedRev, sum(MTDActualCost) as YTDActualCost
	 FROM   mckWipArchive
	 WHERE  Contract IS NOT NULL
		AND (@inMonth IS NULL OR (ThroughMonth BETWEEN @startYear AND DATEADD(MONTH, -1, @firstOfMonth)))
		AND (JCCo=@inCompany OR @inCompany IS NULL)
		AND (Contract=@inContract OR @inContract IS NULL)
		AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))
	 GROUP BY JCCo, Contract, IsLocked, RevenueType, ContractStatus, GLDepartment) wip
ON	ret.ThroughMonth=wip.ThroughMonth AND
	ret.JCCo=wip.JCCo AND
	ret.Contract=wip.Contract AND
	ret.IsLocked=wip.IsLocked AND
	ret.RevenueType=wip.RevenueType AND
	--ret.ContractStatus=wip.ContractStatus AND
	ret.GLDepartment=wip.GLDepartment

IF EXISTS (SELECT 1 FROM dbo.mckWipArchive WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
											 AND (ThroughMonth=@firstOfMonth OR @inMonth IS NULL) 
											 AND (Contract=@inContract OR @inContract IS NULL)
											 AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
BEGIN
	DELETE dbo.mckWipArchive WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
							   AND (ThroughMonth=@firstOfMonth OR @inMonth IS NULL) 
							   AND (Contract=@inContract OR @inContract IS NULL)
							   AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))
END
INSERT dbo.mckWipArchive SELECT * FROM #tmpWip

DROP TABLE #tmpWip

END
GO

--Test Script
--EXEC mspWIPArchive 1, '12/1/2014', null