SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasGridSettings
AS
SELECT     KeyID, QueryName, Seq, CustomName, GridLayout, Sort, MaximumNumberOfRows, ShowFilterBar, PartId, QueryId, GridType, ShowConfiguration, ShowTotals, IsDrillThrough, SelectedRow
FROM         dbo.vVPCanvasGridSettings
GO
GRANT SELECT ON  [dbo].[VPCanvasGridSettings] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridSettings] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridSettings] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridSettings] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasGridSettings] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasGridSettings] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasGridSettings] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasGridSettings] TO [Viewpoint]
GO
