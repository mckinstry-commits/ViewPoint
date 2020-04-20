SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMFlatPriceRevenueSplit]
AS
SELECT *
FROM dbo.vSMFlatPriceRevenueSplit


GO
GRANT SELECT ON  [dbo].[SMFlatPriceRevenueSplit] TO [public]
GRANT INSERT ON  [dbo].[SMFlatPriceRevenueSplit] TO [public]
GRANT DELETE ON  [dbo].[SMFlatPriceRevenueSplit] TO [public]
GRANT UPDATE ON  [dbo].[SMFlatPriceRevenueSplit] TO [public]
GRANT SELECT ON  [dbo].[SMFlatPriceRevenueSplit] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMFlatPriceRevenueSplit] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMFlatPriceRevenueSplit] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMFlatPriceRevenueSplit] TO [Viewpoint]
GO
