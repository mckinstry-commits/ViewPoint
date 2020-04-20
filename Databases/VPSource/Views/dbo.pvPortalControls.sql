SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPortalControls
AS
SELECT     dbo.pPortalControls.*
FROM         dbo.pPortalControls
GO
GRANT SELECT ON  [dbo].[pvPortalControls] TO [public]
GRANT INSERT ON  [dbo].[pvPortalControls] TO [public]
GRANT DELETE ON  [dbo].[pvPortalControls] TO [public]
GRANT UPDATE ON  [dbo].[pvPortalControls] TO [public]
GRANT SELECT ON  [dbo].[pvPortalControls] TO [VCSPortal]
GO
