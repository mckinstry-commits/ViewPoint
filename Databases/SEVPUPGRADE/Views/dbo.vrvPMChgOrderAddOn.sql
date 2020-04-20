SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[vrvPMChgOrderAddOn]

/*************
 Created:  3/1/10
 Created By:  DH



 This view selects PM Change Order Add Ons that need to be included on PM Change Order
 reports.  Add Ons to be included need to meet the following conditions:
  - Add Ons for unapproved change orders
  - Add Ons for approved change orders that were not updated to PM Change Order Lines

 Used in the following reports:
 
 - PM Change Order Request - Cost Type
 - PM Change Order Request - Phase

*************/    

as

/***
 PMOA_Cost CTE: Combines AddOns to change order lines (PMOI).  

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

LEFT OUTER JOIN	PMPA With (NoLock)
	ON  PMPA.PMCo = PMOA.PMCo 
	AND PMPA.Project = PMOA.Project 
	AND PMPA.AddOn = PMOA.AddOn
INNER JOIN	PMOI With (NoLock)
	ON	PMOI.PMCo = PMOA.PMCo
	AND PMOI.Project = PMOA.Project
	AND PMOI.PCOType = PMOA.PCOType
	AND PMOI.PCO = PMOA.PCO
	AND PMOI.PCOItem = PMOA.PCOItem
 )

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
		 and PMOA_Cost.CostType is null)
         )

--Temporary Fix:  Includes unapproved COs or approved COs where AddOn Phase does not exist in PMOL
/*Where 
	(PMOA_Cost.Approved = 'N'

	 OR (PMOA_Cost.Approved = 'Y'
		 and PMOA_Cost.Phase is not null
		 and PMOL.Phase is null))*/
     




GO
GRANT SELECT ON  [dbo].[vrvPMChgOrderAddOn] TO [public]
GRANT INSERT ON  [dbo].[vrvPMChgOrderAddOn] TO [public]
GRANT DELETE ON  [dbo].[vrvPMChgOrderAddOn] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMChgOrderAddOn] TO [public]
GO
