SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[vrvJCEstCostComplete_Except]

/***
 View returns Projected Cost, Current Estimated Cost, and the first projection months by 
 contract item and cost type to use for calculating and comparing estimated cost at completion
 between pre and post 6.3.0 WIP reports.  
 
 ****/

as


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
	 
-- Cost
SELECT 
	JCCP.JCCo
,	JCJP.Contract
,	JCJP.Item

	/*Use the ProjMth column client-side to exclude cost projections that do not fall within
	  a certain date parameter range.  The calculation would be something like: 
	  If ProjMth <= @ThroughMth Then ProjCost Else CurrEstCost
	  
	  The ISNULL ensures that all records can be returned by providing a ThroughMth <= 12/1/2050.*/

,	ISNULL(ProjMthCT.ProjMthCT,'12/1/2050') As ProjMthCT
,	ISNULL(ProjMthCT.ProjPlugMthCT, '12/1/2050') AS ProjPlugMthCT
,	ISNULL(ProjMthItem.ProjMthItem,'12/1/2050') AS ProjMthItem
,	JCCP.Mth
,   JCCP.Job
,	PhaseGroup			= Min(JCCP.PhaseGroup)
,	JCCP.Phase
,	JCCP.CostType
,	CurrEstCost			= sum(JCCP.CurrEstCost)
,	ProjCost			= sum(JCCP.ProjCost)


FROM
	JCCP With (NoLock)
		JOIN 
	JCJP With (NoLock) 
		ON  JCCP.JCCo		= JCJP.JCCo 
		AND JCCP.Job		= JCJP.Job 
		AND JCCP.Phase		= JCJP.Phase 
		AND JCCP.PhaseGroup	= JCJP.PhaseGroup
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
	
GROUP BY
	JCCP.JCCo
,	JCJP.Contract
,	JCJP.Item
,   JCCP.Job
,	ProjMthCT.ProjMthCT
,   ProjMthCT.ProjPlugMthCT
,	ProjMthItem.ProjMthItem
,	JCCP.Mth
,	JCCP.Phase
,	JCCP.CostType

GO
GRANT SELECT ON  [dbo].[vrvJCEstCostComplete_Except] TO [public]
GRANT INSERT ON  [dbo].[vrvJCEstCostComplete_Except] TO [public]
GRANT DELETE ON  [dbo].[vrvJCEstCostComplete_Except] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCEstCostComplete_Except] TO [public]
GRANT SELECT ON  [dbo].[vrvJCEstCostComplete_Except] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCEstCostComplete_Except] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCEstCostComplete_Except] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCEstCostComplete_Except] TO [Viewpoint]
GO
