CREATE TABLE [dbo].[vVPCanvasTreeItems]
(
[ItemType] [int] NOT NULL,
[ItemSeq] [int] NOT NULL CONSTRAINT [DF_vVPCanvasTreeItems_ItemSeq] DEFAULT ((0)),
[Item] [varchar] (2048) COLLATE Latin1_General_BIN NULL,
[ParentId] [int] NULL,
[ItemOrder] [int] NOT NULL,
[CanvasId] [int] NOT NULL,
[ItemTitle] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[Expanded] [dbo].[bYN] NOT NULL,
[KeyID] [int] NULL,
[ShowItem] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPCanvasTreeItems_ShowItem] DEFAULT ('Y'),
[IsCustom] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
