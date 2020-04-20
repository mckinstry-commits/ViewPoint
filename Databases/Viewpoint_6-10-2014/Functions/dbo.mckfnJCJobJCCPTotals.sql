SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/17/2014
-- Description:	Job Cost Totals at the Job Level
-- =============================================
CREATE FUNCTION [dbo].[mckfnJCJobJCCPTotals] 
(	
	-- Add the parameters for the function here
	@JCCo bCompany, 
	@Contract bContract
	, @Mth bMonth
)
RETURNS TABLE 
AS
RETURN 
(
	--DECLARE @JCCo bCompany = 101, @Contract bContract ='080600-', @Mth bMonth = '2014-02-01 00:00:00'
	-- Add the SELECT statement with parameter references here
	SELECT jm.JCCo, jm.Job, SUM(cp.ActualCost) AS JobSumActualCost, SUM(cp.ActualHours) AS JobSumActualHours, SUM(cp.CurrEstCost) AS JobSumCurrEstCost, SUM(cp.CurrEstHours) AS JobSumCurrEstHours, SUM(cp.OrigEstCost) AS JobSumOrigEstCost
	FROM dbo.JCCP cp
	INNER JOIN JCJM jm ON jm.JCCo = cp.JCCo AND jm.Job = cp.Job
	WHERE cp.JCCo = @JCCo AND jm.Contract = @Contract AND cp.Mth <= @Mth
	GROUP BY jm.JCCo, jm.Job
)
GO
