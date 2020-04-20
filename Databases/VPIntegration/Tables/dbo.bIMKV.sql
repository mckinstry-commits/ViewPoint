CREATE TABLE [dbo].[bIMKV]
(
[ImportId] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Identifier] [int] NOT NULL,
[Value] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[IsKeyYN] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biIMKV] ON [dbo].[bIMKV] ([ImportId], [RecordType], [Identifier], [Value]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMKV].[IsKeyYN]'
GO