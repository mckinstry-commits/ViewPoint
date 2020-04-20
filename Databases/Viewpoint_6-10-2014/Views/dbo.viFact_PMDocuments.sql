SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE View [dbo].[viFact_PMDocuments]
as

With PMDocs
     (PMCo,
      Contract,
      Project,
      ProjectMgr,
	  DocumentID,
      DocumentNumber,
      DocType,
      Item,
      Firmnumber,
      ContactCode,
      Sort,
	  SortNumber,	
      DueDate,
      DateRecd,
      Description,
      Sequence,
      VendorGroup,
	  DaysUntilDue,
      Status,
      DocumentNumberAndDescription


)

As

/**Select data from PMBallInCourt View**/
--RFI
(SELECT     bPMRI.PMCo, bJCJM.Contract, bPMRI.Project, bJCJM.ProjectMgr, bPMRI.KeyID as DocumentID, bPMRI.RFI AS DocumentNumber, bPMRI.RFIType as DocType, null as Item,
                 (CASE WHEN bPMRI.Status IS NULL OR (bPMRI.RespondFirm IS NULL OR bPMRI.RespondContact IS NULL OR bPMRI.DateSent IS NULL) 
                  THEN bPMRI.ResponsibleFirm 
                  WHEN bPMRD.RFISeq IS NOT NULL 
                  THEN bPMRD.SentToFirm WHEN bPMRI.RespondFirm IS NOT NULL THEN bPMRI.RespondFirm ELSE bPMRI.ResponsibleFirm END) AS Firmnumber, 
                  
                 (CASE WHEN bPMRI.Status IS NULL OR (bPMRI.RespondFirm IS NULL OR bPMRI.RespondContact IS NULL OR bPMRI.DateSent IS NULL) 
                  THEN bPMRI.ResponsiblePerson WHEN bPMRD.RFISeq IS NOT NULL 
                  THEN bPMRD.SentToContact WHEN bPMRI.RespondFirm IS NOT NULL THEN bPMRI.ResponsiblePerson ELSE bPMRI.ResponsibleFirm END) AS ContactCode,

       			 'RFI' AS Sort,
				  1 As SortNumber,
				 (CASE WHEN bPMRD.DateReqd IS NOT NULL 
                       THEN bPMRD.DateReqd ELSE bPMRI.DateDue END) AS DueDate, (CASE WHEN bPMRD.DateRecd IS NOT NULL 
                       THEN bPMRD.DateRecd WHEN bPMRD.DateRecd IS NOT NULL THEN bPMRD.DateRecd ELSE '12/31/2050' END) AS DateRecd, 
                  bPMRI.Subject AS Description, 
                  CAST(bPMRD.RFISeq AS Varchar(10)) AS Sequence, bPMRI.VendorGroup, 
                  DateDiff(day, (CASE WHEN bPMRD.DateReqd IS NOT NULL 
                    THEN bPMRD.DateReqd ELSE bPMRI.DateDue END),GetDate() ) as 'DaysOverDue', bPMSC.Status,
                  bPMRI.RFI +' '+bPMRI.Subject as DocumentNumberAndDescription

FROM         bPMRI LEFT OUTER JOIN
                      bPMRD ON bPMRD.PMCo = bPMRI.PMCo AND bPMRD.Project = bPMRI.Project AND bPMRD.RFIType = bPMRI.RFIType AND 
                      bPMRD.RFI = bPMRI.RFI 
                      LEFT OUTER JOIN bPMSC ON bPMRI.Status = bPMSC.Status 
                      INNER JOIN bJCJM ON bPMRI.PMCo = bJCJM.JCCo AND bPMRI.Project = bJCJM.Job
WHERE     (ISNULL(bPMSC.CodeType, '') <> 'F')


union all
 --Letter of Transmittal
      select  bPMTM.PMCo, bJCJM.Contract, bPMTM.Project, bJCJM.ProjectMgr, bPMTM.KeyID as DocumentID, bPMTM.Transmittal, 'TRANSMITTAL' as DocType, null as Item,
       Firmnumber=(Case when bPMTC.Seq is not null then bPMTC.SentToFirm else bPMTM.ResponsibleFirm end),
       ContactCode=(Case when bPMTC.Seq is not null then bPMTC.SentToContact  
                    when bPMTM.ResponsiblePerson is not null then bPMTM.ResponsiblePerson else 0 end),
       'Transmittal' as Sort,
	   2 as SortNumber,	
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
       SELECT     bPMSM.PMCo, bJCJM_3.Contract, bPMSM.Project, bJCJM_3.ProjectMgr, bPMSM.KeyID as DocumentID, bPMSM.Submittal,bPMSM.SubmittalType as DocType, bPMSI.Item as Item,
              CASE WHEN bPMSM.Status is null THEN bPMSM.ResponsibleFirm 

        ELSE  --bPMSM.Status check
              (Case when bPMSI.Item is not null Then

                   (Case when bPMSI.DateReqd is null then bPMSM.ResponsibleFirm
                         when bPMSI.ToArchEng is not null and bPMSI.RecdBackArch is null then bPMSM.ArchEngFirm
                         when bPMSI.DateReqd is not null and bPMSI.DateRecd is null then bPMSM.SubFirm
                    else bPMSM.ResponsibleFirm 
                    end) 

                Else  --bPMSI.Item is null

                   (Case when bPMSM.ToArchEng is not null and bPMSM.RecdBackArch is null then bPMSM.ArchEngFirm
                         when bPMSM.DateReqd is not null and bPMSM.DateRecd is null then bPMSM.SubFirm
                    else bPMSM.ResponsibleFirm 
                    end) 

               End) --bPMSI.Item check

         END AS Firmnumber, 

              CASE WHEN bPMSM.Status is null THEN bPMSM.ResponsiblePerson 

        ELSE  --bPMSM.Status check
              (Case when bPMSI.Item is not null Then

                   (Case when bPMSI.DateReqd is null then bPMSM.ResponsiblePerson
                         when bPMSI.ToArchEng is not null and bPMSI.RecdBackArch is null then bPMSM.ArchEngContact
                         when bPMSI.DateReqd is not null and bPMSI.DateRecd is null then bPMSM.SubContact
                    else bPMSM.ResponsiblePerson 
                    end) 

                Else  --bPMSI.Item is null

                   (Case when bPMSM.ToArchEng is not null and bPMSM.RecdBackArch is null then bPMSM.ArchEngContact
                         when bPMSM.DateReqd is not null and bPMSM.DateRecd is null then bPMSM.SubContact
                    else bPMSM.ResponsiblePerson 
                    end) 

               End) --bPMSI.Item check

         END AS ContactCode, 'Submittal' AS Sort,
       3 as SortNumber,

              CASE WHEN bPMSI.Item IS NOT NULL THEN (CASE WHEN bPMSI.DateRecd IS NULL 
              THEN bPMSI.DateReqd WHEN bPMSI.RecdBackArch IS NULL THEN bPMSI.DueBackArch WHEN bPMSI.DateRetd IS NULL 
              THEN bPMSI.RecdBackArch END) ELSE (CASE WHEN bPMSM.DateRecd IS NULL THEN bPMSM.DateReqd WHEN bPMSM.RecdBackArch IS NULL 
              THEN bPMSM.DueBackArch WHEN bPMSM.DateRetd IS NULL THEN bPMSM.RecdBackArch END) END AS DateDue, '12/31/2050' AS DateRecd, 
              bPMSM.Description, CAST(bPMSM.Rev AS varchar(10)) AS Sequence, bPMSM.VendorGroup, 
              DateDiff(day, 
                (CASE WHEN bPMSI.Item IS NOT NULL THEN (CASE WHEN bPMSI.DateRecd IS NULL 
                THEN bPMSI.DateReqd WHEN bPMSI.RecdBackArch IS NULL THEN bPMSI.DueBackArch WHEN bPMSI.DateRetd IS NULL 
                THEN bPMSI.RecdBackArch END) ELSE (CASE WHEN bPMSM.DateRecd IS NULL THEN bPMSM.DateReqd WHEN bPMSM.RecdBackArch IS NULL 
                THEN bPMSM.DueBackArch WHEN bPMSM.DateRetd IS NULL THEN bPMSM.RecdBackArch END) END),GetDate()) as 'DaysOverDue', a.Status,
              bPMSM.Submittal+' '+bPMSM.Description as DocumentNumberAndDescription

FROM         bPMSM
            LEFT OUTER JOIN bPMSI ON bPMSM.PMCo = bPMSI.PMCo AND bPMSM.Project = bPMSI.Project AND bPMSM.Submittal = bPMSI.Submittal AND 
                      bPMSM.SubmittalType = bPMSI.SubmittalType AND bPMSM.Rev = bPMSI.Rev 
             LEFT OUTER JOIN bPMSC AS a ON bPMSM.Status = a.Status            
             --LEFT OUTER JOIN bPMSC AS b ON bPMSI.Status = b.Status
             INNER JOIN bPMDT AS bPMDT_3 ON bPMSM.SubmittalType = bPMDT_3.DocType   
             INNER JOIN bJCJM AS bJCJM_3 ON bPMSM.PMCo = bJCJM_3.JCCo AND bPMSM.Project = bJCJM_3.Job
WHERE     (ISNULL(a.CodeType, '') <> 'F')

union all

--Other Docs
SELECT     bPMOD.PMCo, bJCJM_2.Contract, bPMOD.Project, bJCJM_2.ProjectMgr, bPMOD.KeyID as DocumentID, bPMOD.Document, bPMOD.DocType, null as Item,
             (CASE WHEN bPMOD.Status IS NULL 
             THEN bPMOD.ResponsibleFirm ELSE (CASE WHEN bPMOC.Seq IS NOT NULL THEN bPMOC.SentToFirm ELSE bPMOD.ResponsibleFirm END) END) AS Firmnumber, 
             (CASE WHEN bPMOD.Status IS NULL THEN bPMOD.ResponsiblePerson ELSE (CASE WHEN bPMOC.Seq IS NOT NULL 
             THEN bPMOC.SentToContact ELSE bPMOD.ResponsiblePerson END) END) AS ContactCode, 
             'Other Documents' AS Sort, 4 as SortNumber, CASE WHEN bPMOD.DateDueBack IS NOT NULL THEN bPMOD.DateDueBack ELSE bPMOD.DateDue END AS DueDate, 
             CASE WHEN bPMOD.DateRecdBack IS NULL THEN '12/31/2050' ELSE bPMOD.DateRecdBack END AS DateRecd, bPMOD.Description, 
             bPMOC.Seq, bPMOD.VendorGroup,
             DateDiff(day, (CASE WHEN bPMOD.DateDueBack IS NOT NULL THEN bPMOD.DateDueBack ELSE bPMOD.DateDue END),GetDate()) as 'DaysOverDue',
             bPMSC_2.Status, bPMOD.Document+' '+bPMOD.Description as DocumentNumberAndDescription
FROM         bPMOD 
             LEFT OUTER JOIN bPMOC ON bPMOD.PMCo = bPMOC.PMCo AND bPMOD.Project = bPMOC.Project AND 
                  bPMOD.DocType = bPMOC.DocType AND bPMOD.Document = bPMOC.Document 
             LEFT OUTER JOIN bPMSC AS bPMSC_2 ON bPMOD.Status = bPMSC_2.Status  
             INNER JOIN bJCJM AS bJCJM_2 ON bPMOD.PMCo = bJCJM_2.JCCo AND bPMOD.Project = bJCJM_2.Job

WHERE     (ISNULL(bPMSC_2.CodeType, '') <> 'F') AND (bPMOD.DateRecdBack IS NULL)

union all
 --Request for Quotes
SELECT     bPMRQ.PMCo, bJCJM_1.Contract, bPMRQ.Project, bJCJM_1.ProjectMgr, bPMRQ.KeyID as DocumentID, bPMRQ.RFQ,  bPMRQ.PCOType, null as Item, 
          CASE WHEN bPMRQ.Status IS NULL 
                      THEN bPMRQ.FirmNumber ELSE (CASE WHEN bPMQD.RFQSeq IS NOT NULL THEN (CASE WHEN bPMQD.DateSent IS NOT NULL AND 
                      bPMQD.DateReqd IS NOT NULL THEN bPMQD.SentToFirm ELSE bPMRQ.FirmNumber END) ELSE bPMRQ.FirmNumber END) END AS FirmNumber, 
                      CASE WHEN bPMRQ.Status IS NULL THEN bPMRQ.ResponsiblePerson ELSE (CASE WHEN bPMQD.RFQSeq IS NOT NULL 
                      THEN (CASE WHEN bPMQD.DateSent IS NOT NULL AND bPMQD.DateReqd IS NOT NULL 
                      THEN bPMQD.SentToContact ELSE bPMRQ.ResponsiblePerson END) ELSE bPMRQ.ResponsiblePerson END) END AS ContactCode, 
                      'Request for Quotes' AS Sort, 5 as SortNumber,
                      CASE WHEN bPMQD.DateReqd IS NOT NULL THEN bPMQD.DateReqd ELSE bPMRQ.DateDue END AS DueDate, 
                      CASE WHEN bPMQD.DateRecd IS NULL THEN '12/31/2050' ELSE bPMQD.DateRecd END AS DateRecd, bPMRQ.Description, 
                      null, bPMRQ.VendorGroup,
                      DateDiff(day, (CASE WHEN bPMQD.DateReqd IS NOT NULL THEN bPMQD.DateReqd ELSE bPMRQ.DateDue END ),GetDate()) as 'DaysOverDue',
                      bPMSC_1.Status, bPMRQ.RFQ+' '+bPMRQ.Description as DocumentNumberAndDescription
FROM         bPMRQ 
             LEFT OUTER JOIN bPMQD ON bPMRQ.PMCo = bPMQD.PMCo AND bPMRQ.Project = bPMQD.Project AND bPMRQ.PCOType = bPMQD.PCOType AND 
                      bPMRQ.PCO = bPMQD.PCO AND bPMRQ.RFQ = bPMQD.RFQ 
             LEFT OUTER JOIN bPMSC AS bPMSC_1 ON bPMRQ.Status = bPMSC_1.Status 
             INNER JOIN bJCJM AS bJCJM_1 ON bPMRQ.PMCo = bJCJM_1.JCCo AND bPMRQ.Project = bJCJM_1.Job
where isnull(bPMSC_1.CodeType,'') <> 'F'and bPMQD.DateRecd is null

union all
--Pending Change Orders

SELECT bPMOP.PMCo,
	   bJCJM_1.Contract,
	   bPMOP.Project,
	   bJCJM_1.ProjectMgr,
	   bPMOP.KeyID as DocumentID,
	   bPMOP.PCO, 
	   bPMOP.PCOType,
	   null as Item, 
	   NULL AS FirmNumber, 
       NULL AS ContactCode, 
       'Pending Change Orders' AS Sort,
	   6 as SortNumber,
       NULL AS DueDate, 
       NULL AS DateRecd, max(bPMOP.Description), 
       null,
	   null,
       null as 'DaysOverDue',
       case when bPMOP.PendingStatus=0 then 'Pending'
            when bPMOP.PendingStatus=1 then 'Partial'
	   end as Status
	  ,bPMOP.PCO+' '+max(bPMOP.Description) as DocumentNumberAndDescription
FROM   bPMOP 
	   INNER JOIN bPMOI on bPMOI.PMCo=bPMOP.PMCo and bPMOI.Project=bPMOP.Project
						and bPMOI.PCOType=bPMOP.PCOType and bPMOI.PCO=bPMOP.PCO
	   
	   INNER JOIN bPMSC on bPMSC.Status=bPMOI.Status

	   INNER JOIN bJCJM AS bJCJM_1 ON bPMOP.PMCo = bJCJM_1.JCCo AND bPMOP.Project = bJCJM_1.Job

WHERE bPMOI.InterfacedDate is null and bPMSC.IncludeInProj='Y'
GROUP BY bPMOP.PMCo, bJCJM_1.Contract, bPMOP.Project, bJCJM_1.ProjectMgr,
         bPMOP.KeyID, bPMOP.PCO, bPMOP.PCOType, bPMOP.PendingStatus


)



Select  
         bPMCO.KeyID as PMCoID
        ,bJCCM.KeyID as ContractID
		,bJCCM.Contract+' '+isnull(bJCCM.Description,'') as ContractAndDescription
        ,bJCJM.KeyID as JobID
		,bJCJM.Job +' '+ bJCJM.Description as JobAndDescription
        ,bJCMP.KeyID as ProjMgrID
        ,isnull(bPMFM.KeyID,0) as FirmID
        ,Row_Number() Over (Order by PMDocs.PMCo, PMDocs.Contract, PMDocs.Project, PMDocs.ProjectMgr,
             PMDocs.DocumentNumber, PMDocs.Sequence) as DocumentSeqID 
		,PMDocs.Description as DocDescription
		,Cast(cast(PMDocs.SortNumber as varchar(1))+cast(PMDocs.DocumentID as varchar(16)) as bigint) as DocumentID
		,PMDocs.DocumentNumber as DocNumber
        ,PMDocs.DocumentNumberAndDescription as DocumentNumberAndDescription
		,PMDocs.DocType as DocType
		,PMDocs.Sequence as DocSequence
		,'Seq: '+Cast(PMDocs.Sequence as varchar(10))+' / '+'Firm: '+isnull(bPMFM.FirmName,'')+' / '+'Due: '+isnull(Convert(varchar(20),PMDocs.DueDate, 1),'') as DocSequenceDescription
        ,PMDocs.Sort as Document
		,isnull((case when PMDocs.SortNumber=6 then -1 else bPMSC.KeyID end),0) as StatusID
		,isnull((case when PMDocs.SortNumber=6 then PMDocs.Status else bPMSC.Description end),'Unassigned') as StatusDescription
		,PMDocs.Status as Status
        ,PMDocs.DaysUntilDue
        ,viDim_PMProjectMgrJobs.PMJobID 

From PMDocs
Join vDDBICompanies on vDDBICompanies.Co=PMDocs.PMCo
Inner Join bPMCO with (nolock) on PMDocs.PMCo=bPMCO.PMCo
Inner Join bHQCO with (nolock) on PMDocs.PMCo=bHQCO.HQCo
Inner Join bJCCM with (nolock) on PMDocs.PMCo=bJCCM.JCCo and PMDocs.Contract=bJCCM.Contract
left outer /*Inner*/ Join bJCJM with (nolock) on PMDocs.PMCo=bJCJM.JCCo and PMDocs.Project=bJCJM.Job
left outer Join bJCMP with (nolock) on PMDocs.PMCo=bJCMP.JCCo and PMDocs.ProjectMgr=bJCMP.ProjectMgr
left outer Join bPMFM with (nolock) on PMDocs.VendorGroup=bPMFM.VendorGroup and PMDocs.Firmnumber = bPMFM.FirmNumber
inner join viDim_PMProjectMgrJobs with (nolock) on PMDocs.PMCo=viDim_PMProjectMgrJobs.JCCo and PMDocs.ProjectMgr=viDim_PMProjectMgrJobs.ProjectMgr 
     and PMDocs.Project=viDim_PMProjectMgrJobs.Job
Left Outer Join bPMSC with (nolock) on bPMSC.Status=PMDocs.Status

union all

Select  
         0 PMCoID
        ,0 as ContractID
		,null as ContractAndDescription
        ,0 as JobID
		,null as JobAndDescription
        ,0 as ProjMgrID
        ,0 as FirmID
        ,0 as DocumentSeqID 
		,null as DocDescription
		,0 as DocumentID
		,0 as DocNumber
        ,null as DocumentNumberAndDescription
		,null as DocType
		,0 as DocSequence
		,null as DocSequenceDescription
        ,'RFI' as Document
		,0 as StatusID
		,null as StatusDescription
		,null as Status
        ,null as DaysUntilDue
        ,null

union all 

Select  
         0 PMCoID
        ,0 as ContractID
		,null as ContractAndDescription
        ,0 as JobID
		,null as JobAndDescription
        ,0 as ProjMgrID
        ,0 as FirmID
        ,0 as DocumentSeqID 
		,null as DocDescription
		,0 as DocumentID
		,0 as DocNumber
        ,null as DocumentNumberAndDescription
		,null as DocType
		,0 as DocSequence
		,null as DocSequenceDescription
        ,'Transmittal' as Document
		,0 as StatusID
		,null as StatusDescription
		,null as Status
        ,null as DaysUntilDue
        ,null

union all

Select  
         0 PMCoID
        ,0 as ContractID
		,null as ContractAndDescription
        ,0 as JobID
		,null as JobAndDescription
        ,0 as ProjMgrID
        ,0 as FirmID
        ,0 as DocumentSeqID 
		,null as DocDescription
		,0 as DocumentID
		,0 as DocNumber
        ,null as DocumentNumberAndDescription
		,null as DocType
		,0 as DocSequence
		,null as DocSequenceDescription
        ,'Submittal' as Document
		,0 as StatusID
		,null as StatusDescription
		,null as Status
        ,null as DaysUntilDue
        ,null

union all

Select  
         0 PMCoID
        ,0 as ContractID
		,null as ContractAndDescription
        ,0 as JobID
		,null as JobAndDescription
        ,0 as ProjMgrID
        ,0 as FirmID
        ,0 as DocumentSeqID 
		,null as DocDescription
		,0 as DocumentID
		,0 as DocNumber
        ,null as DocumentNumberAndDescription
		,null as DocType
		,0 as DocSequence
		,null as DocSequenceDescription
        ,'Other Documents' as Document
		,0 as StatusID
		,null as StatusDescription
		,null as Status
        ,null as DaysUntilDue
        ,null

union all

Select  
         0 PMCoID
        ,0 as ContractID
		,null as ContractAndDescription
        ,0 as JobID
		,null as JobAndDescription
        ,0 as ProjMgrID
        ,0 as FirmID
        ,0 as DocumentSeqID 
		,null as DocDescription
		,0 as DocumentID
		,0 as DocNumber
        ,null as DocumentNumberAndDescription
		,null as DocType
		,0 as DocSequence
		,null as DocSequenceDescription
        ,'Request for Quotes' as Document
		,0 as StatusID
		,null as StatusDescription
		,null as Status
        ,null as DaysUntilDue
        ,null

union all

Select  
         0 PMCoID
        ,0 as ContractID
		,null as ContractAndDescription
        ,0 as JobID
		,null as JobAndDescription
        ,0 as ProjMgrID
        ,0 as FirmID
        ,0 as DocumentSeqID 
		,null as DocDescription
		,0 as DocumentID
		,0 as DocNumber
        ,null as DocumentNumberAndDescription
		,null as DocType
		,0 as DocSequence
		,null as DocSequenceDescription
        ,'Pending Change Orders' as Document
		,0 as StatusID
		,null as StatusDescription
		,null as Status
        ,null as DaysUntilDue
        ,null
GO
GRANT SELECT ON  [dbo].[viFact_PMDocuments] TO [public]
GRANT INSERT ON  [dbo].[viFact_PMDocuments] TO [public]
GRANT DELETE ON  [dbo].[viFact_PMDocuments] TO [public]
GRANT UPDATE ON  [dbo].[viFact_PMDocuments] TO [public]
GRANT SELECT ON  [dbo].[viFact_PMDocuments] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_PMDocuments] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_PMDocuments] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_PMDocuments] TO [Viewpoint]
GO
