SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[POPendingPurchaseOrderItem] as select a.* From vPOPendingPurchaseOrderItem a

GO
GRANT SELECT ON  [dbo].[POPendingPurchaseOrderItem] TO [public]
GRANT INSERT ON  [dbo].[POPendingPurchaseOrderItem] TO [public]
GRANT DELETE ON  [dbo].[POPendingPurchaseOrderItem] TO [public]
GRANT UPDATE ON  [dbo].[POPendingPurchaseOrderItem] TO [public]
GRANT SELECT ON  [dbo].[POPendingPurchaseOrderItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POPendingPurchaseOrderItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POPendingPurchaseOrderItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POPendingPurchaseOrderItem] TO [Viewpoint]
GO
