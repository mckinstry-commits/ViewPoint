SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMRateOverrideCatMatlBP]
AS

WITH SMRateOverrideMaterialOverrideBreakPointCTE AS
(
	SELECT *
	FROM dbo.vSMRateOverrideMatlBP
	WHERE RateOverrideMaterialSeq IS NOT NULL
)

SELECT * 
FROM SMRateOverrideMaterialOverrideBreakPointCTE
GO
GRANT SELECT ON  [dbo].[SMRateOverrideCatMatlBP] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverrideCatMatlBP] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverrideCatMatlBP] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverrideCatMatlBP] TO [public]
GRANT SELECT ON  [dbo].[SMRateOverrideCatMatlBP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRateOverrideCatMatlBP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRateOverrideCatMatlBP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRateOverrideCatMatlBP] TO [Viewpoint]
GO
