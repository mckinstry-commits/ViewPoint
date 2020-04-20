SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
       
CREATE   View [dbo].[brvPMACODetEstProfit] 

/* Copied from brvPMEstCo to be specific 
  for the PM Approved CO Detail with Estimated Profit report Issue 22792 11/20/03 NF 

 NOTE:  View may need to be modified when PM issue 138206 is fixed.  Where clause 
       starting on line 67 considered temporary. 

 Mod  2/17/10 DH: Modified section in view brvPMACODetEstProfit that returns addons 
      to include only addons where the PMOA.Status = "N." 
      Addons with this status existed prior to software enhancment 127210 
      and were never updated to PMOL.  
  

*****/      
as    

With PMOA_Cost

as   


(Select	  PMOA.PMCo
		, PMOA.Project
		, PMOA.PCOType
		, PMOA.PCO
		, PMOA.PCOItem
		, PMOI.ACO
		, PMOI.ACOItem
		, PMOA.AddOn
		, PMPA.Phase
		, PMPA.CostType
		, PMOA.AddOnAmount
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

Where PMOI.Approved = 'Y' and PMPA.CostType is not null and PMOA.Status = 'N'

--Temporary Fix:  Includes approved COs where AddOn Phase does not exist in PMOL
/*Where 
         PMOI.Approved = 'Y'
		 and PMPA.Phase is not null
		 and PMOL.Phase is null*/
 )

Select a.PMCo
	  ,a.Project
	  ,a.ACO
	  ,a.ACOItem
	  ,a.Phase
	  ,a.CostType
      ,a.EstUnits
      ,a.UM
      ,a.UnitHours
      ,a.EstHours
      ,a.HourCost
	  ,a.UnitCost
	  ,a.ECM
	  ,"Addon"= NULL
	 , a.EstCost     
      From PMOL a    
      Where a.ACO is Not Null --and a.SendYN = 'Y'      
  
            
      Union All    
          
Select  
	  PMOA_Cost.PMCo
	, PMOA_Cost.Project
	, PMOA_Cost.ACO
	, PMOA_Cost.ACOItem
	, PMOA_Cost.Phase
	, PMOA_Cost.CostType
	, 0 /*Est Units*/
	, null /*UM*/
	, 0 /*UnitHours*/
	, 0 /*EstHours*/
	, 0 /*HourCost*/
	, 0 /*UnitCost*/
	, null /*ECM*/
	,'Add On' /*Addon*/
	, sum(PMOA_Cost.AddOnAmount) /*EstCost*/
From PMOA_Cost

Group By 
      PMOA_Cost.PMCo
	, PMOA_Cost.Project
	, PMOA_Cost.ACO
	, PMOA_Cost.ACOItem
	, PMOA_Cost.Phase
	, PMOA_Cost.CostType   
         
        

  
  
  


GO
GRANT SELECT ON  [dbo].[brvPMACODetEstProfit] TO [public]
GRANT INSERT ON  [dbo].[brvPMACODetEstProfit] TO [public]
GRANT DELETE ON  [dbo].[brvPMACODetEstProfit] TO [public]
GRANT UPDATE ON  [dbo].[brvPMACODetEstProfit] TO [public]
GO
