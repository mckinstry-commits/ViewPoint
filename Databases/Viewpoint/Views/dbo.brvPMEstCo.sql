SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************
   Modified 10/1/04 CR 
   
   
   
   Used in PMEstCODist.rpt
   
   Mod:  2/17/10 DH.  Issue 137035.  Modified section for addons to include only addons
                                     that have not been updated to PMOL.
   
   *****************************/
   
   
   
   
   
   CREATE             View [dbo].[brvPMEstCo]
      as
Select a.PMCo,a.Project,a.ACO,a.ACOItem,a.Phase,a.CostType,
      a.EstUnits,a.UM,a.UnitHours,a.EstHours,a.HourCost,a.UnitCost,a.ECM,a.EstCost 
      From PMOL a
      Where a.ACO is Not Null and a.SendYN = 'Y'  and a.InterfacedDate is Null 
      
      
      Union All
      
      Select Distinct a.PMCo,a.Project,a.ACO,a.ACOItem,c.Phase,c.CostType,
      0,null,0,0,0,0,'Add On',b.AddOnAmount
      From PMOI a
      Left Join PMOA b On a.PMCo = b.PMCo and a.Project = b.Project 
      	and a.PCO = b.PCO and a.PCOItem = b.PCOItem and a.PCOType = b.PCOType
      Left Join PMPA c On b.PMCo = c.PMCo and b.Project = c.Project and b.AddOn = c.AddOn
      	and c.Phase Is not null
      
     
     Where  b.Status <> 'Y' and c.Phase is not null
    /*
     Union All
      
      Select Distinct a.PMCo,a.Project,a.ACO,a.ACOItem,c.Phase,c.CostType,
      0,null,0,0,0,0,'Add On',b.AddOnAmount
      From PMOI a
      Left Join PMOA b On a.PMCo = b.PMCo and a.Project = b.Project 
      	and a.PCO = b.PCO and a.PCOItem = b.PCOItem and a.PCOType = b.PCOType
      Left Join PMPA c On b.PMCo = c.PMCo and b.Project = c.Project and b.AddOn = c.AddOn
      	and c.Phase Is not null
      
     
     Where  b.Status <> 'Y' and c.Phase is not null
    */

GO
GRANT SELECT ON  [dbo].[brvPMEstCo] TO [public]
GRANT INSERT ON  [dbo].[brvPMEstCo] TO [public]
GRANT DELETE ON  [dbo].[brvPMEstCo] TO [public]
GRANT UPDATE ON  [dbo].[brvPMEstCo] TO [public]
GO
