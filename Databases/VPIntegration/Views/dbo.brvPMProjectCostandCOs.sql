SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE          View [dbo].[brvPMProjectCostandCOs] as
/**
   Created 1/26/2005 CR
   Usage:  This view will return costs related to a Job, which includes the following:
           Job Costs, Pending Change Order Contract Amounts, Pending Change Order Costs, and
           Approved Change Order Costs.  Used by the PM Project Drilldown (PMProjectDD.rpt)
   **/
   
       
       select --JCCP.JCCo, JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType,JCCP.Mth,
       JCJP.JCCo, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCH.CostType, JCCP.Mth, 
        
       JCCP.ActualHours, JCCP.ActualUnits, JCCP.ActualCost, 
       JCCP.OrigEstHours, JCCP.OrigEstUnits, JCCP.OrigEstCost, JCCP.CurrEstHours, JCCP.CurrEstUnits, JCCP.CurrEstCost, 
       JCCP.ProjHours, JCCP.ProjUnits, JCCP.ProjCost, JCCP.ForecastHours, JCCP.ForecastUnits, JCCP.ForecastCost, 
       JCCP.TotalCmtdUnits, JCCP.TotalCmtdCost, JCCP.RemainCmtdUnits, JCCP.RemainCmtdCost, JCCP.RecvdNotInvcdUnits, JCCP.RecvdNotInvcdCost,
       
       PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
       SendYN=Null, 
       COContUM=null, COContUnits=0.00, COContUP=0.00,
       COContAmt=0.00, COContEstHrs=0,
       InterfacedDate='1/1/1950',Sort = 1,Description=null
       
    
     	
       from JCJP With (NoLock)
       
       left outer join JCCP With (NoLock) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and
          JCCP.Phase=JCJP.Phase and JCCP.PhaseGroup=JCJP.PhaseGroup 
       left outer join JCCH with (nolock) on JCCH.JCCo=JCCP.JCCo and JCCH.Job=JCCP.Job and
          JCCH.Phase=JCCP.Phase and JCCH.PhaseGroup=JCCP.PhaseGroup and JCCH.CostType=JCCP.CostType
      
     union all    
   
       select PMOL.PMCo, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase,PMOL.CostType, '12/1/2050',
       null, null, null,
       null, null, null, null, null, null,
       null, null, null, null, null, null,
       null, null, null, null, null, null,
       
       PCOType=PMOL.PCOType, PCO=PMOL.PCO, PCOItem=PMOL.PCOItem, ACO=PMOL.ACO, ACOItem=PMOL.ACOItem, 
   
       SendYN=PMOL.SendYN, 
       COContUM=PMOL.UM, COContUnits=PMOL.EstUnits, COContUP=PMOL.UnitCost, 
       COContAmt=PMOL.EstCost,COContEstHrs=PMOL.EstHours,
       InterfacedDate=PMOL.InterfacedDate, Sort=2, I.Description
       
   
   
    From PMOL  with (NoLock)
   
   --where PMCo = 1 and Project = '    1-' and PhaseGroup = 10 and Phase = '    1-   -' and CostType = 2 
   
    Left outer join PMOI I on
    PMOL.PMCo=I.PMCo and PMOL.Project=I.Project and 
    isnull(PMOL.PCOType,'') = isnull(I.PCOType,'') and
    isnull(PMOL.PCO,'') = isnull(I.PCO,'') and
    isnull(PMOL.PCOItem,'') = isnull(I.PCOItem,'') and
    isnull(PMOL.ACO,'')=isnull(I.ACO,'') and 
    isnull(PMOL.ACOItem,'')=isnull(I.ACOItem,'')

GO
GRANT SELECT ON  [dbo].[brvPMProjectCostandCOs] TO [public]
GRANT INSERT ON  [dbo].[brvPMProjectCostandCOs] TO [public]
GRANT DELETE ON  [dbo].[brvPMProjectCostandCOs] TO [public]
GRANT UPDATE ON  [dbo].[brvPMProjectCostandCOs] TO [public]
GO
