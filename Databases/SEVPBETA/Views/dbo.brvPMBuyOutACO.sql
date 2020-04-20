SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  view [dbo].[brvPMBuyOutACO] as
   
   select Company=JCCo, Job=Job,PhaseGroup=PhaseGroup ,Phase=Phase,CT=CostType,ACO=ACO,Item= ACOItem,EstCost=sum(EstCost),TotalCmdtCost=0.00 from JCCD
   
   	group by JCCo, Job,PhaseGroup ,Phase,CostType,ACO, ACOItem
   union All
   select PMCo, Project,PhaseGroup ,Phase,CostType,ACO, ACOItem, EstCost=0.00, TotalCmdtCost=sum(Amount) from PMSL
   	where PMSL.InterfaceDate is not NULL
   
   	group by PMCo, Project,PhaseGroup ,Phase,CostType,ACO, ACOItem
   union All
   select PMCo, Project,PhaseGroup ,Phase,CostType,ACO, ACOItem, EstCost=0.00, TotalCmdtCost=sum(Amount) from PMMF
   	where PMMF.InterfaceDate is not NULL
   
   	group by PMCo, Project,PhaseGroup ,Phase,CostType,ACO, ACOItem
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPMBuyOutACO] TO [public]
GRANT INSERT ON  [dbo].[brvPMBuyOutACO] TO [public]
GRANT DELETE ON  [dbo].[brvPMBuyOutACO] TO [public]
GRANT UPDATE ON  [dbo].[brvPMBuyOutACO] TO [public]
GO
