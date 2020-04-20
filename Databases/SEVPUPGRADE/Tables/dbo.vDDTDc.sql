CREATE TABLE [dbo].[vDDTDc]
(
[FolderTemplate] [smallint] NOT NULL,
[ItemType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MenuItem] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[MenuSeq] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viDDTDc] ON [dbo].[vDDTDc] ([FolderTemplate], [ItemType], [MenuItem]) ON [PRIMARY]
GO
