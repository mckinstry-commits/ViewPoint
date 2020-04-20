CREATE TABLE [dbo].[vHQResponseValueItem]
(
[ValueCode] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[DisplayValue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DatabaseValue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQResponseValueItem] ADD CONSTRAINT [PK_vHQResponseValueItem] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vHQResponseValueItem_Seq] ON [dbo].[vHQResponseValueItem] ([ValueCode], [Seq]) ON [PRIMARY]
GO
