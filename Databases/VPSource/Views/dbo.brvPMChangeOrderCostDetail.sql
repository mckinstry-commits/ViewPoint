SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE     view [dbo].[brvPMChangeOrderCostDetail] as
    
    /********************************
    PM Change Orders Header and Cost Detail
    created 03/25/05 JH

    NOTE:  View may need to be modified when PM issue 138206 is fixed.  Where clause 
       starting on line 90 considered temporary.

	Mod:  2/10/10 DH.  Issue 137252.  Added CTE for PMOI (PMCOItems) and changed linking in main SQL statement.
					   Before fix, view would fail for phase detail records that get added to existing 
					   approved change orders that originated from a PCO.
	
		  7/11/11 HH.  Issue 142428/VersionOne D-02379/TK-06735. ISNULL check on final select statement for item details 
					   (take PMOI if PMOL has no info), before fix view drop items that do not have phases details assigned.
    
    This view links PMOI and PMOL together since PCOType, PCO and PCOItem may be NULL and all change order items do not always have a phase.
    List of Reports used by view:  PM Change Orders - Internal/External

    ********************************/
    
With PMCOItems

as

(select   PMCo
		, Project
		  /*Set null PCO data to empty string.  Allows PMOI data without PCO
           to be returned in last select statement in this view */
		, isnull(PCOType,'') as PCOType 
		, isnull(PCO,'') as PCO
		, isnull(PCOItem,'') as PCOItem
		, ACO
		, ACOItem
		, Description
		, ApprovedDate
		, UM
		, Units
		, UnitPrice
		, PendingAmount
		, ApprovedAmt
		, Issue
		, FixedAmountYN
		, FixedAmount
		, Approved
 from PMOI),

PMOA_Approved_PhaseCT

as   


(Select	  PMOA.PMCo
		, PMOA.Project
		, PMOA.PCOType
		, PMOA.PCO
		, PMOA.PCOItem
		, PMPA.Phase as AddonPhase
		, PMPA.CostType as AddonCostType
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
	(PMOI.Approved = 'N'
	 OR (PMOI.Approved = 'Y' 
		 and PMOA.Status = 'N')
         )

--Temporary Fix:  Includes unapproved COs or approved COs where AddOn Phase does not exist in PMOL
/*Where 
	(PMOI.Approved = 'N'

	 OR (PMOI.Approved = 'Y'
		 and PMPA.Phase is not null
		 and PMOL.Phase is null))*/

Group By  PMOA.PMCo
		, PMOA.Project
		, PMOA.PCOType
		, PMOA.PCO
		, PMOA.PCOItem
		, PMPA.Phase
		, PMPA.CostType) 

   select isnull(L.PMCo,I.PMCo)			AS PMCo
		, isnull(L.Project,I.Project)	AS Project
		, isnull(L.PCOType,I.PCOType)	AS PCOType
		, isnull(L.PCO,I.PCO)			AS PCO
		, isnull(L.PCOItem,I.PCOItem)	AS PCOItem
		, I.ACO
		, I.ACOItem
		, I.Description
		, I.ApprovedDate
		, RevUM=I.UM
		, I.Units
		, I.UnitPrice
		, I.PendingAmount
		, I.ApprovedAmt
		, I.Issue, I.FixedAmountYN
		, I.FixedAmount
		, L.PhaseGroup
		, L.Phase
		, L.CostType
		, I.Approved
		, L.SendYN
		, L.EstHours
		, L.EstUnits
		, CostUM=L.UM
		, L.UnitCost
		, L.EstCost
		, L.InterfacedDate
		, L.CreatedFromAddOn
		, case when I.ACO is null then 'PCO' else 'ACO' end as PCOACO
		, A.AddonPhase
		, A.AddonCostType
    From PMCOItems I
    LEFT JOIN PMOL L 
		ON  I.PMCo=L.PMCo and I.Project=L.Project 
		AND I.PCOType = isnull(L.PCOType,I.PCOType) 
		AND I.PCO = isnull(L.PCO,I.PCO) 
		AND I.PCOItem = isnull(L.PCOItem,I.PCOItem) 
		AND isnull(I.ACO,'') = isnull(L.ACO, '') 
		AND isnull(I.ACOItem, '') = isnull(L.ACOItem, '')
    LEFT JOIN PMOA_Approved_PhaseCT A
		ON	A.PMCo = L.PMCo
		AND A.Project = L.Project
		AND A.PCOType = L.PCOType
		AND A.PCO = L.PCO
		AND A.PCOItem = L.PCOItem
		AND A.AddonPhase = L.Phase
		AND A.AddonCostType = L.CostType
    
    
    
    
    
    
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPMChangeOrderCostDetail] TO [public]
GRANT INSERT ON  [dbo].[brvPMChangeOrderCostDetail] TO [public]
GRANT DELETE ON  [dbo].[brvPMChangeOrderCostDetail] TO [public]
GRANT UPDATE ON  [dbo].[brvPMChangeOrderCostDetail] TO [public]
GO
