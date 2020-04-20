SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPDisplayGridSettings
AS
SELECT     KeyID, DisplayID, QueryName, MaximumNumberOfRows, GridType
FROM         dbo.vVPDisplayGridSettings

GO
GRANT SELECT ON  [dbo].[VPDisplayGridSettings] TO [public]
GRANT INSERT ON  [dbo].[VPDisplayGridSettings] TO [public]
GRANT DELETE ON  [dbo].[VPDisplayGridSettings] TO [public]
GRANT UPDATE ON  [dbo].[VPDisplayGridSettings] TO [public]
GRANT SELECT ON  [dbo].[VPDisplayGridSettings] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPDisplayGridSettings] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPDisplayGridSettings] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPDisplayGridSettings] TO [Viewpoint]
GO
