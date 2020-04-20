CREATE TABLE [dbo].[vPRAUItemsATOCategories]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ItemCode] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[ATOCategory] [char] (4) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUItemsATOCategories] ADD CONSTRAINT [PK_vPRAUItemsATOCategories_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUItemsATOCategories] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUItems_vPRAUItemsATOCategories_ItemCode] FOREIGN KEY ([ItemCode]) REFERENCES [dbo].[vPRAUItems] ([ItemCode])
GO
ALTER TABLE [dbo].[vPRAUItemsATOCategories] NOCHECK CONSTRAINT [FK_vPRAUItems_vPRAUItemsATOCategories_ItemCode]
GO
