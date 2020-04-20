CREATE TABLE [dbo].[vPMProjectMasterTemplates]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[DocType] [dbo].[bDocType] NOT NULL,
[DefaultTemplate] [dbo].[bReportTitle] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
