CREATE TABLE [dbo].[vPMCompanyTemplates]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[DocType] [dbo].[bDocType] NOT NULL,
[DefaultTemplate] [dbo].[bReportTitle] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[vPMCompanyTemplates] WITH NOCHECK ADD
CONSTRAINT [FK_vPMCompanyTemplates_bPMCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bPMCO] ([PMCo])
GO
