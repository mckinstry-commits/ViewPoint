
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMRateOverrideLabor] as select a.* From vSMRateOverrideLabor a
GO

GRANT SELECT ON  [dbo].[SMRateOverrideLabor] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverrideLabor] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverrideLabor] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverrideLabor] TO [public]
GO
