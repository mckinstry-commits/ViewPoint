IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptRevGM]'))
	DROP PROCEDURE [dbo].[mckrptRevGM]
GO

-- =================================================================================================================================
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 04/17/2015 Amit Mody			Authored
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mckrptRevGM] 
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

	DECLARE @sid uniqueidentifier
	SET @sid = NEWID()
	
	INSERT INTO dbo.mckRevGM
	SELECT	@sid
	,		[JCCo]
	,		[GLDepartment]
	,		[GLDepartmentName]
	,		[Contract]
	,		[WorkOrder]
	,		[Contract Description] 
	,		[ContractStatusDesc]
	,		NULL AS [Customer Number]
	,		NULL AS [Customer Name]
	,		[POCName]
	,		[SalesPerson]
	,		[VerticalMarket]
	,		NULL AS [CRM Oppty Numbers]
	,		[RevenueTypeName]

	,		ISNULL([OrigContractAmt], 0.0)
	,		ISNULL([Original Cost Budget], 0.0)
	,		(ISNULL([OrigContractAmt], 0.0) - ISNULL([Original Cost Budget], 0.0))
	,		CASE WHEN ISNULL([OrigContractAmt], 0.0) = 0.0 THEN 0.0
				 ELSE CAST(([OrigContractAmt] - ISNULL([Original Cost Budget], 0.0))/[OrigContractAmt] AS [decimal](18, 2))
			END

	,		NULL AS [Projected Final Contract Amount]
	,		NULL AS [Projected Final Cost]
	,		NULL AS [Projected Final Gross Margin]
	,		NULL AS [Projected Final Gross Margin %]

	,		ISNULL([Projected Final Contract Value], 0.0)
	,		ISNULL([Projected Final Gross Margin], 0.0)
	,		ISNULL([Projected Final Gross Margin %], 0.0)

	,		ISNULL([Projected Final Contract Value], 0.0)
	,		ISNULL([Projected Final Gross Margin], 0.0)
	,		ISNULL([Projected Final Gross Margin %], 0.0)

	,		NULL AS [Period Earned Revenue]
	,		NULL AS [Period Earned Gross Margin]
	,		NULL AS [Period Earned Gross Margin %]
	FROM	mvwWIPReport wip		
	WHERE	ThroughMonth = @mthto
		AND	(@company IS NULL OR JCCo=@company)
		AND	(@dept IS NULL OR GLDepartment=@dept)
		AND ContractStatus NOT IN (0,3)
		AND	RevenueType <> 'N'
		AND (IsLocked = 'Y' OR WorkOrder IS NOT NULL)

	-- Enrich Contracts
		UPDATE  revgm
		SET		[CRM Oppty Numbers]=ISNULL([CRMNums], '')
		FROM	dbo.mckRevGM revgm JOIN dbo.mvwContractCRMNums crm ON [SessionId]=@sid AND revgm.Contract=crm.Contract

		UPDATE	revgm
		SET		[Customer Number] = jccm.Customer
		,		[Customer Name] = c.Name
		FROM	dbo.mckRevGM revgm 
				JOIN (SELECT JCCo, LTRIM(RTRIM(Contract)) AS Contract, CustGroup, Customer FROM JCCM) jccm ON [SessionId]=@sid AND revgm.JCCo=jccm.JCCo AND revgm.Contract=jccm.Contract
				LEFT JOIN ARCM c ON jccm.CustGroup=c.CustGroup AND jccm.Customer=c.Customer

		UPDATE	revgm
		SET		[Projected Final Contract Amount] = ISNULL(wip.[Projected Final Contract Value], 0.0)
		,		[Projected Final Cost] = ISNULL(wip.[Projected Final Cost], 0.0)
		,		[Projected Final Gross Margin] = ISNULL(wip.[Projected Final Gross Margin], 0.0)
		,		[Projected Final Gross Margin %] = ISNULL(wip.[Projected Final Gross Margin %], 0.0) 
		FROM	dbo.mckRevGM revgm JOIN mvwWIPReport wip 
			ON  [SessionId]=@sid 
			AND revgm.JCCo = wip.JCCo 
			AND wip.WorkOrder IS NULL 
			AND revgm.Contract = wip.Contract
			AND	revgm.[GL Dept.]= wip.GLDepartment
			AND ThroughMonth=DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)

		UPDATE  revgm
		SET		[Period Change in Projected Contract Amount] = [Period Change in Projected Contract Amount] - ISNULL(wip.[Projected Final Contract Value], 0.0)
		,		[Period Change in Projected Final Gross Margin] = [Period Change in Projected Final Gross Margin] - ISNULL(wip.[Projected Final Gross Margin], 0.0)
		,		[Period Change in Projected Final Gross Margin %] = CASE WHEN ([Period Change in Projected Contract Amount] - ISNULL(wip.[Projected Final Contract Value], 0.0) = 0.0) THEN 0.0
										  ELSE CAST(([Period Change in Projected Final Gross Margin] - ISNULL(wip.[Projected Final Gross Margin], 0.0))/([Period Change in Projected Contract Amount] - ISNULL(wip.[Projected Final Contract Value], 0.0)) AS [decimal](18, 2))
									 END
		,		[New Projected Final Contract Amount] = NULL
		,		[New Projected Final Gross Margin] = NULL
		,		[New Projected Final Gross Margin %] = NULL
		FROM	dbo.mckRevGM revgm JOIN mvwWIPReport wip
			ON  [SessionId]=@sid 
			AND revgm.JCCo = wip.JCCo 
			AND wip.WorkOrder IS NULL 
			AND revgm.Contract = wip.Contract
			AND	revgm.[GL Dept.]= wip.GLDepartment
			AND ThroughMonth=@mthfrom
		WHERE	[Projected Final Contract Value] <> 0
	
		UPDATE  revgm
		SET		[Period Earned Revenue] = wip.[PeriodEarnedRev]
		,		[Period Earned Gross Margin] = wip.[PeriodEarnedGM]
		,		[Period Earned Gross Margin %] = CASE WHEN wip.[PeriodEarnedRev] = 0.0 THEN 0.0
											ELSE CAST(wip.[PeriodEarnedGM]/wip.[PeriodEarnedRev] AS [decimal](18, 2))
									   END
		FROM dbo.mckRevGM revgm JOIN 
			(SELECT	JCCo
				,	GLDepartment
				,	Contract
				,	SUM(ISNULL([MTD Earned Revenue], 0.0)) AS [PeriodEarnedRev]
				,	SUM(ISNULL([MTD Earned Gross Margin], 0.0)) AS [PeriodEarnedGM]
			 FROM	mvwWIPReport wip
			 WHERE	ThroughMonth > @mthfrom AND ThroughMonth <= @mthto
				AND wip.WorkOrder IS NULL
			 GROUP BY JCCo, GLDepartment, Contract
			) wip
			ON  [SessionId]=@sid 
			AND revgm.JCCo = wip.JCCo
			AND revgm.[Work Order] IS NULL 
			AND revgm.Contract = wip.Contract
			AND	revgm.[GL Dept.]= wip.GLDepartment
	
	-- Enrich WorkOrders
		UPDATE	revgm
		SET		[Customer Number] = wo.Customer
		,		[Customer Name] = c.Name
		FROM	dbo.mckRevGM revgm 
				JOIN (SELECT JCCo, LTRIM(RTRIM(WorkOrder)) AS WorkOrder, CustGroup, Customer FROM SMWorkOrder) wo ON [SessionId]=@sid AND revgm.[Work Order]=wo.WorkOrder
				LEFT JOIN SMCustomerInfo c ON wo.CustGroup=c.CustGroup AND wo.Customer=c.Customer
			
		UPDATE	revgm
		SET		[Projected Final Contract Amount] = ISNULL(wip.[Projected Final Contract Value], 0.0)
		,		[Projected Final Cost] = ISNULL(wip.[Projected Final Cost], 0.0)
		,		[Projected Final Gross Margin] = ISNULL(wip.[Projected Final Gross Margin], 0.0)
		,		[Projected Final Gross Margin %] = ISNULL(wip.[Projected Final Gross Margin %], 0.0) 
		FROM	dbo.mckRevGM revgm JOIN mvwWIPReport wip 
			ON  [SessionId]=@sid 
			AND revgm.JCCo = wip.JCCo 
			AND wip.Contract IS NULL 
			AND revgm.[Work Order] = wip.WorkOrder
			AND	revgm.[GL Dept.]= wip.GLDepartment
			AND ThroughMonth=DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)

		UPDATE  revgm
		SET		[Period Change in Projected Contract Amount] = [Period Change in Projected Contract Amount] - ISNULL(wip.[Projected Final Contract Value], 0.0)
		,		[Period Change in Projected Final Gross Margin] = [Period Change in Projected Final Gross Margin] - ISNULL(wip.[Projected Final Gross Margin], 0.0)
		,		[Period Change in Projected Final Gross Margin %] = CASE WHEN ([Period Change in Projected Contract Amount] - ISNULL(wip.[Projected Final Contract Value], 0.0) = 0.0) THEN 0.0
										  ELSE CAST(([Period Change in Projected Final Gross Margin] - ISNULL(wip.[Projected Final Gross Margin], 0.0))/([Period Change in Projected Contract Amount] - ISNULL(wip.[Projected Final Contract Value], 0.0)) AS [decimal](18, 2))
									 END
		,		[New Projected Final Contract Amount] = NULL
		,		[New Projected Final Gross Margin] = NULL
		,		[New Projected Final Gross Margin %] = NULL
		FROM	dbo.mckRevGM revgm JOIN mvwWIPReport wip
			ON  [SessionId]=@sid 
			AND revgm.JCCo = wip.JCCo 
			AND wip.Contract IS NULL 
			AND revgm.[Work Order] = wip.WorkOrder
			AND	revgm.[GL Dept.]= wip.GLDepartment
			AND ThroughMonth=@mthfrom
		WHERE	[Projected Final Contract Value] <> 0
	
		UPDATE  revgm
		SET		[Period Earned Revenue] = wip.[PeriodEarnedRev]
		,		[Period Earned Gross Margin] = wip.[PeriodEarnedGM]
		,		[Period Earned Gross Margin %] = CASE WHEN wip.[PeriodEarnedRev] = 0.0 THEN 0.0
											ELSE CAST(wip.[PeriodEarnedGM]/wip.[PeriodEarnedRev] AS [decimal](18, 2))
									   END
		FROM	dbo.mckRevGM revgm JOIN 
				(SELECT	JCCo
					,	GLDepartment
					,	WorkOrder
					,	SUM(ISNULL([MTD Earned Revenue], 0.0)) AS [PeriodEarnedRev]
					,	SUM(ISNULL([MTD Earned Gross Margin], 0.0)) AS [PeriodEarnedGM]				
				 FROM	mvwWIPReport wip
				 WHERE	ThroughMonth > @mthfrom AND ThroughMonth <= @mthto
					AND wip.Contract IS NULL
				 GROUP BY JCCo, GLDepartment, WorkOrder
				) wip
			ON  [SessionId]=@sid 
			AND revgm.JCCo = wip.JCCo
			AND revgm.Contract IS NULL 
			AND revgm.[Work Order] = wip.WorkOrder
			AND	revgm.[GL Dept.]= wip.GLDepartment

	SELECT	[JCCo]
	,		[GL Dept.]
	,		[GL Dept. Name]
	,		[Contract]
	,		[Work Order]
	,		[Contract Description]
	,		[Contract Status]
	,		[Customer Number]
	,		[Customer Name]
	,		[POC Name]
	,		[Sales Person]
	,		[Vertical Market]
	,		[CRM Oppty Numbers]
	,		[Revenue Type]

	,		[Original Contract Amount]
	,		[Original Cost]
	,		[Original Gross Margin]
	,		[Original Gross Margin %]

	,		[Projected Final Contract Amount]
	,		[Projected Final Cost]
	,		[Projected Final Gross Margin]
	,		[Projected Final Gross Margin %]

	,		[Period Change in Projected Contract Amount]
	,		[Period Change in Projected Final Gross Margin]
	,		[Period Change in Projected Final Gross Margin %]

	,		[New Projected Final Contract Amount]
	,		[New Projected Final Gross Margin]
	,		[New Projected Final Gross Margin %]

	,		[Period Earned Revenue]
	,		[Period Earned Gross Margin]
	,		[Period Earned Gross Margin %]
	FROM dbo.mckRevGM WHERE [SessionId]=@sid
	ORDER BY 1, 2, 4, 5

	-- Cleanup
	DELETE FROM dbo.mckRevGM WHERE [SessionId]=@sid
END
GO

--Test Script
--EXEC dbo.[mckrptRevGM]
--EXEC dbo.[mckrptRevGM] 1
--EXEC dbo.[mckrptRevGM] 1, '0000'
--EXEC dbo.[mckrptRevGM] 1, null, '4/1/2015'
--EXEC dbo.[mckrptRevGM] 1, '0000', '4/1/2015', '4/30/2015'
--EXEC dbo.[mckrptRevGM] 1, '0521', '4/1/2015', '4/30/2015'

--Validation script
--EXEC dbo.[mckrptRevGM] 1, '0000', '11/1/2014', '12/1/2014'
--select distinct [MTD Earned Revenue], Contract, OrigContractAmt, [Original Cost Budget], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Projected Final Gross Margin %] from mvwWIPReport where ContractStatus in (1,2) and IsLocked = 'Y' and JCCo=1 AND GLDepartment='0000' and RevenueType <> 'N' and ThroughMonth='10/1/2014' and Contract='10938-'
--select distinct [MTD Earned Revenue], Contract, OrigContractAmt, [Original Cost Budget], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Projected Final Gross Margin %] from mvwWIPReport where ContractStatus in (1,2) and IsLocked = 'Y' and JCCo=1 AND GLDepartment='0000' and RevenueType <> 'N' and ThroughMonth='11/1/2014' and Contract='10938-'
--select distinct [MTD Earned Revenue], Contract, OrigContractAmt, [Original Cost Budget], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Projected Final Gross Margin %] from mvwWIPReport where ContractStatus in (1,2) and IsLocked = 'Y' and JCCo=1 AND GLDepartment='0000' and RevenueType <> 'N' and ThroughMonth='12/1/2014' and Contract='10938-'
--select [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin], [Projected Final Gross Margin %] from mvwWIPReport where Contract='10938-' and ThroughMonth='4/1/2015'