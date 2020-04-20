SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VPCanvasGridColumnsTemplate]
AS
SELECT     ColumnId, GridConfigurationId, Name, IsVisible, Position
FROM         dbo.vVPCanvasGridColumnsTemplate

GO
GRANT SELECT ON  [dbo].[VPCanvasGridColumnsTemplate] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridColumnsTemplate] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridColumnsTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridColumnsTemplate] TO [public]
GO
