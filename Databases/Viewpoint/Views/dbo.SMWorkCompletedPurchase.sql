SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[SMWorkCompletedPurchase]
AS
SELECT a.* FROM dbo.vSMWorkCompletedPurchase a







GO
GRANT SELECT ON  [dbo].[SMWorkCompletedPurchase] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedPurchase] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedPurchase] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedPurchase] TO [public]
GO
