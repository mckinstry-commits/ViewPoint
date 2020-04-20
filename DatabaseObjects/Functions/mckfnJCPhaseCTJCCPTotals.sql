USE [Viewpoint]
GO
/****** Object:  UserDefinedFunction [dbo].[mckfnJCPhaseJCCPTotals]    Script Date: 11/6/2014 9:33:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/6/2014
-- Description:	Job Cost Totals at the Phase Cost Type Level
-- Added to support Phase Code Rollup Report.
-- =============================================
ALTER FUNCTION [dbo].[mckfnJCPhaseCTJCCPTotals] 
(	
	-- Add the parameters for the function here
	@JCCo bCompany, 
	@Job bJob
	, @Phase bPhase = NULL
	, @CostType bJCCType = NULL
	, @Mth bMonth
)
RETURNS TABLE 
AS
RETURN 
(
	--DECLARE @JCCo bCompany = 20, @Job bJob =' 20306-001', @Phase bPhase = '0131-1540-      -   ', @Mth bMonth = '2014-11-01 00:00:00', @CostType bJCCType = NULL
	-- Add the SELECT statement with parameter references here
	SELECT cp.JCCo, cp.Job,cp.Phase, cp.CostType, SUM(cp.ActualCost) AS SumActualCost, SUM(cp.ActualHours) AS SumActualHours, SUM(cp.CurrEstCost) AS SumCurrEstCost, SUM(cp.CurrEstHours) AS SumCurrEstHours, SUM(cp.OrigEstCost) AS JobSumOrigEstCost
		, SUM(cp.ProjCost) AS SumProjCost, SUM(cp.ProjHours) AS SumProjHours, MAX(cp.Mth) AS Mth
	FROM dbo.JCCP cp
	--INNER JOIN JCJM jm ON jm.JCCo = cp.JCCo AND jm.Job = cp.Job
	WHERE cp.JCCo = @JCCo 
		AND cp.Job = @Job 
		AND cp.Phase = ISNULL(@Phase,cp.Phase) 
		AND cp.Mth <= @Mth
		AND cp.CostType = ISNULL(@CostType, cp.CostType)
	GROUP BY cp.JCCo, cp.Job, cp.Phase, cp.CostType
)
