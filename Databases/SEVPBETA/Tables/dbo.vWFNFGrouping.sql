CREATE TABLE [dbo].[vWFNFGrouping]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[JobName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[GroupBy] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFNFGrouping] ADD CONSTRAINT [PK_vWFNFGrouping] PRIMARY KEY CLUSTERED  ([JobName], [GroupBy]) ON [PRIMARY]
GO
