CREATE TABLE [dbo].[vWhiteList]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[Email] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWhiteList] ADD CONSTRAINT [PK_vWhiteList] PRIMARY KEY CLUSTERED  ([Id]) ON [PRIMARY]
GO
