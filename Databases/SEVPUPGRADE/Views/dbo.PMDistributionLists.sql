SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[PMDistributionLists]
AS
SELECT D.DocCat, D.DocType, D.DocNum, D.Rev, D.SL, D.PCO,
		D.PMCo, D.Project, D.VendorGroup, D.SentToFirm, D.SentToContact, 
		M.FirstName, M.MiddleInit, M.LastName, M.Fax, M.EMail, F.FirmName
FROM
   (SELECT 'DRAWING' as DocCat, DrawingType as DocType, 
			CAST(Drawing as VARCHAR(10)) as DocNum,			
			ISNULL(Rev,0) as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.vPMDistribution
	UNION ALL
	SELECT 'INSPECT' as DocCat, InspectionType as DocType, 
			CAST(InspectionCode as VARCHAR(10)) as DocNum,	
			ISNULL(Rev,0) as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.vPMDistribution
	UNION ALL
	SELECT 'PURCHASE' as DocCat, '' as DocType, 
			'' as DocNum, 
			ISNULL(Rev,0) as Rev, '' as SL,  CAST(PO as VARCHAR(10)) as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.vPMDistribution
	UNION ALL
	SELECT 'ISSUE' as DocCat, IssueType as DocType, 
			CAST(Issue as VARCHAR(10)) as DocNum, 
			ISNULL(Rev,0) as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.vPMDistribution
	UNION ALL
	SELECT 'SUBMIT' as DocCat, SubmittalType as DocType, 
			CAST(Submittal as VARCHAR(10)) as DocNum, 
			ISNULL(Rev,0) as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.vPMDistribution
	UNION ALL
	SELECT 'TEST' as DocCat, TestType as DocType, 
			CAST(TestCode as VARCHAR(10)) as DocNum, 
			ISNULL(Rev,0) as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.vPMDistribution
	UNION ALL
	SELECT 'DAILY' as DocCat, '' as DocType, 
			CAST(DailyLog as VARCHAR(10)) as DocNum, 
			0 as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.bPMDC
	UNION ALL
	SELECT 'OTHER' as DocCat, DocType as DocType, 
			CAST([Document] as VARCHAR(10)) as DocNum, 
			0 as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.bPMOC
	UNION ALL
	SELECT 'PCO' as DocCat, PCOType as DocType, 
			CAST(PCO as VARCHAR(10)) as DocNum, 
			0 as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.bPMCD
	UNION ALL
	SELECT 'SUB' as DocCat, '' as DocType, 
			'' as DocNum, 
			0 as Rev, CAST(SL as VARCHAR(10)) as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SendToFirm as SentToFirm, SendToContact as SentToContact FROM dbo.bPMSS 
	UNION ALL
	SELECT 'TRANSMIT' as DocCat, '' as DocType, 
			CAST(Transmittal as VARCHAR(10)) as DocNum, 
			0 as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.bPMTC
	UNION ALL
	SELECT 'RFI' as DocCat, RFIType as DocType, 
			CAST(RFI as VARCHAR(10)) as DocNum, 
			0 as Rev, '' as SL,  '' as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.bPMRD
	UNION ALL
	SELECT 'RFQ' as DocCat, PCOType as DocType, 
			ISNULL(RFQ,'') as DocNum, 
			0 as Rev, '' as SL,  ISNULL(PCO,'') as PCO,
			PMCo, Project, VendorGroup, SentToFirm, SentToContact FROM dbo.bPMQD) as D

LEFT JOIN dbo.bPMPF P on D.PMCo=P.PMCo and D.Project=P.Project and D.VendorGroup=P.VendorGroup and
						 D.SentToFirm=P.FirmNumber and D.SentToContact=P.ContactCode
LEFT JOIN dbo.bPMPM M on P.VendorGroup=M.VendorGroup and P.FirmNumber=M.FirmNumber and P.ContactCode=M.ContactCode
LEFT JOIN dbo.bPMFM F on M.VendorGroup=F.VendorGroup and M.FirmNumber=F.FirmNumber
WHERE D.DocNum IS NOT NULL 
		AND ((M.EMail IS NOT NULL) AND (LEN(M.EMail) <> 0))
		AND M.ExcludeYN <> 'Y'




GO
GRANT SELECT ON  [dbo].[PMDistributionLists] TO [public]
GRANT INSERT ON  [dbo].[PMDistributionLists] TO [public]
GRANT DELETE ON  [dbo].[PMDistributionLists] TO [public]
GRANT UPDATE ON  [dbo].[PMDistributionLists] TO [public]
GO
