CREATE TABLE [dbo].[vPMRequestForQuoteDetail]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[RFQ] [dbo].[bDocument] NOT NULL,
[RFQItem] [int] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Scope] [dbo].[bFormattedNotes] NULL,
[ScopeButtonText] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMRequestForQuoteDetail_ScopeButtonText] DEFAULT ('Add Notes'),
[Status] [dbo].[bStatus] NULL,
[ROM] [dbo].[bDollar] NULL,
[SentDate] [dbo].[bDate] NULL,
[ReceivedDate] [dbo].[bDate] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Firm] [dbo].[bFirm] NULL,
[Vendor] [dbo].[bVendor] NULL,
[Contact] [dbo].[bEmployee] NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPMRequestForQuoteDetaild] ON [dbo].[vPMRequestForQuoteDetail] FOR DELETE AS
/*-----------------------------------------------------------------
* Created:	GP 03/12/2013 - TFS 13553
* Modified:	
*
* Purpose:	Auditing
*/----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
SET NOCOUNT ON


--Insert master audit record
INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(d.PMCo AS VARCHAR(3)) + ' Project=' + d.Project + ' RFQ=' + d.RFQ + ' RFQItem=' + CAST(d.RFQItem AS VARCHAR(10)), 
	d.PMCo, 'D', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
FROM deleted d


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPMRequestForQuoteDetaili] ON [dbo].[vPMRequestForQuoteDetail] FOR INSERT AS
/*-----------------------------------------------------------------
* Created:	GP 03/12/2013 - TFS 13553
* Modified:	
*
* Purpose:	Auditing
*/----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
SET NOCOUNT ON


--Insert master audit record
INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
	i.PMCo, 'A', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
FROM inserted i



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPMRequestForQuoteDetailu] ON [dbo].[vPMRequestForQuoteDetail] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:	GP 03/12/2013 - TFS 13553
* Modified:	
*
* Purpose:	Auditing
*/----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
SET NOCOUNT ON


--Insert master audit record
IF UPDATE([Description])
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'Description', d.[Description], i.[Description], GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE(Scope)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'Scope', d.Scope, i.Scope, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE([Status])
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'Status', d.[Status], i.[Status], GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE(ROM)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'ROM', d.ROM, i.ROM, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE(SentDate)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'SentDate', d.SentDate, i.SentDate, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE(ReceivedDate)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'ReceivedDate', d.ReceivedDate, i.ReceivedDate, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE(Firm)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'Firm', d.Firm, i.Firm, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE(Vendor)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'Vendor', d.Vendor, i.Vendor, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE(Contact)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'Contact', d.Contact, i.Contact, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END

IF UPDATE(Notes)
BEGIN
	INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 'vPMRequestForQuoteDetail', 'PMCo=' + CAST(i.PMCo AS VARCHAR(3)) + ' Project=' + i.Project + ' RFQ=' + i.RFQ + ' RFQItem=' + CAST(i.RFQItem AS VARCHAR(10)), 
		i.PMCo, 'C', 'Notes', d.Notes, i.Notes, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON d.PMCo = i.PMCo AND d.Project = i.Project AND d.RFQ = i.RFQ AND d.RFQItem = i.RFQItem
END



GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] ADD CONSTRAINT [PK_vPMRequestForQuoteDetail] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vPMRequestForQuoteDetail_RFQItem] ON [dbo].[vPMRequestForQuoteDetail] ([PMCo], [Project], [RFQ], [RFQItem]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] WITH NOCHECK ADD CONSTRAINT [FK_vPMRequestForQuoteDetail_vPMRequestForQuote] FOREIGN KEY ([PMCo], [Project], [RFQ]) REFERENCES [dbo].[vPMRequestForQuote] ([PMCo], [Project], [RFQ])
GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] WITH NOCHECK ADD CONSTRAINT [FK_vPMRequestForQuoteDetail_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] WITH NOCHECK ADD CONSTRAINT [FK_vPMRequestForQuoteDetail_bPMPM] FOREIGN KEY ([VendorGroup], [Firm], [Contact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] WITH NOCHECK ADD CONSTRAINT [FK_vPMRequestForQuoteDetail_bAPVM] FOREIGN KEY ([VendorGroup], [Vendor]) REFERENCES [dbo].[bAPVM] ([VendorGroup], [Vendor])
GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] NOCHECK CONSTRAINT [FK_vPMRequestForQuoteDetail_vPMRequestForQuote]
GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] NOCHECK CONSTRAINT [FK_vPMRequestForQuoteDetail_bPMSC]
GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] NOCHECK CONSTRAINT [FK_vPMRequestForQuoteDetail_bPMPM]
GO
ALTER TABLE [dbo].[vPMRequestForQuoteDetail] NOCHECK CONSTRAINT [FK_vPMRequestForQuoteDetail_bAPVM]
GO
