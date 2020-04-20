SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  view [dbo].[brvJCIDProjRev]
   
   as
   
    
   
   select JCCo,Contract,Item,Mth,
   ContractUnits=sum(ContractUnits),ContractAmt =sum(ContractAmt),
   ProjUnits=sum(ProjUnits),ProjDollars =sum(ProjDollars),
   BilledUnits=sum(BilledUnits),BilledAmt =sum(BilledAmt)
   from dbo.JCID
   group by JCCo,Contract,Item,Mth
   
    
   
    
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvJCIDProjRev] TO [public]
GRANT INSERT ON  [dbo].[brvJCIDProjRev] TO [public]
GRANT DELETE ON  [dbo].[brvJCIDProjRev] TO [public]
GRANT UPDATE ON  [dbo].[brvJCIDProjRev] TO [public]
GO
