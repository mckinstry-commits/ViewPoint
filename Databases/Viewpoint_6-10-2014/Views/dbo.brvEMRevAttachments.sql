SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvEMRevAttachments] as
/*
this view is used to get the Attachments associated with Revenue transactions in EM.
it is used in the EM Monthly Cost and Revenue Drilldown


*/
Select Src='EM', EMRD.EMCo, EMRD.Mth, EMRD.Trans, EMRD.EMGroup, EMRD.Equipment, EMRD.RevCode,
   EMRD.TransType, EMRD.PostDate, EMRD.ActualDate, EMRD.Source, Type=null, 
   EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, EMRD.JCCostType, EMRD.PRCo, EMRD.Employee, 
   EMRD.GLCo, EMRD.RevGLAcct, EMRD.ExpGLCo, EMRD.ExpGLAcct, EMRD.Memo, 
   EMRD.UM, EMRD.WorkUnits, EMRD.TimeUM, EMRD.TimeUnits, EMRD.Dollars, EMRD.RevRate,
   UniqueAttchID=null, AttachmentID=null, HQATDescription=null, DocName=null

  from EMRD
   
 union all

 select distinct Src='Rev', EMRD.EMCo, EMRD.Mth, EMRD.Trans, null, EMRD.Equipment, EMRD.RevCode, 
 null,null,null,null, null,
 null,null,null, null, null,null, null,
 null,null,null,null, null,
 null,null,null,null,null,null,
 EMRD.UniqueAttchID, HQAT.AttachmentID, HQAT.Description, HQAT.DocName
   from EMRD
  join HQAT with (nolock) on EMRD.UniqueAttchID=HQAT.UniqueAttchID 
  join HQAI with (nolock) on HQAI.AttachmentID=HQAT.AttachmentID

union all

select distinct Src='PR', EMRD.EMCo, EMRD.Mth, EMRD.Trans, EMRD.EMGroup, EMRD.Equipment, EMRD.RevCode,
  EMRD.TransType, EMRD.PostDate, EMRD.ActualDate, EMRD.Source, Type=c.Type,
  null,null,null,null,
  null,null,null,null,null, null, null, null,
  null,null,null,null,null,null,
  c.UniqueAttchID, HQAT.AttachmentID, HQAT.Description, HQAT.DocName
  from EMRD
  
  Inner Join (select PRTH.PRCo, Equipment, Type,Phase, Date=Case when PRCO.JCIPostingDate = 'N' then PREndDate else PostDate end,
  PRTH.UniqueAttchID  from PRTH
  Inner Join PRCO on PRTH.PRCo=PRCO.PRCo
  where PRTH.UniqueAttchID is not null and PRTH.Type = 'J') as c

     on EMRD.PRCo=c.PRCo and EMRD.Equipment=c.Equipment and  c.Date=EMRD.ActualDate
  Join HQAT with (nolock) on c.UniqueAttchID=HQAT.UniqueAttchID

GO
GRANT SELECT ON  [dbo].[brvEMRevAttachments] TO [public]
GRANT INSERT ON  [dbo].[brvEMRevAttachments] TO [public]
GRANT DELETE ON  [dbo].[brvEMRevAttachments] TO [public]
GRANT UPDATE ON  [dbo].[brvEMRevAttachments] TO [public]
GRANT SELECT ON  [dbo].[brvEMRevAttachments] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMRevAttachments] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMRevAttachments] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMRevAttachments] TO [Viewpoint]
GO
