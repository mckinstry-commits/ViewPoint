SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasGridSettingsUser
AS
SELECT     *
FROM         dbo.vVPCanvasGridSettingsUser
GO
GRANT SELECT ON  [dbo].[VPCanvasGridSettingsUser] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridSettingsUser] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridSettingsUser] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridSettingsUser] TO [public]
GO
