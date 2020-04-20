SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PCScopePhases
AS
SELECT     dbo.vPCScopePhases.*
FROM         dbo.vPCScopePhases

GO
GRANT SELECT ON  [dbo].[PCScopePhases] TO [public]
GRANT INSERT ON  [dbo].[PCScopePhases] TO [public]
GRANT DELETE ON  [dbo].[PCScopePhases] TO [public]
GRANT UPDATE ON  [dbo].[PCScopePhases] TO [public]
GRANT SELECT ON  [dbo].[PCScopePhases] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCScopePhases] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCScopePhases] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCScopePhases] TO [Viewpoint]
GO
