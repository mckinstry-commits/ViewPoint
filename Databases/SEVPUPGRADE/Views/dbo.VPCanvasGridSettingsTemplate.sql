SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasGridSettingsTemplate
AS
SELECT     KeyID, QueryName, GridLayout, Sort, MaximumNumberOfRows, ShowFilterBar, PartId, QueryId, GridType, ShowConfiguration
FROM         dbo.vVPCanvasGridSettingsTemplate

GO
GRANT SELECT ON  [dbo].[VPCanvasGridSettingsTemplate] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridSettingsTemplate] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridSettingsTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridSettingsTemplate] TO [public]
GO
