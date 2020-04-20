CREATE TABLE [dbo].[vRPRSServer]
(
[ServerName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Server] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[ReportServerInstance] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[ReportManagerInstance] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[CustomSecurity] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vRPRSServer_CustomSecurity] DEFAULT ('Y')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vRPRSServer] ADD CONSTRAINT [PK_vServerName] PRIMARY KEY CLUSTERED  ([ServerName]) ON [PRIMARY]
GO
