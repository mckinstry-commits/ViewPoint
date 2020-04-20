CREATE TABLE [dbo].[vDDCustomGroups]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[Name] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Order] [int] NOT NULL,
[ImageKey] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[RecordTypeId] [int] NOT NULL CONSTRAINT [DF__vDDCustom__Recor__181627A6] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomGroups] ADD CONSTRAINT [PK_vDDCustomRecordTypeGroups] PRIMARY KEY CLUSTERED  ([Id]) ON [PRIMARY]
GO
