SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMWorkOrderPOHB] as select a.* From vSMWorkOrderPOHB a
GO
GRANT SELECT ON  [dbo].[SMWorkOrderPOHB] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderPOHB] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderPOHB] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderPOHB] TO [public]
GRANT SELECT ON  [dbo].[SMWorkOrderPOHB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkOrderPOHB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkOrderPOHB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkOrderPOHB] TO [Viewpoint]
GO
