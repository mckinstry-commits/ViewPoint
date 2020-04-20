SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLPI] as select a.* From bGLPI a
GO
GRANT SELECT ON  [dbo].[GLPI] TO [public]
GRANT INSERT ON  [dbo].[GLPI] TO [public]
GRANT DELETE ON  [dbo].[GLPI] TO [public]
GRANT UPDATE ON  [dbo].[GLPI] TO [public]
GRANT SELECT ON  [dbo].[GLPI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLPI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLPI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLPI] TO [Viewpoint]
GO
