SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  View [dbo].[brvPMAddonPCOItem]    Script Date: 02/10/2010 05:13:43 ******/

CREATE view [dbo].[brvPMAddonPCOItem] 

/*************
 Created:  2/12/10
 Created By:  DH

NOTE:  View may need to be modified when PM issue 138206 is fixed.  Where clause 
       starting on line 116 considered temporary.

 This view selects PM Change Order Add Ons that need to be included on PM Change Order
 reports.  Add Ons to be included need to meet the following conditions:
  - Add Ons for unapproved change orders
  - Add Ons for approved change orders that were not updated to PM Change Order Lines

Final Select statement groups data by PMCo, Project, PCOType, PCO, PCOItem

 Used in the following reports:

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
		, PMOI.Approved
		, PMOA.AddOn
		, PMPA.Phase
		, PMPA.CostType
		, PMOA.AddOnAmount 
		, PMOA.Status
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
Where PMPA.CostType is not null ),

/**
 Addon CTE:  Select statement returns AddOns for 
  1. Unapproved change orders  OR
  2. Approved change orders that were not updated to PMOL based on PMOA.Status.  PMOA.Status = N
     means that addons were not updated to PMOL.

**/

AddOn 

as

(Select	  PMOA_Cost.PMCo
		, PMOA_Cost.Project
		, PMOA_Cost.PCOType
		, PMOA_Cost.PCO
		, PMOA_Cost.PCOItem
		, PMOA_Cost.AddOn
		, PMOA_Cost.Phase
		, PMOA_Cost.CostType
		, PMOL.Phase as LinePhase
		, PMOL.CostType as LineCostType
		, PMOL.CreatedFromAddOn
		, PMOA_Cost.Approved
		, PMOA_Cost.AddOnAmount
          
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
		 and PMOA_Cost.Status = 'N'
         )
     ) 

--Temporary Fix:  Includes unapproved COs or approved COs where AddOn Phase does not exist in PMOL

/*	(PMOA_Cost.Approved = 'N'

	 OR (PMOA_Cost.Approved = 'Y'
		 and PMOA_Cost.Phase is not null
		 and PMOL.Phase is null))*/

)--End AddOn CTE


 select   AddOn.PMCo
		, AddOn.Project
		, AddOn.PCOType
		, AddOn.PCO
		, AddOn.PCOItem
		, AddonAmout=sum(AddOn.AddOnAmount)
    From AddOn
    Group By  AddOn.PMCo
			, AddOn.Project
			, AddOn.PCOType
			, AddOn.PCO
			, AddOn.PCOItem







GO
GRANT SELECT ON  [dbo].[brvPMAddonPCOItem] TO [public]
GRANT INSERT ON  [dbo].[brvPMAddonPCOItem] TO [public]
GRANT DELETE ON  [dbo].[brvPMAddonPCOItem] TO [public]
GRANT UPDATE ON  [dbo].[brvPMAddonPCOItem] TO [public]
GRANT SELECT ON  [dbo].[brvPMAddonPCOItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPMAddonPCOItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPMAddonPCOItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPMAddonPCOItem] TO [Viewpoint]
GO
