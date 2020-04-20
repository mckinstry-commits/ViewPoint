SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/25/2013
-- Description:	Returns a dataset for JC Contract Status Report - JC Cost Projections data
-- =============================================
CREATE PROCEDURE [dbo].[mckJCContStatSumRpt] 
	-- Add the parameters for the stored procedure here
	@JCCo tinyint = 101, 
	@Contract varchar(30) = 0
	,@Mth bMonth = NULL
	, @OpenClosedAll TINYINT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @Mth = ISNULL(dbo.vfFirstDayOfMonth(@Mth),dbo.vfFirstDayOfMonth(GETDATE()))
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
	, dbo.mckJCProjOrEst (@JCCo,@Contract,@Mth) AS ProjAtCompl
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
	, jt.JobSumOrigEstCost
	, ct.SUMContractActualCost
	, ct.SUMContractCurrEstCost
	, ct.SUMContractOrigEstCost
	, ct.SUMContractProjCost
	--, CASE WHEN dbo.vfFirstDayOfMonth(cp.Mth) <= dbo.vfFirstDayOfMonth(@MaxMth) THEN ProjCost ELSE CurrEstCost END AS ProjectedOrEstimated 
	, c.BilledAmt
	, crt.SUMContractBilledAmt
	, crt.SUMContractBilledTax
	, crt.SUMContractCurrentRetainAmt
	, crt.SUMContractReceivedAmt
	, ISNULL(cpb.Unpaid,0) AS Unpaid
	, pp.ProjectedOrEstimated
	FROM         JCCH AS ch 
		INNER JOIN JCJP AS jp ON ch.JCCo = jp.JCCo AND jp.Job = ch.Job AND jp.PhaseGroup = ch.PhaseGroup AND jp.Phase = ch.Phase 
		INNER JOIN JCCM AS c ON c.Contract = jp.Contract AND jp.JCCo = c.JCCo 
		INNER JOIN mckfnJCCPbyContractTotals(@JCCo, @Contract, @MaxMth) ct ON c.JCCo = ct.JCCo AND c.Contract = ct.Contract
		INNER JOIN mckfnJCIPbyContract(@JCCo, @Contract, @MaxMth) crt ON c.JCCo = crt.JCCo AND c.Contract = crt.Contract
		LEFT OUTER JOIN mckfnJCOpenPayablesbyContract(@JCCo, @Contract, @MaxMth) cpb ON c.JCCo = cpb.JCCo AND c.Contract = cpb.Contract
		INNER JOIN JCCT AS t ON ch.PhaseGroup = t.PhaseGroup AND ch.CostType = t.CostType 
		LEFT OUTER JOIN JCCP AS cp ON ch.Job = cp.Job AND ch.JCCo = cp.JCCo AND ch.PhaseGroup = cp.PhaseGroup AND cp.Phase = ch.Phase AND ch.CostType = cp.CostType
		LEFT OUTER JOIN mckfnJCProjRev(@JCCo, @Contract, @MaxMth) AS rp ON rp.JCCo = c.JCCo AND rp.Contract = c.Contract
		INNER JOIN mckfnJCProjOrEstByCT(@JCCo, @Contract, @MaxMth) AS pp ON pp.JCCo = cp.JCCo AND pp.CostType = cp.CostType
		LEFT OUTER JOIN (SELECT TOP 1 JCCo, Contract, Month, RevCost , OtherAmount FROM dbo.JCOR jor
			WHERE jor.JCCo = @JCCo AND jor.Contract = @Contract AND ISNULL(jor.Month,@MaxMth) = @MaxMth
			ORDER BY Month DESC) AS orp ON orp.JCCo = c.JCCo AND orp.Contract = c.Contract
		INNER JOIN JCJM j ON j.JCCo = ch.JCCo AND j.Job = ch.Job
		INNER JOIN (SELECT * FROM mckfnJCJobJCCPTotals(@JCCo, @Contract, @MaxMth)) jt ON j.JCCo = jt.JCCo AND j.Job = jt.Job
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
	AND (c.ContractStatus = @OpenClosedAll OR @OpenClosedAll IS NULL)
	ORDER BY ch.JCCo, ch.Job, ch.Phase, ch.CostType,cp.Mth DESC
END
GO
GRANT EXECUTE ON  [dbo].[mckJCContStatSumRpt] TO [public]
GO
