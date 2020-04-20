SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMRateOverride]
AS
SELECT *
FROM dbo.vSMRateOverride
GO
GRANT SELECT ON  [dbo].[SMRateOverride] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverride] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverride] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverride] TO [public]
GO
