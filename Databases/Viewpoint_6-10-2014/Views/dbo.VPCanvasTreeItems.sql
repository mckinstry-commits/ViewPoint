SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasTreeItems
AS
SELECT     ItemType, ItemSeq, Item, ParentId, ItemOrder, CanvasId, ItemTitle, Expanded, KeyID, ShowItem, IsCustom
FROM         dbo.vVPCanvasTreeItems

GO
GRANT SELECT ON  [dbo].[VPCanvasTreeItems] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasTreeItems] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasTreeItems] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasTreeItems] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasTreeItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasTreeItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasTreeItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasTreeItems] TO [Viewpoint]
GO
