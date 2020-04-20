SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE                View [dbo].[brvPMBallInCourt] as
       
       /***********************************
       Created by Craig R. 3/10/03
       
       View will pull in all docouments for a Project by Firm Contact.
       Modified 2/15/05 CR added submittal Item dates to view.
       Modified 2/16/06 CR modifed all union statements issue 29940.
       Modified 6/25/07 CR added the PMQD.DateDue field to the RFQ portion 
       Mod  1/22/08 removed the PMQD.DateDue field, reversed the work.
       Mod 1/30/08 issue 126850 CR
       Mod 4/29/09 issue 128780 DH 
	   Mod 06/03/2013 TFS 51910 HH - added PMRequestForQuote, PMSubmittalRegister and PMSubmittalPackage

       Reports: PMBallInCourtbyType, PMBallInCourtbyFirmContact Reports.
       ************************************/
       
       --RFI
       Select PMRI.PMCo, PMRI.Project,
       Firmnumber=(Case when PMRI.Status is null OR
             (PMRI.RespondFirm is null or PMRI.RespondContact is null or PMRI.DateSent is null ) then PMRI.ResponsibleFirm 
              when PMRD.RFISeq is not null  then PMRD.SentToFirm 
              when PMRI.RespondFirm is not null then PMRI.RespondFirm else PMRI.ResponsibleFirm
              end),
       ContactCode=(Case when PMRI.Status is null OR
             (PMRI.RespondFirm is null or PMRI.RespondContact is null or PMRI.DateSent is null ) then PMRI.ResponsiblePerson
              when PMRD.RFISeq is not null then PMRD.SentToContact 
              when PMRI.RespondFirm is not null then PMRI.ResponsiblePerson else PMRI.ResponsibleFirm
              end),
       Sort=1,PMSMStatus=isnull(PMRI.Status,''),
       DueDate=(Case when PMRD.DateReqd is not null then PMRD.DateReqd else PMRI.DateDue end),
       DateRecd=(case when PMRD.DateRecd is not null then PMRD.DateRecd 
                  when PMRD.DateRecd is not null then PMRD.DateRecd else '12/31/2050' end),
       Description=PMRI.Subject,DocType=PMDT.DocType, DocDescription=PMDT.Description,
       RFIType=PMRI.RFIType, RFI=PMRI.RFI, RFISeq=RFISeq,Transmittal=null, Submittal=null,Revision=null,PMSIItem=null,OtherDocType=null,OtherDocs=null,
       PCOType=null,PCO=null,RFQ=null,RFQSeq=null,SubmittalRegisterSequence=null,SubmittalRegisterNumber=null,SubmittalRegisterRev=null,SubmittalPackage=null,SubmittalPackgeRev=null,VendorGroup=PMRI.VendorGroup, headerCodeType=PMSC.CodeType, ItemCodeType=null
       from PMRI
       left join PMRD on PMRD.PMCo=PMRI.PMCo and PMRD.Project=PMRI.Project and PMRD.RFIType=PMRI.RFIType and PMRD.RFI=PMRI.RFI
       Join PMDT on PMRI.RFIType=PMDT.DocType
       left join PMSC on PMRI.Status=PMSC.Status
       join JCJM on PMRI.PMCo=JCJM.JCCo and PMRI.Project=JCJM.Job 
       where isnull(PMSC.CodeType,'') <> 'F' 
       
       
       Union All
       
       --Letter of Transmittal
       select  PMTM.PMCo, PMTM.Project,
       Firmnumber=(Case when PMTC.Seq is not null then PMTC.SentToFirm else PMTM.ResponsibleFirm end),
       ContactCode=(Case when PMTC.Seq is not null then PMTC.SentToContact  
                    when PMTM.ResponsiblePerson is not null then PMTM.ResponsiblePerson else 0 end),
       2,null,
       PMTM.DateDue,
       case when PMTM.DateResponded is null then '12/31/2050' else PMTM.DateResponded end,
       PMTM.Subject,null,null,
       null,null,null,PMTM.Transmittal,null,null,null,null,null,null,null,null,null,null,null,null,null,null,PMTM.VendorGroup,null,null
       from PMTM
       Left Join PMTC on PMTM.PMCo=PMTC.PMCo and PMTM.Project=PMTC.Project and PMTM.Transmittal=PMTC.Transmittal
       join JCJM on PMTM.PMCo = JCJM.JCCo and PMTM.Project=JCJM.Job
   where PMTM.DateDue is not null and PMTM.DateResponded is null 
       
       Union All
       
       --Submittals 
       select PMSM.PMCo, PMSM.Project, 
       --Case statement for Firm
        CASE WHEN PMSM.Status is null THEN PMSM.ResponsibleFirm 

        ELSE  --PMSM.Status check
              (Case when PMSI.Item is not null Then

                   (Case when PMSI.DateReqd is null then PMSM.ResponsibleFirm
                         when PMSI.ToArchEng is not null and PMSI.RecdBackArch is null then PMSM.ArchEngFirm
                         when PMSI.DateReqd is not null and PMSI.DateRecd is null then PMSM.SubFirm
                    else PMSM.ResponsibleFirm 
                    end) 

                Else  --PMSI.Item is null

                   (Case when PMSM.ToArchEng is not null and PMSM.RecdBackArch is null then PMSM.ArchEngFirm
                         when PMSM.DateReqd is not null and PMSM.DateRecd is null then PMSM.SubFirm
                    else PMSM.ResponsibleFirm 
                    end) 

               End) --PMSI.Item check

         END, --end entire case statement

       --Case Statement for Firm Contact
       CASE WHEN PMSM.Status is null THEN PMSM.ResponsiblePerson 

        ELSE  --PMSM.Status check
              (Case when PMSI.Item is not null Then

                   (Case when PMSI.DateReqd is null then PMSM.ResponsiblePerson
                         when PMSI.ToArchEng is not null and PMSI.RecdBackArch is null then PMSM.ArchEngContact
                         when PMSI.DateReqd is not null and PMSI.DateRecd is null then PMSM.SubContact
                    else PMSM.ResponsiblePerson 
                    end) 

                Else  --PMSI.Item is null

                   (Case when PMSM.ToArchEng is not null and PMSM.RecdBackArch is null then PMSM.ArchEngContact
                         when PMSM.DateReqd is not null and PMSM.DateRecd is null then PMSM.SubContact
                    else PMSM.ResponsiblePerson 
                    end) 

               End) --PMSI.Item check

         END --end entire case statement,
       
       ,3,PMSMStatus=isnull(a.Status, ''),
       Case when PMSI.Item is not null then
       (case when PMSI.DateRecd is null then PMSI.DateReqd
        when PMSI.RecdBackArch is null then PMSI.DueBackArch
        when PMSI.DateRetd is null then PMSI.RecdBackArch end)
        else  --(issue 27036 CR)
      (case when PMSM.DateRecd is null then PMSM.DateReqd 
       when PMSM.RecdBackArch is null then PMSM.DueBackArch
       when PMSM.DateRetd is null then PMSM.RecdBackArch end)
       
       end,
       '12/31/2050',
       PMSM.Description,
       PMDT.DocType,PMDT.Description,
       null,null,null,null,PMSM.Submittal,PMSM.Rev,PMSI.Item,null,null,null,null,null,null,null,null,null,null,null,PMSM.VendorGroup, 
       PMSMCodeType=isnull(a.CodeType,''), PMSICodeType=isnull(b.CodeType,'')
       from PMSM
       
       left Join PMSC a on PMSM.Status=a.Status
       
       Join PMDT on PMSM.SubmittalType=PMDT.DocType
       left join PMSI on PMSM.PMCo=PMSI.PMCo and PMSM.Project=PMSI.Project and PMSM.Submittal=PMSI.Submittal and PMSM.SubmittalType=PMSI.SubmittalType
       and PMSM.Rev=PMSI.Rev
       left Join PMSC b on PMSI.Status=b.Status
       join JCJM on PMSM.PMCo=JCJM.JCCo and PMSM.Project=JCJM.Job
       
      where isnull(a.CodeType,'') <> 'F' --and 
      --(PMSM.RecdBackArch is not null and PMSM.DateRetd is null or
      --(PMSM.DueBackArch is not null and PMSM.RecdBackArch is null) or
      --(PMSM.DateReqd is not null and PMSM.DateRecd is null)) 
      --removed during issue 29940, I don't think they need to be here anymore.
       
       
       Union All
       
   
       --Other Docs
       select PMOD.PMCo, PMOD.Project,
       Firmnumber=(Case when PMOD.Status is null then PMOD.ResponsibleFirm else
                  (Case when PMOC.Seq is not null then PMOC.SentToFirm else PMOD.ResponsibleFirm end)end),
       ContactCode=(Case when PMOD.Status is null then PMOD.ResponsiblePerson else
           (Case when PMOC.Seq is not null then PMOC.SentToContact else PMOD.ResponsiblePerson end)end),  
       4,isnull(PMOD.Status,''),
       case when PMOD.DateDueBack is not null then PMOD.DateDueBack else PMOD.DateDue end,
       Case when PMOD.DateRecdBack is null then '12/31/2050' else PMOD.DateRecdBack end ,
       PMOD.Description,PMDT.DocType,PMDT.Description,
       null,null,null,null,null,null,null,PMOD.DocType,PMOD.Document,null,null,null,null,null,null,null,null,null,PMOD.VendorGroup, CodeType=PMSC.CodeType,null
       from PMOD
       Left Join PMOC on PMOD.PMCo=PMOC.PMCo and PMOD.Project=PMOC.Project and PMOD.DocType=PMOC.DocType and PMOD.Document=PMOC.Document
       left Join PMSC on PMOD.Status=PMSC.Status
       Join PMDT on PMOD.DocType = PMDT.DocType
       join JCJM on PMOD.PMCo=JCJM.JCCo and PMOD.Project=JCJM.Job
   where isnull(PMSC.CodeType,'') <> 'F' and PMOD.DateRecdBack is  null 
       
       Union All
       
   
       --Request for Quotes <= 6.6
       select PMRQ.PMCo, PMRQ.Project,
       FirmNumber= Case when PMRQ.Status is null then PMRQ.FirmNumber else
       (Case when PMQD.RFQSeq is not null then 
       (case when PMQD.DateSent is not null and PMQD.DateReqd is not null then PMQD.SentToFirm
               else PMRQ.FirmNumber end) else PMRQ.FirmNumber end) end,
       ContactCode= Case when PMRQ.Status is null then PMRQ.ResponsiblePerson else
       (Case when PMQD.RFQSeq is not null then 
       (case when PMQD.DateSent is not null and PMQD.DateReqd is not null then PMQD.SentToContact 
               else PMRQ.ResponsiblePerson end) else PMRQ.ResponsiblePerson end) end,
       5,isnull(PMRQ.Status,''),
       DueDate=case when PMQD.DateReqd is not null then PMQD.DateReqd else PMRQ.DateDue end /*PMRQ.DateDue*/,
       DateRecd=case when PMQD.DateRecd is null then '12/31/2050' else PMQD.DateRecd end , 
       PMRQ.Description,PMDT.DocType,PMDT.Description,
       null,null,null,null,null,null,null,null,null,PMRQ.PCOType, PMRQ.PCO,PMRQ.RFQ, PMQD.RFQSeq,null,null,null,null,null, PMRQ.VendorGroup, CodeType=PMSC.CodeType,null
       from PMRQ
       Left Join PMQD on PMRQ.PMCo=PMQD.PMCo and PMRQ.Project=PMQD.Project and PMRQ.PCOType=PMQD.PCOType and PMRQ.PCO=PMQD.PCO and PMRQ.RFQ=PMQD.RFQ
       left Join PMSC on PMRQ.Status=PMSC.Status
       Join PMDT on PMRQ.PCOType=PMDT.DocType
       Join JCJM on PMRQ.PMCo=JCJM.JCCo and  PMRQ.Project=JCJM.Job 
       where isnull(PMSC.CodeType,'') <> 'F'and PMQD.DateRecd is null 

	   UNION ALL

	   --Request for Quotes 
       SELECT	PMRequestForQuote.PMCo
				, PMRequestForQuote.Project
				, PMRequestForQuote.FirmNumber
				, PMRequestForQuote.ResponsiblePerson
				, 6
				, isnull(PMRequestForQuote.Status,'')
				, PMRequestForQuote.DueDate
				, PMRequestForQuote.ReceivedDate
				, PMRequestForQuote.[Description]
				, PMDT.DocType
				, PMDT.Description
				, null							--RFIType
				, null							--RFI
				, null							--RFISeq
				, null							--Transmittal
				, null							--Submittal
				, null							--SubmittalRevision
				, null							--SubmittalItem
				, null							--OtherDocType
				, null							--OtherDocs
				, null							--PCOType
				, null							--PCO
				, PMRequestForQuote.RFQ			--RFQ
				, null							--RFQSeq
				, null							--SubmittalRegisterSequence
				, null							--SubmittalRegisterNumber
				, null							--SubmittalRegisterRev
				, null							--SubmittalPackge
				, null							--SubmittalPackgeRev
				, PMRequestForQuote.VendorGroup
				, CodeType=PMSC.CodeType
				,null
	   FROM PMRequestForQuote
       LEFT JOIN PMSC on PMRequestForQuote.[Status] = PMSC.[Status]
       JOIN PMDT on PMRequestForQuote.DocType = PMDT.DocType
       JOIN JCJM on PMRequestForQuote.PMCo=JCJM.JCCo and  PMRequestForQuote.Project=JCJM.Job 
       WHERE ISNULL(PMSC.CodeType,'') <> 'F'
     
	
		UNION ALL

		--PM Submittal Register
		SELECT	PMSubmittal.PMCo
				, PMSubmittal.Project
				, PMSubmittal.ResponsibleFirm 
				, PMSubmittal.ResponsibleFirmContact
				, 7 --sort
				, ISNULL(a.[Status], '')
				, PMSubmittal.DueToResponsibleFirm
				, PMSubmittal.ReceivedFromResponsibleFirm
				, PMSubmittal.[Description]
				, PMDT.DocType
				, PMDT.[Description]
				, null							--RFIType
				, null							--RFI
				, null							--RFISeq
				, null							--Transmittal
				, null							--Submittal
				, null							--SubmittalRevision
				, null							--SubmittalItem
				, null							--OtherDocType
				, null							--OtherDocs
				, null							--PCOType
				, null							--PCO
				, null							--RFQ
				, null							--RFQSeq
				, PMSubmittal.Seq				--SubmittalRegisterSequence
				, PMSubmittal.SubmittalNumber	--SubmittalRegisterNumber
				, PMSubmittal.SubmittalRev		--SubmittalRegisterRev
				, null							--SubmittalPackge
				, null							--SubmittalPackgeRev
				, PMSubmittal.VendorGroup
				, PMSMCodeType=isnull(a.CodeType,'')
				, PMSICodeType=isnull(b.CodeType,'')
       
		FROM PMSubmittal
		LEFT JOIN PMSC a on PMSubmittal.[Status] = a.[Status]
		JOIN PMDT on PMSubmittal.DocumentType = PMDT.DocType
		LEFT JOIN PMSC b on PMSubmittal.Status=b.Status
		JOIN JCJM on PMSubmittal.PMCo=JCJM.JCCo and PMSubmittal.Project=JCJM.Job
		WHERE ISNULL(a.CodeType,'') <> 'F' 
	   	 
    
		UNION ALL

		--PM Submittal Package
		SELECT	PMSubmittalPackage.PMCo
				, PMSubmittalPackage.Project
				, PMSubmittalPackage.ResponsibleFirm 
				, PMSubmittalPackage.ResponsibleContact
				, 8 --sort
				, ISNULL(a.[Status], '')
				, PMSubmittalPackage.DueDate
				, PMSubmittalPackage.ReceivedDate
				, PMSubmittalPackage.[Description]
				, PMDT.DocType
				, PMDT.[Description]
				, null							--RFIType
				, null							--RFI
				, null							--RFISeq
				, null							--Transmittal
				, null							--Submittal
				, null							--SubmittalRevision
				, null							--SubmittalItem
				, null							--OtherDocType
				, null							--OtherDocs
				, null							--PCOType
				, null							--PCO
				, null							--RFQ
				, null							--RFQSeq
				, null							--SubmittalRegisterSequence
				, null							--SubmittalRegisterNumber
				, null							--SubmittalRegisterRev
				, PMSubmittalPackage.Package	--SubmittalPackge
				, PMSubmittalPackage.PackageRev	--SubmittalPackgeRev
				, PMSubmittalPackage.VendorGroup
				, PMSMCodeType=isnull(a.CodeType,'')
				, PMSICodeType=isnull(b.CodeType,'')
       
		FROM PMSubmittalPackage
		LEFT JOIN PMSC a on PMSubmittalPackage.[Status] = a.[Status]
		JOIN PMDT on PMSubmittalPackage.DocType = PMDT.DocType
		LEFT JOIN PMSC b on PMSubmittalPackage.[Status]=b.[Status]
		JOIN JCJM on PMSubmittalPackage.PMCo=JCJM.JCCo and PMSubmittalPackage.Project=JCJM.Job
		WHERE ISNULL(a.CodeType,'') <> 'F' 
   
   
   
  
 
GO
GRANT SELECT ON  [dbo].[brvPMBallInCourt] TO [public]
GRANT INSERT ON  [dbo].[brvPMBallInCourt] TO [public]
GRANT DELETE ON  [dbo].[brvPMBallInCourt] TO [public]
GRANT UPDATE ON  [dbo].[brvPMBallInCourt] TO [public]
GRANT SELECT ON  [dbo].[brvPMBallInCourt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPMBallInCourt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPMBallInCourt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPMBallInCourt] TO [Viewpoint]
GO
