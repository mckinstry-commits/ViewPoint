SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMCallTypeCategory] 
AS
SELECT a.* FROM dbo.vSMCallTypeCategory  a

GO
GRANT SELECT ON  [dbo].[SMCallTypeCategory] TO [public]
GRANT INSERT ON  [dbo].[SMCallTypeCategory] TO [public]
GRANT DELETE ON  [dbo].[SMCallTypeCategory] TO [public]
GRANT UPDATE ON  [dbo].[SMCallTypeCategory] TO [public]
GRANT SELECT ON  [dbo].[SMCallTypeCategory] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMCallTypeCategory] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMCallTypeCategory] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMCallTypeCategory] TO [Viewpoint]
GO
