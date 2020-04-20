SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==================================================================================          
    
Author:       
??      
    
Create date:       
??     
    
Usage:
View for attachment and JCCD detail functionality in various JC reports  
    
Things to keep in mind:
    
Related reports: 
JC Detail (ID: 506)
JC Revenue and Cost Drilldown (ID: 546)  
   
Revision History          
Date  Author   Issue      Description
  
==================================================================================*/ 

CREATE          view [dbo].[brvAttachments] as
Select Src='JC',JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType,
  PostedDate,ActualDate,JCTransType,Source,Description,BatchId,InUseBatchId,GLCo,GLTransAcct,GLOffsetAcct,ReversalStatus,
  UM,ActualUnitCost,PerECM,ActualHours,ActualUnits,ActualCost,ProgressCmplt,EstHours,EstUnits,EstCost,ProjHours,ProjUnits,
  ProjCost,ForecastHours,ForecastUnits,ForecastCost,PostedUM,PostedUnits,PostedUnitCost,PostedECM,PostTotCmUnits,PostRemCmUnits,
  TotalCmtdUnits,TotalCmtdCost,RemainCmtdUnits,RemainCmtdCost,DeleteFlag,AllocCode,ACO,ACOItem,PRCo,Employee,Craft,Class,
  Crew,EarnFactor,EarnType,Shift,LiabilityType,VendorGroup,Vendor,APCo,APTrans,APLine,APRef,PO,POItem,SL,SLItem,MO,MOItem,
  MatlGroup,Material,INCo,Loc,INStdUnitCost,INStdECM,INStdUM,MSTrans,MSTicket,JBBillStatus,JBBillMonth,JBBillNumber,EMCo,
  EMEquip,EMRevCode,EMGroup,EMTrans,TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,UniqueAttchID=null,SrcJCCo,
  AttachmentID=null,HQATDescription=null,DocName=null
  
  From JCCD
 
  Union all
   
  select distinct 'AP',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  PostedDate,ActualDate,null,Source,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,APTH.UniqueAttchID,null,
  HQAI.AttachmentID,HQAT.Description,HQAT.DocName
  
  from JCCD
  Join HQAI with (nolock) on JCCD.APCo=HQAI.APCo and JCCD.VendorGroup=HQAI.APVendorGroup and JCCD.Vendor=HQAI.APVendor and JCCD.APRef=HQAI.APReference and
               JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
             and JCCD.CostType=HQAI.JCCostType
  Join HQAT with (Nolock) on HQAI.AttachmentID=HQAT.AttachmentID
  join APTH with (Nolock) on JCCD.APCo=APTH.APCo and JCCD.Mth=APTH.Mth and JCCD.APTrans=APTH.APTrans
 
  union all
  
  select distinct 'JC',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,JCCD.UniqueAttchID,null,
  HQAI.AttachmentID,HQAT.Description,HQAT.DocName
  from JCCD
  Join HQAI with (nolock) on JCCD.MSTicket=HQAI.MSTicket and
               JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
             and JCCD.CostType=HQAI.JCCostType
  Join HQAT with (Nolock) on HQAI.AttachmentID=HQAT.AttachmentID
 
  union all
  -- remove
 --  select distinct 'JC',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
 --  null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,
 --  HQAI.AttachmentID,HQAT.Description,HQAT.DocName
 --  from JCCD
 --  Join HQAI with (nolock) on JCCD.PO=HQAI.POPurchaseOrder and
 --               JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
 --             and JCCD.CostType=HQAI.JCCostType
 --  Join HQAT with (Nolock) on HQAI.AttachmentID=HQAT.AttachmentID
 --  
 --  union all
  -- remove
 --  select distinct 'SL',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
 --  null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,null,null,
 --  null,null,null,null,null,null,null,null,null,null,null,
 --  HQAI.AttachmentID,HQAT.Description, HQAT.DocName
 --  from JCCD
 --  Join HQAI with (nolock) on JCCD.SL=HQAI.SLSubcontract and JCCD.SLItem=HQAI.SLSubcontractItem and
 --               JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
 --             and JCCD.CostType=HQAI.JCCostType
 --  Join HQAT with (Nolock) on HQAI.AttachmentID=HQAT.AttachmentID
 --  
 --  union all
   
  select distinct 'PR',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  PostedDate,ActualDate,JCTransType,Source,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,JCCD.UniqueAttchID,null,
  HQAT.AttachmentID,HQAT.Description, HQAT.DocName
  from JCCD 
  
  Inner Join (select PRTH.PRCo, Employee, Job, Phase, Date=Case when PRCO.JCIPostingDate = 'N' then PREndDate else PostDate end,
  PRTH.UniqueAttchID  from PRTH
   
  Inner Join PRCO on PRTH.PRCo=PRCO.PRCo
  where PRTH.UniqueAttchID is not null) as c
     on JCCD.PRCo=c.PRCo and JCCD.Job=c.Job and JCCD.Employee=c.Employee and  c.Phase=JCCD.Phase and c.Date=JCCD.ActualDate
  Join HQAT with (nolock) on c.UniqueAttchID=HQAT.UniqueAttchID
 
 union all
 
  select distinct 'JC',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,JCCD.UniqueAttchID,null,
  HQAT.AttachmentID,HQAT.Description,HQAT.DocName
  from JCCD
  Join HQAT with (Nolock) on HQAT.UniqueAttchID=JCCD.UniqueAttchID

  --new JC source, link on HQAT.unique...
 /*
   added new issue 126718 to get MO and MOItem fron INDT to HQAI, can't get the IN attachments without it.*/
  union all
 
    select distinct 'IN',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,null,INMO.UniqueAttchID,null,
  HQAT.AttachmentID,HQAT.Description,HQAT.DocName
  from JCCD
  
  
  Join HQAI with (Nolock) on JCCD.INCo=HQAI.INCo and JCCD.Loc=HQAI.INLoc and JCCD.MO=HQAI.MO and JCCD.MOItem=HQAI.MOItem 
      and JCCD.GLCo=HQAI.GLCo and JCCD.GLTransAcct=HQAI.GLAcct
  join INMO with (Nolock) on HQAI.INCo=INMO.INCo and HQAI.MO=INMO.MO 
  Join HQAT with (Nolock) on HQAT.AttachmentID=HQAI.AttachmentID

GO
GRANT SELECT ON  [dbo].[brvAttachments] TO [public]
GRANT INSERT ON  [dbo].[brvAttachments] TO [public]
GRANT DELETE ON  [dbo].[brvAttachments] TO [public]
GRANT UPDATE ON  [dbo].[brvAttachments] TO [public]
GO
