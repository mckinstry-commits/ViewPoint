SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[SMRateOverrideStandardItem]
AS
SELECT a.* FROM dbo.vSMRateOverrideStandardItem a





GO
GRANT SELECT ON  [dbo].[SMRateOverrideStandardItem] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverrideStandardItem] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverrideStandardItem] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverrideStandardItem] TO [public]
GO
