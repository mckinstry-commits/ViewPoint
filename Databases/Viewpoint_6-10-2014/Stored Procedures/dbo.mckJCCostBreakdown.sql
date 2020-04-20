SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/25/2013
-- Description:	Returns a dataset for JC Phase Code Rollup - JC Cost Projections data
-- =============================================
CREATE PROCEDURE [dbo].[mckJCCostBreakdown] 
	-- Add the parameters for the stored procedure here
	@Period CHAR(1) = 'J'
	,@JCCo tinyint = 101
	,@Job varchar(30) = ''
	--,@GLDept VARCHAR(MAX) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	/*
	
	--Set parameter values for JTD YTD MTD
		--@Period 
			J - Job TD
			Y - Year TD
			M - Month TD
	*/

	--DECLARE @GLDeptTable TABLE(ElementID INT, Element VARCHAR(4))

	DECLARE @MaxMth bMonth, @MinMth bMonth, @Mth bMonth
	--SELECT * FROM dbo.JCCP
	
	
	IF @Period = 'J'
	BEGIN
		SET @MaxMth = dbo.vfFirstDayOfMonth(GETDATE())
		
		SET @MinMth = (SELECT MIN(ISNULL(JCCP.Mth, dbo.vfFirstDayOfMonth(GETDATE())))
				FROM dbo.JCCP
				INNER JOIN dbo.JCJP ON dbo.JCJP.JCCo = dbo.JCCP.JCCo AND dbo.JCJP.Job = dbo.JCCP.Job
				WHERE 
				@JCCo = JCCP.JCCo
				AND JCJP.Job = @Job
				)
	END
	ELSE IF @Period = 'Y'
	BEGIN
		SET @MaxMth = dbo.vfFirstDayOfMonth(GETDATE())
		SET @MinMth = (SELECT
					DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))
	END
	ELSE IF @Period = 'M'
	BEGIN
		SET @MaxMth = dbo.vfFirstDayOfMonth(GETDATE())
		SET @MinMth = @MaxMth
	END
	
	--Handle a blank @GLDept.  This probably won't be needed but just in case.
	--Split multiple @GLDept into a variable table to use in where clause below.		
	/*Commented out for now.  No GLDept Requirement*/
	--IF @GLDept = ''
	--BEGIN
	--	INSERT INTO @GLDeptTable
	--	        ( ElementID, Element )
	--	SELECT  ROW_NUMBER() OVER(ORDER BY gld.Instance), gld.Instance  FROM dbo.JCCO co 
	--	INNER JOIN dbo.JCJP jp ON jp.JCCo = co.JCCo AND jp.Job = @Job
	--	INNER JOIN dbo.JCCI ci ON ci.Contract = jp.Contract AND ci.JCCo = jp.JCCo AND ci.Item = jp.Item
	--	INNER JOIN dbo.GLPI gld ON gld.PartNo = 3 AND gld.GLCo = co.GLCo AND RTRIM(gld.Instance) = LEFT(ci.Department,4) 
	--	WHERE co.JCCo = @JCCo AND jp.Job = @Job
	--END
	--ELSE
	--BEGIN
		
	--	INSERT INTO @GLDeptTable
	--			( ElementID, Element )
	--	SELECT * FROM [dbo].[mckfunc_Split](@GLDept, ',')
	--END

    -- Insert statements for procedure here

	--Primary Select Clause 
	SELECT    ch.JCCo, ch.Job, jm.Description AS [JobDescription], ch.Phase, jp.Description AS [PhaseDescription]
	, LEFT(ch.Phase, 2) AS [CSI Division], LEFT(ch.Phase, 10) AS [Master Phase]
	, t.Abbreviation, t.Description AS [CostType], ISNULL(ch.OrigCost,0.00) AS OrigCost
	, ISNULL(ch.udMarkup,0)AS udMarkup
	, ISNULL(ch.udSellRate,0.00)AS udSellRate
	, COALESCE(cp.Mth, @Mth,@MaxMth) AS Mth
	--, @MaxMth, @MinMth
	, cp.Mth AS cpMth
	--, ac.Mth AS acMth
	, ISNULL(cp.ProjCost,0.00) AS ProjCost
	, ISNULL(cp.ProjHours,0.00) AS ProjHours
	, ISNULL(cp.CurrEstCost, 0.00) AS CurrEstCost
	, CASE WHEN ch.CostType IN (1) AND ch.udSellRate IS NOT NULL AND ch.udSellRate <> 0
			THEN (ISNULL(cp.ProjHours,0.00) * ISNULL(ch.udSellRate, 0.00)) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup,0.00)) 
		WHEN ch.CostType IN (1) AND cp.ProjCost <> 0 AND (ch.udSellRate IS NULL OR ch.udSellRate = 0)
			THEN ISNULL(cp.ProjCost, cp.CurrEstCost)
		WHEN ch.CostType IN (1) AND cp.ProjCost = 0 AND (ch.udSellRate IS NULL OR ch.udSellRate = 0)
			THEN (cp.CurrEstCost)
		WHEN ISNULL(cp.ProjCost,0.00) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup, 0.00)) <> 0
			THEN ISNULL(cp.ProjCost,0.00) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup, 0.00))
		ELSE cp.CurrEstCost 
		END AS ProjBillingByPhase
	,ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup, 0.00) AS Fee
	, RANK() OVER 
			(PARTITION BY cp.JCCo, cp.Job, cp.Phase, cp.CostType 
			ORDER BY cp.JCCo, cp.Job, cp.Phase, cp.CostType, cp.Mth DESC) AS cpRANK
	, t.CostType AS CostTypeNum
	, cp.CurrEstHours, cp.ActualHours
	, pm.Description AS MasterDescription
	, csi.Description AS CSIDivDescription
	--, gld.Instance AS GLDept
	--, gld.Description AS GLDeptDescription
	, ci.Item AS ContractItem
	, ci.Department AS JCDepartment
	, cp.ActualCost AS ActualCostUnfiltered
	--, ac.ActualCost AS ActualCostFiltered
	, CASE WHEN cp.Mth <= @MaxMth AND cp.Mth >= @MinMth THEN cp.ActualCost ELSE 0 END AS ActualCost
	--, ac.ActualCost
	--, @MaxMth, @MinMth
	, CASE WHEN pm.Phase <> pm.udParentPhase THEN pm.udParentPhase ELSE pm.Phase END AS ParentPhase
	, ParentPhase.Description AS [ParentPhaseDescription]
	FROM         JCCH AS ch 
		INNER JOIN JCJP AS jp ON ch.JCCo = jp.JCCo AND jp.Job = ch.Job AND jp.PhaseGroup = ch.PhaseGroup AND jp.Phase = ch.Phase 
		--INNER JOIN JCCM AS c ON c.Contract = jp.Contract AND jp.JCCo = c.JCCo 
		INNER JOIN JCJM AS jm ON jm.JCCo = jp.JCCo AND jm.Job = jp.Job
		INNER JOIN JCCT AS t ON ch.PhaseGroup = t.PhaseGroup AND ch.CostType = t.CostType 
		LEFT OUTER JOIN JCCP AS cp ON ch.Job = cp.Job AND ch.JCCo = cp.JCCo AND ch.PhaseGroup = cp.PhaseGroup AND cp.Phase = ch.Phase AND ch.CostType = cp.CostType
		LEFT OUTER JOIN JCPM AS pm ON jp.PhaseGroup = pm.PhaseGroup AND LEFT(jp.Phase,10)=LEFT(pm.Phase,10)
		LEFT OUTER JOIN dbo.udCSIPhaseSeg csi ON --csi.CSI = LTRIM(RTRIM(LEFT(ch.Phase,2)))
			csi.CSI = pm.udCSIDiv
		INNER JOIN dbo.JCCO co ON co.JCCo = ch.JCCo
		INNER JOIN dbo.JCCI ci ON ci.Contract = jp.Contract AND ci.JCCo = jp.JCCo AND ci.Item = jp.Item
		--INNER JOIN dbo.GLPI gld ON gld.PartNo = 3 AND gld.GLCo = co.GLCo AND RTRIM(gld.Instance) = LEFT(ci.Department,4) 
		LEFT OUTER JOIN (SELECT ppm.PhaseGroup, ppm.Phase, ppm.Description, ppm.udParentPhase FROM JCPM ppm ) AS ParentPhase ON ParentPhase.PhaseGroup = pm.PhaseGroup AND ParentPhase.Phase = ISNULL(pm.udParentPhase,pm.Phase) 
	WHERE     (ch.JCCo = @JCCo) 
		--AND RTRIM(gld.Instance) IN (SELECT Element FROM @GLDeptTable)
		AND (jm.Job = @Job OR LTRIM(RTRIM(jm.Job)) = @Job)
		--AND ISNULL(cp.Mth,@MaxMth) <= @MaxMth
		AND (cp.ProjCost > 0 OR (ch.udSellRate > 0 OR cp.ProjHours > 0)
		OR (CASE WHEN ch.CostType IN (1) AND ch.udSellRate IS NOT NULL AND ch.udSellRate <> 0
			THEN (ISNULL(cp.ProjHours,0.00) * ISNULL(ch.udSellRate, 0.00)) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup,0.00)) 
			WHEN ch.CostType IN (1) AND cp.ProjCost <> 0 AND (ch.udSellRate IS NULL OR ch.udSellRate = 0)
				THEN ISNULL(cp.ProjCost, cp.CurrEstCost)
			WHEN ch.CostType IN (1) AND cp.ProjCost = 0 AND (ch.udSellRate IS NULL OR ch.udSellRate = 0)
				THEN (cp.CurrEstCost)
			WHEN ISNULL(cp.ProjCost,0.00) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup, 0.00)) <> 0
				THEN ISNULL(cp.ProjCost,0.00) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup, 0.00))
			ELSE cp.CurrEstCost 
			END)>0)
	ORDER BY ch.JCCo, ch.Job, ch.Phase, ch.CostType,cp.Mth DESC

	--SELECT @GLDept
	--SELECT @CountGLDpt
END


GO
GRANT EXECUTE ON  [dbo].[mckJCCostBreakdown] TO [public]
GO
