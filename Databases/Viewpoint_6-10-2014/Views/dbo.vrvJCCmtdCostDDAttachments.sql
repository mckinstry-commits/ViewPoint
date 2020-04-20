SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[vrvJCCmtdCostDDAttachments]

/*==================================================================================          
    
Author:       
DML      
    
Create date:       
04/20/2009      
    
Usage:
View for attachments for JC Committed Cost DrillDown.  
Creates opportunity to add attachments from IN, PO, SL. Returns one set of records 
with JC Cost transactions with amounts. Other SQL statements return lines of attachments.
    
Things to keep in mind:
    
Related reports: 
JC Committed Cost Drilldown (ID: 473)  
   
Revision History          
Date  Author   Issue      Description
12/27/2010	DarinHoward	CL-138746 / V1-??	Added SL Chg Order, PO Chg Order, PO Receipt, 
	and AP Invoice related attachments.
07/10/2012 ScottAlvey	CL-NA / V1-B-10098	Add Workorder fields to various reports.
	Pulled in the Work Order field from JCCD so it can be added to the report. Filled in 
	(Fillmore and Taylor, part of the SKA Know Your History Series) some documentation
	holes and change the documentation format.
  
==================================================================================*/   
  
AS  
  
SELECT Src='JC'  /* main table for report = JCCD */  
, JCCo  
, Mth  
, CostTrans  
, Job  
, PhaseGroup  
, Phase  
, CostType  
, PostedDate  
, ActualDate  
, JCTransType  
, Source  
, Description  
, INCo  
, APCo  
, MO  
, MOItem  
, PO  
, POItem  
, RemainCmtdCost  
, RemainCmtdUnits  
, SL  
, SLItem  
, TotalCmtdCost  
, TotalCmtdUnits  
, UniqueAttchID=null  
, AttachmentID=null  
, HQATDescription=null  
, DocName=null  
, AttachmentSource=null  
, 0 as SLPOMOAttachID
, SMWorkOrder -- V1-B-10098
  
FROM JCCD with (nolock)  
  
Union ALL  
  
  
Select Distinct 'MO'  /* table for MO attachments = INMI */  
, JCCD.JCCo  
, '1/1/1950' as Mth --Not returning JC Mth and Trans since attachments print under the MO Number  
, 0 as CostTrans  
, JCCD.Job  
, JCCD.PhaseGroup  
, JCCD.Phase  
, JCCD.CostType  
, JCCD.PostedDate  
, JCCD.ActualDate  
, JCCD.JCTransType  
, JCCD.Source  
, JCCD.Description  
, JCCD.INCo  
, JCCD.APCo  
, JCCD.MO  
, JCCD.MOItem  
, NULL as PO  
, NULL as POItem  
, 0 as RemainCmtdCost  
, 0 as RemainCmtdUnits  
, NULL as SL  
, NULL as SLItem  
, 0 as TotalCmtdCost  
, 0 as TotalCmtdUnits  
, HQAT.UniqueAttchID  
, HQAT.AttachmentID  
, HQAT.Description  
, HQAT.DocName  
, 'IN MatlOrd' as AttachmentSource  
, HQAT.AttachmentID as SLPOMOAttachID /*Used to group header attachments (entered through SL, PO, or MO Entry programs*/  
, JCCD.SMWorkOrder -- V1-B-10098
  
FROM JCCD  
  
Join HQAI with (nolock)   
  on   
       JCCD.INCo = HQAI.INCo  
       and JCCD.MO=HQAI.MO  
       --and JCCD.MOItem=HQAI.MOItem  
JOIN HQAT with (nolock) on HQAI.AttachmentID=HQAT.AttachmentID  
JOIN INMO with (nolock)   
  on JCCD.INCo=INMO.INCo   
  and JCCD.MO=INMO.MO   
  
  
Union ALL  
  
  
SELECT Distinct 'PO'  /* table for PO attachments = POIT */  
, JCCD.JCCo  
, '1/1/1950' as Mth --Not returning JC Mth and Trans since attachments print under the PO Number  
, 0 as CostTrans  
, JCCD.Job  
, JCCD.PhaseGroup  
, JCCD.Phase  
, JCCD.CostType  
, JCCD.PostedDate  
, JCCD.ActualDate  
, JCCD.JCTransType  
, JCCD.Source  
, JCCD.Description  
, JCCD.INCo  
, JCCD.APCo  
, NULL as MO  
, NULL as MOItem   
, JCCD.PO  
, JCCD.POItem  
, 0 as RemainCmtdCost  
, 0 as RemainCmtdUnits  
, NULL as SL  
, NULL as SLItem  
, 0 as TotalCmtdCost  
, 0 as TotalCmtdUnits  
, HQAT.UniqueAttchID  
, HQAT.AttachmentID  
, HQAT.Description  
, HQAT.DocName  
, 'PO Entry' as AttachmentSource  
, HQAT.AttachmentID as SLPOMOAttachID  
, JCCD.SMWorkOrder -- V1-B-10098
From JCCD  
Join HQAI with (nolock) on JCCD.JCCo=HQAI.JCCo  
       and JCCD.Job=HQAI.JCJob   
       and JCCD.PhaseGroup=HQAI.JCPhaseGroup   
       and JCCD.Phase=HQAI.JCPhase  
       and JCCD.CostType=HQAI.JCCostType  
       and JCCD.PO=HQAI.POPurchaseOrder  
       and HQAI.APReference is null  
JOIN HQAT with (nolock) on HQAI.AttachmentID=HQAT.AttachmentID  
JOIN POHD with (nolock)   
 on  JCCD.APCo=POHD.POCo  
 and JCCD.PO=POHD.PO   
Where HQAT.FormName='POEntry' and JCCD.Source='PO Entry'  
  
UNION ALL  
  
SELECT Distinct 'SL'  /* table for SL attachments = SLIT */  
, JCCD.JCCo  
, '1/1/1950' as Mth  --Not returning JC Mth and Trans since attachments print under the MO Number  
, 0 as CostTrans  
, JCCD.Job  
, JCCD.PhaseGroup  
, JCCD.Phase  
, JCCD.CostType  
, JCCD.PostedDate  
, JCCD.ActualDate  
, JCCD.JCTransType  
, JCCD.Source  
, JCCD.Description  
, JCCD.INCo  
, JCCD.APCo  
, NULL as MO   
, NULL as MOItem   
, NULL as PO   
, NULL as POItem   
, 0 as RemainCmtdCost   
, 0 as RemainCmtdUnits   
, JCCD.SL  
, JCCD.SLItem  
, 0 as TotalCmtdCost   
, 0 as TotalCmtdUnits  
, HQAT.UniqueAttchID  
, HQAT.AttachmentID  
, HQAT.Description  
, HQAT.DocName  
, 'SL Entry' as AttachmentSource  
, HQAT.AttachmentID as SLPOMOAttachID 
, JCCD.SMWorkOrder -- V1-B-10098 
  
  
From JCCD  
Join HQAI with (nolock) on JCCD.JCCo=HQAI.JCCo  
       and JCCD.Job=HQAI.JCJob   
       and JCCD.PhaseGroup=HQAI.JCPhaseGroup   
       and JCCD.Phase=HQAI.JCPhase  
       and JCCD.CostType=HQAI.JCCostType  
       and JCCD.SL=HQAI.SLSubcontract  
       and HQAI.APReference is null  
JOIN HQAT with (nolock) on HQAI.AttachmentID=HQAT.AttachmentID  
JOIN SLHD with (nolock)   
 on JCCD.APCo=SLHD.SLCo  
 and JCCD.SL=SLHD.SL   
Where HQAT.FormName='SLEntry' and JCCD.Source='SL Entry'  
  
UNION ALL  
  
SELECT Distinct 'PO'  /* table for PO Change Order attachments */  
, JCCD.JCCo  
, JCCD.Mth  
, JCCD.CostTrans  
, JCCD.Job  
, JCCD.PhaseGroup  
, JCCD.Phase  
, JCCD.CostType  
, JCCD.PostedDate  
, JCCD.ActualDate  
, JCCD.JCTransType  
, JCCD.Source  
, JCCD.Description  
, JCCD.INCo  
, JCCD.APCo  
, NULL as MO  
, NULL as MOItem   
, JCCD.PO  
, JCCD.POItem  
, 0 as RemainCmtdCost  
, 0 as RemainCmtdUnits  
, NULL as SL  
, NULL as SLItem  
, 0 as TotalCmtdCost  
, 0 as TotalCmtdUnits  
, HQAT.UniqueAttchID  
, HQAT.AttachmentID  
, HQAT.Description  
, HQAT.DocName  
, 'PO Change' as AttachmentSource  
, 0 as SLPOMOAttachID
, JCCD.SMWorkOrder -- V1-B-10098  
  
From JCCD  
Join HQAI with (nolock)   
  on JCCD.APCo=HQAI.POCo  
       and JCCD.PO=HQAI.POPurchaseOrder  
       and JCCD.POItem=HQAI.POItem  
JOIN HQAT with (nolock) on HQAI.AttachmentID=HQAT.AttachmentID  
JOIN POHD with (nolock)   
 on  JCCD.APCo=POHD.POCo  
 and JCCD.PO=POHD.PO   
Where HQAT.FormName='POChgOrder' and JCCD.Source='PO Change'  
  
UNION ALL  
  
SELECT 'PO'  /* table for PO Receipt attachments */  
, JCCD.JCCo  
, JCCD.Mth  
, JCCD.CostTrans  
, JCCD.Job  
, JCCD.PhaseGroup  
, JCCD.Phase  
, JCCD.CostType  
, JCCD.PostedDate  
, JCCD.ActualDate  
, JCCD.JCTransType  
, JCCD.Source  
, JCCD.Description  
, JCCD.INCo  
, JCCD.APCo  
, NULL as MO  
, NULL as MOItem   
, JCCD.PO  
, JCCD.POItem  
, 0 as RemainCmtdCost  
, 0 as RemainCmtdUnits  
, NULL as SL  
, NULL as SLItem  
, 0 as TotalCmtdCost  
, 0 as TotalCmtdUnits  
, HQAT.UniqueAttchID  
, HQAT.AttachmentID  
, HQAT.Description  
, HQAT.DocName  
, 'PO Receipt' as AttachmentSource  
, 0 as SLPOMOAttachID 
, JCCD.SMWorkOrder -- V1-B-10098 
  
From JCCD  
Join HQAI with (nolock)   
  on JCCD.APCo=HQAI.POCo  
       and JCCD.PO=HQAI.POPurchaseOrder  
       and JCCD.POItem=HQAI.POItem  
JOIN HQAT with (nolock) on HQAI.AttachmentID=HQAT.AttachmentID  
JOIN POHD with (nolock)   
 on  JCCD.APCo=POHD.POCo  
 and JCCD.PO=POHD.PO   
Where HQAT.FormName='POReceipts' and JCCD.Source='PO Receipt'  
  
UNION ALL  
  
SELECT 'SL'  /* table for SL Change Order attachments */  
, JCCD.JCCo  
, JCCD.Mth  
, JCCD.CostTrans  
, JCCD.Job  
, JCCD.PhaseGroup  
, JCCD.Phase  
, JCCD.CostType  
, JCCD.PostedDate  
, JCCD.ActualDate  
, JCCD.JCTransType  
, JCCD.Source  
, JCCD.Description  
, JCCD.INCo  
, JCCD.APCo  
, NULL as MO   
, NULL as MOItem   
, NULL as PO   
, NULL as POItem   
, 0 as RemainCmtdCost   
, 0 as RemainCmtdUnits   
, JCCD.SL  
, JCCD.SLItem  
, 0 as TotalCmtdCost   
, 0 as TotalCmtdUnits  
, HQAT.UniqueAttchID  
, HQAT.AttachmentID  
, HQAT.Description  
, HQAT.DocName  
, 'SL Change' as AttachmentSource  
, 0 as SLPOMOAttachID
, JCCD.SMWorkOrder -- V1-B-10098  
  
  
From JCCD  
Join HQAI with (nolock)   
  on JCCD.APCo=HQAI.SLCo  
       and JCCD.SL=HQAI.SLSubcontract  
       and JCCD.SLItem=HQAI.SLSubcontractItem  
JOIN HQAT with (nolock) on HQAI.AttachmentID=HQAT.AttachmentID  
JOIN SLHD with (nolock)   
 on JCCD.APCo=SLHD.SLCo  
 and JCCD.SL=SLHD.SL   
Where HQAT.FormName='SLChangeOrders' and JCCD.Source='SL Change'  
  
UNION ALL  
  
SELECT 'AP'  /* table for AP Attachments in Job Cost */  
, JCCD.JCCo  
, JCCD.Mth  
, JCCD.CostTrans  
, JCCD.Job  
, JCCD.PhaseGroup  
, JCCD.Phase  
, JCCD.CostType  
, JCCD.PostedDate  
, JCCD.ActualDate  
, JCCD.JCTransType  
, JCCD.Source  
, JCCD.Description  
, JCCD.INCo  
, JCCD.APCo  
, NULL as MO   
, 0 as MOItem   
, JCCD.PO   
, JCCD.POItem   
, 0 as RemainCmtdCost   
, 0 as RemainCmtdUnits   
, JCCD.SL  
, JCCD.SLItem  
, 0 as TotalCmtdCost   
, 0 as TotalCmtdUnits  
, HQAT.UniqueAttchID  
, HQAT.AttachmentID  
, HQAT.Description  
, HQAT.DocName  
, 'AP Invoices' as AttachmentSource  
, 0 as SLPOMOAttachID
, JCCD.SMWorkOrder -- V1-B-10098  
  
  
from JCCD  
  Join HQAI with (nolock)   
 on JCCD.APCo=HQAI.APCo   
 and JCCD.VendorGroup=HQAI.APVendorGroup   
 and JCCD.Vendor=HQAI.APVendor   
 and JCCD.APRef=HQAI.APReference   
 and JCCD.JCCo=HQAI.JCCo   
 and JCCD.Job=HQAI.JCJob   
 and JCCD.PhaseGroup=HQAI.JCPhaseGroup   
 and JCCD.Phase=HQAI.JCPhase  
 and JCCD.CostType=HQAI.JCCostType  
  Join HQAT with (Nolock)   
 on HQAI.AttachmentID=HQAT.AttachmentID  
Where JCCD.JCTransType='AP' --Use JC TransType because AP transactions can be entered from JC Cost Adjustments  
  
  
  
GO
GRANT SELECT ON  [dbo].[vrvJCCmtdCostDDAttachments] TO [public]
GRANT INSERT ON  [dbo].[vrvJCCmtdCostDDAttachments] TO [public]
GRANT DELETE ON  [dbo].[vrvJCCmtdCostDDAttachments] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCCmtdCostDDAttachments] TO [public]
GRANT SELECT ON  [dbo].[vrvJCCmtdCostDDAttachments] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCCmtdCostDDAttachments] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCCmtdCostDDAttachments] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCCmtdCostDDAttachments] TO [Viewpoint]
GO
