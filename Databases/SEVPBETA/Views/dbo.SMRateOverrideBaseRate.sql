SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMRateOverrideBaseRate]
AS
SELECT *
FROM dbo.vSMRateOverrideBaseRate
GO
GRANT SELECT ON  [dbo].[SMRateOverrideBaseRate] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverrideBaseRate] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverrideBaseRate] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverrideBaseRate] TO [public]
GO
