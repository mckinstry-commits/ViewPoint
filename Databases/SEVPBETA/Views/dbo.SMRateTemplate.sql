SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMRateTemplate] as select a.* From vSMRateTemplate a
GO
GRANT SELECT ON  [dbo].[SMRateTemplate] TO [public]
GRANT INSERT ON  [dbo].[SMRateTemplate] TO [public]
GRANT DELETE ON  [dbo].[SMRateTemplate] TO [public]
GRANT UPDATE ON  [dbo].[SMRateTemplate] TO [public]
GO
