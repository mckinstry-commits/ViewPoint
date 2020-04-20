SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/25/2013
-- Description:	Returns a dataset for JC Contract Status Report - JC Cost Projections data
-- =============================================
CREATE PROCEDURE [dbo].[mckJCContStatRpt] 
	-- Add the parameters for the stored procedure here
	@JCCo tinyint = 101, 
	@Contract varchar(30) = 0
	,@Mth bMonth
	--, @OpenClosedAll TINYINT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	DECLARE @MaxMth bMonth
	SET @MaxMth = (SELECT MAX( ISNULL(JCCP.Mth,dbo.vfFirstDayOfMonth(GETDATE()))) 
			FROM JCCP
				INNER JOIN JCJP ON dbo.JCJP.JCCo = dbo.JCCP.JCCo AND dbo.JCJP.Job = dbo.JCCP.Job
			WHERE 
			@JCCo = JCCP.JCCo 
			AND JCJP.Contract = @Contract	
			AND JCCP.Mth <= ISNULL(@Mth,dbo.vfFirstDayOfMonth(GETDATE())
			))
			
	

    -- Insert statements for procedure here
	SELECT    ch.JCCo, ch.Job, ch.Phase, jp.Description,c.Contract,c.ContractAmt 
	, t.Abbreviation
	--, ISNULL(ch.OrigCost,0.00) AS OrigCost
	, ISNULL(cp.OrigEstCost, 0.00) AS OrigCost
	, ISNULL(ch.udMarkup,0)AS udMarkup
	, ISNULL(ch.udSellRate,0.00)AS udSellRate
	, COALESCE(cp.Mth, @Mth,@MaxMth) AS Mth
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
	, c.ContractStatus
	, rp.EstRevMth AS ProjectedRevenue
	, orp.RevCost AS OverrideRev
	, orp.OtherAmount AS OverrideOtherRev
	, c.Contract + ' - '+c.Description AS ContractDescription
	, j.Job + ' - ' + j.Description AS JobDescription
	, ci.Item AS [ContractItem]
	, ci.Description AS [CItemDescription]
	, cp.ActualCost AS ActualCost
	, c.OrigContractAmt OriginalContract
	FROM         JCCH AS ch 
		INNER JOIN JCJP AS jp ON ch.JCCo = jp.JCCo AND jp.Job = ch.Job AND jp.PhaseGroup = ch.PhaseGroup AND jp.Phase = ch.Phase 
		INNER JOIN JCCM AS c ON c.Contract = jp.Contract AND jp.JCCo = c.JCCo 
		INNER JOIN JCCT AS t ON ch.PhaseGroup = t.PhaseGroup AND ch.CostType = t.CostType 
		LEFT OUTER JOIN JCCP AS cp ON ch.Job = cp.Job AND ch.JCCo = cp.JCCo AND ch.PhaseGroup = cp.PhaseGroup AND cp.Phase = ch.Phase AND ch.CostType = cp.CostType
		LEFT OUTER JOIN (SELECT r.JCCo AS JCCo, r.Contract AS Contract,SUM(r.ProjDollars) AS ProjRev, SUM(r.EstRevenue_Mth) AS EstRevMth
						FROM dbo.vrvJCIPProjRev r
						WHERE r.JCCo = @JCCo AND r.Contract = @Contract AND (r.Mth <= @MaxMth OR @MaxMth IS NULL)
						GROUP BY r.JCCo, r.Contract
					) AS rp ON rp.JCCo = c.JCCo AND rp.Contract = c.Contract
		LEFT OUTER JOIN (SELECT TOP 1 JCCo, Contract, Month, RevCost , OtherAmount FROM dbo.JCOR jor
			WHERE jor.JCCo = @JCCo AND jor.Contract = @Contract AND ISNULL(jor.Month,@MaxMth) = @MaxMth
			ORDER BY Month DESC) AS orp ON orp.JCCo = c.JCCo AND orp.Contract = c.Contract
		INNER JOIN JCJM j ON j.JCCo = ch.JCCo AND j.Job = ch.Job
		INNER JOIN JCCI ci ON jp.JCCo = ci.JCCo AND jp.Contract = ci.Contract AND jp.Item = ci.Item
	WHERE     (ch.JCCo = @JCCo) AND (c.Contract=@Contract) AND ISNULL(cp.Mth,@MaxMth) <= @MaxMth
	AND (cp.ProjCost > 0 OR (ch.udSellRate > 0 OR cp.ProjHours > 0) OR (CASE WHEN ch.CostType IN (1) AND ch.udSellRate IS NOT NULL AND ch.udSellRate <> 0
			THEN (ISNULL(cp.ProjHours,0.00) * ISNULL(ch.udSellRate, 0.00)) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup,0.00)) 
		WHEN ch.CostType IN (1) AND cp.ProjCost <> 0 AND (ch.udSellRate IS NULL OR ch.udSellRate = 0)
			THEN ISNULL(cp.ProjCost, cp.CurrEstCost)
		WHEN ch.CostType IN (1) AND cp.ProjCost = 0 AND (ch.udSellRate IS NULL OR ch.udSellRate = 0)
			THEN (cp.CurrEstCost)
		WHEN ISNULL(cp.ProjCost,0.00) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup, 0.00)) <> 0
			THEN ISNULL(cp.ProjCost,0.00) + (ISNULL(cp.ProjCost,0.00) * ISNULL(ch.udMarkup, 0.00))
		ELSE cp.CurrEstCost 
		END)>0)
	--AND (c.ContractStatus = @OpenClosedAll OR @OpenClosedAll IS NULL)
	ORDER BY ch.JCCo, ch.Job, ch.Phase, ch.CostType,cp.Mth DESC
END
GO
GRANT EXECUTE ON  [dbo].[mckJCContStatRpt] TO [public]
GO
