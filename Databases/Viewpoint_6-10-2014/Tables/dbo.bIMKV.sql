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
ALTER TABLE [dbo].[bIMKV] WITH NOCHECK ADD CONSTRAINT [CK_bIMKV_IsKeyYN] CHECK (([IsKeyYN]='Y' OR [IsKeyYN]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biIMKV] ON [dbo].[bIMKV] ([ImportId], [RecordType], [Identifier], [Value]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
