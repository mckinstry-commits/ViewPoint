SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VCPortalControls
AS
SELECT     dbo.pPortalControls.*
FROM         dbo.pPortalControls

GO
GRANT SELECT ON  [dbo].[VCPortalControls] TO [public]
GRANT INSERT ON  [dbo].[VCPortalControls] TO [public]
GRANT DELETE ON  [dbo].[VCPortalControls] TO [public]
GRANT UPDATE ON  [dbo].[VCPortalControls] TO [public]
GO
