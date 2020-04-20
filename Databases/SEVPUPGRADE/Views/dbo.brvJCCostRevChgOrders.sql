SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE    View [dbo].[brvJCCostRevChgOrders] as
   
   /**
   Created 10/27/2004 DH
   Usage:  This view will return all types of revenue and costs related to a Contract, which includes the following:
           Contract Amounts, Job Costs, Pending Change Order Contract Amounts, Pending Change Order Costs, and
           Pending Change Order Addon Costs.  Used by the JC Cost and Revenue With Change Order template (JCCostRevCOTemplate.rpt)
   **/
   
    select JCIP.JCCo, JCIP.Contract, JCIP.Item, JCIP.Mth,
       JCIP.OrigContractAmt, JCIP.OrigContractUnits, JCIP.OrigUnitPrice, JCIP.ContractAmt, 
       JCIP.ContractUnits, JCIP.CurrentUnitPrice, JCIP.BilledUnits, JCIP.BilledAmt, 
       JCIP.ReceivedAmt, JCIP.CurrentRetainAmt, JCIP.BilledTax, 
       
       Job=null, PhaseGroup=null, Phase= null, CostType= null, ActualHours= 0.00,  ActualUnits=0.00,  ActualCost=0.00,  
       OrigEstHours=0.00,  OrigEstUnits=0.00,  OrigEstCost=0.00,  CurrEstHours=0.00,  CurrEstUnits=0.00,  CurrEstCost=0.00, 
       ProjHours=0.00,  ProjUnits=0.00,  ProjCost=0.00,  ForecastHours=0.00,  ForecastUnits=0.00,  ForecastCost=0.00, 
       TotalCmtdUnits=0.00,  TotalCmtdCost=0.00,  RemainCmtdUnits=0.00,  RemainCmtdCost=0.00,  RecvdNotInvcdUnits=0.00,  RecvdNotInvcdCost=0.00,
       
       PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, COStatus=null, COApprovedYN=Null, COApprovedMth='1/1/1950', COApprovedDate='1/1/1950', COContUM=null, COContUnits=0.00, COContUP=0.00,
       COContAmt=0.00, COContPendAmt=0.00, COCostUnits=0.00, COCostUM=null, COUnitsPerHour=0.00, COHours=0.00, COCostPerHr=0.00, COUnitCost=0.00, COECM=null, COCostDollars=0.00, COCostAddon=0, COCostIntDate='1/1/1950'
      
       
       from JCIP With (NoLock)
    
       union all
       
       select JCCP.JCCo, JCJP.Contract, JCJP.Item, JCCP.Mth,
       null, null, null, null, 
       null, null, null, null, 
       null, null, null, 
       
       JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType, JCCP.ActualHours, JCCP.ActualUnits, JCCP.ActualCost, 
       JCCP.OrigEstHours, JCCP.OrigEstUnits, JCCP.OrigEstCost, JCCP.CurrEstHours, JCCP.CurrEstUnits, JCCP.CurrEstCost, 
       JCCP.ProjHours, JCCP.ProjUnits, JCCP.ProjCost, JCCP.ForecastHours, JCCP.ForecastUnits, JCCP.ForecastCost, 
       JCCP.TotalCmtdUnits, JCCP.TotalCmtdCost, JCCP.RemainCmtdUnits, JCCP.RemainCmtdCost, JCCP.RecvdNotInvcdUnits, JCCP.RecvdNotInvcdCost,
       
       PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, COStatus=null, COApprovedYN=Null, COApprovedMth='1/1/1950', COApprovedDate='1/1/1950', COContUM=null, COContUnits=0.00, COContUP=0.00,
       COContAmt=0.00, COContPendAmt=0.00, COCostUnits=0.00, COCostUM=null, COUnitsPerHour=0.00, COHours=0.00, COCostPerHr=0.00, COUnitCost=0.00, COECM=null, COCostDollars=0.00, COCostAddon=0, COCostIntDate='1/1/1950'  
    
     	
       from JCCP With (NoLock)
       
       join JCJP With (NoLock) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and
          JCCP.Phase=JCJP.Phase and JCCP.PhaseGroup=JCJP.PhaseGroup 
      
     union all    
   
   select PMOI.PMCo, PMOI.Contract, PMOI.ContractItem, '1/1/1950',
       null, null, null, null, 
       null, null, null, null, 
       null, null, null, 
      
       null, null, null, null, null, null, null, 
       null, null, null, null, null, null, 
       null, null, null, null, null, null, 
       null, null, null, null, null, null,
       
       PCOType=PMOI.PCOType, PCO=PMOI.PCO, PCOItem=PMOI.PCOItem, ACO=PMOI.ACO, ACOItem=PMOI.ACOItem, COStatus=PMOI.Status, COApprovedYN=PMOI.Approved, COApprovedMth=isnull(JCOI.ApprovedMonth,'12/1/2050'), COApprovedDate=isnull(PMOI.ApprovedDate,'1/1/1950'), COContUM=PMOI.UM, COContUnits=PMOI.Units, COContUP=PMOI.UnitPrice, 
       COContAmt=(case when isnull(PMOI.FixedAmount,0)=0 then PMOI.ApprovedAmt else PMOI.FixedAmount end),
       COContPendAmt=(case when isnull(PMOI.FixedAmount,0)=0 then PMOI.PendingAmount else PMOI.FixedAmount end),
       COCostUnits=0.00, COCostUM=null, COUnitsPerHour=0.00, COHours=0.00, COCostPerHr=0.00, COUnitCost=0.00, COECM=null, COCostDollars=0.00, COCostAddon=0, COCostIntDate='1/1/1950'
   
   From PMOI
   Left Join JCOI on JCOI.JCCo=PMOI.PMCo and JCOI.Job=PMOI.Project and JCOI.ACO=PMOI.ACO and JCOI.ACOItem=PMOI.ACOItem
   
      union all
   
   select PMOI.PMCo, PMOI.Contract, PMOI.ContractItem, '1/1/1950',
       null, null, null, null, 
       null, null, null, null, 
       null, null, null, 
      
       PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType, null, null, null, 
       null, null, null, null, null, null, 
       null, null, null, null, null, null, 
       null, null, null, null, null, null,
       
       PCOType=PMOI.PCOType, PCO=PMOI.PCO, PCOItem=PMOI.PCOItem, ACO=PMOI.ACO, ACOItem=PMOI.ACOItem, COStatus=PMOI.Status, COApprovedYN=PMOI.Approved, COApprovedMth=isnull(JCOI.ApprovedMonth,'12/1/2050'), COApprovedDate=isnull(PMOI.ApprovedDate,'1/1/1950'), COContUM=PMOI.UM, COContUnits=0, COContUP=0, 
       COContAmt=0.00, 
       COContPendAmt=0.00,
       COCostUnits=PMOL.EstUnits, COCostUM=PMOL.UM, COUnitsPerHour=PMOL.UnitHours, COHours=PMOL.EstHours, COCostPerHr=PMOL.HourCost, COUnitCost=PMOL.UnitCost, COECM=PMOL.ECM, COCostDollars=PMOL.EstCost, COCostAddon=0, COCostIntDate=isnull(PMOL.InterfacedDate,'1/1/1950')
   
   From PMOI
   Join PMOL on PMOL.PMCo=PMOI.PMCo and PMOL.Project=PMOI.Project and isnull(PMOL.PCOType,'')=isnull(PMOI.PCOType,'') and isnull(PMOL.PCO,'')=isnull(PMOI.PCO,'') and isnull(PMOL.PCOItem,'')=isnull(PMOI.PCOItem,'') and
        isnull(PMOL.ACO,'')=isnull(PMOI.ACO,'') and isnull(PMOL.ACOItem,'')=isnull(PMOI.ACOItem,'')
   Left Join JCOI on JCOI.JCCo=PMOI.PMCo and JCOI.Job=PMOI.Project and JCOI.ACO=PMOI.ACO and JCOI.ACOItem=PMOI.ACOItem
   
   union all 
   
   select PMOI.PMCo, PMOI.Contract, PMOI.ContractItem, '1/1/1950',
       null, null, null, null, 
       null, null, null, null, 
       null, null, null, 
      
       PMOA.Project, PMPA.PhaseGroup, PMPA.Phase, PMPA.CostType, null, null, null, 
       null, null, null, null, null, null, 
       null, null, null, null, null, null, 
       null, null, null, null, null, null,
       
       PCOType=PMOA.PCOType, PCO=PMOA.PCO, PCOItem=PMOA.PCOItem, ACO=PMOI.ACO, ACOItem=PMOI.ACOItem, COStatus=PMOI.Status, COApprovedYN=PMOI.Approved, COApprovedMth=isnull(JCOI.ApprovedMonth,'12/1/2050'), COApprovedDate=isnull(PMOI.ApprovedDate,'1/1/1950'), COContUM=PMOI.UM, COContUnits=0, COContUP=0, 
       COContAmt=0.00, 
       COContPendAmt=0.00,
       COCostUnits=0, COCostUM=null, COUnitsPerHour=0, COHours=0, COCostPerHr=0, COUnitCost=0, COECM=null, COCostDollars=0, COCostAddon=PMOA.AddOnAmount, COCostIntDate=isnull(OL.InterfacedDate,'1/1/1950')
   
   From PMOA
   Join PMOI on PMOI.PMCo=PMOA.PMCo and PMOI.Project=PMOA.Project and PMOI.PCOType=PMOA.PCOType and PMOI.PCO=PMOA.PCO
             and PMOI.PCOItem=PMOA.PCOItem 
   Join (Select l.PMCo, l.Project, l.PCOType, l.PCO, l.PCOItem, InterfacedDate=max(l.InterfacedDate) 
               From PMOL l Group By l.PMCo, l.Project, l.PCOType, l.PCO, l.PCOItem) as OL
   	            on OL.PMCo=PMOA.PMCo and OL.Project=PMOA.Project and OL.PCOType=PMOA.PCOType and OL.PCO=PMOA.PCO
   		       and OL.PCOItem=PMOA.PCOItem
   	Join PMPA  on PMPA.PMCo=PMOA.PMCo and PMPA.Project=PMOA.Project and PMPA.AddOn=PMOA.AddOn
   	Join JCJP  on JCJP.JCCo=PMPA.PMCo and JCJP.Job=PMPA.Project and JCJP.PhaseGroup=PMPA.PhaseGroup and JCJP.Phase=PMPA.Phase
   
   Left Join JCOI on JCOI.JCCo=PMOI.PMCo and JCOI.Job=PMOI.Project and JCOI.ACO=PMOI.ACO and JCOI.ACOItem=PMOI.ACOItem
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvJCCostRevChgOrders] TO [public]
GRANT INSERT ON  [dbo].[brvJCCostRevChgOrders] TO [public]
GRANT DELETE ON  [dbo].[brvJCCostRevChgOrders] TO [public]
GRANT UPDATE ON  [dbo].[brvJCCostRevChgOrders] TO [public]
GO
