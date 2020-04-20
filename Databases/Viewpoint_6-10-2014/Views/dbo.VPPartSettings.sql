SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[VPPartSettings] as select a.* From vVPPartSettings a
GO
GRANT SELECT ON  [dbo].[VPPartSettings] TO [public]
GRANT INSERT ON  [dbo].[VPPartSettings] TO [public]
GRANT DELETE ON  [dbo].[VPPartSettings] TO [public]
GRANT UPDATE ON  [dbo].[VPPartSettings] TO [public]
GRANT SELECT ON  [dbo].[VPPartSettings] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPPartSettings] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPPartSettings] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPPartSettings] TO [Viewpoint]
GO
