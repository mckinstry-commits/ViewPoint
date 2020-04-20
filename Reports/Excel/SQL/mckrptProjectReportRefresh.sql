IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptProjectReportRefresh]'))
	DROP PROCEDURE [dbo].[mckrptProjectReportRefresh]
GO

-- =======================================================================================================================
-- Author:		Amit Mody
-- Create date: 1/29/2015
-- Date       Author            Description
-- ---------- ----------------- ------------------------------------------------------------------------------------------
-- 2/19/2015  Amit Mody			Added RevenueType and ProcessedOn fields to resultset
-- 3/09/2015  Amit Mody			Change request (OnTime # 98613) 
-- =======================================================================================================================

CREATE PROCEDURE [dbo].[mckrptProjectReportRefresh] 
	@reportMonth datetime = null
,	@company tinyint = null
,	@dept varchar(10) = null
,	@revType varchar(10) = null
,	@contract varchar(10) = null
AS
BEGIN

DECLARE @thisMonth DateTime
DECLARE @lastMonth DateTime
DECLARE @effDate DateTime

SELECT @thisMonth=DATEADD(m, DATEDIFF(m, 0, ISNULL(@reportMonth, GETDATE())), 0)
SELECT @lastMonth=DATEADD(m, DATEDIFF(m, 0, ISNULL(@reportMonth, GETDATE())) - 1, 0)
SELECT @effDate=DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@thisMonth)+1,0))
IF @effDate>GETDATE()
	SELECT @effDate=GETDATE()

IF OBJECT_ID('tempdb..#tmpProjReport') IS NOT NULL
    DROP TABLE #tmpProjReport

SELECT * INTO #tmpProjReport FROM dbo.mckProjectReport WHERE 1=2

-----------------------------
-- *** WIP DERIVATIVES *** --
-----------------------------
INSERT INTO #tmpProjReport
SELECT 
	@thisMonth AS [Month]
,	wip.JCCo
,	wip.GLDepartment AS [GL Department]
,	wip.GLDepartmentName AS [GL Department Name]
,	wip.Contract
,	'' AS [Contract Description]
,	wip.ContractStatus AS [Contract Status]
,	wip.RevenueType AS [Revenue Type]
,	NULL AS [Completion Date]
,	NULL AS [Last Revenue Projection]
,	NULL AS [Last Cost Projection]
,	wip.OrigGM AS [Original Gross Margin]
,	wip.OrigGMPerc AS [Original Gross Margin %]
,	NULL AS [Projected Final Billing]
,	wip.POCName AS [POC]
,	wip.SalesPerson AS [Sales Person]
,	0 AS [Customer #]
,	'' AS [Customer Name]
,	'' AS [Customer Contact Name]
,	'' AS [Customer Phone Number]
,	'' AS [Customer Email Address]
,   wip.[Current Contract Value]
,	wip.[Current WIP Revenue] AS [Projected Final Contract Amount]
,	wip.[Current WIP Revenue] - wip.[Current Contract Value] AS [Projected COs]
,	wip.[Prior WIP Revenue] AS [Previous Month Projected Final Contract Amount]
,	wip.[Prior JTD Actual Cost] AS [JTD Costs Previous Month]
,	wip.[Prior WIP Cost] AS [Previous Month Projected Final Cost]
--,	CASE WHEN (wip.[Prior Projected Cost] = 0) 
--		 THEN 0.0 
--		 ELSE CAST(wip.[Prior JTD Actual Cost]/wip.[Prior Projected Cost] AS DECIMAL(18,10)) 
--	END AS [% Complete Previous Month]
,	wip.[PrevPercComplete] AS [% Complete Previous Month]
,	wip.[Current JTD Actual Cost] AS [Current JTD Costs]
,	wip.[CommittedCostAmount] AS [Current Remaining Committed Cost]
,	wip.[Current JTD Amount Billed]
,	wip.[Current JTD Revenue Earned]
,	wip.[Current JTD Net Under Over Billed]
,	0 AS [JTD Net Cash Position]
,	0 AS [Current Retention Unbilled]
,	1 AS [Partition Ratio]
,	0 AS [Unpaid A/R Balance]
,	0 AS [AR Current Amount]
,	0 AS [AR 31-60 Days Amount]
,	0 AS [AR 61-90 Days Amount]
,	0 AS [AR Over 90 Amount]
,	wip.[Current WIP Cost] AS [Current Projected Final Cost]
,	wip.[Current WIP GM] AS [Current Projected Final Gross Margin]
,	wip.[Current WIP GM %] AS [Current Projected Final Gross Margin %]
,	wip.[Current WIP Revenue] - wip.[Prior WIP Revenue] AS [MOM Variance of Projected Final Contract Amount]
,	wip.[Current WIP Cost] - wip.[Prior WIP Cost] AS [MOM Variance of Projected Final Cost]
,	wip.[Current WIP GM] - wip.[Prior WIP GM] AS [MOM Variance of Projected Final Gross Margin]
,	wip.[Current WIP GM %] - wip.[Prior WIP GM %] AS [MOM Variance of Projected Final Gross Margin %]
,	GETDATE() AS [Processed On]
FROM
	(SELECT	currWip.JCCo
	 ,		currWip.Contract
	 ,		currWip.GLDepartment
	 ,		currWip.GLDepartmentName
	 ,		currWip.RevenueType
	 ,		currWip.ContractStatus
	 ,		currWip.POCName
	 ,		currWip.SalesPerson
	 --,	currWip.RevenueOverridePercent
	 ,		prevWip.[Percent Complete] AS [PrevPercComplete]
	 ,		SUM(ISNULL(currWip.[CommittedCostAmount], 0)) as [CommittedCostAmount]
	 ,		SUM(ISNULL(currWip.[CurrContractAmt], 0)) as [Current Contract Value]
	 ,		SUM(ISNULL(currWip.[JTD Actual Cost], 0)) as [Current JTD Actual Cost]
	 ,		SUM(ISNULL(currWip.[JTD Billed], 0)) as [Current JTD Amount Billed]
	 ,		SUM(ISNULL(currWip.[JTD Earned Revenue], 0)) as [Current JTD Revenue Earned]
	 ,		SUM(ISNULL(currWip.Overbilled, 0)) - SUM(ISNULL(currWip.Underbilled, 0)) as [Current JTD Net Under Over Billed]
	 ,		SUM(ISNULL(currWip.[JTD Earned Gross Margin], 0)) as [Current JTD Net Cash Position]
	 ,		SUM(ISNULL(currWip.[Projected Final Cost], 0)) as [Current Projected Cost]
	 ,		SUM(ISNULL(currWip.[Projected Final Contract Value], 0)) as [Current WIP Revenue]
	 ,		SUM(ISNULL(currWip.[Projected Final Cost], 0)) as [Current WIP Cost]
	 ,		SUM(ISNULL(currWip.[Projected Final Gross Margin], 0)) as [Current WIP GM]
	 ,		CASE SUM(ISNULL(currWip.[Projected Final Contract Value], 0)) 
				 WHEN 0
				 THEN 0.0
				 ELSE CAST(SUM(ISNULL(currWip.[Projected Final Gross Margin], 0))/SUM(ISNULL(currWip.[Projected Final Contract Value], 0)) AS DECIMAL(18,10)) 
			END AS [Current WIP GM %]
	 ,		SUM(ISNULL(prevWip.[JTD Actual Cost], 0)) as [Prior JTD Actual Cost]
	 ,		SUM(ISNULL(prevWip.[ProjectedCost], 0)) as [Prior Projected Cost]
	 ,		SUM(ISNULL(prevWip.[JTD Billed], 0)) as [Prior JTD Amount Billed]
	 ,		SUM(ISNULL(prevWip.[JTD Earned Revenue], 0)) as [Prior JTD Revenue Earned]
	 ,		SUM(ISNULL(prevWip.[JTD Earned Revenue], 0)) - SUM(ISNULL(prevWip.[JTD Billed], 0)) as [Prior JTD Net Under Over Billed]
	 ,		SUM(ISNULL(prevWip.[Projected Final Contract Value], 0)) as [Prior WIP Revenue]
	 ,		SUM(ISNULL(prevWip.[Projected Final Cost], 0)) as [Prior WIP Cost]
	 ,		SUM(ISNULL(prevWip.[Projected Final Gross Margin], 0)) as [Prior WIP GM]
	 ,		CASE SUM(ISNULL(prevWip.[Projected Final Contract Value], 0)) 
				 WHEN 0
				 THEN 0.0
				 ELSE CAST(SUM(ISNULL(prevWip.[Projected Final Gross Margin], 0))/SUM(ISNULL(prevWip.[Projected Final Contract Value], 0)) AS DECIMAL(18,10))
			END AS [Prior WIP GM %]
	 ,		SUM(ISNULL(currWip.[OrigContractAmt], 0)) - SUM(ISNULL(currWip.[Original Cost Budget], 0)) AS OrigGM
	 ,		CASE WHEN ISNULL(SUM(currWip.[OrigContractAmt]),0)=0 THEN 0
				 ELSE CAST(((SUM(currWip.[OrigContractAmt])-ISNULL(SUM(currWip.[Original Cost Budget]),0))/SUM(currWip.[OrigContractAmt])) AS DECIMAL(18,10)) 
			END AS OrigGMPerc
	 FROM	
		(SELECT JCCo, Contract, ContractStatus, GLDepartment, GLDepartmentName, IsLocked, RevenueType, [CurrContractAmt], [ProjContractAmt], [ProjectedCost], [JTD Actual Cost], [JTD Billed], [JTD Earned Revenue], Overbilled, Underbilled, [JTD Earned Gross Margin], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [CommittedCostAmount], [POCName], [SalesPerson], [OrigContractAmt], [Original Cost Budget], [RevenueOverridePercent]
			FROM dbo.mvwWIPReport 
			WHERE	ThroughMonth=@thisMonth
			AND	Contract IS NOT NULL
			AND (@company IS NULL OR JCCo = @company)
			AND (@contract IS NULL OR Contract = @contract)
			AND (@dept IS NULL OR GLDepartment = @dept)
			AND ContractStatus IN (1,2) 
			AND IsLocked = 'Y') currWip LEFT JOIN
		(SELECT JCCo, Contract, GLDepartment, IsLocked, RevenueType, [CurrContractAmt], [ProjContractAmt], [ProjectedCost], [JTD Actual Cost], [JTD Billed], [JTD Earned Revenue], Overbilled, Underbilled, [JTD Earned Gross Margin], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Percent Complete]
			FROM dbo.mvwWIPReport 
			WHERE	ThroughMonth=@lastMonth
			AND	Contract IS NOT NULL
			AND (@company IS NULL OR JCCo = @company)
			AND (@contract IS NULL OR Contract = @contract)
			AND (@dept IS NULL OR GLDepartment = @dept)
			AND ContractStatus IN (1,2) 
			AND IsLocked = 'Y') prevWip
		ON  currWip.JCCo=prevWip.JCCo
			AND currWip.Contract=prevWip.Contract
			AND currWip.GLDepartment=prevWip.GLDepartment
			AND	currWip.IsLocked=prevWip.IsLocked
			AND	currWip.RevenueType=prevWip.RevenueType
	 GROUP BY
			currWip.JCCo
	 ,		currWip.Contract
	 ,		currWip.GLDepartment
	 ,		currWip.GLDepartmentName
	 ,		currWip.RevenueType
	 ,		currWip.ContractStatus
	 ,		currWip.POCName
	 ,		currWip.SalesPerson
	 --,	currWip.RevenueOverridePercent
	 ,		prevWip.[Percent Complete]
	 ) wip 
ORDER BY 
		wip.JCCo
,		wip.Contract 
	 
---------------------------------
-- *** CONTRACT & CUSTOMER *** --
---------------------------------
UPDATE	wip
SET		[Contract Description]=ISNULL(c.Description, '')
,		[Completion Date]=CASE WHEN ([Contract Status] < 2) THEN c.ProjCloseDate ELSE c.ActualCloseDate END
,		[Last Revenue Projection]=c.MaxRevProjDate
,		[Last Cost Projection]=c.MaxCostProjDate
,		[Projected Final Billing]=ISNULL(c.ProjFinalBilling, 0)
,		[Customer #]=ISNULL(c.Customer, 0)
,		[Current Retention Unbilled]=ISNULL(c.CurrentRetainAmt, 0.0)
,		[Customer Name]=ISNULL(arcm.Name, '')
,		[Customer Contact Name]=ISNULL(arcm.Contact, '')
,		[Customer Phone Number]=ISNULL(arcm.Phone, '')
,		[Customer Email Address]=ISNULL(arcm.EMail, '')
FROM	#tmpProjReport wip 
		LEFT OUTER JOIN 
			(SELECT jccm.JCCo, ltrim(rtrim(jccm.Contract)) AS Contract, jccm.Description, jccm.ProjCloseDate, jccm.ActualCloseDate, jccm.Customer, jccm.CustGroup, jccm.CurrentRetainAmt
				   ,MAX(jcip.Mth) AS MaxRevProjDate
				   ,j.Mth AS MaxCostProjDate
				   ,CASE WHEN ISNULL(jccm.ContractAmt, 0) <= ISNULL(j.ProjBilling, 0) THEN ISNULL(jccm.ContractAmt, 0) ELSE ISNULL(j.ProjBilling, 0) END AS ProjFinalBilling
			 FROM	dbo.JCCM jccm INNER JOIN
						(SELECT JCCo, Contract, Item FROM dbo.JCCI
						 WHERE (JCCo=@company OR @company IS NULL)
						   AND (@contract is null OR ltrim(rtrim(Contract))=@contract)
						)jcci
					 ON	 jcci.JCCo=jccm.JCCo
					 AND jcci.Contract=jccm.Contract LEFT OUTER JOIN
						 dbo.JCIP jcip
					 ON  jcci.JCCo=jcip.JCCo
					 AND jcci.Contract=jcip.Contract
					 AND jcci.Item=jcip.Item
					 AND jcip.Mth <= @effDate LEFT OUTER JOIN
						(SELECT jcjp.JCCo
							   ,jcjp.Contract
							   ,MAX(jccp.Mth) AS Mth
							   ,SUM(CASE WHEN 
											(CASE WHEN jcch.CostType IN (1) AND jcch.udSellRate IS NOT NULL AND jcch.udSellRate <> 0
												THEN (ISNULL(jccp.ProjHours,0.00) * ISNULL(jcch.udSellRate, 0.00)) + (ISNULL(jccp.ProjCost,0.00) * ISNULL(jcch.udMarkup,0.00)) 
											 WHEN jcch.CostType IN (1) AND jccp.ProjCost <> 0 AND (jcch.udSellRate IS NULL OR jcch.udSellRate = 0)
												THEN ISNULL(jccp.ProjCost, jccp.CurrEstCost)
											 WHEN jcch.CostType IN (1) AND jccp.ProjCost = 0 AND (jcch.udSellRate IS NULL OR jcch.udSellRate = 0)
												THEN (jccp.CurrEstCost)
											 WHEN ISNULL(jccp.ProjCost,0.00) + (ISNULL(jccp.ProjCost,0.00) * ISNULL(jcch.udMarkup, 0.00)) <> 0
												THEN ISNULL(jccp.ProjCost,0.00) + (ISNULL(jccp.ProjCost,0.00) * ISNULL(jcch.udMarkup, 0.00))
											 ELSE jccp.CurrEstCost 
											 END) < 0 
										 THEN 0 
										 ELSE
											 (CASE WHEN jcch.CostType IN (1) AND jcch.udSellRate IS NOT NULL AND jcch.udSellRate <> 0
												THEN (ISNULL(jccp.ProjHours,0.00) * ISNULL(jcch.udSellRate, 0.00)) + (ISNULL(jccp.ProjCost,0.00) * ISNULL(jcch.udMarkup,0.00)) 
											 WHEN jcch.CostType IN (1) AND jccp.ProjCost <> 0 AND (jcch.udSellRate IS NULL OR jcch.udSellRate = 0)
												THEN ISNULL(jccp.ProjCost, jccp.CurrEstCost)
											 WHEN jcch.CostType IN (1) AND jccp.ProjCost = 0 AND (jcch.udSellRate IS NULL OR jcch.udSellRate = 0)
												THEN (jccp.CurrEstCost)
											 WHEN ISNULL(jccp.ProjCost,0.00) + (ISNULL(jccp.ProjCost,0.00) * ISNULL(jcch.udMarkup, 0.00)) <> 0
												THEN ISNULL(jccp.ProjCost,0.00) + (ISNULL(jccp.ProjCost,0.00) * ISNULL(jcch.udMarkup, 0.00))
											 ELSE jccp.CurrEstCost 
											 END) 
										 END) AS ProjBilling
						 FROM	dbo.JCJP jcjp INNER JOIN
								dbo.JCCP jccp ON
								jcjp.JCCo=jccp.JCCo
							AND jcjp.Job=jccp.Job
							AND jcjp.Phase=jccp.Phase
							AND jcjp.PhaseGroup=jccp.PhaseGroup		
							AND jccp.Mth <= @effDate
							AND (jcjp.JCCo=@company OR @company IS NULL)
							AND (@contract is null OR ltrim(rtrim(jcjp.Contract))=@contract) LEFT OUTER JOIN
								dbo.JCCH jcch ON 
								jcch.Job=jccp.Job 
							AND jcch.JCCo=jccp.JCCo 
							AND jcch.PhaseGroup=jccp.PhaseGroup 
							AND jcch.Phase=jccp.Phase 
							AND jcch.CostType=jccp.CostType
						 GROUP BY 
							jcjp.JCCo
						   ,jcjp.Contract) j
					 ON  jccm.JCCo=j.JCCo
					 AND jccm.Contract=j.Contract 
				GROUP BY
					jccm.JCCo, jccm.Contract, jccm.Description, jccm.ProjCloseDate, jccm.ActualCloseDate, jccm.Customer, jccm.CustGroup, jccm.CurrentRetainAmt, jccm.ContractAmt, j.Mth, j.ProjBilling) c
			ON	wip.JCCo=c.JCCo
			AND wip.Contract=c.Contract
		LEFT OUTER JOIN dbo.ARCM arcm
			ON c.CustGroup=arcm.CustGroup
			AND c.Customer=arcm.Customer

-----------------------------
-- *** AR AGED AMOUNTS *** --
-----------------------------
UPDATE	wip
SET		[Partition Ratio] = CASE WHEN tot.ContractJTDBilledAmt = 0 THEN 1.0
								 ELSE CAST([Current JTD Amount Billed]/tot.ContractJTDBilledAmt AS DECIMAL(18,15))
							END
FROM	#tmpProjReport wip JOIN
		--(SELECT	jcci.JCCo, jcci.Contract, SUM(jcip.BilledAmt) AS ContractJTDBilledAmt
		-- FROM	dbo.JCCI jcci JOIN
		--		dbo.JCIP jcip ON
		--		jcci.JCCo=jcip.JCCo
		--	AND jcci.Contract=jcip.Contract
		--	AND jcci.Item=jcip.Item
		--	AND jcip.Mth <= @thisMonth --@effDate
		--	WHERE jcci.udLockYN = 'Y'
		--	GROUP BY 
		--		jcci.JCCo, 
		--		jcci.Contract) tot
		(SELECT	JCCo, Contract, SUM([Current JTD Amount Billed]) AS ContractJTDBilledAmt
		 FROM	#tmpProjReport
		 GROUP BY JCCo, Contract) tot
		ON	wip.JCCo=tot.JCCo
		AND wip.Contract=tot.Contract

UPDATE  wip
SET		[Current Retention Unbilled] = wip.[Partition Ratio] * [Current Retention Unbilled]
,		[Unpaid A/R Balance]= wip.[Partition Ratio] * (ISNULL(ar.[Current], 0.0) + ISNULL(ar.[31-60 Days], 0.0) + ISNULL(ar.[61-90 Days], 0.0) + ISNULL(ar.[>91 Days], 0.0))
,		[AR Current Amount]= wip.[Partition Ratio] * (ISNULL(ar.[Current], 0.0))
,		[AR 31-60 Days Amount]= wip.[Partition Ratio] * (ISNULL(ar.[31-60 Days], 0.0))
,		[AR 61-90 Days Amount]= wip.[Partition Ratio] * (ISNULL(ar.[61-90 Days], 0.0))
,		[AR Over 90 Amount]= wip.[Partition Ratio] * (ISNULL(ar.[>91 Days], 0.0))
FROM	#tmpProjReport wip 
		LEFT OUTER JOIN
			--(SELECT * FROM dbo.mvwARAgedAmount WHERE @company IS NULL OR ARTH.ARCo=@company) ar
			(SELECT *
			 FROM   (SELECT	ARCo, 
							ltrim(rtrim(InvoiceContract)) AS [Contract], 
							DaysBracket, 
							COALESCE (SUM(AgeAmount), 0.0) AS AgeAmount
                     FROM  (SELECT	ARTH.ARCo, 
									InvoiceContract = ISNULL(ARTH.Contract, ARTL.Contract), 
									AgeDate = ARTH.DueDate, 
									DaysFromAge = DATEDIFF(day, ARTH.DueDate, @effDate), 
									DaysBracket = CASE	WHEN (DATEDIFF(day, ARTH.DueDate, @effDate) <= 30) THEN 'Current' 
														WHEN (DATEDIFF(day, ARTH.DueDate, @effDate) > 30 AND DATEDIFF(day, ARTH.DueDate, @effDate) <= 60) THEN '31-60 Days' 
														WHEN (DATEDIFF(day, ARTH.DueDate, @effDate) > 60 AND DATEDIFF(day, ARTH.DueDate, @effDate) <= 90) 
                                                        THEN '61-90 Days' ELSE '>91 Days' END, 
									Amount = isnull(ARTL.Amount, 0) - 0, 
									Retainage = isnull(ARTL.Retainage, 0) - 0, 
									AgeAmount = isnull(ARTL.Amount, 0) - isnull(ARTL.Retainage, 0) - 0
							FROM    ARTL ARTL WITH (NOLOCK) JOIN
                                    ARTH ARTH WITH (NOLOCK) ON ARTL.ARCo = ARTH.ARCo AND ARTL.ApplyMth = ARTH.Mth AND ARTL.ApplyTrans = ARTH.ARTrans
							WHERE   --ARTH.TransDate <= @effDate AND
								    ARTL.RecType = 1
								AND (@company IS NULL OR ARTH.ARCo=@company)
					 ) Data
					 GROUP BY ARCo, InvoiceContract, DaysBracket
                     HAVING	COALESCE (SUM(AgeAmount), 0.0) <> 0) Aggr 
			 PIVOT	(SUM(AgeAmount) FOR DaysBracket IN ([Current], [31-60 Days], [61-90 Days], [>91 Days])) Piv) ar
		ON	wip.JCCo=ar.ARCo
		AND wip.Contract=ar.Contract

-------------------------------
-- *** NET CASH POSITION *** --
-------------------------------
UPDATE	wip
SET		[JTD Net Cash Position]=ncp.JTDNetCashPosition
FROM	#tmpProjReport wip	
		INNER JOIN
			(SELECT jcs.JCCo, ltrim(rtrim(jcs.Contract)) AS Contract, jcci.udRevType AS RevenueType, d.Instance as GLDepartment, (SUM(jcs.ReceivedAmt)-SUM(jcs.ActualCost)+SUM(CASE WHEN jcs.RecType=3 then jcs.APOpenAmt ELSE 0 END)) AS JTDNetCashPosition
			 FROM	--dbo.brvJCContStat jcs (NOLOCK) LEFT OUTER JOIN
				(SELECT JCCo, Contract, COALESCE(Item, (select top 1 Item from JCCI where JCCo=b.JCCo AND Contract=b.Contract and udRevType<>'N')) as Item, RecType, SUM(ReceivedAmt) AS ReceivedAmt, SUM(ActualCost) AS ActualCost, SUM(APOpenAmt) AS APOpenAmt 
				 FROM	dbo.brvJCWIPCashFlow (NOLOCK) b
					WHERE 	Mth < @effDate
						AND PaidMth >= @effDate
						AND (@company IS NULL OR JCCo = @company)
						AND (@contract IS NULL OR Contract = @contract)
					GROUP BY JCCo, Contract, Item, RecType
				) jcs LEFT OUTER JOIN
					dbo.JCCI jcci ON
						jcci.JCCo=jcs.JCCo
					AND jcci.Contract=jcs.Contract
					AND jcci.Item=jcs.Item LEFT OUTER JOIN
				(SELECT jcdm.JCCo, jcdm.Department, glpi.Instance
				 FROM	dbo.JCDM jcdm JOIN
						dbo.GLPI glpi ON
						jcdm.GLCo=glpi.GLCo
					AND glpi.PartNo=3
					AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4)) d ON
						jcci.JCCo=d.JCCo
					AND jcci.Department=d.Department
			 GROUP BY jcs.JCCo, jcs.Contract, d.Instance, jcci.udRevType
			) ncp
		ON	wip.JCCo=ncp.JCCo
		AND wip.Contract=ncp.Contract
		AND wip.[GL Department]=ncp.GLDepartment
		AND wip.[Revenue Type]=ncp.RevenueType

IF EXISTS (SELECT 1 FROM dbo.mckProjectReport WHERE Month=@thisMonth AND (@company IS NULL OR JCCo=@company) AND (@dept IS NULL OR [GL Department]=@dept) AND (@contract IS NULL OR Contract=@contract))
BEGIN
	DELETE dbo.mckProjectReport WHERE Month=@thisMonth AND (@company IS NULL OR JCCo=@company) AND (@dept IS NULL OR [GL Department]=@dept) AND (@contract IS NULL OR Contract=@contract)
END
INSERT dbo.mckProjectReport SELECT * FROM #tmpProjReport

DROP TABLE #tmpProjReport

END
GO

--Test Script
--EXEC [dbo].[mckrptProjectReportRefresh]
--EXECUTE [dbo].[mckrptProjectReportRefresh] '11/1/2014'
--EXECUTE [dbo].[mckrptProjectReportRefresh] '2/1/2015', 1
--EXEC [dbo].[mckrptProjectReportRefresh] '1/1/2015', 1, '0000'