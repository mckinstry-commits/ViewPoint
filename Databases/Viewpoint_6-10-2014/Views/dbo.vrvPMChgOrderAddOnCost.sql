SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[vrvPMChgOrderAddOnCost]

/*************
 Created:  2/12/10
 Created By:  DH

NOTE:  View may need to be modified when PM issue 138206 is fixed.  Where clause 
       starting on line 137 considered temporary.

 This view selects PM Change Order Add Ons that need to be included on PM Change Order
 reports.  Add Ons to be included need to meet the following conditions:
  - Add Ons for unapproved change orders
  - Add Ons for approved change orders that were not updated to PM Change Order Lines

 Used in the following reports:
 
 - PM Change Order Request - Cost Type
 - PM Change Order Request - Phase
 - PM Pending COs - Contract/Cost Approved
 - PM Pending Change Orders - Contract/Cost
 - PM Change Orders - Internal/External

*************/    

as

/***
 PMOA_Cost CTE: Combines AddOns to change order lines (PMOI).  
 Includes Addons only assigned to a cost type in PM Project Addons (PMPA).
 AddOns assigned to cost type need to be included as cost on various PM reports.
****/

With PMOA_Cost

as   


(Select	  PMOA.PMCo
		, PMOA.Project
		, PMOA.PCOType
		, PMOA.PCO
		, PMOA.PCOItem
		, PMOI.ACO
		, PMOI.ACOItem
		, PMOI.Approved
		, PMOA.AddOn
		, PMOA.Basis
		, PMOA.AddOnPercent
		, PMOA.AddOnAmount
		, PMOA.Status
		, PMOA.TotalType
		, PMOA.UniqueAttchID
		, PMOA.Include
		, PMOA.NetCalcLevel
		, PMOA.KeyID
		, PMOA.BasisCostType
		, PMOA.PhaseGroup
		, PMOA.RevACOItemId
		, PMOA.RevACOItemAmt
		, PMPA.Phase
		, PMPA.CostType

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
Where PMPA.CostType is not null )

/**
 Select statement returns AddOns for 
  1. Unapproved change orders  OR
  2. Approved change orders that were not updated to PMOL.  PMOA_Cost.Status = 'N' signifies
	 Addons that were not updated to PMOL, which is how these records were created prior to
     6.1.0 issue 127210.

**/

Select	  PMOA_Cost.PMCo
		, PMOA_Cost.Project
		, PMOA_Cost.PCOType
		, PMOA_Cost.PCO
		, PMOA_Cost.PCOItem
		, PMOA_Cost.ACO
		, PMOA_Cost.ACOItem
		, PMOA_Cost.AddOn
		, PMOA_Cost.Basis
		, PMOA_Cost.AddOnPercent
		, PMOA_Cost.AddOnAmount
		, PMOA_Cost.Status
		, PMOA_Cost.TotalType
		, PMOA_Cost.UniqueAttchID
		, PMOA_Cost.Include
		, PMOA_Cost.NetCalcLevel
		, PMOA_Cost.KeyID
		, PMOA_Cost.BasisCostType
		, PMOA_Cost.RevACOItemId
		, PMOA_Cost.RevACOItemAmt
		, PMOA_Cost.PhaseGroup
		, PMOA_Cost.Phase
		, PMOA_Cost.CostType
		, PMOL.Phase as LinePhase
		, PMOL.CostType as LineCostType
		, PMOL.CreatedFromAddOn
		, PMOA_Cost.Approved
          
From PMOA_Cost

LEFT JOIN	PMOL With (NoLock)
	ON  PMOA_Cost.PMCo = PMOL.PMCo
	AND PMOA_Cost.Project = PMOL.Project
	AND PMOA_Cost.PCOType = PMOL.PCOType
	AND PMOA_Cost.PCO = PMOL.PCO
	AND PMOA_Cost.PCOItem = PMOL.PCOItem
	AND PMOA_Cost.Phase = PMOL.Phase
	AND PMOA_Cost.CostType = PMOL.CostType

Where 
	(PMOA_Cost.Approved = 'N'
	 OR (PMOA_Cost.Approved = 'Y' 
		 and PMOA_Cost.Status = 'N')
         )

--Temporary Fix:  Includes unapproved COs or approved COs where AddOn Phase does not exist in PMOL
/*Where 
	(PMOA_Cost.Approved = 'N'

	 OR (PMOA_Cost.Approved = 'Y'
		 and PMOA_Cost.Phase is not null
		 and PMOL.Phase is null))*/
     



GO
GRANT SELECT ON  [dbo].[vrvPMChgOrderAddOnCost] TO [public]
GRANT INSERT ON  [dbo].[vrvPMChgOrderAddOnCost] TO [public]
GRANT DELETE ON  [dbo].[vrvPMChgOrderAddOnCost] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMChgOrderAddOnCost] TO [public]
GRANT SELECT ON  [dbo].[vrvPMChgOrderAddOnCost] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMChgOrderAddOnCost] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMChgOrderAddOnCost] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMChgOrderAddOnCost] TO [Viewpoint]
GO
