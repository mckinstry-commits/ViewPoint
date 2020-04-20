CREATE TABLE [dbo].[vPMSubmittal]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[Seq] [bigint] NOT NULL,
[SubmittalNumber] [dbo].[bDocument] NULL,
[SubmittalRev] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[Package] [dbo].[bDocument] NULL,
[PackageRev] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[Details] [dbo].[bNotes] NULL,
[DocumentType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Status] [dbo].[bStatus] NULL,
[SpecSection] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Copies] [tinyint] NULL,
[ApprovingFirm] [dbo].[bFirm] NULL,
[ApprovingFirmContact] [dbo].[bEmployee] NULL,
[OurFirmContact] [dbo].[bEmployee] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsibleFirmContact] [dbo].[bEmployee] NULL,
[Subcontract] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PurchaseOrder] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ActivityID] [int] NULL,
[ActivityDescription] [dbo].[bItemDesc] NULL,
[ActivityDate] [dbo].[bDate] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[DueToResponsibleFirm] [dbo].[bDate] NULL,
[SentToResponsibleFirm] [dbo].[bDate] NULL,
[DueFromResponsibleFirm] [dbo].[bDate] NULL,
[ReceivedFromResponsibleFirm] [dbo].[bDate] NULL,
[ReturnedToResponsibleFirm] [dbo].[bDate] NULL,
[DueToApprovingFirm] [dbo].[bDate] NULL,
[SentToApprovingFirm] [dbo].[bDate] NULL,
[DueFromApprovingFirm] [dbo].[bDate] NULL,
[ReceivedFromApprovingFirm] [dbo].[bDate] NULL,
[LeadDays1] [smallint] NULL,
[LeadDays2] [smallint] NULL,
[LeadDays3] [smallint] NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[OurFirm] [dbo].[bFirm] NULL,
[APCo] [dbo].[bCompany] NULL,
[Closed] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPMSubmittal_Closed] DEFAULT ('N'),
[udEquipmentTag] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udOtherTag] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udManufacturer] [dbo].[bItemDesc] NULL,
[udVendor] [dbo].[bVendor] NULL,
[udDateSubNotified] [smalldatetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**********************************************/
CREATE trigger [dbo].[vtPMSubmittald] on [dbo].[vPMSubmittal] for DELETE as
/*-----------------------------------------------------------------
* Created:	NH 08/02/12
* Modified:	  TRL  09/13/2012 TK-17847 Added code to delete related records in vPMRelateRecord
*			GP 09/18/2012 - TK-17982  Added document history insert
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

if @@rowcount = 0 return
set nocount on



DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName = 'PMSubmittal' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName = 'PMSubmittal' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- document history (PMDH)
INSERT INTO dbo.bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
SELECT d.PMCo, d.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY d.PMCo ASC, d.Project ASC, d.Seq ASC),
		'SBMTL', d.DocumentType, '', NULL, GETDATE(), 'D', 'SubmittalNumber', d.SubmittalNumber, NULL, SUSER_SNAME(),
		'Submittal: ' + ISNULL(d.SubmittalNumber,'') + ' Revision: ' + ISNULL(d.SubmittalRev,'') + ' has been deleted.',
		d.SubmittalNumber, d.SubmittalRev, d.Seq
FROM DELETED d
LEFT JOIN dbo.bPMDH h ON h.PMCo=d.PMCo and h.Project=d.Project and h.DocCategory='SBMTL'
JOIN dbo.bPMCO c ON d.PMCo=c.PMCo
LEFT JOIN dbo.bJCJM j ON j.JCCo=d.PMCo and j.Job=d.Project
WHERE j.ClosePurgeFlag <> 'Y' AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
GROUP BY d.PMCo, d.Project, d.Seq, d.SubmittalNumber, d.SubmittalRev, d.DocumentType


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**********************************************/
CREATE trigger [dbo].[vtPMSubmittali] on [dbo].[vPMSubmittal] for INSERT as
/*-----------------------------------------------------------------
* Created:	NH 08/02/12
* Modified:	GP 09/18/2012 - TK-17982 Added document history insert
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

if @@rowcount = 0 return
set nocount on

---- document history (PMDH)
INSERT INTO dbo.bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 'A', 'SubmittalNumber', NULL, i.SubmittalNumber, SUSER_SNAME(),
		'Submittal: ' + ISNULL(i.SubmittalNumber,'') + ' Revision: ' + ISNULL(i.SubmittalRev,'') + ' has been added.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
FROM INSERTED i
LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SBMTL'
JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
WHERE ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************/
CREATE trigger [dbo].[vtPMSubmittalu] on [dbo].[vPMSubmittal] for UPDATE as
/*-----------------------------------------------------------------
* Created:	NH 08/02/12
* Modified:	GP 09/18/2012 - TK-17982  Added document history insert
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

if @@rowcount = 0 return
set nocount on

---- document history (bPMDH)
IF UPDATE(SubmittalNumber)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'SubmittalNumber', d.SubmittalNumber, i.SubmittalNumber, SUSER_SNAME(), 'Submittal Number has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.SubmittalNumber,'') <> ISNULL(i.SubmittalNumber,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, d.SubmittalNumber
END

IF UPDATE(SubmittalRev)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'SubmittalRev', d.SubmittalRev, i.SubmittalRev, SUSER_SNAME(), 'Submittal Revision has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.SubmittalRev,'') <> ISNULL(i.SubmittalRev,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, d.SubmittalRev
END

IF UPDATE(Package)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'Package', d.Package, i.Package, SUSER_SNAME(), 'Package has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.Package,'') <> ISNULL(i.Package,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.Package, d.Package
END

IF UPDATE(PackageRev)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'PackageRev', d.PackageRev, i.PackageRev, SUSER_SNAME(), 'PackageRev has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.PackageRev,'') <> ISNULL(i.PackageRev,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.PackageRev, d.PackageRev
END

IF UPDATE([Description])
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'Description', d.[Description], i.[Description], SUSER_SNAME(), 'Description has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.[Description],'') <> ISNULL(i.[Description],'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.[Description], d.[Description]
END

IF UPDATE(Details)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'Details', d.Details, i.Details, SUSER_SNAME(), 'Details has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.Details,'') <> ISNULL(i.Details,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.Details, d.Details
END

IF UPDATE(DocumentType)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'DocumentType', d.DocumentType, i.DocumentType, SUSER_SNAME(), 'DocumentType has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.DocumentType,'') <> ISNULL(i.DocumentType,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.DocumentType, d.DocumentType
END

IF UPDATE([Status])
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'Status', d.[Status], i.[Status], SUSER_SNAME(), 'Status has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.[Status],'') <> ISNULL(i.[Status],'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.[Status], d.[Status]
END

IF UPDATE(SpecSection)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'SpecSection', d.SpecSection, i.SpecSection, SUSER_SNAME(), 'SpecSection has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.SpecSection,'') <> ISNULL(i.SpecSection,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.SpecSection, d.SpecSection
END

IF UPDATE(Copies)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'Copies', d.Copies, i.Copies, SUSER_SNAME(), 'Copies has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.Copies,'') <> ISNULL(i.Copies,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.Copies, d.Copies
END

IF UPDATE(ApprovingFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ApprovingFirm', d.ApprovingFirm, i.ApprovingFirm, SUSER_SNAME(), 'ApprovingFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ApprovingFirm,'') <> ISNULL(i.ApprovingFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ApprovingFirm, d.ApprovingFirm
END

IF UPDATE(ApprovingFirmContact)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ApprovingFirmContact', d.ApprovingFirmContact, i.ApprovingFirmContact, SUSER_SNAME(), 'ApprovingFirmContact has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ApprovingFirmContact,'') <> ISNULL(i.ApprovingFirmContact,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ApprovingFirmContact, d.ApprovingFirmContact
END

IF UPDATE(OurFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'OurFirm', d.OurFirm, i.OurFirm, SUSER_SNAME(), 'OurFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.OurFirm,'') <> ISNULL(i.OurFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.OurFirm, d.OurFirm
END

IF UPDATE(OurFirmContact)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'OurFirmContact', d.OurFirmContact, i.OurFirmContact, SUSER_SNAME(), 'OurFirmContact has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.OurFirmContact,'') <> ISNULL(i.OurFirmContact,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.OurFirmContact, d.OurFirmContact
END

IF UPDATE(ResponsibleFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ResponsibleFirm', d.ResponsibleFirm, i.ResponsibleFirm, SUSER_SNAME(), 'ResponsibleFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ResponsibleFirm,'') <> ISNULL(i.ResponsibleFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ResponsibleFirm, d.ResponsibleFirm
END

IF UPDATE(ResponsibleFirmContact)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ResponsibleFirmContact', d.ResponsibleFirmContact, i.ResponsibleFirmContact, SUSER_SNAME(), 'ResponsibleFirmContact has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ResponsibleFirmContact,'') <> ISNULL(i.ResponsibleFirmContact,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ResponsibleFirmContact, d.ResponsibleFirmContact
END

IF UPDATE(Subcontract)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'Subcontract', d.Subcontract, i.Subcontract, SUSER_SNAME(), 'Subcontract has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.Subcontract,'') <> ISNULL(i.Subcontract,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.Subcontract, d.Subcontract
END

IF UPDATE(PurchaseOrder)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'PurchaseOrder', d.PurchaseOrder, i.PurchaseOrder, SUSER_SNAME(), 'PurchaseOrder has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.PurchaseOrder,'') <> ISNULL(i.PurchaseOrder,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.PurchaseOrder, d.PurchaseOrder
END

IF UPDATE(ActivityID)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ActivityID', d.ActivityID, i.ActivityID, SUSER_SNAME(), 'ActivityID has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ActivityID,'') <> ISNULL(i.ActivityID,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ActivityID, d.ActivityID
END

IF UPDATE(ActivityDescription)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ActivityDescription', d.ActivityDescription, i.ActivityDescription, SUSER_SNAME(), 'ActivityDescription has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ActivityDescription,'') <> ISNULL(i.ActivityDescription,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ActivityDescription, d.ActivityDescription
END

IF UPDATE(ActivityDate)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ActivityDate', d.ActivityDate, i.ActivityDate, SUSER_SNAME(), 'ActivityDate has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ActivityDate,'') <> ISNULL(i.ActivityDate,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ActivityDate, d.ActivityDate
END

IF UPDATE(VendorGroup)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'VendorGroup', d.VendorGroup, i.VendorGroup, SUSER_SNAME(), 'VendorGroup has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.VendorGroup,'') <> ISNULL(i.VendorGroup,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.VendorGroup, d.VendorGroup
END

IF UPDATE(DueToResponsibleFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'DueToResponsibleFirm', d.DueToResponsibleFirm, i.DueToResponsibleFirm, SUSER_SNAME(), 'DueToResponsibleFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.DueToResponsibleFirm,'') <> ISNULL(i.DueToResponsibleFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.DueToResponsibleFirm, d.DueToResponsibleFirm
END

IF UPDATE(SentToResponsibleFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'SentToResponsibleFirm', d.SentToResponsibleFirm, i.SentToResponsibleFirm, SUSER_SNAME(), 'SentToResponsibleFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.SentToResponsibleFirm,'') <> ISNULL(i.SentToResponsibleFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.SentToResponsibleFirm, d.SentToResponsibleFirm
END

IF UPDATE(DueFromResponsibleFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'DueFromResponsibleFirm', d.DueFromResponsibleFirm, i.DueFromResponsibleFirm, SUSER_SNAME(), 'DueFromResponsibleFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.DueFromResponsibleFirm,'') <> ISNULL(i.DueFromResponsibleFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.DueFromResponsibleFirm, d.DueFromResponsibleFirm
END

IF UPDATE(ReceivedFromResponsibleFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ReceivedFromResponsibleFirm', d.ReceivedFromResponsibleFirm, i.ReceivedFromResponsibleFirm, SUSER_SNAME(), 'ReceivedFromResponsibleFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ReceivedFromResponsibleFirm,'') <> ISNULL(i.ReceivedFromResponsibleFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ReceivedFromResponsibleFirm, d.ReceivedFromResponsibleFirm
END

IF UPDATE(ReturnedToResponsibleFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ReturnedToResponsibleFirm', d.ReturnedToResponsibleFirm, i.ReturnedToResponsibleFirm, SUSER_SNAME(), 'ReturnedToResponsibleFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ReturnedToResponsibleFirm,'') <> ISNULL(i.ReturnedToResponsibleFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ReturnedToResponsibleFirm, d.ReturnedToResponsibleFirm
END

IF UPDATE(DueToApprovingFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'DueToApprovingFirm', d.DueToApprovingFirm, i.DueToApprovingFirm, SUSER_SNAME(), 'DueToApprovingFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.DueToApprovingFirm,'') <> ISNULL(i.DueToApprovingFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.DueToApprovingFirm, d.DueToApprovingFirm
END

IF UPDATE(SentToApprovingFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'SentToApprovingFirm', d.SentToApprovingFirm, i.SentToApprovingFirm, SUSER_SNAME(), 'SentToApprovingFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.SentToApprovingFirm,'') <> ISNULL(i.SentToApprovingFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.SentToApprovingFirm, d.SentToApprovingFirm
END

IF UPDATE(DueFromApprovingFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'DueFromApprovingFirm', d.DueFromApprovingFirm, i.DueFromApprovingFirm, SUSER_SNAME(), 'DueFromApprovingFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.DueFromApprovingFirm,'') <> ISNULL(i.DueFromApprovingFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.DueFromApprovingFirm, d.DueFromApprovingFirm
END

IF UPDATE(ReceivedFromApprovingFirm)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'ReceivedFromApprovingFirm', d.ReceivedFromApprovingFirm, i.ReceivedFromApprovingFirm, SUSER_SNAME(), 'ReceivedFromApprovingFirm has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ReceivedFromApprovingFirm,'') <> ISNULL(i.ReceivedFromApprovingFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.ReceivedFromApprovingFirm, d.ReceivedFromApprovingFirm
END

IF UPDATE(APCo)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'APCo', d.APCo, i.APCo, SUSER_SNAME(), 'APCo has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.APCo,'') <> ISNULL(i.APCo,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.APCo, d.APCo
END

IF UPDATE(Closed)
BEGIN
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalRegisterNumber, SubmittalRegisterRev, SubmittalRegisterSeq)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Seq ASC),
		'SBMTL', i.DocumentType, '', NULL, GETDATE(), 
		'C', 'Closed', d.Closed, i.Closed, SUSER_SNAME(), 'Closed has been changed.',
		i.SubmittalNumber, i.SubmittalRev, i.Seq
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Seq=i.Seq
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTL'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.Closed,'') <> ISNULL(i.Closed,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Seq, i.SubmittalNumber, i.SubmittalRev, i.DocumentType, i.Closed, d.Closed
END



GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [CK_vPMSubmittal_APCo] CHECK ((NOT ([APCo] IS NULL AND ([PurchaseOrder] IS NOT NULL OR [Subcontract] IS NOT NULL))))
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [CK_vPMSubmittal_ApprovingFirmContact] CHECK ((NOT ([ApprovingFirm] IS NULL AND [ApprovingFirmContact] IS NOT NULL)))
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [CK_vPMSubmittal_OurFirmContact] CHECK ((NOT ([OurFirm] IS NULL AND [OurFirmContact] IS NOT NULL)))
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [CK_vPMSubmittal_ResponsibleFirmContact] CHECK ((NOT ([ResponsibleFirm] IS NULL AND [ResponsibleFirmContact] IS NOT NULL)))
GO
ALTER TABLE [dbo].[vPMSubmittal] ADD CONSTRAINT [PK_vPMSubmittal] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMSubmittalSeq] ON [dbo].[vPMSubmittal] ([PMCo], [Project], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bPOHD_PurchaseOrder] FOREIGN KEY ([APCo], [PurchaseOrder]) REFERENCES [dbo].[bPOHD] ([POCo], [PO])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bSLHD_Subcontract] FOREIGN KEY ([APCo], [Subcontract]) REFERENCES [dbo].[bSLHD] ([SLCo], [SL])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_vPMSubmittalPackage] FOREIGN KEY ([PMCo], [Project], [Package], [PackageRev]) REFERENCES [dbo].[vPMSubmittalPackage] ([PMCo], [Project], [Package], [PackageRev])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bPMFM_ApprovingFirm] FOREIGN KEY ([VendorGroup], [ApprovingFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bPMPM_ApprovingFirm] FOREIGN KEY ([VendorGroup], [ApprovingFirm], [ApprovingFirmContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bPMFM_OurFirm] FOREIGN KEY ([VendorGroup], [OurFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bPMPM_OurFirm] FOREIGN KEY ([VendorGroup], [OurFirm], [OurFirmContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bPMFM_ResponsibleFirm] FOREIGN KEY ([VendorGroup], [ResponsibleFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[vPMSubmittal] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubmittal_bPMPM_ResponsibleFirm] FOREIGN KEY ([VendorGroup], [ResponsibleFirm], [ResponsibleFirmContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bPOHD_PurchaseOrder]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bSLHD_Subcontract]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bJCJM]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_vPMSubmittalPackage]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bPMFM_ApprovingFirm]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bPMPM_ApprovingFirm]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bPMFM_OurFirm]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bPMPM_OurFirm]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bPMFM_ResponsibleFirm]
GO
ALTER TABLE [dbo].[vPMSubmittal] NOCHECK CONSTRAINT [FK_vPMSubmittal_bPMPM_ResponsibleFirm]
GO
