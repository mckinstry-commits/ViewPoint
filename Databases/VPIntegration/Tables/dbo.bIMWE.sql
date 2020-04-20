CREATE TABLE [dbo].[bIMWE]
(
[ImportId] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NULL,
[Identifier] [int] NOT NULL,
[RecordSeq] [int] NOT NULL,
[ImportedVal] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UploadVal] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biIMWE] ON [dbo].[bIMWE] ([ImportId], [ImportTemplate], [RecordType], [Identifier], [RecordSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biIMWERecordSeq] ON [dbo].[bIMWE] ([ImportId], [RecordSeq], [Identifier]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biIMWEImportId] ON [dbo].[bIMWE] ([ImportTemplate], [Identifier], [RecordType], [UploadVal]) ON [PRIMARY]
GO
CREATE STATISTICS [IMWEAll] ON [dbo].[bIMWE] ([ImportId], [UploadVal], [RecordType], [ImportTemplate], [Form], [Seq], [Identifier], [RecordSeq], [ImportedVal])
GO
