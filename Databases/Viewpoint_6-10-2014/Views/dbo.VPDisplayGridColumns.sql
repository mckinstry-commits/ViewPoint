SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPDisplayGridColumns
AS
SELECT     ColumnId, GridConfigurationId, Name, IsVisible, Position
FROM         dbo.vVPDisplayGridColumns

GO
GRANT SELECT ON  [dbo].[VPDisplayGridColumns] TO [public]
GRANT INSERT ON  [dbo].[VPDisplayGridColumns] TO [public]
GRANT DELETE ON  [dbo].[VPDisplayGridColumns] TO [public]
GRANT UPDATE ON  [dbo].[VPDisplayGridColumns] TO [public]
GRANT SELECT ON  [dbo].[VPDisplayGridColumns] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPDisplayGridColumns] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPDisplayGridColumns] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPDisplayGridColumns] TO [Viewpoint]
GO
