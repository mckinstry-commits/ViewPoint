SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPDisplayTreeItems
AS
SELECT     KeyID, TabNavigationID, TreeItemTemplateID, ShowItem, ItemOrder, ItemTitle, ParentID, ItemType, Item, IsCustom, GridConfigurationID
FROM         dbo.vVPDisplayTreeItems

GO
GRANT SELECT ON  [dbo].[VPDisplayTreeItems] TO [public]
GRANT INSERT ON  [dbo].[VPDisplayTreeItems] TO [public]
GRANT DELETE ON  [dbo].[VPDisplayTreeItems] TO [public]
GRANT UPDATE ON  [dbo].[VPDisplayTreeItems] TO [public]
GO
