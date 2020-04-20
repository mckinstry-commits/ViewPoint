SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMProjDefDistInsert]
   
   /***********************************************************
    * CREATED BY:	AW	7/11/2013 - TFS 54422 insert default contacts into distribution tables
    * MODIFIED BY:	AW 7/22/2013 - TFS 54422 insert default contacts for PO
    *
    * USAGE:
    * inserts default contacts from project distribution defaults
	* Supported Doc Categories:  (source PMDocumentMapping table)
	* ACO
	* CCO
	* COR
	* DAILYLOG
	* DRAWING
	* INSPECT
	* ISSUE
	* MTG
	* OTHER
	* PCO
	* POCO
	* PUNCH
	* PURCHASE
	* REQQUOTE
	* RFI
	* RFQ
	* SBMTL
	* SBMTLPCKG
	* SUB
	* SUBCO
	* SUBMIT
	* TEST
	* TRANSMIT
    *
    *
    * INPUT PARAMETERS
    *	@doccat varchar(10) document category
    *	@keyid bigint source records keyid
    *
    * OUTPUT PARAMETERS
    *	@msq varchar(255) output error
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure
    *****************************************************/
   (@doccat varchar(10),@keyid BIGINT, @msg varchar(255) output)
	AS
	BEGIN
		SET NOCOUNT ON

		IF @doccat IS NULL OR @keyid IS NULL 
		BEGIN
			SET @msg = 'The document category and/or keyid is incorrect. Please contact Viewpoint Customer Support.'
			RETURN 1
		END

		IF @doccat = 'ACO'
		BEGIN
			INSERT INTO dbo.PMDistribution (PMCo, Project, ACO, ApprovedCOID, Seq, VendorGroup,
				SentToFirm, SentToContact, Send, PrefMethod, CC) 
			SELECT aco.PMCo, aco.Project, aco.ACO, @keyid,
					-- row over keyfields
					ROW_NUMBER() OVER(ORDER BY aco.PMCo ASC, aco.ACO ASC, aco.KeyID),
					f.VendorGroup, f.FirmNumber, f.ContactCode,
					'Y', f.PrefMethod,f.EmailOption
			FROM dbo.PMOH aco 
			CROSS APPLY dbo.vfPMProjectDefaultContacts(aco.PMCo,aco.Project,@doccat,aco.DocType) f 
			WHERE aco.KeyID = @keyid
			--not exists by keyfields & vendorgroup,contact,firm
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=aco.PMCo
								AND dist.Project=aco.Project AND dist.ACO=aco.ACO AND dist.ApprovedCOID = aco.KeyID 
								AND dist.VendorGroup=f.VendorGroup AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
								)

		END

		-- Contracts can have subjobs so we use vspPMChangeOrderRequestGetProject to get correct project
		DECLARE @PMCo bCompany, @Contract bContract, @Project bProject

		IF @doccat = 'CCO'
		BEGIN
			SELECT @PMCo=PMCo,@Contract=[Contract] FROM PMContractChangeOrder WHERE KeyID = @keyid

			exec [dbo].[vspPMChangeOrderRequestGetProject] @PMCo,@Contract,@Project output,@msg output

			INSERT INTO dbo.PMDistribution (PMCo, Project, [Contract], ID, Seq, VendorGroup,
				SentToFirm, SentToContact, ContractCOID, Send, PrefMethod, CC) 
			select cco.PMCo, @Project, cco.Contract, cco.ID,
				ROW_NUMBER() OVER(ORDER BY cco.PMCo ASC, cco.Contract ASC, cco.ID),
				cco.VendorGroup, f.FirmNumber, f.ContactCode,
				@keyid, 'Y', f.PrefMethod,f.EmailOption
			FROM dbo.PMContractChangeOrder cco
			CROSS APPLY dbo.vfPMProjectDefaultContacts(cco.PMCo,@Project,@doccat,cco.DocType) f 
			WHERE cco.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=cco.PMCo
					AND dist.Project=@Project AND dist.VendorGroup=cco.VendorGroup
					AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
					AND dist.Contract=cco.Contract AND dist.ID = cco.ID)
		END

		IF @doccat = 'COR'
		BEGIN
			SELECT @PMCo=PMCo,@Contract=[Contract] FROM PMChangeOrderRequest WHERE KeyID = @keyid

			exec [dbo].[vspPMChangeOrderRequestGetProject] @PMCo,@Contract,@Project output,@msg output

			INSERT INTO dbo.PMDistribution (PMCo, Project, CORContract, COR, Seq, VendorGroup,
				SentToFirm, SentToContact, DateSent, CORID, Send, PrefMethod, CC) 
			SELECT cor.PMCo, @Project, cor.Contract, cor.COR,
					ROW_NUMBER() OVER(ORDER BY cor.PMCo ASC, cor.Contract ASC, cor.COR),
					cor.VendorGroup, f.FirmNumber, f.ContactCode,
					ISNULL(cor.Date, dbo.vfDateOnly()), @keyid, 'Y', f.PrefMethod,
					f.EmailOption
			FROM  dbo.PMChangeOrderRequest cor
			CROSS APPLY dbo.vfPMProjectDefaultContacts(cor.PMCo,@Project,@doccat,cor.DocType) f 
			WHERE cor.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=cor.PMCo
					AND dist.Project=@Project AND dist.CORContract=cor.Contract AND dist.COR = cor.COR
					AND dist.VendorGroup=cor.VendorGroup AND dist.SentToFirm=f.FirmNumber 
					AND dist.SentToContact=f.ContactCode)
		END

		IF @doccat = 'DAILYLOG'
		BEGIN
			INSERT INTO PMDC
				(PMCo, Project, LogDate, DailyLog, Seq, VendorGroup, SentToFirm, SentToContact , 
					[Send], PrefMethod, CC) 
			SELECT	dl.PMCo, dl.Project, dl.LogDate, dl.DailyLog
				, ROW_NUMBER() OVER(ORDER BY dl.PMCo,dl.Project,dl.LogDate,dl.DailyLog)	
				, f.VendorGroup, f.FirmNumber, f.ContactCode, 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMDL dl
			CROSS APPLY dbo.vfPMProjectDefaultContacts(dl.PMCo,dl.Project,@doccat,dl.DocType) f 
			WHERE dl.KeyID = @keyid
			AND NOT EXISTS(	SELECT TOP 1 1 
								FROM dbo.PMDC 
								WHERE PMCo = dl.PMCo 
										AND Project = dl.Project AND LogDate = dl.LogDate AND DailyLog = dl.DailyLog
											AND VendorGroup = f.VendorGroup 
											AND SentToFirm = f.FirmNumber 
											AND SentToContact = f.ContactCode)
		END

		IF @doccat = 'DRAWING'
		BEGIN
			INSERT INTO PMDistribution
				(PMCo, Project, DrawingType, Drawing, Seq, VendorGroup, SentToFirm, SentToContact
				, DrawingLogID, [Send], PrefMethod, CC) 
			SELECT	dg.PMCo, dg.Project, dg.DrawingType ,dg.Drawing 
				, ROW_NUMBER() OVER(ORDER BY dg.PMCo,dg.Project,dg.DrawingType,dg.Drawing)
				, f.VendorGroup,f.FirmNumber, f.ContactCode,@keyid,'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMDG dg
			CROSS APPLY dbo.vfPMProjectDefaultContacts(dg.PMCo,dg.Project,@doccat,dg.DrawingType) f 
			WHERE dg.KeyID = @keyid
			AND NOT EXISTS(SELECT 1 
								FROM dbo.PMDistribution dist
								WHERE dist.PMCo = dg.PMCo AND dist.Project = dg.Project 
										AND dist.DrawingType = dg.DrawingType	AND dist.Drawing = dg.Drawing
										AND dist.VendorGroup = f.VendorGroup	AND dist.SentToFirm = f.FirmNumber 
										AND dist.SentToContact = f.ContactCode)

		END

		IF @doccat = 'INSPECT'
		BEGIN
			INSERT INTO PMDistribution
				(PMCo, Project, InspectionType, InspectionCode, Seq, VendorGroup, SentToFirm, SentToContact
				, InspectionLogID, [Send], PrefMethod, CC) 
			SELECT	il.PMCo, il.Project, il.InspectionType,il.InspectionCode
				, ROW_NUMBER() OVER(ORDER BY il.PMCo,il.Project,il.InspectionType,il.InspectionCode)
				, f.VendorGroup, f.FirmNumber, f.ContactCode, @keyid, 'Y' , f.PrefMethod, f.EmailOption
			FROM dbo.PMIL il
			CROSS APPLY dbo.vfPMProjectDefaultContacts(il.PMCo,il.Project,@doccat,il.InspectionType) f 
			WHERE il.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution 
						WHERE PMCo=il.PMCo AND Project=il.Project AND InspectionType=il.InspectionType 
							AND InspectionCode=il.InspectionCode
							AND VendorGroup=f.VendorGroup AND SentToFirm=f.FirmNumber 
							AND SentToContact=f.ContactCode )

		END

		IF @doccat = 'ISSUE'
		BEGIN
			INSERT INTO dbo.PMDistribution (Seq, VendorGroup, SentToFirm, SentToContact, Send,
				PrefMethod, CC, PMCo, Project, IssueType, Issue, IssueID)
			SELECT ROW_NUMBER() OVER(ORDER BY im.PMCo,im.Project,im.Issue)
				, f.VendorGroup, f.FirmNumber, f.ContactCode, 'Y', f.PrefMethod, f.EmailOption, 
				im.PMCo, im.Project, im.Type, im.Issue, @keyid
			FROM dbo.PMIM im
			CROSS APPLY dbo.vfPMProjectDefaultContacts(im.PMCo,im.Project,@doccat,im.[Type]) f 
			WHERE im.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution 
								WHERE PMCo=im.PMCo AND Project=im.Project AND Issue=im.Issue
								AND VendorGroup=f.VendorGroup AND SentToFirm=f.FirmNumber 
								AND SentToContact=f.ContactCode)
		END

		IF @doccat = 'MTG'
		BEGIN
			INSERT INTO PMDistribution
			(PMCo, Project, MeetingType, Meeting, MinutesType, Seq, VendorGroup, SentToFirm, SentToContact ,
			   MeetingMinuteID, [Send], PrefMethod, CC) 
			SELECT	mm.PMCo, mm.Project, mm.MeetingType, mm.Meeting, mm.MinutesType								
				, ROW_NUMBER() OVER(ORDER BY mm.PMCo, mm.Project, mm.MeetingType, mm.Meeting, mm.MinutesType)
				, f.VendorGroup, f.FirmNumber, f.ContactCode, @keyid, 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMMM mm
			CROSS APPLY dbo.vfPMProjectDefaultContacts(mm.PMCo,mm.Project,@doccat,mm.MeetingType) f 
			WHERE mm.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution 
						WHERE PMCo=mm.PMCo AND Project=mm.Project AND MeetingType=mm.MeetingType
						AND Meeting=mm.Meeting AND MinutesType=mm.MinutesType
							AND VendorGroup=f.VendorGroup AND SentToFirm=f.FirmNumber 
							AND SentToContact=f.ContactCode )
		END

		IF @doccat = 'OTHER'
		BEGIN
			INSERT INTO PMOC
				(PMCo, Project, DocType, Document, Seq, VendorGroup, SentToFirm, SentToContact
				,[Send], PrefMethod, CC) 
			SELECT od.PMCo, od.Project, od.DocType
				, od.Document,ROW_NUMBER() OVER(ORDER BY od.PMCo,od.Project,od.DocType,od.Document), f.VendorGroup
				, f.FirmNumber, f.ContactCode, 'Y', f.PrefMethod, f.EmailOption 'CC'
			FROM dbo.PMOD od
			CROSS APPLY dbo.vfPMProjectDefaultContacts(od.PMCo,od.Project,@doccat,od.DocType) f 
			WHERE od.KeyID = @keyid
			AND NOT EXISTS(	SELECT TOP 1 1 FROM dbo.PMOC
						WHERE PMCo=od.PMCo AND Project=od.Project AND DocType=od.DocType AND Document=od.Document
						AND VendorGroup=f.VendorGroup AND SentToFirm=f.FirmNumber 
						AND SentToContact=f.ContactCode )
		END

		IF @doccat = 'PCO'
		BEGIN
			INSERT INTO PMCD
				(PMCo, Project, PCOType, PCO, Seq, VendorGroup, SentToFirm, SentToContact
				, Send, PrefMethod, CC) 
			SELECT	pco.PMCo, pco.Project, pco.PCOType, pco.PCO
				, ROW_NUMBER() OVER(ORDER BY pco.PMCo, pco.Project, pco.PCOType, pco.PCO)
				, f.VendorGroup, f.FirmNumber, f.ContactCode,'Y', f.PrefMethod,f.EmailOption
			FROM dbo.PMOP pco
			CROSS APPLY dbo.vfPMProjectDefaultContacts(pco.PMCo,pco.Project,@doccat,pco.PCOType) f 
			WHERE pco.KeyID = @keyid
			AND NOT EXISTS(	SELECT TOP 1 1 FROM dbo.PMCD
							WHERE PMCo=pco.PMCo AND Project=pco.Project AND PCOType=pco.PCOType AND PCO=pco.PCO
								AND VendorGroup=f.VendorGroup AND SentToFirm=f.FirmNumber 
								AND SentToContact=f.ContactCode)

		END

		IF @doccat = 'POCO'
		BEGIN
			INSERT INTO dbo.PMDistribution(POCOID,PMCo, Project, POCo, PO, POCONum, Seq, VendorGroup,SentToFirm, SentToContact, [Send], PrefMethod, CC)
			SELECT @keyid,  poco.PMCo, poco.Project, poco.POCo, poco.PO, poco.POCONum, 
				ROW_NUMBER() OVER(ORDER BY poco.PMCo, poco.Project, poco.POCo,poco.PO, poco.POCONum),
				f.VendorGroup, f.FirmNumber, f.ContactCode, 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMPOCO poco
			CROSS APPLY dbo.vfPMProjectDefaultContacts(poco.PMCo,poco.Project,@doccat,poco.DocType) f 
			WHERE poco.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE 
					dist.PMCo=poco.PMCo AND dist.Project=poco.Project AND 
					dist.POCo=poco.POCo AND dist.PO = poco.PO AND dist.POCONum = poco.POCONum AND
					dist.VendorGroup=f.VendorGroup AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode)
		END

		IF @doccat = 'PUNCH'
		BEGIN
			INSERT INTO dbo.PMDistribution (PMCo, Project, PunchList, PunchListID, Seq, VendorGroup,
				SentToFirm, SentToContact, Send, PrefMethod, CC)
			select punch.PMCo, punch.Project, punch.PunchList, @keyid,
				ROW_NUMBER() OVER(ORDER BY punch.PMCo, punch.PunchList),
				f.VendorGroup, f.FirmNumber, f.ContactCode,
				 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMPU punch
			CROSS APPLY dbo.vfPMProjectDefaultContacts(punch.PMCo,punch.Project,@doccat,punch.DocType) f 
			WHERE punch.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE 
					dist.PMCo=punch.PMCo AND dist.Project=punch.Project AND dist.PunchList=punch.PunchList
					AND	dist.VendorGroup=f.VendorGroup AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode)
		END

		IF @doccat = 'PO'
		BEGIN
			INSERT INTO PMDistribution (PurchaseOrderID, PMCo, Project, POCo, PO, Seq, VendorGroup, 
				SentToFirm, SentToContact, [Send], PrefMethod, CC, DateSent)
			SELECT @keyid , POHDPM.PMCo, POHDPM.Project, 
				POHDPM.POCo ,POHDPM.PO, ROW_NUMBER() OVER(ORDER BY POHDPM.PMCo, POHDPM.Project, POHDPM.POCo,POHDPM.PO), 
				POHDPM.VendorGroup, f.FirmNumber, f.ContactCode,'Y', f.PrefMethod, 
				f.EmailOption, ISNULL(POHDPM.OrderDate, dbo.vfDateOnly())
			FROM dbo.POHDPM
			CROSS APPLY dbo.vfPMProjectDefaultContacts(POHDPM.PMCo,POHDPM.Project,@doccat,POHDPM.DocType) f 	
			WHERE POHDPM.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE 
					dist.PMCo=POHDPM.PMCo AND dist.Project=POHDPM.Project  AND
					dist.POCo=POHDPM.POCo AND dist.PO = POHDPM.PO AND dist.VendorGroup=POHDPM.VendorGroup AND 
					dist.SentToFirm=f.FirmNumber AND 	dist.SentToContact=f.ContactCode)
		END

		IF @doccat = 'REQQUOTE'
		BEGIN
			INSERT INTO dbo.PMDistribution (PMCo, Project, RFQ, RFQID, Seq, VendorGroup,
				SentToFirm, SentToContact, Send, PrefMethod, CC) 
			SELECT rfq.PMCo, rfq.Project, rfq.RFQ, @keyid,
					ROW_NUMBER() OVER(ORDER BY rfq.PMCo, rfq.Project, rfq.RFQ),
					f.VendorGroup, f.FirmNumber, f.ContactCode,
					'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMRequestForQuote rfq
			CROSS APPLY dbo.vfPMProjectDefaultContacts(rfq.PMCo,rfq.Project,@doccat,rfq.DocType) f 
			WHERE rfq.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=rfq.PMCo
					AND dist.Project=rfq.Project AND dist.VendorGroup=f.VendorGroup
					AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
					AND dist.RFQ=rfq.RFQ AND dist.RFQID = rfq.KeyID)
		END

		IF @doccat = 'RFI'
		BEGIN
			INSERT INTO PMRD
				(PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm, SentToContact
				, [Send], PrefMethod, CC)
			SELECT	rfi.PMCo, rfi.Project, rfi.RFIType, rfi.RFI
				, ROW_NUMBER() OVER(ORDER BY rfi.PMCo,rfi.Project,rfi.RFIType,rfi.RFI)
				, f.VendorGroup, f.FirmNumber, f.ContactCode, 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMRI rfi
			CROSS APPLY dbo.vfPMProjectDefaultContacts(rfi.PMCo,rfi.Project,@doccat,rfi.RFIType) f
			WHERE rfi.KeyID = @keyid 
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMRD dist WHERE dist.PMCo=rfi.PMCo
					AND dist.Project=rfi.Project AND dist.VendorGroup=f.VendorGroup
					AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
					AND dist.RFI=rfi.RFI AND dist.RFIType = rfi.RFIType)
		END

		IF @doccat = 'RFQ'
		BEGIN
			INSERT INTO PMQD
				(PMCo, Project, PCOType, PCO, RFQ, RFQSeq, VendorGroup, SentToFirm, SentToContact,
				[Send], PrefMethod, CC) 
			SELECT	rfq.PMCo, rfq.Project, rfq.PCOType, rfq.PCO, rfq.RFQ,
				ROW_NUMBER() OVER(ORDER BY rfq.PMCo, rfq.Project, rfq.PCOType, rfq.PCO, rfq.RFQ),
				f.VendorGroup, f.FirmNumber, f.ContactCode, 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMRQ rfq
			CROSS APPLY dbo.vfPMProjectDefaultContacts(rfq.PMCo,rfq.Project,@doccat,rfq.PCOType) f
			WHERE rfq.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMQD dist WHERE dist.PMCo=rfq.PMCo
					AND dist.Project=rfq.Project AND dist.VendorGroup=f.VendorGroup
					AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
					AND dist.PCOType=rfq.PCOType AND dist.PCO = rfq.PCO AND dist.RFQ = rfq.RFQ)
		END

		/* no default distribution for submittal records
		IF @doccat = 'SBMTL'
		BEGIN
		END
		*/

		IF @doccat = 'SBMTLPCKG'
		BEGIN
			INSERT INTO PMDistribution
				(PMCo, Project, SubmittalPackage, SubmittalPackageRev, Seq, VendorGroup, 
					SentToFirm, SentToContact , SubmittalPackageID, [Send], PrefMethod, CC) 
			SELECT	spkg.PMCo, spkg.Project,spkg.Package,spkg.PackageRev
				, ROW_NUMBER() OVER(ORDER BY spkg.PMCo, spkg.Project,spkg.Package,spkg.PackageRev)	
				, f.VendorGroup, f.FirmNumber, f.ContactCode, @keyid								
				, 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMSubmittalPackage spkg
			CROSS APPLY dbo.vfPMProjectDefaultContacts(spkg.PMCo,spkg.Project,@doccat,spkg.DocType) f
			WHERE spkg.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=spkg.PMCo
					AND dist.Project=spkg.Project AND dist.VendorGroup=f.VendorGroup
					AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
					AND dist.SubmittalPackage=spkg.Package AND dist.SubmittalPackageRev = spkg.PackageRev)
		END

		IF @doccat = 'SUB'
		BEGIN
			INSERT INTO PMSS
				(PMCo, Project, SLCo, SL, Seq, VendorGroup, SendToFirm, SendToContact , [Send], PrefMethod, CC) 
			SELECT	sub.PMCo, sub.Project, sub.SLCo, sub.SL
				, ROW_NUMBER() OVER(ORDER BY sub.PMCo, sub.Project, sub.SLCo, sub.SL)	
				, f.VendorGroup, f.FirmNumber, f.ContactCode, 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.SLHDPM sub
			CROSS APPLY dbo.vfPMProjectDefaultContacts(sub.PMCo,sub.Project,@doccat,sub.DocType) f
			WHERE sub.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMSS dist WHERE dist.PMCo=sub.PMCo
					AND dist.Project=sub.Project AND dist.VendorGroup=f.VendorGroup
					AND dist.SendToFirm=f.FirmNumber AND dist.SendToContact=f.ContactCode
					AND dist.SLCo=sub.SLCo AND dist.SL = sub.SL)
		END

		IF @doccat = 'SUBCO'
		BEGIN
			INSERT INTO dbo.PMDistribution (PMCo, Project, SLCo, SL, SubCO, Seq, VendorGroup,
				SentToFirm, SentToContact, SubcontractCOID, Send, PrefMethod, CC) 
			SELECT sco.PMCo, sco.Project, sco.SLCo, sco.SL, sco.SubCO, 
				ROW_NUMBER() OVER(ORDER BY sco.PMCo, sco.Project, sco.SLCo, sco.SL, sco.SubCO),
				f.VendorGroup, f.FirmNumber, f.ContactCode, @keyid, 'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMSubcontractCO sco
			CROSS APPLY dbo.vfPMProjectDefaultContacts(sco.PMCo,sco.Project,@doccat,sco.DocType) f
			WHERE sco.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=sco.PMCo
					AND dist.Project=sco.Project AND dist.VendorGroup=f.VendorGroup
					AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
					AND dist.SLCo=sco.SLCo AND dist.SL = sco.SL AND dist.SubCO = sco.SubCO)

		END

		IF @doccat = 'SUBMIT'
		BEGIN
			INSERT INTO PMDistribution
				(PMCo, Project, SubmittalType, Submittal, Rev, Seq, VendorGroup, SentToFirm, SentToContact
				, SubmittalID, [Send], PrefMethod, CC) 
			SELECT sub.PMCo, sub.Project, sub.SubmittalType,sub.Submittal,sub.Rev,
				(select isnull(max(Seq),0) from PMDistribution where SubmittalID=@keyid) +
				  ROW_NUMBER() OVER(ORDER BY sub.PMCo, sub.Project, sub.SubmittalType,sub.Submittal,sub.Rev), 
				f.VendorGroup, f.FirmNumber, f.ContactCode, @keyid,'Y', f.PrefMethod, f.EmailOption
			FROM dbo.PMSM sub
			CROSS APPLY dbo.vfPMProjectDefaultContacts(sub.PMCo,sub.Project,@doccat,sub.SubmittalType) f
			WHERE sub.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=sub.PMCo
					AND dist.Project=sub.Project AND dist.VendorGroup=f.VendorGroup
					AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
					AND dist.SubmittalType=sub.SubmittalType AND dist.Submittal = sub.Submittal AND dist.Rev = sub.Rev)
		END

		IF @doccat = 'TEST'
		BEGIN
			INSERT INTO PMDistribution
				(PMCo, Project, TestType, TestCode, Seq, VendorGroup, SentToFirm, SentToContact
				, TestLogID, [Send], PrefMethod, CC) 
			SELECT	test.PMCo, test.Project, test.TestType,test.TestCode,
				ROW_NUMBER() OVER(ORDER BY test.PMCo, test.Project, test.TestType,test.TestCode),
				f.VendorGroup, f.FirmNumber, f.ContactCode, @keyid,'Y', f.PrefMethod,f.EmailOption
			FROM dbo.PMTL test
			CROSS APPLY dbo.vfPMProjectDefaultContacts(test.PMCo,test.Project,@doccat,test.TestType) f
			WHERE test.KeyID = @keyid
			AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMDistribution dist WHERE dist.PMCo=test.PMCo
					AND dist.Project=test.Project AND dist.VendorGroup=f.VendorGroup
					AND dist.SentToFirm=f.FirmNumber AND dist.SentToContact=f.ContactCode
					AND dist.TestType=test.TestType AND dist.TestCode = test.TestCode)
		END

		IF @doccat = 'TRANSMIT'
		BEGIN
			INSERT INTO PMTC
				(PMCo, Project, Transmittal, Seq, VendorGroup, SentToFirm, SentToContact , [Send], PrefMethod, CC) 
			SELECT tm.PMCo, tm.Project, tm.Transmittal
				, ROW_NUMBER() OVER(ORDER BY tm.PMCo, tm.Project, tm.Transmittal)	
				, f.VendorGroup, f.FirmNumber, f.ContactCode, 'Y', f.PrefMethod,f.EmailOption
		  FROM dbo.PMTM tm
		  CROSS APPLY dbo.vfPMProjectDefaultContacts(tm.PMCo,tm.Project,@doccat,tm.DocType) f
		  WHERE tm.KeyID = @keyid
		  AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMTC dist WHERE dist.PMCo=tm.PMCo
					AND dist.Project=tm.Project AND dist.Transmittal=tm.Transmittal
					AND dist.VendorGroup=f.VendorGroup AND dist.SentToFirm=f.FirmNumber 
					AND dist.SentToContact=f.ContactCode)
		END

	END
GO
GRANT EXECUTE ON  [dbo].[vspPMProjDefDistInsert] TO [public]
GO
