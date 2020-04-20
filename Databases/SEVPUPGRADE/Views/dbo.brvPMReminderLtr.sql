SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   view [dbo].[brvPMReminderLtr] as
   
   
   
   
   select PMSM.PMCo, PMSM.Project, 
       --Case statement for Firm
       Firm= PMSM.ArchEngFirm,
       --Case Statement for Firm Contact
      Contact= PMSM.ArchEngContact,
      PMSMStatus=a.Status,
      Date1=(case when PMSI.Item is null then PMSM.DueBackArch else PMSI.DueBackArch end),
       Desccription =(case when PMSI.Item is null then PMSM.Description else PMSI.Description end),
       PMDT.DocType,PMDTDesc=PMDT.Description,
       PMSM.Submittal,PMSM.SubmittalType,PMSM.Rev,PMSI.Item,VendorGroup,PMSM.SubFirm,
       CopiesSent = (case when PMSI.Item is null then PMSM.CopiesSentArch else PMSI.CopiesSentArch end)
       from PMSM
       
       Join PMSC a on PMSM.Status=a.Status
       
       Join PMDT on PMSM.SubmittalType=PMDT.DocType
       left join PMSI on PMSM.PMCo=PMSI.PMCo and PMSM.Project=PMSI.Project and PMSM.Submittal=PMSI.Submittal and PMSM.SubmittalType=PMSI.SubmittalType
       and PMSM.Rev=PMSI.Rev
       left Join PMSC b on PMSI.Status=b.Status
       
      where a.CodeType <> 'F' and isnull(b.CodeType,'') <> 'F' and 
      (PMSM.RecdBackArch is null and PMSI.RecdBackArch is null) and
      (PMSM.DueBackArch is not null or PMSI.DueBackArch is  not null)
   
   
   
   
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPMReminderLtr] TO [public]
GRANT INSERT ON  [dbo].[brvPMReminderLtr] TO [public]
GRANT DELETE ON  [dbo].[brvPMReminderLtr] TO [public]
GRANT UPDATE ON  [dbo].[brvPMReminderLtr] TO [public]
GO
