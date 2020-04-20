SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMRateOverrideMatlBP]
AS

WITH SMRateOverrideMaterialBreakPointCTE AS
(
	SELECT *
	FROM dbo.vSMRateOverrideMatlBP
	WHERE RateOverrideMaterialSeq IS NULL
)

SELECT * 
FROM SMRateOverrideMaterialBreakPointCTE
GO
GRANT SELECT ON  [dbo].[SMRateOverrideMatlBP] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverrideMatlBP] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverrideMatlBP] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverrideMatlBP] TO [public]
GO
