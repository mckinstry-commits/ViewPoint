CREATE TABLE [dbo].[vVPReportAssociationc]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[ReportID] [int] NOT NULL,
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
GO
