SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  View [dbo].[brvPMBallInCourtNotifier] as
       
       /***********************************
       Copied from brvPMBallInCourt by Craig R. 5/20/08
         replaced views with tables for Security purposes.
       Mod:  Issue 128780 DH  4/29/09.


       ************************************/
       
SELECT     bPMRI.PMCo, bJCJM.Contract, bPMRI.Project, bJCJM.ProjectMgr, bPMRI.RFI AS DocumentNumber, left((bPMRI.RFIType+'           '),11)as DocType, null as Item,
                 (CASE WHEN bPMRI.Status IS NULL OR (bPMRI.RespondFirm IS NULL OR bPMRI.RespondContact IS NULL OR bPMRI.DateSent IS NULL) 
                  THEN bPMRI.ResponsibleFirm 
                  WHEN bPMRD.RFISeq IS NOT NULL 
                  THEN bPMRD.SentToFirm WHEN bPMRI.RespondFirm IS NOT NULL THEN bPMRI.RespondFirm ELSE bPMRI.ResponsibleFirm END) AS Firmnumber, 
                  
                 (CASE WHEN bPMRI.Status IS NULL OR (bPMRI.RespondFirm IS NULL OR bPMRI.RespondContact IS NULL OR bPMRI.DateSent IS NULL) 
                  THEN bPMRI.ResponsiblePerson WHEN bPMRD.RFISeq IS NOT NULL 
                  THEN bPMRD.SentToContact WHEN bPMRI.RespondFirm IS NOT NULL THEN bPMRI.ResponsiblePerson ELSE bPMRI.ResponsibleFirm END) AS ContactCode,

       			 'RFI' AS Sort, (CASE WHEN bPMRD.DateReqd IS NOT NULL 
                  THEN bPMRD.DateReqd ELSE bPMRI.DateDue END) AS DueDate, (CASE WHEN bPMRD.DateRecd IS NOT NULL 
                  THEN bPMRD.DateRecd WHEN bPMRD.DateRecd IS NOT NULL THEN bPMRD.DateRecd ELSE '12/31/2050' END) AS DateRecd, 
                  bPMRI.Subject AS Description, 
                  CAST(bPMRD.RFISeq AS Varchar(10)) AS Sequence, bPMRI.VendorGroup, 
                  DateDiff(day, (CASE WHEN bPMRD.DateReqd IS NOT NULL 
                    THEN bPMRD.DateReqd ELSE bPMRI.DateDue END),GetDate() ) as 'DaysOverDue', bPMSC.Description as Status,
                  bPMRI.RFI +' '+bPMRI.Subject as DocumentNumberAndDescription

FROM         bPMRI LEFT OUTER JOIN
                      bPMRD ON bPMRD.PMCo = bPMRI.PMCo AND bPMRD.Project = bPMRI.Project AND bPMRD.RFIType = bPMRI.RFIType AND 
                      bPMRD.RFI = bPMRI.RFI 
                      LEFT OUTER JOIN bPMSC ON bPMRI.Status = bPMSC.Status 
                      INNER JOIN bJCJM ON bPMRI.PMCo = bJCJM.JCCo AND bPMRI.Project = bJCJM.Job
WHERE     (ISNULL(bPMSC.CodeType, '') <> 'F')


union all
 --Letter of Transmittal
      select  bPMTM.PMCo, bJCJM.Contract, bPMTM.Project, bJCJM.ProjectMgr, bPMTM.Transmittal, 'TRANSMITTAL' as DocType, null as Item,
       Firmnumber=(Case when bPMTC.Seq is not null then bPMTC.SentToFirm else bPMTM.ResponsibleFirm end),
       ContactCode=(Case when bPMTC.Seq is not null then bPMTC.SentToContact  
                    when bPMTM.ResponsiblePerson is not null then bPMTM.ResponsiblePerson else 0 end),
       'Transmittal' as Sort,
       bPMTM.DateDue as DateDue,
       (case when bPMTM.DateResponded is null then '12/31/2050' else bPMTM.DateResponded end) as DateRecd,
       bPMTM.Subject as Description, 
       null as Sequence, bPMTM.VendorGroup as VendorGroup, 
       DateDiff(day, bPMTM.DateDue, GetDate()) as 'DaysOverDue', Null as Status,
       bPMTM.Transmittal + ' '+ bPMTM.Subject as DocumentNumberAndDescription

from bPMTM
       LEFT JOIN bPMTC on bPMTM.PMCo=bPMTC.PMCo and bPMTM.Project=bPMTC.Project and bPMTM.Transmittal=bPMTC.Transmittal
       INNER JOIN bJCJM on bPMTM.PMCo = bJCJM.JCCo and bPMTM.Project=bJCJM.Job
where bPMTM.DateDue is not null and bPMTM.DateResponded is null 

union all

--Submittals 
       SELECT     bPMSM.PMCo, bJCJM_3.Contract, bPMSM.Project, bJCJM_3.ProjectMgr, bPMSM.Submittal,left((bPMSM.SubmittalType+'           '),11) as DocType, bPMSI.Item as Item,
              --Case statement for Firm
        CASE WHEN bPMSM.Status is null THEN bPMSM.ResponsibleFirm 

        ELSE  --PMSM.Status check
              (Case when bPMSI.Item is not null Then

                   (Case when bPMSI.DateReqd is null then bPMSM.ResponsibleFirm
                         when bPMSI.ToArchEng is not null and bPMSI.RecdBackArch is null then bPMSM.ArchEngFirm
                         when bPMSI.DateReqd is not null and bPMSI.DateRecd is null then bPMSM.SubFirm
                    else bPMSM.ResponsibleFirm 
                    end) 

                Else  --PMSI.Item is null

                   (Case when bPMSM.ToArchEng is not null and bPMSM.RecdBackArch is null then bPMSM.ArchEngFirm
                         when bPMSM.DateReqd is not null and bPMSM.DateRecd is null then bPMSM.SubFirm
                    else bPMSM.ResponsibleFirm 
                    end) 

               End) --PMSI.Item check

         END, --end entire case statement

       --Case Statement for Firm Contact
       CASE WHEN bPMSM.Status is null THEN bPMSM.ResponsiblePerson 

        ELSE  --PMSM.Status check
              (Case when bPMSI.Item is not null Then

                   (Case when bPMSI.DateReqd is null then bPMSM.ResponsiblePerson
                         when bPMSI.ToArchEng is not null and bPMSI.RecdBackArch is null then bPMSM.ArchEngContact
                         when bPMSI.DateReqd is not null and bPMSI.DateRecd is null then bPMSM.SubContact
                    else bPMSM.ResponsiblePerson 
                    end) 

                Else  --PMSI.Item is null

                   (Case when bPMSM.ToArchEng is not null and bPMSM.RecdBackArch is null then bPMSM.ArchEngContact
                         when bPMSM.DateReqd is not null and bPMSM.DateRecd is null then bPMSM.SubContact
                    else bPMSM.ResponsiblePerson 
                    end) 

               End) --PMSI.Item check

         END, --end entire case statement
        'Submittal' AS Sort, 

              CASE WHEN bPMSI.Item IS NOT NULL THEN (CASE WHEN bPMSI.DateRecd IS NULL 
              THEN bPMSI.DateReqd WHEN bPMSI.RecdBackArch IS NULL THEN bPMSI.DueBackArch WHEN bPMSI.DateRetd IS NULL 
              THEN bPMSI.RecdBackArch END) ELSE (CASE WHEN bPMSM.DateRecd IS NULL THEN bPMSM.DateReqd WHEN bPMSM.RecdBackArch IS NULL 
              THEN bPMSM.DueBackArch WHEN bPMSM.DateRetd IS NULL THEN bPMSM.RecdBackArch END) END AS DateDue, '12/31/2050' AS DateRecd, 
              bPMSM.Description, CAST(bPMSM.Rev AS varchar(10)) AS Sequence, bPMSM.VendorGroup, 
              DateDiff(day, 
                (CASE WHEN bPMSI.Item IS NOT NULL THEN (CASE WHEN bPMSI.DateRecd IS NULL 
                THEN bPMSI.DateReqd WHEN bPMSI.RecdBackArch IS NULL THEN bPMSI.DueBackArch WHEN bPMSI.DateRetd IS NULL 
                THEN bPMSI.RecdBackArch END) ELSE (CASE WHEN bPMSM.DateRecd IS NULL THEN bPMSM.DateReqd WHEN bPMSM.RecdBackArch IS NULL 
                THEN bPMSM.DueBackArch WHEN bPMSM.DateRetd IS NULL THEN bPMSM.RecdBackArch END) END),GetDate()) as 'DaysOverDue', a.Description,
              bPMSM.Submittal+' '+bPMSM.Description as DocumentNumberAndDescription

FROM         bPMSI
            LEFT OUTER JOIN bPMSM ON bPMSM.PMCo = bPMSI.PMCo AND bPMSM.Project = bPMSI.Project AND bPMSM.Submittal = bPMSI.Submittal AND 
                      bPMSM.SubmittalType = bPMSI.SubmittalType AND bPMSM.Rev = bPMSI.Rev 
             LEFT OUTER JOIN bPMSC AS a ON bPMSM.Status = a.Status            
             --LEFT OUTER JOIN bPMSC AS b ON bPMSI.Status = b.Status
             INNER JOIN bPMDT AS bPMDT_3 ON bPMSM.SubmittalType = bPMDT_3.DocType   
             INNER JOIN bJCJM AS bJCJM_3 ON bPMSM.PMCo = bJCJM_3.JCCo AND bPMSM.Project = bJCJM_3.Job
WHERE     (ISNULL(a.CodeType, '') <> 'F')

union all

--Other Docs
SELECT     bPMOD.PMCo, bJCJM_2.Contract, bPMOD.Project, bJCJM_2.ProjectMgr, bPMOD.Document, left((bPMOD.DocType+'           '),11), null as Item,
             (CASE WHEN bPMOD.Status IS NULL 
             THEN bPMOD.ResponsibleFirm ELSE (CASE WHEN bPMOC.Seq IS NOT NULL THEN bPMOC.SentToFirm ELSE bPMOD.ResponsibleFirm END) END) AS Firmnumber, 
             (CASE WHEN bPMOD.Status IS NULL THEN bPMOD.ResponsiblePerson ELSE (CASE WHEN bPMOC.Seq IS NOT NULL 
             THEN bPMOC.SentToContact ELSE bPMOD.ResponsiblePerson END) END) AS ContactCode, 
             'Other Documents' AS Sort, CASE WHEN bPMOD.DateDueBack IS NOT NULL THEN bPMOD.DateDueBack ELSE bPMOD.DateDue END AS DueDate, 
             CASE WHEN bPMOD.DateRecdBack IS NULL THEN '12/31/2050' ELSE bPMOD.DateRecdBack END AS DateRecd, bPMOD.Description, 
             bPMOC.Seq, bPMOD.VendorGroup,
             DateDiff(day, (CASE WHEN bPMOD.DateDueBack IS NOT NULL THEN bPMOD.DateDueBack ELSE bPMOD.DateDue END),GetDate()) as 'DaysOverDue',
             bPMSC_2.Description, bPMOD.Document+' '+bPMOD.Description as DocumentNumberAndDescription
FROM         bPMOD 
             LEFT OUTER JOIN bPMOC ON bPMOD.PMCo = bPMOC.PMCo AND bPMOD.Project = bPMOC.Project AND 
                  bPMOD.DocType = bPMOC.DocType AND bPMOD.Document = bPMOC.Document 
             LEFT OUTER JOIN bPMSC AS bPMSC_2 ON bPMOD.Status = bPMSC_2.Status  
             INNER JOIN bJCJM AS bJCJM_2 ON bPMOD.PMCo = bJCJM_2.JCCo AND bPMOD.Project = bJCJM_2.Job

WHERE     (ISNULL(bPMSC_2.CodeType, '') <> 'F') AND (bPMOD.DateRecdBack IS NULL)

union all
 --Request for Quotes
SELECT     bPMRQ.PMCo, bJCJM_1.Contract, bPMRQ.Project, bJCJM_1.ProjectMgr,  bPMRQ.RFQ,  left((bPMRQ.PCOType+'           '),11), null as Item, 
          CASE WHEN bPMRQ.Status IS NULL 
                      THEN bPMRQ.FirmNumber ELSE (CASE WHEN bPMQD.RFQSeq IS NOT NULL THEN (CASE WHEN bPMQD.DateSent IS NOT NULL AND 
                      bPMQD.DateReqd IS NOT NULL THEN bPMQD.SentToFirm ELSE bPMRQ.FirmNumber END) ELSE bPMRQ.FirmNumber END) END AS FirmNumber, 
                      CASE WHEN bPMRQ.Status IS NULL THEN bPMRQ.ResponsiblePerson ELSE (CASE WHEN bPMQD.RFQSeq IS NOT NULL 
                      THEN (CASE WHEN bPMQD.DateSent IS NOT NULL AND bPMQD.DateReqd IS NOT NULL 
                      THEN bPMQD.SentToContact ELSE bPMRQ.ResponsiblePerson END) ELSE bPMRQ.ResponsiblePerson END) END AS ContactCode, 
                      'Request for Quotes' AS Sort, 
                      CASE WHEN bPMQD.DateReqd IS NOT NULL THEN bPMQD.DateReqd ELSE bPMRQ.DateDue END AS DueDate, 
                      CASE WHEN bPMQD.DateRecd IS NULL THEN '12/31/2050' ELSE bPMQD.DateRecd END AS DateRecd, bPMRQ.Description, 
                      null, bPMRQ.VendorGroup,
                      DateDiff(day, (CASE WHEN bPMQD.DateReqd IS NOT NULL THEN bPMQD.DateReqd ELSE bPMRQ.DateDue END ),GetDate()) as 'DaysOverDue',
                      bPMSC_1.Description, bPMRQ.RFQ+' '+bPMRQ.Description as DocumentNumberAndDescription
FROM         bPMRQ 
             LEFT OUTER JOIN bPMQD ON bPMRQ.PMCo = bPMQD.PMCo AND bPMRQ.Project = bPMQD.Project AND bPMRQ.PCOType = bPMQD.PCOType AND 
                      bPMRQ.PCO = bPMQD.PCO AND bPMRQ.RFQ = bPMQD.RFQ 
             LEFT OUTER JOIN bPMSC AS bPMSC_1 ON bPMRQ.Status = bPMSC_1.Status 
             INNER JOIN bJCJM AS bJCJM_1 ON bPMRQ.PMCo = bJCJM_1.JCCo AND bPMRQ.Project = bJCJM_1.Job
where isnull(bPMSC_1.CodeType,'') <> 'F'and bPMQD.DateRecd is null

GO
GRANT SELECT ON  [dbo].[brvPMBallInCourtNotifier] TO [public]
GRANT INSERT ON  [dbo].[brvPMBallInCourtNotifier] TO [public]
GRANT DELETE ON  [dbo].[brvPMBallInCourtNotifier] TO [public]
GRANT UPDATE ON  [dbo].[brvPMBallInCourtNotifier] TO [public]
GO
