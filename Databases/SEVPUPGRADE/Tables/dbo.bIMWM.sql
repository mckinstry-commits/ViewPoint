CREATE TABLE [dbo].[bIMWM]
(
[ImportId] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[RecordSeq] [int] NOT NULL,
[Error] [int] NULL,
[Message] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Identifier] [int] NULL,
[Sequence] [int] NOT NULL IDENTITY(1, 1),
[SQLStatement] [varchar] (4000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bIMWM] ADD CONSTRAINT [PK_bIMWM] PRIMARY KEY CLUSTERED  ([Sequence]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biIMWM] ON [dbo].[bIMWM] ([ImportId], [ImportTemplate], [RecordSeq], [Identifier]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biIMWMRecordSeq] ON [dbo].[bIMWM] ([ImportId], [RecordSeq], [ImportTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
