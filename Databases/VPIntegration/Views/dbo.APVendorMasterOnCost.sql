SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[APVendorMasterOnCost]
AS
SELECT     dbo.vAPVendorMasterOnCost.*
FROM         dbo.vAPVendorMasterOnCost

GO
GRANT SELECT ON  [dbo].[APVendorMasterOnCost] TO [public]
GRANT INSERT ON  [dbo].[APVendorMasterOnCost] TO [public]
GRANT DELETE ON  [dbo].[APVendorMasterOnCost] TO [public]
GRANT UPDATE ON  [dbo].[APVendorMasterOnCost] TO [public]
GO
