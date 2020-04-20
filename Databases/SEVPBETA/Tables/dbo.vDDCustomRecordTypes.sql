CREATE TABLE [dbo].[vDDCustomRecordTypes]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomRecordTypes] ADD CONSTRAINT [PK_vDDCustomRecordTypes] PRIMARY KEY CLUSTERED  ([Id]) ON [PRIMARY]
GO
