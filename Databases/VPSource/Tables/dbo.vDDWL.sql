CREATE TABLE [dbo].[vDDWL]
(
[VPUserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Address] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [tinyint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viDDWL] ON [dbo].[vDDWL] ([VPUserName], [Name]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
