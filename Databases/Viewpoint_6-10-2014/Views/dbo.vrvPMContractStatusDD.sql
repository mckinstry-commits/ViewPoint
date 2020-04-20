SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[vrvPMContractStatusDD] as              
                 
   /**              
   Created 8/21/07 JH              
   Usage:  This view will return revenue costs related to a Contract, which includes the following:              
           Job Costs/Revenues, Pending Change Order Contract Amounts, Pending Change Order Costs, and              
           Approved Change Order Costs.  Used by the PM ContractStatus Drilldown (PMContractStatusDD.rpt) 

   Mod:  issue # 135156 Updated 02/16/10 MB           
	     TK-06751 DH.  Added EstRev_Mth field
   **/              
                 
              
/*Revenue*/              
select 'u1' as 'U', JCIP.JCCo, JCIP.Contract, Job=b.Job, PhaseGroup=null,Phase=null, CostType=null,JCIP.Mth,              
              
 JCIP.OrigContractAmt, JCIP.ContractAmt, JCIP.BilledAmt, JCIP.ReceivedAmt, JCIP.CurrentRetainAmt, JCIP.ProjDollars, 
 EstRev.EstRevenue_Mth, --net change of estimated revenue at completion by each month.             
 ProjMth=(select isnull(min(i.Mth),'12/1/2050') from JCIP i with (nolock)              
             where JCIP.JCCo=i.JCCo and JCIP.Contract=i.Contract and JCIP.Item=i.Item and (i.ProjDollars <>0 or i.ProjPlug='Y')),              
                      
        ActualHours=0, ActualUnits=0, ActualCost=0,               
        OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0,               
        ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0,               
        TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,              
                     
        PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null,               
        SendYN=Null,               
        COContUM=null, COContUnits=0.00, COContUP=0.00,              
        COContAmt=0.00, COContEstHrs=0,              
        InterfacedDate='1/1/1950',Sort = 1,Description=null, APAmt=0.00, RetAPAmt=0.00, PaidMth='12/31/2050',          
  Null as 'Approved',          
  Null as 'ApprovedAmt',          
  Null as 'ApprovedMonth',          
  Null as 'FixedAmountYN',           
  Null as 'PendingAmount',          
  Null as 'FixedAmount',          
  Null as 'APPMthGreater'          
from JCIP With (NoLock)              
 join brvJCContrMinJob b on JCIP.JCCo=b.JCCo and JCIP.Contract=b.Contract
 OUTER APPLY vf_rptJCEstRevenue (JCIP.JCCo,JCIP.Contract,JCIP.Item,JCIP.Mth) EstRev          
                     
              
union all              
              
                     
select 'u2' as 'U', JCCP.JCCo, JCJP.Contract, JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType,JCCP.Mth,              
              
 OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, 
 EstRevenue_Mth=0.00,             
              
         ProjMth=(Select isnull(min(Mth),'12/1/2050') From JCCP p With (NoLock)              
                              Join JCJP j With (NoLock) on j.JCCo=p.JCCo and j.Job=p.Job and j.PhaseGroup=p.PhaseGroup and j.Phase=p.Phase              
                              Where j.JCCo=JCCP.JCCo and j.Contract=JCJP.Contract and j.Item=JCJP.Item and p.ProjCost<>0),              
              
       JCCP.ActualHours, JCCP.ActualUnits, JCCP.ActualCost,               
        JCCP.OrigEstHours, JCCP.OrigEstUnits, JCCP.OrigEstCost, JCCP.CurrEstHours, JCCP.CurrEstUnits, JCCP.CurrEstCost,               
       JCCP.ProjHours, JCCP.ProjUnits, JCCP.ProjCost, JCCP.ForecastHours, JCCP.ForecastUnits, JCCP.ForecastCost,               
        JCCP.TotalCmtdUnits, JCCP.TotalCmtdCost, JCCP.RemainCmtdUnits, JCCP.RemainCmtdCost, JCCP.RecvdNotInvcdUnits, JCCP.RecvdNotInvcdCost,              
                     
        PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null,               
        SendYN=Null,               
        COContUM=null, COContUnits=0.00, COContUP=0.00,              
        COContAmt=0.00, COContEstHrs=0,              
        InterfacedDate='1/1/1950',Sort = 1,Description=null, APAmt=0.00, RetAPAmt=0.00, PaidMth='12/31/2050',              
         Null as 'Approved',          
  Null as 'ApprovedAmt',          
  Null as 'ApprovedMonth',          
  Null as 'FixedAmountYN',           
  Null as 'PendingAmount',          
  Null as 'FixedAmount',          
  Null as 'APPMthGreater'          
from JCCP With (NoLock)              
        join JCJP With (NoLock) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and              
  JCCP.Phase=JCJP.Phase and JCCP.PhaseGroup=JCJP.PhaseGroup               
              
union all                  
          
                 
select 'u3' as 'U', PMOL.PMCo, PMOI.Contract, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase,PMOL.CostType, '1/1/1950',              
 OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00,
 EstRevenue_Mth=0.00, ProjMth='1/1/1950',              
 null, null, null,              
 null, null, null, null, null, null,              
        null, null, null, null, null, null,              
        null, null, null, null, null, null,              
                     
        PCOType=PMOL.PCOType, PCO=PMOL.PCO, PCOItem=PMOL.PCOItem, ACO=PMOL.ACO, ACOItem=PMOL.ACOItem,               
                 
        SendYN=PMOL.SendYN,               
        COContUM=PMOL.UM, COContUnits=PMOL.EstUnits, COContUP=PMOL.UnitCost,             
        COContAmt=PMOL.EstCost,COContEstHrs=PMOL.EstHours,              
        InterfacedDate=PMOL.InterfacedDate, Sort=2, PMOI.Description, APAmt=0.00, RetAPAmt=0.00, PaidMth='12/31/2050',              
         Null as 'Approved',          
  Null as 'ApprovedAmt',          
  Null as 'ApprovedMonth',          
  Null as 'FixedAmountYN',           
  Null as 'PendingAmount',          
  Null as 'FixedAmount',          
  Null as 'APPMthGreater'          
From PMOL  with (NoLock)                 
 Left outer join PMOI on  PMOL.PMCo=PMOI.PMCo and PMOL.Project=PMOI.Project and isnull(PMOL.PCOType,'') = isnull(PMOI.PCOType,'') and              
  isnull(PMOL.PCO,'') = isnull(PMOI.PCO,'') and isnull(PMOL.PCOItem,'') = isnull(PMOI.PCOItem,'') and isnull(PMOL.ACO,'')=isnull(PMOI.ACO,'') and               
  isnull(PMOL.ACOItem,'')=isnull(PMOI.ACOItem,'')              
              
union all              
              
/**AP Amount**/              
Select 'u4' as 'U', JCJM.JCCo, JCJM.Contract, JCJM.Job, PhaseGroup=null, Phase=null, CostType=null, APTD.Mth,              
     OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, 
     EstRevenue_Mth=0.00, ProjMth='1/1/1950',              
              
        ActualHours=0, ActualUnits=0, ActualCost=0,               
        OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0,               
        ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0,               
        TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,              
                     
        PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null,               
        SendYN=Null,               
        COContUM=null, COContUnits=0.00, COContUP=0.00,              
        COContAmt=0.00, COContEstHrs=0,              
        InterfacedDate='1/1/1950',Sort = 1,Description=null,               
 APAmt=Sum(APTD.Amount), RetAPAmt=sum(case when APTD.PayType=APCO.RetPayType then APTD.Amount else 0 end),              
 PaidMth=IsNull(PaidMth,'12/31/2050') ,             
     Null as 'Approved',          
  Null as 'ApprovedAmt',          
  Null as 'ApprovedMonth',          
  Null as 'FixedAmountYN',           
  Null as 'PendingAmount',          
  Null as 'FixedAmount',          
  Null as 'APPMthGreater'          
from JCJM              
 join APTL on APTL.JCCo=JCJM.JCCo and APTL.Job=JCJM.Job              
     join APTD on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and APTL.APLine=APTD.APLine              
     join JCCM e on JCJM.JCCo = e.JCCo and JCJM.Contract = e.Contract              
     join (Select JCCo, Contract,Job=Min(Job),ProjectMgr=Min(ProjectMgr)  From JCJM Group By JCCo,Contract ) As JM on              
      e.JCCo = JM.JCCo and e.Contract = JM.Contract               
 join APCO on APTL.APCo=APCO.APCo              
Group by JCJM.JCCo, JCJM.Contract,APTD.Mth,JCJM.Job,APTD.PaidMth              
                  
          
Union All            
          
--This section added for Issue #135156 2/16/10 MB
        
SELECT             
'u5' as 'U',            
PMOI.PMCo,            
PMOI.Contract,             
PMOI.Project ,             
Null, Null, Null,          
--PMOL.PhaseGroup,             
--PMOL.Phase,            
--PMOL.CostType,             
'1/1/1950',              
OrigContractAmt=0.00,             
ContractAmt=0.00,           
BilledAmt=0.00,             
ReceivedAmt=0.00,             
CurrentRetainAmt=0.00,             
ProjDollars=0.00,
EstRevenue_Mth=0.00,             
ProjMth='1/1/1950',              
 null, null, null,              
 null, null, null, null, null, null,              
        null, null, null, null, null, null,              
        null, null, null, null, null, null,            
PMOI.PCOType,             
PMOI.PCO,             
PCOItem=PMOI.PCOItem,             
JCOI.ACO,            
PMOI.ACOItem,            
Null as 'SendYN',            
Null as 'COContUM',            
Null as 'COContUnits',            
Null as 'COContUP',            
Null as 'COContAmt',            
Null as 'COContEstHrs',            
InterfacedDate = Null,     
5 as 'Sort',            
PMOI.Description,             
Null as 'APAmt',            
Null as 'RetAPAmt',            
'2050-12-31' as 'PaidMth',            
PMOI.Approved,          
PMOI.ApprovedAmt,          
JCOI.ApprovedMonth,          
PMOI.FixedAmountYN,           
PMOI.PendingAmount as 'PendingAmount',          
PMOI.FixedAmount as 'FixedAmount',          
isNULL(JCOI.ApprovedMonth,'2050-12-31' ) as 'APPMthGreater'          
FROM   PMOI PMOI    
LEFT OUTER JOIN PMOH PMOH             
 ON PMOI.PMCo=PMOH.PMCo             
 AND PMOI.Project=PMOH.Project             
 AND PMOI.ACO=PMOH.ACO             
LEFT OUTER JOIN PMOP PMOP             
 ON PMOI.PMCo=PMOP.PMCo             
 AND PMOI.Project=PMOP.Project             
 AND PMOI.PCOType=PMOP.PCOType             
 AND PMOI.PCO=PMOP.PCO             
LEFT OUTER JOIN JCOI JCOI             
 ON PMOI.PMCo=JCOI.JCCo             
 AND PMOI.Project=JCOI.Job             
 AND PMOI.ACO=JCOI.ACO             
 AND PMOI.ACOItem=JCOI.ACOItem             
LEFT OUTER JOIN PMSC PMSC             
 ON PMOI.Status=PMSC.Status            
WHERE              
PMSC.IncludeInProj='C' OR PMSC.IncludeInProj='Y'            
            
              
                 
                 
                 
GO
GRANT SELECT ON  [dbo].[vrvPMContractStatusDD] TO [public]
GRANT INSERT ON  [dbo].[vrvPMContractStatusDD] TO [public]
GRANT DELETE ON  [dbo].[vrvPMContractStatusDD] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMContractStatusDD] TO [public]
GRANT SELECT ON  [dbo].[vrvPMContractStatusDD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMContractStatusDD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMContractStatusDD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMContractStatusDD] TO [Viewpoint]
GO
