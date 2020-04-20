CREATE TABLE [dbo].[vVPCanvasTreeItemsTemplate]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[ItemType] [int] NOT NULL,
[Item] [varchar] (2048) COLLATE Latin1_General_BIN NOT NULL,
[ItemTitle] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[ParentId] [int] NULL,
[ItemOrder] [int] NOT NULL,
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Expanded] [dbo].[bYN] NOT NULL,
[ShowItem] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPCanvasTreeItemsTemplate_ShowItem] DEFAULT ('Y')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasTreeItemsTemplate] ADD CONSTRAINT [PK_vVPCanvasTreeItemsTemplate] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
