USE [Viewpoint]
GO
/****** Object:  UserDefinedFunction [dbo].[mckfnJCJobJCCPTotals]    Script Date: 11/6/2014 9:19:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/6/2014
-- Description:	Job Cost Totals at the Phase Level
-- =============================================
ALTER FUNCTION [dbo].[mckfnJCPhaseJCCPTotals] 
(	
	-- Add the parameters for the function here
	@JCCo bCompany, 
	@Job bJob
	, @Phase bPhase = NULL
	, @Mth bMonth
)
RETURNS TABLE 
AS
RETURN 
(
	--DECLARE @JCCo bCompany = 20, @Job bJob =' 20306-001', @Phase bPhase = NULL, @Mth bMonth = '2014-11-01 00:00:00'
	-- Add the SELECT statement with parameter references here
	SELECT cp.JCCo, cp.Job,cp.Phase, SUM(cp.ActualCost) AS JobSumActualCost, SUM(cp.ActualHours) AS JobSumActualHours, SUM(cp.CurrEstCost) AS JobSumCurrEstCost, SUM(cp.CurrEstHours) AS JobSumCurrEstHours, SUM(cp.OrigEstCost) AS JobSumOrigEstCost
	FROM dbo.JCCP cp
	--INNER JOIN JCJM jm ON jm.JCCo = cp.JCCo AND jm.Job = cp.Job
	WHERE cp.JCCo = @JCCo AND cp.Job = @Job AND cp.Phase = ISNULL(@Phase,cp.Phase) AND cp.Mth <= @Mth
	GROUP BY cp.JCCo, cp.Job, cp.Phase
)
