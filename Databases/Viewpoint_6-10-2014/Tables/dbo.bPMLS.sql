CREATE TABLE [dbo].[bPMLS]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DocCat] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[TableName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ColumnAlias] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ColumnType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Visible] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMLS_Visible] DEFAULT ('Y')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMLS] WITH NOCHECK ADD CONSTRAINT [CK_bPMLS_Visible] CHECK (([Visible]='N' OR [Visible]='Y'))
GO
ALTER TABLE [dbo].[bPMLS] ADD CONSTRAINT [PK_bPMLS] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bPMLS_DocCatTableColumn] ON [dbo].[bPMLS] ([DocCat], [TableName], [ColumnName]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMLS] WITH NOCHECK ADD CONSTRAINT [FK_bPMLS_bPMCU] FOREIGN KEY ([DocCat]) REFERENCES [dbo].[bPMCU] ([DocCat])
GO
ALTER TABLE [dbo].[bPMLS] NOCHECK CONSTRAINT [FK_bPMLS_bPMCU]
GO
