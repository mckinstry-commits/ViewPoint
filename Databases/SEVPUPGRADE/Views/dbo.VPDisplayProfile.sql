SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VPDisplayProfile]
AS
SELECT     KeyID, Name
FROM         dbo.vVPDisplayProfile


GO
GRANT SELECT ON  [dbo].[VPDisplayProfile] TO [public]
GRANT INSERT ON  [dbo].[VPDisplayProfile] TO [public]
GRANT DELETE ON  [dbo].[VPDisplayProfile] TO [public]
GRANT UPDATE ON  [dbo].[VPDisplayProfile] TO [public]
GO
