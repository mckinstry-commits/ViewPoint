SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VPCanvasGridGroupedColumns]
AS
SELECT * FROM vVPCanvasGridGroupedColumns;

GO
GRANT SELECT ON  [dbo].[VPCanvasGridGroupedColumns] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridGroupedColumns] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridGroupedColumns] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridGroupedColumns] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasGridGroupedColumns] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasGridGroupedColumns] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasGridGroupedColumns] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasGridGroupedColumns] TO [Viewpoint]
GO
