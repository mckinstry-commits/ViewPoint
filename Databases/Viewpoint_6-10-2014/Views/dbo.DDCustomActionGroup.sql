SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDCustomActionGroup
AS
SELECT     ActionId, GroupId
FROM         dbo.vDDCustomActionGroup

GO
GRANT SELECT ON  [dbo].[DDCustomActionGroup] TO [public]
GRANT INSERT ON  [dbo].[DDCustomActionGroup] TO [public]
GRANT DELETE ON  [dbo].[DDCustomActionGroup] TO [public]
GRANT UPDATE ON  [dbo].[DDCustomActionGroup] TO [public]
GRANT SELECT ON  [dbo].[DDCustomActionGroup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCustomActionGroup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCustomActionGroup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCustomActionGroup] TO [Viewpoint]
GO
