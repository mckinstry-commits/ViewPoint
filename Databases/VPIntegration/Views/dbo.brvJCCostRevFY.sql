SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE		VIEW [dbo].[brvJCCostRevFY] 
	AS 

/**********************************************************************
 * Created: ??
 * Modified:      TMS 03/17/2009 - #128667 - removed ProjMth sub-query 
 *						for revenue, moved ProjMth sub-query for cost 
 *						into a CTE, reformatted for readability, added 
 *						comments
 *
 *				   DH 7/7/11 - D-02251 - Added new column from function for EstRevenue_Mth.
 *								         Returns Estimated Revenue at Completion, which is either
 *                                       Projected Revenue or Current Contract.  Amount equals the
 *										 revenue amount for each month (difference between Job To Date
 *                                       for each month and its prior month.)
 *
 * A view that combines Revenue (from the Contract) and Cost (from 
 * the Job), and override amounts into one view, listed by Company, Contract,
 * Item and Mth.  Additionally GL Fiscal Year information.  
 * This view also respects projections for both revenue and cost.
 * 
 * Related reports: JC Work in Progress Report - Fiscal Year, JC Work in 
 * Progress by Gross Profit
 * 
 * Related views: brvJCCostRevenue, brvJCContStat, and brvJCCostRevenueOverride
 *
 **********************************************************************/

WITH
	/*Projected Month CTE returns a month for the client to sort off of to get the 
	  appropriate Projected dollar amount for each item.  This allows the client to provide
	  a ThroughMonth parameter and exclude items that did not have a projected dollar amount
	  as of the provided date.  

	  The Min(p.Mth) returns the minimum month for each each unique JCCP/JCJP row match. */
	ProjMth AS
	(SELECT j.JCCo, j.Contract, j.Item, MIN(p.Mth) AS ProjMth 
	 FROM	JCCP p With (NoLock)
				INNER JOIN 
			JCJP j With (NoLock) 
				ON j.JCCo			= p.JCCo 
				AND j.Job			= p.Job 
				AND j.PhaseGroup	= p.PhaseGroup 
				AND j.Phase			= p.Phase
	 WHERE (p.ProjCost <> 0 OR p.ProjPlug = 'Y')
	 GROUP BY j.JCCo, j.Contract, j.Item) 

-- Revenue
SELECT 
	JCIP.JCCo
,	JCIP.Contract
,	JCIP.Item

	/*Proj Mth is not used on the revenue side, but for compatability has been set to 12/1/2050 
	  to prevent issues with users who use the old WIP report and don't use revenue projections*/
,	ProjMth = '12/1/2050'
,	JCIP.Mth
,	JCIP.OrigContractAmt
,	JCIP.OrigContractUnits
,	JCIP.OrigUnitPrice
,	JCIP.ContractAmt
,	JCIP.ContractUnits
,	JCIP.CurrentUnitPrice
,	JCIP.BilledUnits
,	JCIP.BilledAmt
,	JCIP.ReceivedAmt
,	JCIP.CurrentRetainAmt
,	JCIP.BilledTax
,	JCIP.ProjUnits
,	JCIP.ProjDollars
,	JCIP.ProjPlug
,	EstRev.EstRevenue_Mth

	--Placeholders
	,Job=null				,PhaseGroup=null		,Phase=null				,CostType=null
	,ActualHours= 0.00		,ActualUnits=0.00		,ActualCost=0.00		,OrigEstHours=0.00
	,OrigEstUnits=0.00		,OrigEstCost=0.00		,CurrEstHours=0.00		,CurrEstUnits=0.00
	,CurrEstCost=0.00		,ProjHours=0.00			,ProjRevUnits=0.00		,ProjCost=0.00	
	,ForecastHours=0.00		,ForecastUnits=0.00		,ForecastCost=0.00		,TotalCmtdUnits=0.00
	,TotalCmtdCost=0.00		,RemainCmtdUnits=0.00	,RemainCmtdCost=0.00	,RecvdNotInvcdUnits=0.00
	,RecvdNotInvcdCost=0.00

,	GLFY.BeginMth
,	GLFY.FYEMO
,	GLFY.FiscalYear

FROM
	JCIP
		JOIN 
	JCCO With (NoLock)
		ON JCCO.JCCo	= JCIP.JCCo
		LEFT OUTER JOIN 
	GLFY With (NoLock)
		ON  GLFY.GLCo	 = JCCO.GLCo 
		AND JCIP.Mth	>= GLFY.BeginMth 
		AND JCIP.Mth	<= GLFY.FYEMO
CROSS APPLY vf_rptJCEstRevenue (JCIP.JCCo,JCIP.Contract,JCIP.Item,JCIP.Mth) EstRev		

UNION ALL

-- Cost
SELECT
	JCCP.JCCo
,	JCJP.Contract
,	JCJP.Item

	/*Use the ProjMth column client-side to exclude cost projections that do not fall within
	  a certain date parameter range.  The calculation would be something like: 
	  If ProjMth <= @ThroughMth Then ProjCost Else CurrEstCost
	  
	  The ISNULL ensures that all records can be returned by providing a ThroughMth <= 12/1/2050.*/

,	ISNULL(ProjMth.ProjMth,'12/1/2050') As ProjMth
,	JCCP.Mth

	--Placeholders
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null	

,	JCCP.Job
,	JCCP.PhaseGroup
,	JCCP.Phase
,	JCCP.CostType
,	JCCP.ActualHours
,	JCCP.ActualUnits
,	JCCP.ActualCost
,	JCCP.OrigEstHours
,	JCCP.OrigEstUnits
,	JCCP.OrigEstCost
,	JCCP.CurrEstHours
,	JCCP.CurrEstUnits
,	JCCP.CurrEstCost
,	JCCP.ProjHours
,	JCCP.ProjUnits
,	JCCP.ProjCost
,	JCCP.ForecastHours
,	JCCP.ForecastUnits
,	JCCP.ForecastCost
,	JCCP.TotalCmtdUnits
,	JCCP.TotalCmtdCost
,	JCCP.RemainCmtdUnits
,	JCCP.RemainCmtdCost
,	JCCP.RecvdNotInvcdUnits
,	JCCP.RecvdNotInvcdCost
,	GLFY.BeginMth
,	GLFY.FYEMO
,	GLFY.FiscalYear
	
FROM
	JCCP  With (NoLock)
		LEFT OUTER JOIN 
	JCJP With (NoLock)
		ON  JCCP.JCCo		= JCJP.JCCo 
		AND JCCP.Job		= JCJP.Job 
		AND JCCP.Phase		= JCJP.Phase 
		AND JCCP.PhaseGroup	= JCJP.PhaseGroup 
		LEFT OUTER JOIN 
	ProjMth 	 -- CTE (see top of statement for definition)
		ON	ProjMth.JCCo		= JCCP.JCCo 
		AND ProjMth.Contract	= JCJP.Contract 
		AND ProjMth.Item		= JCJP.Item 
		JOIN 
	JCCO With (NoLock)
		ON JCCO.JCCo=JCCP.JCCo
		JOIN 
	GLFY With (NoLock)
		ON  GLFY.GLCo	 = JCCO.GLCo 
		AND JCCP.Mth	>= GLFY.BeginMth 
		AND JCCP.Mth	<= GLFY.FYEMO


GO
GRANT SELECT ON  [dbo].[brvJCCostRevFY] TO [public]
GRANT INSERT ON  [dbo].[brvJCCostRevFY] TO [public]
GRANT DELETE ON  [dbo].[brvJCCostRevFY] TO [public]
GRANT UPDATE ON  [dbo].[brvJCCostRevFY] TO [public]
GO
