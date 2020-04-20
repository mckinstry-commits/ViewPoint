CREATE TABLE [dbo].[vDDCustomRecordTypeGroups]
(
[GroupId] [int] NOT NULL,
[RecordTypeId] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomRecordTypeGroups] ADD CONSTRAINT [PK_vDDCustomRecordTypeGroups_1] PRIMARY KEY CLUSTERED  ([GroupId], [RecordTypeId]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomRecordTypeGroups] WITH NOCHECK ADD CONSTRAINT [FK_vDDCustomRecordTypeGroups_vDDCustomGroups] FOREIGN KEY ([GroupId]) REFERENCES [dbo].[vDDCustomGroups] ([Id])
GO
ALTER TABLE [dbo].[vDDCustomRecordTypeGroups] WITH NOCHECK ADD CONSTRAINT [FK_vDDCustomRecordTypeGroups_vDDCustomRecordTypes] FOREIGN KEY ([RecordTypeId]) REFERENCES [dbo].[vDDCustomRecordTypes] ([Id])
GO
ALTER TABLE [dbo].[vDDCustomRecordTypeGroups] NOCHECK CONSTRAINT [FK_vDDCustomRecordTypeGroups_vDDCustomGroups]
GO
ALTER TABLE [dbo].[vDDCustomRecordTypeGroups] NOCHECK CONSTRAINT [FK_vDDCustomRecordTypeGroups_vDDCustomRecordTypes]
GO
