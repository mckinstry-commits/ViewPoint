CREATE TABLE [dbo].[bPMWX]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[ImportId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[DataRow] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[RecType] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMWX] ON [dbo].[bPMWX] ([PMCo], [ImportId], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMWX] WITH NOCHECK ADD CONSTRAINT [FK_bPMWX_bPMWH] FOREIGN KEY ([PMCo], [ImportId]) REFERENCES [dbo].[bPMWH] ([PMCo], [ImportId]) ON DELETE CASCADE
GO
