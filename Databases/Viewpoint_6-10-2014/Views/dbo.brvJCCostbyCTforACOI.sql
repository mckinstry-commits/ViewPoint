SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
    
    CREATE View [dbo].[brvJCCostbyCTforACOI] as
    /***********************************
    JC Cost by CostType for ACO
    created 6/4/2003 CR
    
    This view will produce the actual costs for CostTypes for each ACO Item
    
    Reports:  JCCostACO.rpt
    
    ***********************************/
    
    
    select JCCo, Job, ACO, ACOItem, PhaseGroup, Phase,  CostType,MonthAdded,  EstCost, CurrEstCost=null,ActualCost=null
    from JCOD
    
    Union all
    
    select JCCo, Job, null, null, PhaseGroup, Phase, CostType, Mth, null, CurrEstCost,ActualCost
    from JCCP
    
    
    
   
  
 



GO
GRANT SELECT ON  [dbo].[brvJCCostbyCTforACOI] TO [public]
GRANT INSERT ON  [dbo].[brvJCCostbyCTforACOI] TO [public]
GRANT DELETE ON  [dbo].[brvJCCostbyCTforACOI] TO [public]
GRANT UPDATE ON  [dbo].[brvJCCostbyCTforACOI] TO [public]
GRANT SELECT ON  [dbo].[brvJCCostbyCTforACOI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCCostbyCTforACOI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCCostbyCTforACOI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCCostbyCTforACOI] TO [Viewpoint]
GO
