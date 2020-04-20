SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPPartFormChangedMessages
AS
SELECT     KeyID, FormName, FormTitle
FROM         dbo.vVPPartFormChangedMessages

GO
GRANT SELECT ON  [dbo].[VPPartFormChangedMessages] TO [public]
GRANT INSERT ON  [dbo].[VPPartFormChangedMessages] TO [public]
GRANT DELETE ON  [dbo].[VPPartFormChangedMessages] TO [public]
GRANT UPDATE ON  [dbo].[VPPartFormChangedMessages] TO [public]
GRANT SELECT ON  [dbo].[VPPartFormChangedMessages] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPPartFormChangedMessages] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPPartFormChangedMessages] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPPartFormChangedMessages] TO [Viewpoint]
GO
