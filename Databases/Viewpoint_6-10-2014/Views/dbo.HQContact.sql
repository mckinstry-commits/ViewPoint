SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[HQContact]
AS
SELECT     dbo.vHQContact.*
FROM         dbo.vHQContact


GO
GRANT SELECT ON  [dbo].[HQContact] TO [public]
GRANT INSERT ON  [dbo].[HQContact] TO [public]
GRANT DELETE ON  [dbo].[HQContact] TO [public]
GRANT UPDATE ON  [dbo].[HQContact] TO [public]
GRANT SELECT ON  [dbo].[HQContact] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQContact] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQContact] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQContact] TO [Viewpoint]
GO
