SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/17/2014
-- Description:	Returns Contract Totals
-- =============================================
CREATE FUNCTION [dbo].[mckfnJCCPbyContractTotals] 
(	
	-- Add the parameters for the function here
	@JCCo bCompany, 
	@Contract bContract
	,@Mth bMonth
)
RETURNS TABLE 
AS
RETURN 
(
	--
	--DECLARE @JCCo bCompany = 101, @Contract bContract = '022814-', @Mth bMonth='2014-02-01 00:00:00'
	-- Add the SELECT statement with parameter references here
	SELECT cm.JCCo, cm.Contract, SUM(cp.ActualCost) AS SUMContractActualCost, SUM(cp.ActualHours) AS SUMContractActualHours, SUM(cp.CurrEstCost) AS SUMContractCurrEstCost, SUM(cp.CurrEstHours) AS SUMContractCurrEstHours, SUM(cp.ForecastCost) AS SUMContractForecastCost, SUM(cp.ForecastHours) AS SUMContractForecastHours, SUM(cp.OrigEstCost) AS SUMContractOrigEstCost, SUM(cp.OrigEstHours) AS SUMContractOrigEstHours
	, SUM(cp.ProjCost) AS SUMContractProjCost, SUM(cp.ProjHours) AS SUMContractProjHours, SUM(cp.TotalCmtdCost) AS SUMContractTotalCmtdCost
	FROM dbo.JCCM cm
	INNER JOIN dbo.JCJM jm ON jm.JCCo = cm.JCCo AND jm.Contract = cm.Contract
	INNER JOIN JCCP cp ON cp.JCCo = jm.JCCo AND cp.Job = jm.Job
	WHERE cp.JCCo = @JCCo AND cm.Contract = @Contract AND cp.Mth <= @Mth
	GROUP BY cm.JCCo, cm.Contract
)
GO
