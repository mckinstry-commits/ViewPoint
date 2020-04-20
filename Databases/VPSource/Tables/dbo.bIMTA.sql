CREATE TABLE [dbo].[bIMTA]
(
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[AddonNumber] [int] NOT NULL,
[Seq] [int] NULL,
[Identifier] [int] NOT NULL,
[RecColumn] [int] NULL,
[BegPos] [int] NULL,
[EndPos] [int] NULL,
[AddColumn] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bIMTA] ADD
CONSTRAINT [CK_bIMTA_AddColumn] CHECK (([AddColumn]='Y' OR [AddColumn]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biIMTA] ON [dbo].[bIMTA] ([ImportTemplate], [RecordType], [AddonNumber], [Identifier]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMTA].[AddColumn]'
GO
