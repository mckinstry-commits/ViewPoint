CREATE TABLE [dbo].[vVPDisplayTreeItems]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[TabNavigationID] [int] NOT NULL,
[TreeItemTemplateID] [int] NOT NULL,
[ShowItem] [dbo].[bYN] NOT NULL,
[ItemOrder] [int] NULL,
[ItemTitle] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[ParentID] [int] NULL,
[ItemType] [int] NULL,
[Item] [varchar] (2048) COLLATE Latin1_General_BIN NULL,
[IsCustom] [dbo].[bYN] NULL,
[GridConfigurationID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplayTreeItems] ADD CONSTRAINT [PK_vVPDisplayTreeItems] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplayTreeItems] WITH NOCHECK ADD CONSTRAINT [FK_vVPDisplayTreeItems_vVPDisplayTabNavigation] FOREIGN KEY ([TabNavigationID]) REFERENCES [dbo].[vVPDisplayTabNavigation] ([KeyID]) ON DELETE CASCADE
GO
