CREATE TABLE [dbo].[vDDTD]
(
[FolderTemplate] [smallint] NOT NULL,
[ItemType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MenuItem] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[MenuSeq] [smallint] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viDDTD] ON [dbo].[vDDTD] ([FolderTemplate], [ItemType], [MenuItem]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
