SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMProjectMasterTemplates] as select a.* From vPMProjectMasterTemplates a
GO
GRANT SELECT ON  [dbo].[PMProjectMasterTemplates] TO [public]
GRANT INSERT ON  [dbo].[PMProjectMasterTemplates] TO [public]
GRANT DELETE ON  [dbo].[PMProjectMasterTemplates] TO [public]
GRANT UPDATE ON  [dbo].[PMProjectMasterTemplates] TO [public]
GRANT SELECT ON  [dbo].[PMProjectMasterTemplates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMProjectMasterTemplates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMProjectMasterTemplates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMProjectMasterTemplates] TO [Viewpoint]
GO
