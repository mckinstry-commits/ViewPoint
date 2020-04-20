CREATE TABLE [dbo].[vVPInstallHistory]
(
[ID] [int] NOT NULL IDENTITY(100, 1),
[Version] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[InstallDate] [datetime] NOT NULL,
[OptOut] [bit] NOT NULL,
[NTUserName] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [vivVPInstallHistory] ON [dbo].[vVPInstallHistory] ([ID]) ON [PRIMARY]
GO
