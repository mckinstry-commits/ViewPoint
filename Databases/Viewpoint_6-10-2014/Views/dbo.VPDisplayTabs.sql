SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPDisplayTabs
AS
SELECT     Seq, DisplayID, TabNumber, TabName, TemplateName, NavigationID, KeyID
FROM         dbo.vVPDisplayTabs

GO
GRANT SELECT ON  [dbo].[VPDisplayTabs] TO [public]
GRANT INSERT ON  [dbo].[VPDisplayTabs] TO [public]
GRANT DELETE ON  [dbo].[VPDisplayTabs] TO [public]
GRANT UPDATE ON  [dbo].[VPDisplayTabs] TO [public]
GRANT SELECT ON  [dbo].[VPDisplayTabs] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPDisplayTabs] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPDisplayTabs] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPDisplayTabs] TO [Viewpoint]
GO
