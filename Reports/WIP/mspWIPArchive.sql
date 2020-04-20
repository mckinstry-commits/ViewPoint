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
-- 03/02/2015 Amit Mody			Updated straight line JTD Earned Revenue calculation when pre-term open contracts have negative
--								Projected Final Gross Margin
-- 04/28/2015 Amit Mody			Fixed YTD updates to sum MTD amounts without accounting for contract status
--								Set default values of parameters @inContract and @inExcludeRevenueType to NULL
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mspWIPArchive] 
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10)  = NULL
,	@inExcludeRevenueType	varchar(255) = NULL
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
				ELSE [RevenueWIPAmount] * --PercentComplete
						CASE WHEN (([ContractStatus]=2 OR [ContractStatus]=3) AND CurrentCost=0) THEN 1.0 -- Closed Cost-to-Cost contract with JTD Actual Cost = 0: Force 100% project completion
							 WHEN ([ContractStatus]=1 AND CurrentCost < 0) THEN 0.0 -- Open Cost-to-Cost contract with negative JTD Actual Cost: Force 0% project completion
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
			 WHEN ([ContractStatus]=1 AND CurrentCost < 0) THEN 0.0 -- Open Cost-to-Cost contract with negative JTD Actual Cost: Force 0% project completion
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
  ,[Department]
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

------------------------------------------------------
---UPDATE MTD (AND SPECIAL CASES FOR STRAIGHT LINE)---
------------------------------------------------------
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
,	JTDEarnedRev = CASE WHEN ([RevenueType] = 'A' AND [IsLocked] = 'Y' AND [ContractStatus] = 1 AND [StrLineTermStart] > @firstOfMonth) THEN PrevEarnedRevenue
	 		    ELSE JTDEarnedRev 
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
		       WHEN ([RevenueType] = 'A' AND [IsLocked] = 'Y' AND [ContractStatus] = 1 AND [StrLineTermStart] > @firstOfMonth) THEN COALESCE(JTDEarnedRev,0)-COALESCE([JTDActualCost],0)
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
   	(SELECT @firstOfMonth as ThroughMonth, JCCo, Contract, IsLocked, RevenueType, GLDepartment, sum(MTDEarnedRev) as YTDEarnedRev, sum(MTDActualCost) as YTDActualCost
	 FROM   mckWipArchive
	 WHERE  Contract IS NOT NULL
		AND (@inMonth IS NULL OR (ThroughMonth BETWEEN @startYear AND DATEADD(MONTH, -1, @firstOfMonth)))
		AND (JCCo=@inCompany OR @inCompany IS NULL)
		AND (Contract=@inContract OR @inContract IS NULL)
		AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))
	 GROUP BY JCCo, Contract, IsLocked, RevenueType, GLDepartment) wip
ON	ret.ThroughMonth=wip.ThroughMonth AND
	ret.JCCo=wip.JCCo AND
	ret.Contract=wip.Contract AND
	ret.IsLocked=wip.IsLocked AND
	ret.RevenueType=wip.RevenueType AND
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
--EXEC mspWIPArchive 1, '4/1/2015'