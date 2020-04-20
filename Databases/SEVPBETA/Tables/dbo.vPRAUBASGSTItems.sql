CREATE TABLE [dbo].[vPRAUBASGSTItems]
(
[GSTItem] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUBASGSTItems] ADD CONSTRAINT [PK_vPRAUBASGSTItems] PRIMARY KEY CLUSTERED  ([GSTItem]) ON [PRIMARY]
GO
