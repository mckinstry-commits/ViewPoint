SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE		VIEW [dbo].[vrvJCCostRevenueExcept]
	AS

/**********************************************************************
 * Created: ??
 * Modified:      TMS 03/17/2009 - #128667 - removed ProjMth sub-query 
 *						for revenue, moved ProjMth sub-query for cost 
 *						into a CTE, reformatted for readability, added 
 *						comments
 * 
 * A view that combines Revenue (from the Contract) and Cost (from 
 * the Job) into one view, listed by Company, Contract, Item and Mth.
 * This view also respects projections for both revenue and cost.
 *
 * The following standard reports use this view: JC Cost and Revenue By 
 * Item, JC Jobs per Contract Drilldown, JC Work In Progress Report 
 * (landscape/portrait)
 *
 * Related views: brvJCCostRevFY, brvJCContStat, and brvJCCostRevenueOverride
 *
 **********************************************************************/

WITH
	/*Projected Month CTE returns a month for the client to sort off of to get the 
	  appropriate Projected dollar amount for each item.  This allows the client to provide
	  a ThroughMonth parameter and exclude items that did not have a projected dollar amount
	  as of the provided date.  

	  The Min(p.Mth) returns the minimum month for each each unique JCCP/JCJP row match. */
	ProjMthCT AS
	(SELECT p.JCCo, p.Job, p.Phase, p.PhaseGroup, p.CostType, MIN(p.Mth) AS ProjMthCT
			, MIN(case when p.ProjPlug = 'Y' then p.Mth else '12/1/2050' end) AS ProjPlugMthCT
	 FROM	JCCP p With (NoLock)
				INNER JOIN 
			JCJP j With (NoLock) 
				ON j.JCCo			= p.JCCo 
				AND j.Job			= p.Job 
				AND j.PhaseGroup	= p.PhaseGroup 
				AND j.Phase			= p.Phase
	 WHERE (p.ProjCost <> 0 OR p.ProjPlug = 'Y')
	 GROUP BY p.JCCo, p.Job, p.Phase, p.PhaseGroup, p.CostType),
	 
    ProjMthItem AS

	(SELECT j.JCCo, j.Contract, j.Item, MIN(p.Mth) AS ProjMthItem
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
,	ProjMthItem = '12/1/2050'
,	ProjMthCT = '12/1/2050'
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

	--Placeholders for JC Cost portion of UNION ALL
    ,Job=null				,PhaseGroup=null		,Phase=null				,CostType=null 
	,ActualHours= 0.00		,ActualUnits=0.00		,ActualCost=0.00		,OrigEstHours=0.00
	,OrigEstUnits=0.00  	,OrigEstCost=0.00		,CurrEstHours=0.00		,CurrEstUnits=0.00
	,CurrEstCost=0.00		,ProjHours=0.00			,ProjRevUnits=0.00		,ProjCost=0.00
	,ForecastHours=0.00		,ForecastUnits=0.00		,ForecastCost=0.00		,TotalCmtdUnits=0.00
	,TotalCmtdCost=0.00		,RemainCmtdUnits=0.00	,RemainCmtdCost=0.00	,RecvdNotInvcdUnits=0.00
	,RecvdNotInvcdCost=0.00

FROM
	JCIP With (NoLock)

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

,	ISNULL(ProjMthItem.ProjMthItem,'12/1/2050') As ProjMthItem
,	ISNULL(ProjMthCT.ProjMthCT, '12/1/2050') As ProjMthCT
,	JCCP.Mth
       
	--Placeholders for JC Revenue portion of UNION ALL
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	

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

FROM 
	JCCP With (NoLock)
		INNER JOIN 
	JCJP With (NoLock) 
		ON  JCCP.JCCo		= JCJP.JCCo 
		AND JCCP.Job		= JCJP.Job 
		AND JCCP.Phase		= JCJP.Phase 
		AND JCCP.PhaseGroup = JCJP.PhaseGroup 
		LEFT OUTER JOIN 
	ProjMthCT		-- CTE (see top of statement for definition)
		ON	ProjMthCT.JCCo		= JCCP.JCCo
		AND ProjMthCT.Job			= JCCP.Job
		AND ProjMthCT.Phase		= JCCP.Phase
		AND ProjMthCT.PhaseGroup	= JCCP.PhaseGroup
		AND ProjMthCT.CostType	= JCCP.CostType
		LEFT OUTER JOIN	
	ProjMthItem
		ON  ProjMthItem.JCCo = JCJP.JCCo
		AND ProjMthItem.Contract = JCJP.Contract
		AND ProjMthItem.Item = JCJP.Item 


GO
GRANT SELECT ON  [dbo].[vrvJCCostRevenueExcept] TO [public]
GRANT INSERT ON  [dbo].[vrvJCCostRevenueExcept] TO [public]
GRANT DELETE ON  [dbo].[vrvJCCostRevenueExcept] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCCostRevenueExcept] TO [public]
GRANT SELECT ON  [dbo].[vrvJCCostRevenueExcept] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCCostRevenueExcept] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCCostRevenueExcept] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCCostRevenueExcept] TO [Viewpoint]
GO
