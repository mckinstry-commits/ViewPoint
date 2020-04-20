CREATE TABLE [dbo].[vUDVersion]
(
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Version] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vUDVersion] ADD CONSTRAINT [PK_vUDVersion] PRIMARY KEY CLUSTERED  ([TableName]) ON [PRIMARY]
GO
