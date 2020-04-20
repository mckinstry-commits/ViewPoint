IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptRevGMJoin]'))
	DROP PROCEDURE [dbo].[mckrptRevGMJoin]
GO

-- =================================================================================================================================
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 04/17/2015 Amit Mody			Authored
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mckrptRevGMJoin] 
	@company	tinyint			= NULL,
	@dept		varchar(4)		= NULL,
	@mthfrom	smalldatetime	= NULL,
	@mthto		smalldatetime	= NULL
AS
BEGIN
	-- Period Validation
	IF (@mthfrom IS NULL)
		SET @mthfrom = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)	-- Jan 1 of current year
	ELSE
		SET @mthfrom = dbo.mfnFirstOfMonth(@mthfrom)
	SET @mthfrom = DATEADD(MONTH, DATEDIFF(MONTH, 0, @mthfrom)-1, 0)

	IF (@mthto IS NULL)
		SET @mthto = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)	-- 1st of current month
	ELSE
		SET @mthto = dbo.mfnFirstOfMonth(@mthto)

	IF (@mthto < @mthfrom)
		SET @mthto = @mthfrom

	--SELECT * FROM (
	SELECT	revgm.[JCCo]
	,		revgm.[GLDepartment] AS [GL Dept.]
	,		revgm.[GLDepartmentName] AS [GL Dept. Name]
	,		revgm.[Contract]
	,		revgm.[WorkOrder] AS [Work Order]
	,		revgm.[Contract Description]
	,		revgm.[ContractStatusDesc] AS [Contract Status]
	,		ISNULL(jccm.Customer, '') AS [Customer Number]
	,		ISNULL(c.Name, '') AS [Customer Name]
	,		revgm.[POCName] AS [POC Name]
	,		revgm.[SalesPerson] AS [Sales Person]
	,		revgm.[VerticalMarket] AS [Vertical Market]
	,		ISNULL([CRMNums], '') AS [CRM Oppty Numbers]
	,		revgm.[RevenueTypeName] AS [Revenue Type]

	,		ISNULL(revgm.[OrigContractAmt], 0.0) AS [Original Contract Amount]
	,		ISNULL(revgm.[Original Cost Budget], 0.0) AS [Original Cost]
	,		(ISNULL(revgm.[OrigContractAmt], 0.0) - ISNULL(revgm.[Original Cost Budget], 0.0)) AS [Original Gross Margin]
	,		CASE WHEN ISNULL(revgm.[OrigContractAmt], 0.0) = 0.0 THEN 0.0
				 ELSE CAST((revgm.[OrigContractAmt] - ISNULL(revgm.[Original Cost Budget], 0.0))/revgm.[OrigContractAmt] AS DECIMAL(18,10))
			END AS [Original Gross Margin %]

	,		ISNULL(latestwip.[Projected Final Contract Value], 0.0) AS [Projected Final Contract Amount]
	,		ISNULL(latestwip.[Projected Final Cost], 0.0) AS [Projected Final Cost] 
	,		ISNULL(latestwip.[Projected Final Gross Margin], 0.0) AS [Projected Final Gross Margin] 
	,		ISNULL(latestwip.[Projected Final Gross Margin %], 0.0) [Projected Final Gross Margin %] 
	
	,		ISNULL(revgm.[Projected Final Contract Value], 0.0) - ISNULL(fromwip.[Projected Final Contract Value], 0.0) AS [Period Change in Projected Contract Amount]
	,		ISNULL(revgm.[Projected Final Gross Margin], 0.0) - ISNULL(fromwip.[Projected Final Gross Margin], 0.0) AS [Period Change in Projected Final Gross Margin]
	,		CASE WHEN (ISNULL(revgm.[Projected Final Contract Value], 0.0) - ISNULL(fromwip.[Projected Final Contract Value], 0.0) = 0.0) THEN 0.0
										  ELSE CAST((ISNULL(revgm.[Projected Final Gross Margin], 0.0) - ISNULL(fromwip.[Projected Final Gross Margin], 0.0))/(ISNULL(revgm.[Projected Final Contract Value], 0.0) - ISNULL(fromwip.[Projected Final Contract Value], 0.0)) AS DECIMAL(18,10))
									 END AS [Period Change in Projected Final Gross Margin %]

	,		CASE WHEN fromwip.Contract IS NOT NULL THEN NULL ELSE ISNULL(revgm.[Projected Final Contract Value], 0.0) END AS [New Projected Final Contract Amount]
	,		CASE WHEN fromwip.Contract IS NOT NULL THEN NULL ELSE ISNULL(revgm.[Projected Final Gross Margin], 0.0) END AS [New Projected Final Gross Margin]
	,		CASE WHEN fromwip.Contract IS NOT NULL THEN NULL ELSE ISNULL(revgm.[Projected Final Gross Margin %], 0.0) END AS [New Projected Final Gross Margin %]

	,		ISNULL(cumwip.[PeriodEarnedRev], 0.0) AS [Period Earned Revenue]
	,		ISNULL(cumwip.[PeriodEarnedGM], 0.0) AS [Period Earned Gross Margin]
	,		CASE WHEN ISNULL(cumwip.[PeriodEarnedRev], 0.0) = 0.0 THEN 0.0
				 ELSE CAST(ISNULL(cumwip.[PeriodEarnedGM], 0.0)/cumwip.[PeriodEarnedRev] AS DECIMAL(18,10))
			END AS [Period Earned Gross Margin %]

	FROM	(SELECT * FROM mvwWIPReport
			 WHERE	ThroughMonth = @mthto
				AND Contract IS NOT NULL
				AND	(@company IS NULL OR JCCo=@company)
				AND	(@dept IS NULL OR GLDepartment=@dept)
				AND ContractStatus NOT IN (0,3)
				AND	RevenueType <> 'N'
				AND (IsLocked = 'Y' OR WorkOrder IS NOT NULL)) revgm
			LEFT JOIN dbo.mvwContractCRMNums crm ON revgm.Contract=crm.Contract
			LEFT JOIN (SELECT JCCo, LTRIM(RTRIM(Contract)) AS Contract, CustGroup, Customer FROM JCCM) jccm ON revgm.JCCo=jccm.JCCo AND revgm.Contract=jccm.Contract
			LEFT JOIN ARCM c ON jccm.CustGroup=c.CustGroup AND jccm.Customer=c.Customer
			LEFT JOIN mvwWIPReport latestwip 
				ON  revgm.JCCo = latestwip.JCCo 
				AND revgm.Contract = latestwip.Contract
				AND	revgm.[GLDepartment]= latestwip.GLDepartment
				AND latestwip.ThroughMonth=DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
			LEFT JOIN mvwWIPReport fromwip
				ON  revgm.JCCo = fromwip.JCCo 
				AND revgm.Contract = fromwip.Contract
				AND	revgm.[GLDepartment]= fromwip.GLDepartment
				AND fromwip.ThroughMonth=@mthfrom
				AND	fromwip.[Projected Final Contract Value] <> 0
			LEFT JOIN (SELECT	JCCo
						,	GLDepartment
						,	Contract
						,	SUM(ISNULL([MTD Earned Revenue], 0.0)) AS [PeriodEarnedRev]
						,	SUM(ISNULL([MTD Earned Gross Margin], 0.0)) AS [PeriodEarnedGM]
					 FROM	mvwWIPReport wip
					 WHERE	ThroughMonth > @mthfrom AND ThroughMonth <= @mthto
						AND wip.Contract IS NOT NULL
					 GROUP BY JCCo, GLDepartment, Contract
					) cumwip
				ON  revgm.JCCo = cumwip.JCCo
				AND revgm.Contract = cumwip.Contract
				AND	revgm.[GLDepartment] = cumwip.GLDepartment
	
	UNION ALL
	
	SELECT	revgm.[JCCo]
	,		revgm.[GLDepartment] AS [GL Dept.]
	,		revgm.[GLDepartmentName] AS [GL Dept. Name]
	,		revgm.[Contract]
	,		revgm.[WorkOrder] AS [Work Order]
	,		revgm.[Contract Description]
	,		revgm.[ContractStatusDesc] AS [Contract Status]
	,		ISNULL(wo.Customer, '') AS [Customer Number]
	,		ISNULL(c.Name, '') AS [Customer Name]
	,		revgm.[POCName] AS [POC Name]
	,		revgm.[SalesPerson] AS [Sales Person]
	,		revgm.[VerticalMarket] AS [Vertical Market]
	,		NULL AS [CRM Oppty Numbers]
	,		revgm.[RevenueTypeName] AS [Revenue Type]

	,		ISNULL(revgm.[OrigContractAmt], 0.0) AS [Original Contract Amount]
	,		ISNULL(revgm.[Original Cost Budget], 0.0) AS [Original Cost]
	,		(ISNULL(revgm.[OrigContractAmt], 0.0) - ISNULL(revgm.[Original Cost Budget], 0.0)) AS [Original Gross Margin]
	,		CASE WHEN ISNULL(revgm.[OrigContractAmt], 0.0) = 0.0 THEN 0.0
				 ELSE CAST((revgm.[OrigContractAmt] - ISNULL(revgm.[Original Cost Budget], 0.0))/revgm.[OrigContractAmt] AS DECIMAL(18,10))
			END AS [Original Gross Margin %]

	,		ISNULL(latestwip.[Projected Final Contract Value], 0.0) AS [Projected Final Contract Amount]
	,		ISNULL(latestwip.[Projected Final Cost], 0.0) AS [Projected Final Cost] 
	,		ISNULL(latestwip.[Projected Final Gross Margin], 0.0) AS [Projected Final Gross Margin] 
	,		ISNULL(latestwip.[Projected Final Gross Margin %], 0.0) [Projected Final Gross Margin %] 
	
	,		ISNULL(revgm.[Projected Final Contract Value], 0.0) - ISNULL(fromwip.[Projected Final Contract Value], 0.0) AS [Period Change in Projected Contract Amount]
	,		ISNULL(revgm.[Projected Final Gross Margin], 0.0) - ISNULL(fromwip.[Projected Final Gross Margin], 0.0) AS [Period Change in Projected Final Gross Margin]
	,		CASE WHEN (ISNULL(revgm.[Projected Final Contract Value], 0.0) - ISNULL(fromwip.[Projected Final Contract Value], 0.0) = 0.0) THEN 0.0
										  ELSE CAST((ISNULL(revgm.[Projected Final Gross Margin], 0.0) - ISNULL(fromwip.[Projected Final Gross Margin], 0.0))/(ISNULL(revgm.[Projected Final Contract Value], 0.0) - ISNULL(fromwip.[Projected Final Contract Value], 0.0)) AS DECIMAL(18,10))
									 END AS [Period Change in Projected Final Gross Margin %]

	,		CASE WHEN fromwip.Contract IS NOT NULL THEN NULL ELSE ISNULL(revgm.[Projected Final Contract Value], 0.0) END AS [New Projected Final Contract Amount]
	,		CASE WHEN fromwip.Contract IS NOT NULL THEN NULL ELSE ISNULL(revgm.[Projected Final Gross Margin], 0.0) END AS [New Projected Final Gross Margin]
	,		CASE WHEN fromwip.Contract IS NOT NULL THEN NULL ELSE ISNULL(revgm.[Projected Final Gross Margin %], 0.0) END AS [New Projected Final Gross Margin %]

	,		ISNULL(cumwip.[PeriodEarnedRev], 0.0) AS [Period Earned Revenue]
	,		ISNULL(cumwip.[PeriodEarnedGM], 0.0) AS [Period Earned Gross Margin]
	,		CASE WHEN ISNULL(cumwip.[PeriodEarnedRev], 0.0) = 0.0 THEN 0.0
				 ELSE CAST(ISNULL(cumwip.[PeriodEarnedGM], 0.0)/cumwip.[PeriodEarnedRev] AS DECIMAL(18,10))
			END AS [Period Earned Gross Margin %]
	FROM	(SELECT * FROM mvwWIPReport
			 WHERE	ThroughMonth = @mthto
				AND WorkOrder IS NOT NULL
				AND	(@company IS NULL OR JCCo=@company)
				AND	(@dept IS NULL OR GLDepartment=@dept)
				AND ContractStatus NOT IN (0,3)
				AND	RevenueType <> 'N'
				AND (IsLocked = 'Y' OR WorkOrder IS NOT NULL)) revgm
			LEFT JOIN (SELECT JCCo, LTRIM(RTRIM(WorkOrder)) AS WorkOrder, CustGroup, Customer FROM SMWorkOrder) wo ON revgm.[WorkOrder]=wo.WorkOrder
			LEFT JOIN SMCustomerInfo c ON wo.CustGroup=c.CustGroup AND wo.Customer=c.Customer
			LEFT JOIN mvwWIPReport latestwip 
				ON  revgm.JCCo = latestwip.JCCo 
				AND revgm.WorkOrder = latestwip.WorkOrder
				AND	revgm.[GLDepartment]= latestwip.GLDepartment
				AND latestwip.ThroughMonth=DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
			LEFT JOIN mvwWIPReport fromwip
				ON  revgm.JCCo = fromwip.JCCo 
				AND revgm.WorkOrder = fromwip.WorkOrder
				AND	revgm.[GLDepartment]= fromwip.GLDepartment
				AND fromwip.ThroughMonth=@mthfrom
				AND	fromwip.[Projected Final Contract Value] <> 0
			LEFT JOIN (SELECT	JCCo
					,	GLDepartment
					,	WorkOrder
					,	SUM(ISNULL([MTD Earned Revenue], 0.0)) AS [PeriodEarnedRev]
					,	SUM(ISNULL([MTD Earned Gross Margin], 0.0)) AS [PeriodEarnedGM]				
				 FROM	mvwWIPReport wip
				 WHERE	ThroughMonth > @mthfrom AND ThroughMonth <= @mthto
					AND wip.WorkOrder IS NOT NULL
				 GROUP BY JCCo, GLDepartment, WorkOrder
				) cumwip
			ON  revgm.JCCo = cumwip.JCCo
			AND revgm.[WorkOrder] = cumwip.WorkOrder
			AND	revgm.[GLDepartment] = cumwip.GLDepartment
	--) u
	--ORDER BY 1, 2, 4, 5
END
GO

--Test Script
--EXEC dbo.[mckrptRevGMJoin]
--EXEC dbo.[mckrptRevGMJoin] 1
--EXEC dbo.[mckrptRevGMJoin] 1, '0000'
--EXEC dbo.[mckrptRevGMJoin] 1, null, '4/1/2015'
--EXEC dbo.[mckrptRevGMJoin] 1, '0000', '4/1/2015', '4/30/2015'
--EXEC dbo.[mckrptRevGMJoin] 1, '0521', '4/1/2015', '4/30/2015'

--Validation script
--EXEC dbo.[mckrptRevGMJoin] 1, '0000', '11/1/2014', '12/1/2014'
--select distinct [MTD Earned Revenue], Contract, OrigContractAmt, [Original Cost Budget], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Projected Final Gross Margin %] from mvwWIPReport where ContractStatus in (1,2) and IsLocked = 'Y' and JCCo=1 AND GLDepartment='0000' and RevenueType <> 'N' and ThroughMonth='10/1/2014' and Contract='10938-'
--select distinct [MTD Earned Revenue], Contract, OrigContractAmt, [Original Cost Budget], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Projected Final Gross Margin %] from mvwWIPReport where ContractStatus in (1,2) and IsLocked = 'Y' and JCCo=1 AND GLDepartment='0000' and RevenueType <> 'N' and ThroughMonth='11/1/2014' and Contract='10938-'
--select distinct [MTD Earned Revenue], Contract, OrigContractAmt, [Original Cost Budget], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Projected Final Gross Margin %] from mvwWIPReport where ContractStatus in (1,2) and IsLocked = 'Y' and JCCo=1 AND GLDepartment='0000' and RevenueType <> 'N' and ThroughMonth='12/1/2014' and Contract='10938-'
--select [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Projected Final Gross Margin %] from mvwWIPReport where Contract='10938-' and ThroughMonth='4/1/2015'