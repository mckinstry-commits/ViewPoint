CREATE TABLE [dbo].[bIMXD]
(
[ImportTemplate] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[XRefName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ImportValue] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[BidtekGroup] [dbo].[bGroup] NULL,
[BidtekValue] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biIMXD] ON [dbo].[bIMXD] ([ImportTemplate], [XRefName], [ImportValue], [RecordType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
