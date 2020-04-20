SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE  View [dbo].[brvPMSubmittals] as
   /****************************
This view is used in the PMLateSubmittal.rpt
originally copied the Submittal portion from the brvPMBallInCourt.
Issue 123894 modified to account for Null dates in the Subcontract fields CR




*******************************/
       select PMSM.PMCo, PMSM.Project, 
       --Case statement for Firm
       Firm= Case when PMSM.Status is null then PMSM.ResponsibleFirm else
                (Case when PMSI.Item is not null then
                   (Case when PMSI.DateReqd is null then PMSM.ResponsibleFirm
                    when PMSI.ToArchEng is not null and PMSI.RecdBackArch is null then PMSM.ArchEngFirm
                    when PMSI.DateReqd is not null and PMSI.DateRecd is null then PMSM.SubFirm
                    else PMSM.ResponsibleFirm 
                    end) 
              Else
                   (Case when PMSM.ToArchEng is not null and PMSM.RecdBackArch is null then PMSM.ArchEngFirm
                    when PMSM.DateReqd is not null and PMSM.DateRecd is null then PMSM.SubFirm
                    Else PMSM.ResponsibleFirm 
                    end)
                  end)
             End,
       --Case Statement for Firm Contact
       Contact=Case when PMSM.Status is null then PMSM.ResponsiblePerson else       
                 (Case when PMSI.Item is not null then
                     (case when PMSI.DateReqd is null then PMSM.ResponsiblePerson
                      when PMSI.ToArchEng is not null and PMSI.RecdBackArch is null then PMSM.ArchEngContact
                      when PMSI.DateReqd is not null and PMSI.DateRecd is null then PMSM.SubContact
                      else PMSM.ResponsiblePerson 
                      end)
               Else
                     (Case when PMSM.ToArchEng is not null and PMSM.RecdBackArch is null then PMSM.ArchEngFirm
                      when PMSM.DateReqd is not null and PMSM.DateRecd is null then PMSM.SubFirm
                      Else PMSM.ResponsibleFirm 
                      end)
                  End) 
               End,
      PMSMStatus=isnull(a.Status, ''),
      DueDate=Case when PMSI.Item is not null then
       (case when PMSI.DateRecd is null then PMSI.DateReqd
        when PMSI.RecdBackArch is null then PMSI.DueBackArch
        when PMSI.DateRetd is null then PMSI.RecdBackArch end)
        else  --(issue 27036 CR)
      (case when PMSM.DateRecd is null then PMSM.DateReqd 
       when PMSM.RecdBackArch is null then PMSM.DueBackArch
       when PMSM.DateRetd is null then PMSM.RecdBackArch end)
       end,
       DateReceived='12/31/2050',
       PMSMDesc=PMSM.Description,
       PMDT.DocType,PMDTDesc=PMDT.Description,
       PMSM.Submittal,PMSM.Rev,PMSI.Item,VendorGroup
       from PMSM
       
       left Join PMSC a on PMSM.Status=a.Status
       
       Join PMDT on PMSM.SubmittalType=PMDT.DocType
       left join PMSI on PMSM.PMCo=PMSI.PMCo and PMSM.Project=PMSI.Project and PMSM.Submittal=PMSI.Submittal and PMSM.SubmittalType=PMSI.SubmittalType
       and PMSM.Rev=PMSI.Rev
       
       
      where isnull(a.CodeType,'') <> 'F' and PMSM.DateRetd is null and PMSI.DateRetd is null
      
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPMSubmittals] TO [public]
GRANT INSERT ON  [dbo].[brvPMSubmittals] TO [public]
GRANT DELETE ON  [dbo].[brvPMSubmittals] TO [public]
GRANT UPDATE ON  [dbo].[brvPMSubmittals] TO [public]
GO
