CREATE TABLE [dbo].[bHQAO]
(
[TempDirectory] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PermanentDirectory] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ByCompany] [dbo].[bYN] NULL,
[ByModule] [dbo].[bYN] NULL,
[ByForm] [dbo].[bYN] NULL,
[ByMonth] [dbo].[bYN] NULL,
[Custom] [dbo].[bYN] NULL,
[CustomFormat] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[UseJPG] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAO_UseJPG] DEFAULT ('N'),
[UseStructForAttYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAO_UseStructForAttYN] DEFAULT ('N'),
[SaveToDatabase] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAO_SaveToDatabase] DEFAULT ('N'),
[ScanningFileFormat] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHQAO_ScanningFileFormat] DEFAULT ('TIF'),
[CreateStandAloneOnDelete] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAO_CreateStandAloneOnDelete] DEFAULT ('Y'),
[UseAuditing] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAO_UseAuditing] DEFAULT ('Y'),
[ArchiveDeletedAttachments] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAO_ArchiveDeletedAttachments] DEFAULT ('N'),
[PdfResolution] [int] NOT NULL CONSTRAINT [DF_bHQAO_PdfResolution] DEFAULT ((120)),
[UseViewpointViewer] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAO_UseViewpointViewer] DEFAULT ('Y'),
[AttachmentDatabaseServer] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHQAO_AttachmentDatabaseServer] DEFAULT (''),
[AttachmentDatabaseName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHQAO_AttachmentDatabaseName] DEFAULT ('')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQAOi] on [dbo].[bHQAO] for INSERT as
/*-----------------------------------------------------------------
* Created:	JonathanP 05/18/2007
* Modified:	
*
*	This Trigger updates the HQ Master Audit table
*
*/----------------------------------------------------------------


insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHQAO', 'There is no keystring for this table.', null, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[btHQAOu] on [dbo].[bHQAO] for update as
/*-----------------------------------------------------------------
* Created:	JonathanP 05/18/2007
* Modified:	JonathanP 01/25/2010 - Updated to include all the columns that have been added 
*								   in the last few years.
*
*	This Trigger updates the HQ Master Audit table
*
*/----------------------------------------------------------------

if UPDATE(TempDirectory)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'TempDirectory', d.TempDirectory, 
			i.TempDirectory, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.TempDirectory, '') <> ISNULL(d.TempDirectory,'')
end

if UPDATE(PermanentDirectory)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'PermanentDirectory', d.PermanentDirectory, 
			i.PermanentDirectory, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.PermanentDirectory, '') <> ISNULL(d.PermanentDirectory,'')
end

if UPDATE(ByCompany)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'ByCompany', d.ByCompany, 
			i.ByCompany, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.ByCompany, '') <> ISNULL(d.ByCompany,'')
end

if UPDATE(ByModule)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'ByModule', d.ByModule, 
			i.ByModule, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.ByModule, '') <> ISNULL(d.ByModule,'')
end

if UPDATE(ByForm)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'ByForm', d.ByForm, 
			i.ByForm, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.ByForm, '') <> ISNULL(d.ByForm,'')
end

if UPDATE(ByMonth)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'ByMonth', d.ByMonth, 
			i.ByMonth, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.ByMonth, '') <> ISNULL(d.ByMonth,'')
end

if UPDATE(Custom)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'Custom', d.Custom, 
			i.Custom, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.Custom, '') <> ISNULL(d.Custom,'')
end

if UPDATE(CustomFormat)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'CustomFormat', d.CustomFormat, 
			i.CustomFormat, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.CustomFormat, '') <> ISNULL(d.CustomFormat,'')
end

if UPDATE(UseJPG)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'UseJPG', d.UseJPG, 
			i.UseJPG, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.UseJPG, '') <> ISNULL(d.UseJPG,'')
end

if UPDATE(UseStructForAttYN)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'UseStructForAttYN', d.UseStructForAttYN, 
			i.UseStructForAttYN, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.UseStructForAttYN, '') <> ISNULL(d.UseStructForAttYN,'')
end

if UPDATE(SaveToDatabase)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'SaveToDatabase', d.SaveToDatabase, 
			i.SaveToDatabase, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.SaveToDatabase, '') <> ISNULL(d.SaveToDatabase,'')
end

if UPDATE(ScanningFileFormat)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'ScanningFileFormat', d.ScanningFileFormat, 
			i.ScanningFileFormat, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.ScanningFileFormat, '') <> ISNULL(d.ScanningFileFormat,'')
end

if UPDATE(CreateStandAloneOnDelete)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'CreateStandAloneOnDelete', d.CreateStandAloneOnDelete, 
			i.CreateStandAloneOnDelete, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.CreateStandAloneOnDelete, '') <> ISNULL(d.CreateStandAloneOnDelete,'')
end

if UPDATE(UseAuditing)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'UseAuditing', d.UseAuditing, 
			i.UseAuditing, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.UseAuditing, '') <> ISNULL(d.UseAuditing,'')
end

if UPDATE(ArchiveDeletedAttachments)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'ArchiveDeletedAttachments', d.ArchiveDeletedAttachments, 
			i.ArchiveDeletedAttachments, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.ArchiveDeletedAttachments, '') <> ISNULL(d.ArchiveDeletedAttachments,'')
end

if UPDATE(PdfResolution)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'PdfResolution', d.PdfResolution, 
			i.PdfResolution, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.PdfResolution, '') <> ISNULL(d.PdfResolution,'')
end

if UPDATE(UseViewpointViewer)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'UseViewpointViewer', d.UseViewpointViewer, 
			i.UseViewpointViewer, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.UseViewpointViewer, '') <> ISNULL(d.UseViewpointViewer,'')
end

if UPDATE(AttachmentDatabaseServer)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'AttachmentDatabaseServer', d.AttachmentDatabaseServer, 
			i.AttachmentDatabaseServer, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.AttachmentDatabaseServer, '') <> ISNULL(d.AttachmentDatabaseServer,'')
end

if UPDATE(AttachmentDatabaseName)
begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHQAO', 'There is no keystring for this table.', null, 'C', 'AttachmentDatabaseName', d.AttachmentDatabaseName, 
			i.AttachmentDatabaseName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on 1=1 --Have to join on something, but we can't since there is only one record
	where ISNULL(i.AttachmentDatabaseName, '') <> ISNULL(d.AttachmentDatabaseName,'')
end

GO
ALTER TABLE [dbo].[bHQAO] WITH NOCHECK ADD CONSTRAINT [CK_bHQAO_ByCompany] CHECK (([ByCompany]='Y' OR [ByCompany]='N' OR [ByCompany] IS NULL))
GO
ALTER TABLE [dbo].[bHQAO] WITH NOCHECK ADD CONSTRAINT [CK_bHQAO_ByForm] CHECK (([ByForm]='Y' OR [ByForm]='N' OR [ByForm] IS NULL))
GO
ALTER TABLE [dbo].[bHQAO] WITH NOCHECK ADD CONSTRAINT [CK_bHQAO_ByModule] CHECK (([ByModule]='Y' OR [ByModule]='N' OR [ByModule] IS NULL))
GO
ALTER TABLE [dbo].[bHQAO] WITH NOCHECK ADD CONSTRAINT [CK_bHQAO_ByMonth] CHECK (([ByMonth]='Y' OR [ByMonth]='N' OR [ByMonth] IS NULL))
GO
ALTER TABLE [dbo].[bHQAO] WITH NOCHECK ADD CONSTRAINT [CK_bHQAO_Custom] CHECK (([Custom]='Y' OR [Custom]='N' OR [Custom] IS NULL))
GO
ALTER TABLE [dbo].[bHQAO] WITH NOCHECK ADD CONSTRAINT [CK_bHQAO_UseJPG] CHECK (([UseJPG]='Y' OR [UseJPG]='N'))
GO
ALTER TABLE [dbo].[bHQAO] WITH NOCHECK ADD CONSTRAINT [CK_bHQAO_UseStructForAttYN] CHECK (([UseStructForAttYN]='Y' OR [UseStructForAttYN]='N'))
GO
