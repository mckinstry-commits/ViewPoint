CREATE TABLE [dbo].[vRPTMc]
(
[ReportID] [int] NOT NULL,
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NOT NULL,
[KeyID] [int] NOT NULL IDENTITY(2, 2)
) ON [PRIMARY]
GO
