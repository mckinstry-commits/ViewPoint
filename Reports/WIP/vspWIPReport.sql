USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[vspWIPReport]    Script Date: 12/30/2014 4:55:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 11/18/2014 Arun Thomas		Changed the where condition to handle null value 
**								properly and to map pocname parameter to poc
** 12/30/2014 Amit Mody			Updated Where clauses to fix missing rows on reports
** 1/6/2015   Amit Mody			Included WorkOrder field on E and I reports
** 1/30/2015  Amit Mody			Filtered E and I reports to exclude unlocked 
**								contract items and pending/hard-closed contracts,
**								Removed join with JCCOCompany
** 2/2/2015   Amit Mody			Added JCCM Department field to QA edition
** 2/10/2015   Amit Mody		Excluded non-revenue contracts from all editions
******************************************************************************/

ALTER PROC [dbo].[vspWIPReport] 
		@ReportType CHAR(1) = 'E',
		@JCCo TINYINT = 1, 
		@GLDepartment VARCHAR(4) = NULL, 
		@POC bProjectMgr = NULL, 
		@Contract VARCHAR(50) = NULL,
		@SalesPersonID BIGINT = NULL,
		@ThroughMonth date = NULL
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

IF @ThroughMonth IS NULL 
	SET @ThroughMonth = DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0));
ELSE
	SET @ThroughMonth = dbo.mckfFirstDayOfMonth(@ThroughMonth);

IF (LTRIM(RTRIM(@GLDepartment)) = '') SET @GLDepartment = NULL;
IF @Contract IS NOT NULL SET @Contract=ltrim(rtrim(@Contract));

IF @ReportType = 'Q' 
	BEGIN
		SELECT 
				[ThroughMonth] AS [Through Month],
				A.[JCCo] AS [JC Company],
				A.[Contract] AS [Contract],
				[Contract Description] AS [Contract Description],
				[WorkOrder] AS [Work Order],
				[IsLocked] AS [Is Locked?],
				--[RevenueType] AS [RevenueType],
				[RevenueTypeName] AS [Revenue Type],
				--[ContractStatus] AS [ContractStatus],
				[ContractStatusDesc] AS [Contract Status],
				ISNULL(B.[Department], '') AS [Contract Department],
				[GLDepartment] AS [GL Department],
				[GLDepartmentName] AS [GL Department Name],
				[POC] AS [POC],
				[POCName] AS [POC Name],
				A.[OrigContractAmt] AS [Original Contract Amount],
				[CurrContractAmt] AS [Current Contract Amount],
				[ProjContractAmt] AS [Projected Contract Amount],
				[RevenueIsOverride] AS [Is Revenue Override?],
				[RevenueOverrideTotal] AS [Revenue Override Total],
				[RevenueOverridePercent] AS [Revenue Override %],
				[RevenueOverrideAmount] AS [Revenue Override Amount],
				[Projected Final Contract Value] AS [Projected Final Contract Amount],
				[JTD Billed] AS [JTD Billed],
				[JTD Actual Cost] AS [JTD Actual Cost],
				[Original Cost Budget] AS [Original Cost Budget],
				[Estimated Cost] AS [Estimated Cost],
				[CommittedCostAmount] AS [Open Committed Cost],
				[ProjectedCost] AS [Projected Cost],
				[CostIsOverride] AS [Is Cost Override?],
				[CostOverrideTotal] AS [Cost Override Total],
				[CostOverridePercent] AS [Cost Override %],
				[CostOverrideAmount] AS [Cost Override Amount],
				[Projected Final Cost] AS [Projected Final Cost],
				[EstimatedCostToComplete] AS [Estimated Cost To Complete],
				[Percent Complete] AS [Percent Complete],
				[Projected Final Gross Margin] AS [Projected Final Gross Margin],
				[Projected Final Gross Margin %] AS [Projected Final Gross Margin %],
				[JTD Earned Revenue] AS [JTD Earned Revenue],
				[JTD Earned Gross Margin] AS [JTD Earned Gross Margin],
				[Overbilled] AS [Overbilled],
				[Underbilled] AS [Underbilled],
				[MTD Earned Revenue] AS [MTD Earned Revenue],
				[MTD Actual Cost] AS [MTD Actual Cost],
				[MTD Earned Gross Margin] AS [MTD Earned Gross Margin],
				CAST(CASE COALESCE([MTD Earned Revenue],0) 
					 WHEN 0 THEN 0.00 
					 ELSE [MTD Earned Gross Margin]/[MTD Earned Revenue]
			   		 END 
				AS DECIMAL(18,10)) AS [MTD Earned Gross Margin %],
				[YTD Earned Revenue] AS [YTD Earned Revenue],
				[YTD Actual Cost] AS [YTD Actual Cost],
				[YTD Earned Gross Margin] AS [YTD Earned Gross Margin],
				[ContractIsPositive] AS [Is Contract Positive?],
				CAST([SalesPersonID] AS VARCHAR(50)) + ' - ' + [SalesPerson] AS [Sales Person],
				[VerticalMarket] AS [Vertical Market],
				[Markup] AS [Markup],
				[Straight Line Term Start] AS [Straight Line Term Start],
				[Straight Line Term Months] AS [Straight Line Term Months],
				[CGCJobNumber] AS [CGC Job Number],
				[Batch Processed On] AS [Batch Processed On]
			FROM dbo.mvwWIPReport A --JOIN JCCOCompany B ON A.JCCo = B.JCCo
				LEFT JOIN dbo.JCCM B
				ON A.JCCo=B.JCCo AND A.Contract=ltrim(rtrim(B.Contract))
			WHERE 
				A.ThroughMonth = @ThroughMonth AND
				A.RevenueType <> 'N' AND
				(@JCCo IS NULL OR A.JCCo = @JCCo) AND
				(@GLDepartment IS NULL OR A.GLDepartment = @GLDepartment) AND
				(@POC IS NULL OR A.POC = @POC) AND
				(@Contract IS NULL OR A.[Contract] = @Contract) AND
				(@SalesPersonID IS NULL OR A.SalesPersonID = @SalesPersonID)
	END
ELSE IF @ReportType = 'I'
	BEGIN
		SELECT 
			[ThroughMonth] AS [Through Month],
			A.[JCCo] AS [JC Company],
			[Contract] AS [Contract],
			[Contract Description] AS [Contract Description],
			[WorkOrder] AS [Work Order],
			[RevenueTypeName] AS [Revenue Type],
			[ContractStatusDesc] AS [Contract Status],
			[GLDepartment] AS [GL Department],
			[GLDepartmentName] AS [GL Department Name],
			[POC] AS [POC],
			[POCName] AS [POC Name],
			[Projected Final Contract Value] AS [Projected Final Contract Amount],
			[JTD Billed] AS [JTD Billed],
			[JTD Actual Cost] AS [JTD Actual Cost],
			[Projected Final Cost] AS [Projected Final Cost],
			[Estimated Cost] AS [Estimated Cost],
			[EstimatedCostToComplete] AS [Estimated Cost To Complete],
			[Percent Complete] AS [Percent Complete],
			[Projected Final Gross Margin] AS [Projected Final Gross Margin],
			[Projected Final Gross Margin %] AS [Projected Final Gross Margin %],
			[JTD Earned Revenue] AS [JTD Earned Revenue],
			[JTD Earned Gross Margin] AS [JTD Earned Gross Margin],
			[Overbilled] AS [Overbilled],
			[Underbilled] AS [Underbilled],
			[MTD Earned Revenue] AS [MTD Earned Revenue],
			[MTD Earned Gross Margin] AS [MTD Earned Gross Margin],
			CAST(CASE COALESCE([MTD Earned Revenue],0) 
					 WHEN 0 THEN 0.00 
					 ELSE [MTD Earned Gross Margin]/[MTD Earned Revenue]
			   		 END 
				AS DECIMAL(18,10)) AS [MTD Earned Gross Margin %],
			CAST([SalesPersonID] AS VARCHAR(50)) + ' - ' + [SalesPerson] AS [Sales Person],
			[VerticalMarket] AS [Vertical Market],
			[CGCJobNumber] AS [CGC Job Number]			
		FROM dbo.mvwWIPReport A --JOIN JCCOCompany B ON A.JCCo = B.JCCo
		WHERE
			((A.Contract IS NOT NULL AND A.IsLocked = 'Y') OR (A.WorkOrder IS NOT NULL)) AND
			A.ContractStatus IN (1,2) AND
			A.ThroughMonth = @ThroughMonth AND
			A.RevenueType <> 'N' AND
			(@JCCo IS NULL OR A.JCCo = @JCCo) AND
			(@GLDepartment IS NULL OR A.GLDepartment = @GLDepartment) AND
			(@POC IS NULL OR A.POC = @POC) AND
			(@Contract IS NULL OR A.[Contract] = @Contract) AND
			(@SalesPersonID IS NULL OR A.SalesPersonID = @SalesPersonID)			
	END
ELSE IF @ReportType = 'E'
	BEGIN
		SELECT
			A.[JCCo] AS [JC Company],
			[Contract] AS [Contract],
			[Contract Description] AS [Contract Description],
			[WorkOrder] AS [Work Order],
			SUM([Projected Final Contract Value]) AS [Projected Final Contract Amount],
			SUM([JTD Billed]) AS [JTD Billed],
			SUM([JTD Actual Cost]) AS [JTD Actual Cost],
			SUM([Projected Final Cost]) AS [Projected Final Cost],
			SUM([EstimatedCostToComplete]) AS [Estimated Cost To Complete],
			SUM([Percent Complete]) AS [Percent Complete],
			SUM([Projected Final Gross Margin]) AS [Projected Final Gross Margin],
			SUM([Projected Final Gross Margin %]) AS [Projected Final Gross Margin %],
			SUM([JTD Earned Revenue]) AS [JTD Earned Revenue],
			SUM([JTD Earned Gross Margin]) AS [JTD Earned Gross Margin],
			SUM([Overbilled]) AS [Overbilled],
			SUM([Underbilled]) AS [Underbilled],
			[CGCJobNumber] AS [CGC Job Number]
		FROM dbo.mvwWIPReport A --JOIN JCCOCompany B ON A.JCCo = B.JCCo
		WHERE
			((A.Contract IS NOT NULL AND A.IsLocked = 'Y') OR (A.WorkOrder IS NOT NULL)) AND
			A.ThroughMonth = @ThroughMonth AND
			A.ContractStatus IN (1,2) AND
			A.RevenueType <> 'N' AND
			(@JCCo IS NULL OR A.JCCo = @JCCo) AND
			(@GLDepartment IS NULL OR A.GLDepartment = @GLDepartment) AND
			(@POC IS NULL OR A.POC = @POC) AND
			(@Contract IS NULL OR A.[Contract] = @Contract) AND
			(@SalesPersonID IS NULL OR A.SalesPersonID = @SalesPersonID)
		GROUP BY A.[JCCo], [Contract],[Contract Description],[WorkOrder],[CGCJobNumber]
	END
GO

GRANT EXECUTE
    ON OBJECT::[dbo].[vspWIPReport] TO [MCKINSTRY\ViewpointUsers];
GO

--Test Script
--EXEC  [dbo].[vspWIPReport] 'Q', 1 --(12/1/2014)
--EXEC  [dbo].[vspWIPReport] 'I', 1, null, null, null, null, '1/1/2015'
--EXEC  [dbo].[vspWIPReport] 'E', 1, null, null, null, null, '1/1/2015'