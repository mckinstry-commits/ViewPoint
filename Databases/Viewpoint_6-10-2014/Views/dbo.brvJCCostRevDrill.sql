SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE    view [dbo].[brvJCCostRevDrill] 
   as
   
        Select JCIP.JCCo, JCIP.Contract, JCIP.Item, 
        Job=null, PhaseGroup=null, Phase=null, CostType=null, 
        OrigContractAmt=JCIP.OrigContractAmt,
        OrigContractUnits=JCIP.OrigContractUnits, 	
        OrigUnitPrice=JCIP.OrigUnitPrice,
        CurrContractAmt=JCIP.ContractAmt,CurrContractUnits=JCIP.ContractUnits, 
        CurrUnitPrice=JCIP.CurrentUnitPrice, BilledAmt=JCIP.BilledAmt, 
        BilledUnits=JCIP.BilledUnits, ReceivedAmt=JCIP.ReceivedAmt, OrigEstHours=0, 
        OrigEstUnits=0, 
        OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, 
        CurrEstCost=0, ActualHours=0, ActualUnits=0, 
        ActualCost=0, Mth=JCIP.Mth,--'1/1/1950', 
        ProjHours=0, ProjUnits=0, 
        ProjCost=0, 
        PhaseDesc=null 
                 
        FROM  JCIP with(nolock)
        
      
        /* insert jtd Cost info */
   
   UNION ALL   
       
     Select JCJP.JCCo, JCJP.Contract, JCJP.Item, Job=JCCP.Job, PhaseGroup=JCJP.PhaseGroup, 
        Phase=JCJP.Phase, CostType=JCCP.CostType, --CTAbbrev=JCCT.Abbreviation, 
        OrigContractAmt=0, 
        OrigContractUnits=0, OrigUnitPrice=0, CurrContractAmt=0, CurrContractUnits=0, 
        CurrUnitPrice=0, BilledAmt=0, BilledUnits=0, ReceivedAmt=0,
        OrigEstHours=JCCP.OrigEstHours,
        OrigEstUnits=JCCP.OrigEstUnits,
        OrigEstCost=JCCP.OrigEstCost, CurrEstHours=JCCP.CurrEstHours, CurrEstUnits=JCCP.CurrEstUnits,
        CurrEstCost=JCCP.CurrEstCost,
        ActualHours=JCCP.ActualHours, ActualUnits=JCCP.ActualUnits,
        JCCP.ActualCost, Mth=JCCP.Mth, 
        ProjHours=JCCP.ProjHours,  
        ProjUnits=JCCP.ProjUnits,
        ProjCost=JCCP.ProjCost, 
        PhaseDesc=JCJP.Description
        
        FROM JCCP with(nolock)
        Join JCJP with(nolock) on JCJP.JCCo=JCCP.JCCo and JCJP.Job=JCCP.Job and JCJP.Phase=JCCP.Phase 
              and JCJP.PhaseGroup=JCCP.PhaseGroup
        
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 




GO
GRANT SELECT ON  [dbo].[brvJCCostRevDrill] TO [public]
GRANT INSERT ON  [dbo].[brvJCCostRevDrill] TO [public]
GRANT DELETE ON  [dbo].[brvJCCostRevDrill] TO [public]
GRANT UPDATE ON  [dbo].[brvJCCostRevDrill] TO [public]
GRANT SELECT ON  [dbo].[brvJCCostRevDrill] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCCostRevDrill] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCCostRevDrill] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCCostRevDrill] TO [Viewpoint]
GO
