SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[viDim_CubeDataSecurity]
AS
SELECT     u.VPUserName, u.Datatype, j.KeyID
FROM         dbo.DDDU AS u INNER JOIN
                      dbo.JCJM AS j ON u.Instance = j.Job

GO
GRANT SELECT ON  [dbo].[viDim_CubeDataSecurity] TO [public]
GRANT INSERT ON  [dbo].[viDim_CubeDataSecurity] TO [public]
GRANT DELETE ON  [dbo].[viDim_CubeDataSecurity] TO [public]
GRANT UPDATE ON  [dbo].[viDim_CubeDataSecurity] TO [public]
GO
