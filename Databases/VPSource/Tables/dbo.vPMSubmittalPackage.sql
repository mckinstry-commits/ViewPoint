CREATE TABLE [dbo].[vPMSubmittalPackage]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[Package] [dbo].[bDocument] NOT NULL,
[PackageRev] [varchar] (5) COLLATE Latin1_General_BIN NOT NULL,
[CreateDate] [dbo].[bDate] NULL,
[Description] [dbo].[bItemDesc] NULL,
[Status] [dbo].[bStatus] NULL,
[SpecSection] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ApprovingFirm] [dbo].[bFirm] NULL,
[ApprovingContact] [dbo].[bEmployee] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsibleContact] [dbo].[bEmployee] NULL,
[SentDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NULL,
[ReceivedDate] [dbo].[bDate] NULL,
[ReturnedDate] [dbo].[bDate] NULL,
[ActivityID] [int] NULL,
[ActivityDescription] [dbo].[bItemDesc] NULL,
[ActivityDate] [dbo].[bDate] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Closed] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPMSubmittalPackage_Closed] DEFAULT ('N'),
[DocType] [dbo].[bDocType] NULL,
[OurFirm] [dbo].[bFirm] NULL,
[OurFirmContact] [dbo].[bEmployee] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vPMSubmittalPackage] ADD
CONSTRAINT [FK_vPMSubmittalPackage_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************/
CREATE trigger [dbo].[vtPMSubmittalPackaged] on [dbo].[vPMSubmittalPackage] for DELETE as
/*-----------------------------------------------------------------
* Created:	GPT 08/03/12
* Modified:	TRL  09/13/2012 TK-17847 Added code to delete related records in vPMRelateRecord
*			AJW  10/1/12 TK-18131 SBMTL - Package History
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

IF @@rowcount = 0 RETURN
SET NOCOUNT ON


DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName = 'PMSubmittalPackage' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName = 'PMSubmittalPackage' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL

---- document history (PMDH)
INSERT INTO dbo.bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
SELECT d.PMCo, d.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY d.PMCo ASC, d.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 'D', 'Package', d.Package, NULL, SUSER_SNAME(),
		'Package: ' + ISNULL(d.Package,'') + ' Revision: ' + ISNULL(d.PackageRev,'') + ' has been deleted.',
		d.Package, d.PackageRev
FROM DELETED d
LEFT JOIN dbo.bPMDH h ON h.PMCo=d.PMCo and h.Project=d.Project and h.DocCategory='SBMTLPCKG'
JOIN dbo.bPMCO c ON d.PMCo=c.PMCo
LEFT JOIN dbo.bJCJM j ON j.JCCo=d.PMCo and j.Job=d.Project
WHERE j.ClosePurgeFlag <> 'Y' AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
GROUP BY d.PMCo, d.Project, d.Package, d.PackageRev

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************/
CREATE trigger [dbo].[vtPMSubmittalPackagei] on [dbo].[vPMSubmittalPackage] for INSERT as
/*-----------------------------------------------------------------
* Created:	GPT 08/03/12
* Modified:	AJW 10/1/12 TK-18131 SBMTL - Package History
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

IF @@rowcount = 0 RETURN
SET NOCOUNT ON

---- document history (PMDH)
INSERT INTO dbo.bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 'A', 'Package', NULL, i.Package, SUSER_SNAME(),
		'Package: ' + ISNULL(i.Package,'') + ' Revision: ' + ISNULL(i.PackageRev,'') + ' has been added.',
		i.Package, i.PackageRev
FROM INSERTED i
LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SBMTLPCKG'
JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
WHERE ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************/
CREATE TRIGGER [dbo].[vtPMSubmittalPackageu] ON [dbo].[vPMSubmittalPackage] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:	GPT 08/03/12
* Modified:	AJW 10/1/12 TK-18131 SBMTL - Package History
*				TRL  11/22/12 TK-11378 - Added Audits for new columns
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

IF @@rowcount = 0 RETURN
SET NOCOUNT ON

if UPDATE(Description)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'Description', d.Description, i.Description, SUSER_SNAME(), 'Description has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.Description,'') <> ISNULL(i.Description,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.[Description], d.[Description]
end

if UPDATE(Status)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'Status', d.Status, i.Status, SUSER_SNAME(), 'Status has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.Status,'') <> ISNULL(i.Status,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.Status, d.Status
end

if UPDATE(SpecSection)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'SpecSection', d.SpecSection, i.SpecSection, SUSER_SNAME(), 'SpecSection has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.SpecSection,'') <> ISNULL(i.SpecSection,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.SpecSection, d.SpecSection
end

if UPDATE(ApprovingFirm)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ApprovingFirm', d.ApprovingFirm, i.ApprovingFirm, SUSER_SNAME(), 'ApprovingFirm has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ApprovingFirm,'') <> ISNULL(i.ApprovingFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ApprovingFirm, d.ApprovingFirm
end

if UPDATE(ApprovingContact)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ApprovingContact', d.ApprovingContact, i.ApprovingContact, SUSER_SNAME(), 'Approving Contact has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ApprovingContact,'') <> ISNULL(i.ApprovingContact,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ApprovingContact, d.ApprovingContact
end


if UPDATE(ActivityID)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ActivityID', d.ActivityID, i.ActivityID, SUSER_SNAME(), 'Activity ID has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ActivityID,0) <> ISNULL(i.ActivityID,0) AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ActivityID, d.ActivityID
end

if UPDATE(ActivityDescription)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ActivityDescription', d.ActivityDescription, i.ActivityDescription, SUSER_SNAME(), 'Activity Description has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ActivityDescription,'') <> ISNULL(i.ActivityDescription,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ActivityDescription, d.ActivityDescription
end

if UPDATE(ActivityDate)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ActivityDate', d.ActivityDate, i.ActivityDate, SUSER_SNAME(), 'Activity Date has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ActivityDate,'') <> ISNULL(i.ActivityDate,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ActivityDate, d.ActivityDate
end

if UPDATE(VendorGroup)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'VendorGroup', d.VendorGroup, i.VendorGroup, SUSER_SNAME(), 'Vendor Group has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.VendorGroup,'') <> ISNULL(i.VendorGroup,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.VendorGroup, d.VendorGroup
end

if UPDATE(Closed)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'Closed', d.Closed, i.Closed, SUSER_SNAME(), 'Closed has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.Closed,'') <> ISNULL(i.Closed,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.Closed, d.Closed
end

if UPDATE(ResponsibleFirm)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ResponsibleFirm', d.ResponsibleFirm, i.ResponsibleFirm, SUSER_SNAME(), 'ResponsibleFirm has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ResponsibleFirm,'') <> ISNULL(i.ResponsibleFirm,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ResponsibleFirm, d.ResponsibleFirm
end

if UPDATE(ResponsibleContact)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ResponsibleContact', d.ResponsibleContact, i.ResponsibleContact, SUSER_SNAME(), 'Responsible Contact has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ResponsibleContact,'') <> ISNULL(i.ResponsibleContact,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ResponsibleContact, d.ResponsibleContact
end

if UPDATE(CreateDate)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'CreateDate', d.CreateDate, i.CreateDate, SUSER_SNAME(), 'Create Date has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.CreateDate,'') <> ISNULL(i.CreateDate,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.CreateDate, d.CreateDate
end

if UPDATE(SentDate)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'SentDate', d.SentDate, i.SentDate, SUSER_SNAME(), 'Sent Date has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.SentDate,'') <> ISNULL(i.SentDate,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.SentDate, d.SentDate
end

if UPDATE(DueDate)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'DueDate', d.DueDate, i.DueDate, SUSER_SNAME(), 'Due Date has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.DueDate,'') <> ISNULL(i.DueDate,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.DueDate, d.DueDate
end

if UPDATE(ReceivedDate)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ReceivedDate', d.ReceivedDate, i.ReceivedDate, SUSER_SNAME(), 'Received Date has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ReceivedDate,'') <> ISNULL(i.ReceivedDate,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ReceivedDate, d.ReceivedDate
end

if UPDATE(ReturnedDate)
begin
	INSERT INTO dbo.bPMDH (PMCo, Project, Seq, 
		DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, [Action],
		SubmittalPackage, SubmittalPackageRev)
	SELECT i.PMCo, i.Project, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SBMTLPCKG', null, '', NULL, GETDATE(), 
		'C', 'ReturnedDate', d.ReturnedDate, i.ReturnedDate, SUSER_SNAME(), 'Returned Date has been changed.',
		i.Package, i.PackageRev
	FROM INSERTED i
	JOIN DELETED d ON d.PMCo=i.PMCo AND d.Project=i.Project AND d.Package=i.Package and d.PackageRev=i.PackageRev
	LEFT JOIN dbo.bPMDH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.DocCategory='SBMTLPCKG'
	JOIN dbo.bPMCO c ON i.PMCo=c.PMCo
	WHERE ISNULL(d.ReturnedDate,'') <> ISNULL(i.ReturnedDate,'') AND ISNULL(c.DocHistSubmittalRegister,'N') = 'Y'
	GROUP BY i.PMCo, i.Project, i.Package, i.PackageRev, i.ReturnedDate, d.ReturnedDate
end

GO
ALTER TABLE [dbo].[vPMSubmittalPackage] ADD CONSTRAINT [CK_vPMSubmittalPackage_ApprovingContact] CHECK ((NOT ([ApprovingFirm] IS NULL AND [ApprovingContact] IS NOT NULL)))
GO
ALTER TABLE [dbo].[vPMSubmittalPackage] ADD CONSTRAINT [CK_vPMSubmittalPackage_OurFirmContact] CHECK ((NOT ([OurFirm] IS NULL AND [OurFirmContact] IS NOT NULL)))
GO
ALTER TABLE [dbo].[vPMSubmittalPackage] ADD CONSTRAINT [CK_vPMSubmittalPackage_ResponsibleContact] CHECK ((NOT ([ResponsibleFirm] IS NULL AND [ResponsibleContact] IS NOT NULL)))
GO
ALTER TABLE [dbo].[vPMSubmittalPackage] ADD CONSTRAINT [PK_vPMSubmittalPackage] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMSubmittalPackage_PackageRevision] ON [dbo].[vPMSubmittalPackage] ([PMCo], [Project], [Package], [PackageRev]) ON [PRIMARY]
GO
