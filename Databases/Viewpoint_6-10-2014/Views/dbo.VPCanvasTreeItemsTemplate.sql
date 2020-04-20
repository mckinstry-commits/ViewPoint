SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasTreeItemsTemplate
AS
SELECT     KeyID, ItemType, Item, ItemTitle, ParentId, ItemOrder, TemplateName, Expanded, ShowItem
FROM         dbo.vVPCanvasTreeItemsTemplate

GO
GRANT SELECT ON  [dbo].[VPCanvasTreeItemsTemplate] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasTreeItemsTemplate] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasTreeItemsTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasTreeItemsTemplate] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasTreeItemsTemplate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasTreeItemsTemplate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasTreeItemsTemplate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasTreeItemsTemplate] TO [Viewpoint]
GO
