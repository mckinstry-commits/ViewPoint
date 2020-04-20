SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvEMAttachments] as
/*
this view is used to get Attachments on EM Cost Transactions.
it is used in the EM Monthly Cost and Revenue Drilldown

Maintenance Log
Issue	Date	ChangeBY	Description
132839	2/12/10	C. Wirtz	Added union all select for Src ='EMA' This select will bring in 
							EM attachments.  Also set data item UniqueAttchID to null for select where
							Src = 'EM' because this select brings in only EM detail data and not the attachments.


*/
Select Src='EM', EMCD.EMCo, EMCD.Mth, EMCD.EMTrans, EMCD.EMGroup, EMCD.Equipment, EMCD.CostCode,
   EMCD.EMCostType, EMCD.PostedDate, EMCD.ActualDate, EMCD.Source, EMCD.EMTransType, EMCD.Description,
   EMCD.WorkOrder, EMCD.WOItem, EMCD.GLCo, EMCD.GLTransAcct, EMCD.GLOffsetAcct, EMCD.PRCo, EMCD.PREmployee, Type=null,
   EMCD.APCo, EMCD.VendorGrp, EMCD.APVendor, EMCD.MatlGroup, EMCD.INCo, EMCD.INLocation, EMCD.Material, EMCD.AllocCode,
   EMCD.ReversalStatus, EMCD.APTrans, EMCD.APLine, EMCD.APRef, EMCD.UM, EMCD.Units, EMCD.Dollars, EMCD.UnitPrice,
   EMCD.PerECM, EMCD.PO, EMCD.POItem, UniqueAttchID=null, AttachmentID=null, HQATDescription=null, DocName=null

  from EMCD
   
 union all
 select distinct 'AP',EMCD.EMCo, EMCD.Mth, EMCD.EMTrans, EMCD.EMGroup, EMCD.Equipment, EMCD.CostCode, 
  EMCD.EMCostType, EMCD.PostedDate,EMCD.ActualDate,EMCD.Source, null, null,
  null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,
  null, null,null, APTH.UniqueAttchID, HQAI.AttachmentID, HQAT.Description, HQAT.DocName
  
  from EMCD
  Join HQAI with (nolock) on EMCD.APCo=HQAI.APCo and EMCD.VendorGrp=HQAI.APVendorGroup and EMCD.APVendor=HQAI.APVendor and 
         EMCD.APRef=HQAI.APReference and EMCD.APCo=HQAI.APCo and EMCD.Equipment=HQAI.EMEquipment and EMCD.CostCode=HQAI.EMCostCode 
         and EMCD.CostCode=HQAI.EMCostCode and EMCD.EMCostType=HQAI.EMCostType
  Join HQAT with (Nolock) on HQAI.AttachmentID=HQAT.AttachmentID
  join APTH with (Nolock) on EMCD.APCo=APTH.APCo and EMCD.Mth=APTH.Mth and EMCD.APTrans=APTH.APTrans  

union all

select distinct Src='PR', EMCD.EMCo, EMCD.Mth, EMCD.EMTrans, EMCD.EMGroup, EMCD.Equipment, EMCD.CostCode,
  EMCD.EMCostType, EMCD.PostedDate, EMCD.ActualDate, EMCD.Source, null, null,
  null, null,null,null,null,null,null,Type=c.Type,
  null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null, null,
  null, null, null, c.UniqueAttchID, HQAT.AttachmentID, HQAT.Description, HQAT.DocName
  from EMCD
  
  Inner Join (select PRTH.PRCo, Equipment, Type,Phase, Date=Case when PRCO.JCIPostingDate = 'N' then PREndDate else PostDate end,
  PRTH.UniqueAttchID  from PRTH
  Inner Join PRCO on PRTH.PRCo=PRCO.PRCo
  where PRTH.UniqueAttchID is not null and PRTH.Type = 'M') as c

     on EMCD.PRCo=c.PRCo and EMCD.Equipment=c.Equipment and  c.Date=EMCD.ActualDate
  Join HQAT with (nolock) on c.UniqueAttchID=HQAT.UniqueAttchID

union all

select   distinct Src='EMA', EMCD.EMCo, EMCD.Mth, EMCD.EMTrans, EMCD.EMGroup, EMCD.Equipment, EMCD.CostCode,
  EMCD.EMCostType, EMCD.PostedDate, EMCD.ActualDate, EMCD.Source, null, null,
  null, null,null,null,null,null,null,null,
  null,null,null,null,null,null,null,null,
  null,null,null,null,null,null,null, null,
  null, null, null, EMCD.UniqueAttchID, HQAT.AttachmentID, HQAT.Description, HQAT.DocName
  from EMCD
  Join HQAT with (Nolock) on HQAT.UniqueAttchID=EMCD.UniqueAttchID
/*union all  

 select distinct Src='Rev', EMRD.EMCo, EMRD.Mth, EMRD.Trans, EMRD.EMGroup, EMRD.Equipment, EMRD.RevCode, 
 null, EMRD.PostDate, EMRD.ActualDate, EMRD.Source, EMRD.TransType, null, 
 EMRD.WorkOrder, EMRD.WOItem, EMRD.GLCo, EMRD.ExpGLAcct, null, EMRD.PRCo, EMRD.Employee,null,
 null,null,null,null,EMRD.INCo, EMRD.ToLoc, null, null,
 null,null,null,null,null,null,null,null,
 null,null,null, EMRD.UniqueAttchID, HQAT.AttachmentID, HQAT.Description, HQAT.DocName
   from EMRD
  join HQAT with (nolock) on EMRD.UniqueAttchID=HQAT.UniqueAttchID 
  join HQAI with (nolock) on HQAI.AttachmentID=HQAT.AttachmentID
   
   
*/

GO
GRANT SELECT ON  [dbo].[brvEMAttachments] TO [public]
GRANT INSERT ON  [dbo].[brvEMAttachments] TO [public]
GRANT DELETE ON  [dbo].[brvEMAttachments] TO [public]
GRANT UPDATE ON  [dbo].[brvEMAttachments] TO [public]
GO
