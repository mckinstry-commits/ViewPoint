SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasGridGroupedColumnsTemplate
AS
SELECT     ColumnId, GridConfigurationId, Name, ColumnOrder
FROM         dbo.vVPCanvasGridGroupedColumnsTemplate

GO
GRANT SELECT ON  [dbo].[VPCanvasGridGroupedColumnsTemplate] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridGroupedColumnsTemplate] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridGroupedColumnsTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridGroupedColumnsTemplate] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasGridGroupedColumnsTemplate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasGridGroupedColumnsTemplate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasGridGroupedColumnsTemplate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasGridGroupedColumnsTemplate] TO [Viewpoint]
GO
