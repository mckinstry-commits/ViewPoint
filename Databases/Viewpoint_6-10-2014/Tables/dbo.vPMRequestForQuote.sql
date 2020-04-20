CREATE TABLE [dbo].[vPMRequestForQuote]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[RFQ] [dbo].[bDocument] NOT NULL,
[CreateDate] [dbo].[bDate] NOT NULL CONSTRAINT [DF_vPMRequestForQuote_CreateDate] DEFAULT (dateadd(day,(0),datediff(day,(0),getdate()))),
[SentDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NULL,
[Description] [dbo].[bItemDesc] NULL,
[Scope] [dbo].[bFormattedNotes] NULL,
[ScopeButtonText] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMRequestForQuote_ScopeButtonText] DEFAULT ('Add Notes'),
[Status] [dbo].[bStatus] NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PMRQKeyID] [bigint] NULL,
[ReceivedDate] [dbo].[bDate] NULL,
[DocType] [dbo].[bDocType] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[FirmNumber] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPMRequestForQuoted] ON [dbo].[vPMRequestForQuote] FOR DELETE AS
/*-----------------------------------------------------------------
* Created:	GP 03/12/2013 - TFS 13553
* Modified:	GP 03/18/2013 - TFS 13553 Added PMDH audit
*
* Purpose:	Auditing
*/----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
SET NOCOUNT ON


--Insert master audit record
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(d.PMCo AS VARCHAR(3)) + ' Project=' + d.Project + ' RFQ=' + d.RFQ, d.PMCo, 'D', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
FROM deleted d

--Insert pm document history record
INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
	ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
SELECT d.PMCo, d.Project, d.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY d.PMCo ASC, d.Project ASC), 
	GETDATE(), 'RFQ: ' + d.RFQ + ' has been deleted.', 'RFQ', 'D', 'RFQ', d.RFQ, NULL, SUSER_SNAME()
FROM deleted d
LEFT JOIN dbo.bPMDH h ON h.PMCo = d.PMCo and h.Project = d.Project and h.DocCategory = 'RFQ'
JOIN dbo.bPMCO c ON c.PMCo = d.PMCo
WHERE c.DocHistRFQ = 'Y'
GROUP BY d.PMCo, d.Project, d.RFQ

---- delete associations if any from both sides
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMRequestForQuote' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMRequestForQuote' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPMRequestForQuotei] ON [dbo].[vPMRequestForQuote] FOR INSERT AS
/*-----------------------------------------------------------------
* Created:	GP 03/12/2013 - TFS 13553
* Modified:	GP 03/18/2013 - TFS 13553 Added PMDH audit
*
* Purpose:	Auditing
*/----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
SET NOCOUNT ON


--Insert master audit record
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ, i.PMCo, 'A', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
FROM inserted i

--Insert pm document history record
INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
	ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
SELECT i.PMCo, i.Project, i.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC), 
	GETDATE(), 'RFQ: ' + i.RFQ + ' has been created.', 'RFQ', 'A', 'RFQ', NULL, i.RFQ, SUSER_SNAME()
FROM inserted i
LEFT JOIN dbo.bPMDH h ON h.PMCo = i.PMCo and h.Project = i.Project and h.DocCategory = 'RFQ'
JOIN dbo.bPMCO c ON c.PMCo = i.PMCo
WHERE c.DocHistRFQ = 'Y'
GROUP BY i.PMCo, i.Project, i.RFQ


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPMRequestForQuoteu] ON [dbo].[vPMRequestForQuote] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:	GP 03/12/2013 - TFS 13553
* Modified:	GP 03/18/2013 - TFS 13553 Added PMDH audit
*
* Purpose:	Auditing
*/----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
SET NOCOUNT ON


--Insert master audit record
--Insert pm document history record
IF UPDATE(CreateDate)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ, i.PMCo, 'C', 'CreateDate', d.CreateDate, i.CreateDate, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ

	INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
		ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
	SELECT i.PMCo, i.Project, i.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC), 
		GETDATE(), 'CreateDate has been updated.', 'RFQ', 'C', 'CreateDate', d.CreateDate, i.CreateDate, SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ
	LEFT JOIN dbo.bPMDH h ON h.PMCo = i.PMCo and h.Project = i.Project and h.DocCategory = 'RFQ'
	JOIN dbo.bPMCO c ON c.PMCo = i.PMCo
	WHERE c.DocHistRFQ = 'Y'
	GROUP BY i.PMCo, i.Project, i.RFQ, d.CreateDate, i.CreateDate
END

IF UPDATE(SentDate)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ, i.PMCo, 'C', 'SentDate', d.SentDate, i.SentDate, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ

	INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
		ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
	SELECT i.PMCo, i.Project, i.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC), 
		GETDATE(), 'SentDate has been updated.', 'RFQ', 'C', 'SentDate', d.SentDate, i.SentDate, SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ
	LEFT JOIN dbo.bPMDH h ON h.PMCo = i.PMCo and h.Project = i.Project and h.DocCategory = 'RFQ'
	JOIN dbo.bPMCO c ON c.PMCo = i.PMCo
	WHERE c.DocHistRFQ = 'Y'
	GROUP BY i.PMCo, i.Project, i.RFQ, d.SentDate, i.SentDate
END

IF UPDATE(DueDate)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ, i.PMCo, 'C', 'DueDate', d.DueDate, i.DueDate, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ

	INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
		ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
	SELECT i.PMCo, i.Project, i.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC), 
		GETDATE(), 'DueDate has been updated.', 'RFQ', 'C', 'DueDate', d.DueDate, i.DueDate, SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ
	LEFT JOIN dbo.bPMDH h ON h.PMCo = i.PMCo and h.Project = i.Project and h.DocCategory = 'RFQ'
	JOIN dbo.bPMCO c ON c.PMCo = i.PMCo
	WHERE c.DocHistRFQ = 'Y'
	GROUP BY i.PMCo, i.Project, i.RFQ, d.DueDate, i.DueDate
END

IF UPDATE([Description])
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ, i.PMCo, 'C', 'Description', d.[Description], i.[Description], GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ

	INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
		ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
	SELECT i.PMCo, i.Project, i.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC), 
		GETDATE(), 'Description has been updated.', 'RFQ', 'C', 'Description', d.[Description], i.[Description], SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ
	LEFT JOIN dbo.bPMDH h ON h.PMCo = i.PMCo and h.Project = i.Project and h.DocCategory = 'RFQ'
	JOIN dbo.bPMCO c ON c.PMCo = i.PMCo
	WHERE c.DocHistRFQ = 'Y'
	GROUP BY i.PMCo, i.Project, i.RFQ, d.[Description], i.[Description]
END

IF UPDATE(Scope)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ, i.PMCo, 'C', 'Scope', d.Scope, i.Scope, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ

	INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
		ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
	SELECT i.PMCo, i.Project, i.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC), 
		GETDATE(), 'Scope has been updated.', 'RFQ', 'C', 'Scope', NULL, NULL, SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ
	LEFT JOIN dbo.bPMDH h ON h.PMCo = i.PMCo and h.Project = i.Project and h.DocCategory = 'RFQ'
	JOIN dbo.bPMCO c ON c.PMCo = i.PMCo
	WHERE c.DocHistRFQ = 'Y'
	GROUP BY i.PMCo, i.Project, i.RFQ, d.Scope, i.Scope
END

IF UPDATE([Status])
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ, i.PMCo, 'C', 'Status', d.[Status], i.[Status], GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ

	INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
		ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
	SELECT i.PMCo, i.Project, i.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC), 
		GETDATE(), 'Status has been updated.', 'RFQ', 'C', 'Status', d.[Status], i.[Status], SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ
	LEFT JOIN dbo.bPMDH h ON h.PMCo = i.PMCo and h.Project = i.Project and h.DocCategory = 'RFQ'
	JOIN dbo.bPMCO c ON c.PMCo = i.PMCo
	WHERE c.DocHistRFQ = 'Y'
	GROUP BY i.PMCo, i.Project, i.RFQ, d.[Status], i.[Status]
END

IF UPDATE(Notes)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuote', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ, i.PMCo, 'C', 'Notes', d.Notes, i.Notes, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ

	INSERT dbo.bPMDH (PMCo, Project, Document, Seq, 
		ActionDateTime, [Action], DocCategory, FieldType, FieldName, OldValue, NewValue, UserName)
	SELECT i.PMCo, i.Project, i.RFQ, ISNULL(MAX(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC), 
		GETDATE(), 'Notes has been updated.', 'RFQ', 'C', 'Notes', NULL, NULL, SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ
	LEFT JOIN dbo.bPMDH h ON h.PMCo = i.PMCo and h.Project = i.Project and h.DocCategory = 'RFQ'
	JOIN dbo.bPMCO c ON c.PMCo = i.PMCo
	WHERE c.DocHistRFQ = 'Y'
	GROUP BY i.PMCo, i.Project, i.RFQ, d.Notes, i.Notes
END


GO
ALTER TABLE [dbo].[vPMRequestForQuote] ADD CONSTRAINT [PK_vPMRequestForQuote] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vPMRequestForQuote_RFQ] ON [dbo].[vPMRequestForQuote] ([PMCo], [Project], [RFQ]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMRequestForQuote] WITH NOCHECK ADD CONSTRAINT [FK_vPMRequestForQuote_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[vPMRequestForQuote] WITH NOCHECK ADD CONSTRAINT [FK_vPMRequestForQuote_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[vPMRequestForQuote] WITH NOCHECK ADD CONSTRAINT [FK_vPMRequestForQuote_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[vPMRequestForQuote] NOCHECK CONSTRAINT [FK_vPMRequestForQuote_bPMDT]
GO
ALTER TABLE [dbo].[vPMRequestForQuote] NOCHECK CONSTRAINT [FK_vPMRequestForQuote_bJCJM]
GO
ALTER TABLE [dbo].[vPMRequestForQuote] NOCHECK CONSTRAINT [FK_vPMRequestForQuote_bPMSC]
GO
