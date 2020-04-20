CREATE TABLE [dbo].[vDDCustomActionGroup]
(
[ActionId] [int] NOT NULL,
[GroupId] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomActionGroup] ADD CONSTRAINT [PK_vDDCustomActionGroup] PRIMARY KEY CLUSTERED  ([ActionId], [GroupId]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomActionGroup] WITH NOCHECK ADD CONSTRAINT [FK_vDDCustomActionGroup_vDDCustomActionsTEMP] FOREIGN KEY ([ActionId]) REFERENCES [dbo].[vDDCustomActions] ([Id])
GO
ALTER TABLE [dbo].[vDDCustomActionGroup] WITH NOCHECK ADD CONSTRAINT [FK_vDDCustomActionGroup_vDDCustomGroups] FOREIGN KEY ([GroupId]) REFERENCES [dbo].[vDDCustomGroups] ([Id])
GO
