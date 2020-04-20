CREATE TABLE [dbo].[vDDCustomActionRecordTypes]
(
[ActionId] [int] NOT NULL,
[RecordTypeName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomActionRecordTypes] ADD CONSTRAINT [PK_vDDCustomActionRecordTypes] PRIMARY KEY CLUSTERED  ([ActionId], [RecordTypeName]) ON [PRIMARY]
GO
