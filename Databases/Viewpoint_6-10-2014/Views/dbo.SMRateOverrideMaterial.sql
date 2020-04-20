SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMRateOverrideMaterial]
AS
SELECT *
FROM dbo.vSMRateOverrideMaterial
GO
GRANT SELECT ON  [dbo].[SMRateOverrideMaterial] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverrideMaterial] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverrideMaterial] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverrideMaterial] TO [public]
GRANT SELECT ON  [dbo].[SMRateOverrideMaterial] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRateOverrideMaterial] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRateOverrideMaterial] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRateOverrideMaterial] TO [Viewpoint]
GO
