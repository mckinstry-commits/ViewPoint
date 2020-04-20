SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[PMDocDistribution] as
-- =============================================
-- Author:		AJW - Returns the Distribution Contacts for PMCT.DocCat
-- Create date: 12/12/12
-- Modified:	GP 01/15/13 - TK-20491 Added Daily Log and Purchase Order
--
-- Current mapping by doc type otherwise empty dataset
-- DocType,			DistributionTable,	SourceTable 
-- COR,				PMDistribution,		PMChangeOrderRequest
-- CCO,				PMDistribution,		PMContractChangeOrder
-- DRAWING,			PMDistribution,		PMDG
-- INSPECT,			PMDistribution,		PMIL
-- ISSUE,			PMDistribution,		PMIM
-- OTHER,			PMOC,				PMOD
-- PCO,				PMCD,				PMOP
-- POCO,			PMDistribution,		PMPOCO
-- RFI,				PMRD,				PMRI
-- RFQ,				PMQD,				PMRQ
-- (SUB,SUBITEM)**	PMSS,				SLHD  
-- SUBCO,			PMDistribution,		PMChangeOrderRequest
-- SUBMIT,			PMDistribution,		PMSM
-- TEST,			PMDistribution,		PMTL
-- TRANSMIT,		PMTC,				PMTM
-- DAILYLOG,		PMDC,				PMDL
-- PURCHASE,		PMDistribution,		POHDPM
--
-- ** View only returns distribution for 'SUB' SUBITEM DocCat is ths same result
-- =============================================

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='COR',DocKeyID=b.KeyID
  FROM PMDistribution a
  JOIN PMChangeOrderRequest b on b.KeyID=a.CORID

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='CCO',DocKeyID=b.KeyID
  FROM PMDistribution a
  JOIN PMContractChangeOrder b on b.KeyID=a.ContractCOID

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='DRAWING',DocKeyID=b.KeyID
  FROM PMDistribution a
  JOIN PMDG b on b.KeyID=a.DrawingLogID

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='INSPECT',DocKeyID=b.KeyID
    FROM PMDistribution a
  JOIN PMIL b on b.KeyID=a.InspectionLogID

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='ISSUE',DocKeyID=b.KeyID
    FROM PMDistribution a
  JOIN PMIM b on b.KeyID=a.IssueID

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='OTHER',DocKeyID=b.KeyID
    FROM PMOC a
  JOIN PMOD b on b.PMCo=a.PMCo and b.Project=a.Project and b.DocType=a.DocType and b.Document=a.Document

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='PCO',DocKeyID=b.KeyID
  FROM PMCD a
  JOIN PMOP b on b.PMCo=a.PMCo and b.Project=a.Project and b.PCOType=a.PCOType and b.PCO=a.PCO

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='POCO',DocKeyID=b.KeyID
  FROM PMDistribution a
  JOIN PMPOCO b on b.KeyID=a.POCOID

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='RFI',DocKeyID=b.KeyID
  FROM PMRD a
  JOIN PMRI b on b.PMCo=a.PMCo and b.Project=a.Project and b.RFIType=a.RFIType and b.RFI=a.RFI

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='RFQ',DocKeyID=b.KeyID
  FROM PMQD a
  JOIN PMRQ b on b.PMCo=a.PMCo and b.Project=a.Project and b.PCOType=a.PCOType and b.PCO=a.PCO and b.RFQ=a.RFQ

UNION ALL

  Select a.VendorGroup,a.SendToFirm as SentToFirm,a.SendToContact as SentToContact,'Y' as Send,'N' as CC, PMPM.PrefMethod,DocCat='SUB',DocKeyID=b.KeyID
  FROM PMSS a
  JOIN SLHD b on a.PMCo=b.JCCo and a.Project=b.Job and a.SLCo=b.SLCo and a.SL=b.SL
  JOIN PMPM on a.VendorGroup=PMPM.VendorGroup and a.SendToFirm=PMPM.FirmNumber and a.SendToContact=PMPM.ContactCode

UNION ALL

  Select a.VendorGroup,a.SendToFirm as SentToFirm,a.SendToContact as SentToContact,'Y' as Send,'N' as CC, PMPM.PrefMethod,DocCat='SUBITEM',DocKeyID=b.KeyID
  FROM PMSS a
  JOIN SLHD b on a.PMCo=b.JCCo and a.Project=b.Job and a.SLCo=b.SLCo and a.SL=b.SL
  JOIN PMPM on a.VendorGroup=PMPM.VendorGroup and a.SendToFirm=PMPM.FirmNumber and a.SendToContact=PMPM.ContactCode

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='SUBCO',DocKeyID=b.KeyID
  FROM PMDistribution a
  JOIN PMSubcontractCO b on b.KeyID=a.SubcontractCOID

 UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='SUBMIT',DocKeyID=b.KeyID
  FROM PMDistribution a
  JOIN PMSM b on b.KeyID=a.SubmittalID

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='TEST',DocKeyID=b.KeyID
  FROM PMDistribution a
  JOIN PMTL b on b.KeyID=a.TestLogID

UNION ALL

  Select a.VendorGroup,a.SentToFirm,a.SentToContact,a.Send,a.CC,a.PrefMethod,DocCat='TRANSMIT',DocKeyID=b.KeyID
  FROM PMTC a
  JOIN PMTM b on b.PMCo=a.PMCo and b.Project=a.Project and b.Transmittal=a.Transmittal

UNION ALL

SELECT PMCO.VendorGroup, PMDC.SentToFirm, PMDC.SentToContact, 'Y', PMDC.CC, PMPM.PrefMethod, DocCat = 'DAILYLOG', DocKeyID = PMDL.KeyID
FROM PMDL
JOIN PMDC ON PMDC.PMCo = PMDL.PMCo AND PMDC.Project = PMDL.Project AND PMDC.LogDate = PMDL.LogDate AND PMDC.DailyLog = PMDL.DailyLog
JOIN PMCO ON PMCO.PMCo = PMDL.PMCo
JOIN PMPM on PMPM.VendorGroup = PMCO.VendorGroup and PMPM.FirmNumber = PMDC.SentToFirm and PMPM.ContactCode = PMDC.SentToContact

UNION ALL

SELECT a.VendorGroup, a.SentToFirm, a.SentToContact, a.Send, a.CC, a.PrefMethod, DocCat = 'PURCHASE', DocKeyID = b.KeyID
FROM PMDistribution a
JOIN POHDPM b ON b.KeyID = a.PurchaseOrderID


GO
GRANT SELECT ON  [dbo].[PMDocDistribution] TO [public]
GRANT INSERT ON  [dbo].[PMDocDistribution] TO [public]
GRANT DELETE ON  [dbo].[PMDocDistribution] TO [public]
GRANT UPDATE ON  [dbo].[PMDocDistribution] TO [public]
GO
