CREATE TABLE [dbo].[bIMWENotes]
(
[ImportId] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NULL,
[Identifier] [int] NOT NULL,
[RecordSeq] [int] NOT NULL,
[ImportedVal] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UploadVal] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE CLUSTERED INDEX [biIMWENotesImport] ON [dbo].[bIMWENotes] ([ImportId], [ImportTemplate], [Form], [Identifier], [RecordSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
