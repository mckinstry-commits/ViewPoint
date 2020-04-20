SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasSettings
AS
SELECT     KeyID, VPUserName, NumberOfRows, NumberOfColumns, RefreshInterval, TableLayout, GridLayout, TabNumber, TabName, TemplateName, FilterConfigurationSettings
FROM         dbo.vVPCanvasSettings AS a

GO
GRANT SELECT ON  [dbo].[VPCanvasSettings] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasSettings] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasSettings] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasSettings] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasSettings] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasSettings] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasSettings] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasSettings] TO [Viewpoint]
GO
