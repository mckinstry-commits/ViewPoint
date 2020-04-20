USE [Viewpoint]
GO

/****** Object:  StoredProcedure [dbo].[mspShopProductivity]    Script Date: 2/9/2015 9:41:26 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ben Hampson
-- Create date: 2015-02-03
-- Description:	Fabrication Shop Productivity report details
-- =============================================
CREATE PROCEDURE [dbo].[mspShopProductivity]
	@PeriodBegin bDate,
	@PeriodEnd bDate,
	@GroupPhases nvarchar(4000) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	--SET @PeriodBegin = '1/1/2015'
	--SET @PeriodEnd = '2/1/2015'

	;WITH phasesGroup AS (
		SELECT
			[Order],
			[Phase],
			[Description],
			[UOM]
		FROM
			dbo.mfnShopProductivityPhases(@GroupPhases)
	)
			
	SELECT
		[bjccd].[JCCo] [Company], 
		[bjccd].[Job], 
		[bjccd].[PhaseGroup], 
		[phases].[Order] [PhaseOrder],
		[bjccd].[Phase], 
		[phases].[Description] [PhaseDescription],
		[CostType], 
		[PostedDate], 
		[JCTransType], 
		'' [Employee], 
		[bjccd].[Description],
		'' [Craft], 
		'' [CraftDescription],
		'' [Class], 
		'' [ClassDescription],
		0 [Shift],

		[PostedUM],
		SUM([PostedUnits]) [PostedUnits], 
		[PostedUnitCost], 

		0 [HoursRegular], 
		0 [HoursOvertime], 
		0 [HoursOther], 
		0 [ActualHours], 

		SUM([ActualCost]) [ActualCost]
	FROM 
		[dbo].[bJCCD] [bjccd]
		--[dbo].[JCCD] [bjccd]
	INNER JOIN 
		phasesGroup [phases]
	ON
		[bjccd].[Phase] = [phases].[Phase]
	AND
		[bjccd].[PostedUM] = [phases].[UOM]
	INNER JOIN
		--limit to production phase group
		[Viewpoint].[dbo].[HQCO] [hqco]
	ON
		[bjccd].[JCCo] = [hqco].[HQCo]
	AND
		[bjccd].[PhaseGroup] = [hqco].[PhaseGroup]
	WHERE
		[JCTransType] = 'MO'
	AND
		[PostedUnits] <> 0 
		--[ActualCost] <> 0
	AND
		[PostedDate] >= @PeriodBegin
	AND
		[PostedDate] < @PeriodEnd
	GROUP BY
		[bjccd].[JCCo], 
		[bjccd].[Job], 
		[bjccd].[PhaseGroup], 
		[phases].[Order],
		[bjccd].[Phase], 
		[phases].[Description],
		[CostType], 
		[PostedDate], 
		[JCTransType], 
		[bjccd].[Description],
		[PostedUM],
		[PostedUnitCost]

	UNION ALL

	SELECT
		[bjccd].[JCCo] [Company], 
		[bjccd].[Job], 
		[bjccd].[PhaseGroup], 
		[phases].[Order] [PhaseOrder],
		[bjccd].[Phase], 
		[phases].[Description] [PhaseDescription],
		[CostType], 
		[PostedDate], 
		[JCTransType], 
		[bjccd].[Employee], 
		[prehn].[FullName] [Description],
		[bjccd].[Craft], 
		[prcm].[Description] [CraftDescription],
		[bjccd].[Class], 
		[prcc].[Description] [ClassDescription],
		[Shift],
		[phases].[UOM] [PostedUM],
		0 [PostedUnits], 
		0 [PostedUnitCost], 
		SUM(
			CASE
				WHEN [EarnType] = 5 OR [EarnType] IS NULL THEN [ActualHours]
				ELSE 0
			END 
		) [HoursRegular], 
		SUM(
			CASE
				WHEN [EarnType] = 6 THEN [ActualHours]
				ELSE 0
			END 
		) [HoursOvertime], 
		SUM(
			CASE
				WHEN [EarnType] NOT IN(5, 6)THEN [ActualHours]
				ELSE 0
			END 
		) [HoursOther], 
		SUM([ActualHours]) [ActualHours], 
		SUM([ActualCost]) [ActualCost]
	FROM 
		[dbo].[bJCCD] [bjccd]
	INNER JOIN 
		phasesGroup [phases]
	ON
		[bjccd].[Phase] = [phases].[Phase]
	INNER JOIN
		--limit to production phase group
		[Viewpoint].[dbo].[HQCO] [hqco]
	ON
		[bjccd].[JCCo] = [hqco].[HQCo]
	AND
		[bjccd].[PhaseGroup] = [hqco].[PhaseGroup]
	LEFT JOIN 
		[dbo].[PREHName] [prehn] WITH (NOLOCK)
	ON 
		[prehn].[PRCo] = [bjccd].[PRCo]
	AND 
		[prehn].[Employee] = [bjccd].[Employee] 
	LEFT OUTER JOIN
		[Viewpoint].[dbo].[PRCM] [prcm]
	ON
		[prehn].[PRCo] = [prcm].[PRCo]
	AND
		[prehn].[Craft] = [prcm].[Craft]
	LEFT OUTER JOIN
		[Viewpoint].[dbo].[PRCC] [prcc]
	ON
		[prehn].[PRCo] = [prcc].[PRCo]
	AND
		[prehn].[Craft] = [prcc].[Craft]
	AND
		[prehn].[Class] = [prcc].[Class]
	WHERE
		[JCTransType] = 'PR'
	AND
		[ActualCost] <> 0
	AND
		[PostedDate] >= @PeriodBegin
	AND
		[PostedDate] < @PeriodEnd
	--AND
		--dbo.mfnMultiPartFieldParse([bjccd].[Phase], 'bPhase', 1) IN (9000, 9500)
		--SUBSTRING([bjccd].[Phase], 1, 4) IN ('9000', '9500')
	GROUP BY
		[bjccd].[JCCo], 
		[bjccd].[Job], 
		[bjccd].[PhaseGroup], 
		[phases].[Order],
		[bjccd].[Phase], 
		[phases].[Description],
		[CostType], 
		[PostedDate], 
		[JCTransType], 
		[bjccd].[Employee], 
		[prehn].[FullName],
		[bjccd].[Craft], 
		[prcm].[Description],
		[bjccd].[Class], 
		[prcc].[Description],
		[Shift],
		[phases].[UOM]


END

GO


