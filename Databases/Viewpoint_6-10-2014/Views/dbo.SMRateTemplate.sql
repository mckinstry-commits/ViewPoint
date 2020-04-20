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
GRANT SELECT ON  [dbo].[SMRateTemplate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRateTemplate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRateTemplate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRateTemplate] TO [Viewpoint]
GO
