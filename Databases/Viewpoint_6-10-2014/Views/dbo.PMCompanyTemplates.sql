SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMCompanyTemplates] as select a.* From vPMCompanyTemplates a
GO
GRANT SELECT ON  [dbo].[PMCompanyTemplates] TO [public]
GRANT INSERT ON  [dbo].[PMCompanyTemplates] TO [public]
GRANT DELETE ON  [dbo].[PMCompanyTemplates] TO [public]
GRANT UPDATE ON  [dbo].[PMCompanyTemplates] TO [public]
GRANT SELECT ON  [dbo].[PMCompanyTemplates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMCompanyTemplates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMCompanyTemplates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMCompanyTemplates] TO [Viewpoint]
GO
