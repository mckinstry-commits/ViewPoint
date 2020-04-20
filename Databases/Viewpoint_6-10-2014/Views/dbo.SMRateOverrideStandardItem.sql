SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMRateOverrideStandardItem] as select a.* From vSMRateOverrideStandardItem a
GO
GRANT SELECT ON  [dbo].[SMRateOverrideStandardItem] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverrideStandardItem] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverrideStandardItem] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverrideStandardItem] TO [public]
GRANT SELECT ON  [dbo].[SMRateOverrideStandardItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRateOverrideStandardItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRateOverrideStandardItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRateOverrideStandardItem] TO [Viewpoint]
GO
