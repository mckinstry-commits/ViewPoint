SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPDisplayTabNavigation
AS
SELECT     KeyID, Description, TemplateName
FROM         dbo.vVPDisplayTabNavigation

GO
GRANT SELECT ON  [dbo].[VPDisplayTabNavigation] TO [public]
GRANT INSERT ON  [dbo].[VPDisplayTabNavigation] TO [public]
GRANT DELETE ON  [dbo].[VPDisplayTabNavigation] TO [public]
GRANT UPDATE ON  [dbo].[VPDisplayTabNavigation] TO [public]
GRANT SELECT ON  [dbo].[VPDisplayTabNavigation] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPDisplayTabNavigation] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPDisplayTabNavigation] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPDisplayTabNavigation] TO [Viewpoint]
GO
