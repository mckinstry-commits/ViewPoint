CREATE TABLE [dbo].[vPMProjectMasterTemplates]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[DocType] [dbo].[bDocType] NULL,
[DefaultTemplate] [dbo].[bReportTitle] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DocCategory] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DefaultYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPMProjectMasterTemplates_DefaultYN] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMProjectMasterTemplates] ADD CONSTRAINT [CK_vPMProjectMasterTemplates_ProjectDocType] UNIQUE NONCLUSTERED  ([PMCo], [Project], [DocType], [DocCategory], [DefaultTemplate]) ON [PRIMARY]

ALTER TABLE [dbo].[vPMProjectMasterTemplates] ADD
CONSTRAINT [CK_vPMProjectMasterTemplate_DefaultYN] CHECK ((NOT ([dbo].[vfPMProjectMasterTemplatesDefault]([PMCo],[Project],[DocCategory],[DocType])>(1) AND [DefaultYN]='Y')))
ALTER TABLE [dbo].[vPMProjectMasterTemplates] ADD
CONSTRAINT [FK_vPMProjectMasterTemplates_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMProjectMasterTemplates] ADD
CONSTRAINT [FK_vPMProjectMasterTemplates_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMProjectMasterTemplates] ADD
CONSTRAINT [FK_vPMProjectMasterTemplates_bHQWD] FOREIGN KEY ([DefaultTemplate]) REFERENCES [dbo].[bHQWD] ([TemplateName]) ON DELETE CASCADE
GO
