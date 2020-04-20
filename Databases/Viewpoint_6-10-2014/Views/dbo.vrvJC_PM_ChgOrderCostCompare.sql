SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[vrvJC_PM_ChgOrderCostCompare]

as

/**SQL script compares cost from PM Change Order lines (PMOL) with Addons 
  to Job Cost Change Order Detail (JCOD)
 **/

/***
 Select Addons linked to PM Approved and interfaced change orders
****/

With PMOA_Cost

as   


(Select	  PMOA.PMCo
		, PMOA.Project
--		, PMOA.PCOType
--		, PMOA.PCO
--		, PMOA.PCOItem
		, PMOI.ACO
		, PMOI.ACOItem
		, PMPA.PhaseGroup
		, PMPA.Phase
		, PMPA.CostType
		, sum(PMOA.AddOnAmount) as AddOnAmount

From PMOA

INNER JOIN	PMPA With (NoLock)
	ON  PMPA.PMCo = PMOA.PMCo 
	AND PMPA.Project = PMOA.Project 
	AND PMPA.AddOn = PMOA.AddOn
INNER JOIN	PMOI With (NoLock)
	ON	PMOI.PMCo = PMOA.PMCo
	AND PMOI.Project = PMOA.Project
	AND PMOI.PCOType = PMOA.PCOType
	AND PMOI.PCO = PMOA.PCO
	AND PMOI.PCOItem = PMOA.PCOItem
LEFT JOIN	PMOL With (NoLock)
	ON  PMOA.PMCo = PMOL.PMCo
	AND PMOA.Project = PMOL.Project
	AND PMOA.PCOType = PMOL.PCOType
	AND PMOA.PCO = PMOL.PCO
	AND PMOA.PCOItem = PMOL.PCOItem
	AND PMPA.Phase = PMOL.Phase
	AND PMPA.CostType = PMOL.CostType
Where 
        PMOI.Approved = 'Y'
		 and PMPA.Phase is not null
--		 and (PMOL.Phase is null or (PMOL.Phase is not null and PMOL.EstCost = 0))
         and PMOI.InterfacedDate is not null

Group By PMOA.PMCo
		, PMOA.Project
--		, PMOA.PCOType
--		, PMOA.PCO
--		, PMOA.PCOItem
		, PMOI.ACO
		, PMOI.ACOItem
		, PMPA.PhaseGroup
		, PMPA.Phase
		, PMPA.CostType  ),

JCOD_Cost

as

(Select	 JCOD.JCCo
		,JCOD.Job
		,JCOD.ACO
		,JCOD.ACOItem
		,sum(JCOD.EstCost) as JCEstCost
		,sum(PMOA_Cost.AddOnAmount) as AddOnAmount
 From JCOD
 LEFT OUTER JOIN PMOA_Cost
	ON  PMOA_Cost.PMCo = JCOD.JCCo
	AND PMOA_Cost.Project = JCOD.Job
	AND PMOA_Cost.ACO = JCOD.ACO
	AND PMOA_Cost.ACOItem = JCOD.ACOItem
	AND PMOA_Cost.PhaseGroup = JCOD.PhaseGroup
	AND PMOA_Cost.Phase = JCOD.Phase
	AND PMOA_Cost.CostType = JCOD.CostType 
 Group By JCOD.JCCo
		,JCOD.Job
		,JCOD.ACO
		,JCOD.ACO
		,JCOD.ACOItem),


/**
Select Cost from PM Change Order lines linked to 
change order addons that were updated to PMOL

**/

PMOL_Cost

as

(Select   PMOL.PMCo
		, PMOL.Project
--		, PMOL.PCOType
--		, PMOL.PCO
--		, PMOL.PCOItem
		, PMOL.ACO
		, PMOL.ACOItem
		, sum(PMOL.EstCost) as PMEstCost

		
          
From PMOL

Group By PMOL.PMCo
		, PMOL.Project
--		, PMOL.PCOType
--		, PMOL.PCO
--		, PMOL.PCOItem
		, PMOL.ACO
		, PMOL.ACOItem),

JCandPMDiff

as


(select  P.PMCo
		,P.Project
		,P.ACO
		,P.ACOItem
		,sum(P.PMEstCost) as PMEstCost
		,sum(J.JCEstCost) as JCEstCost
		,sum(J.AddOnAmount) as AddOnAmount
From PMOL_Cost P
Join JCOD_Cost J
	 ON  P.PMCo = J.JCCo
	 AND P.Project = J.Job
	 AND P.ACO = J.ACO
	 AND P.ACOItem = J.ACOItem
Group By  P.PMCo
		 ,P.Project
		 ,P.ACO
		 ,P.ACOItem
--having sum(J.JCEstCost) - sum(P.PMEstCost) = sum(J.AddOnAmount)
 
)

select	 J.JCCo
		,J.Job
		,J.ACO
		,J.ACOItem
		,J.Phase	as JCPhase
		,J.CostType as JCCostType
		,PMOL.Phase as PMPhase
		,PMOL.CostType as PMCostType
		,A.Phase as AddOnPhase
		,A.CostType as AddOnCostType
		,J.EstCost as JCPhaseEstCost
		,PMOL.EstCost as PMPhaseEstCost
		--,D.PMEstCost as PMEstCost_TotalACOItem
		--,D.JCEstCost as JCEstCost_TotalACOItem
		--,D.AddOnAmount as AddOnAmount_TotalACOItem
		,J.EstCost - isnull(PMOL.EstCost,0) as JC_PMDifference
		,A.AddOnAmount


From JCOD J
/*INNER JOIN JCandPMDiff D
	ON D.PMCo = J.JCCo
	AND D.Project = J.Job
	AND D.ACO = J.ACO
	AND D.ACOItem = J.ACOItem*/
LEFT OUTER JOIN PMOA_Cost A
	ON  A.PMCo = J.JCCo
	AND A.Project = J.Job
	AND A.ACO = J.ACO
	AND A.ACOItem = J.ACOItem
	AND A.PhaseGroup = J.PhaseGroup
	AND A.Phase = J.Phase
	AND A.CostType = J.CostType
LEFT OUTER JOIN PMOL 
	ON J.JCCo = PMOL.PMCo
	AND J.Job = PMOL.Project
	AND J.ACO = PMOL.ACO
	AND J.ACOItem = PMOL.ACOItem
	AND J.PhaseGroup = PMOL.PhaseGroup
	AND J.Phase = PMOL.Phase
	AND J.CostType = PMOL.CostType
Where J.EstCost <> isnull(PMOL.EstCost,0) 
	  and J.JCCo = 1 --and J.Job = '7103- 9'
--	  and J.EstCost - isnull(PMOL.EstCost,0) = A.AddOnAmount


GO
GRANT SELECT ON  [dbo].[vrvJC_PM_ChgOrderCostCompare] TO [public]
GRANT INSERT ON  [dbo].[vrvJC_PM_ChgOrderCostCompare] TO [public]
GRANT DELETE ON  [dbo].[vrvJC_PM_ChgOrderCostCompare] TO [public]
GRANT UPDATE ON  [dbo].[vrvJC_PM_ChgOrderCostCompare] TO [public]
GRANT SELECT ON  [dbo].[vrvJC_PM_ChgOrderCostCompare] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJC_PM_ChgOrderCostCompare] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJC_PM_ChgOrderCostCompare] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJC_PM_ChgOrderCostCompare] TO [Viewpoint]
GO
