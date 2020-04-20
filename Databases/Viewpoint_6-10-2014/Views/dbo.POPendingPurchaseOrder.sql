SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view dbo.POPendingPurchaseOrder as select a.* From dbo.vPOPendingPurchaseOrder a
GO
GRANT SELECT ON  [dbo].[POPendingPurchaseOrder] TO [public]
GRANT INSERT ON  [dbo].[POPendingPurchaseOrder] TO [public]
GRANT DELETE ON  [dbo].[POPendingPurchaseOrder] TO [public]
GRANT UPDATE ON  [dbo].[POPendingPurchaseOrder] TO [public]
GRANT SELECT ON  [dbo].[POPendingPurchaseOrder] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POPendingPurchaseOrder] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POPendingPurchaseOrder] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POPendingPurchaseOrder] TO [Viewpoint]
GO
