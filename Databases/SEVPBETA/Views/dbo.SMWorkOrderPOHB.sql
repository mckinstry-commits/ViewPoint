SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE VIEW [dbo].[SMWorkOrderPOHB]
AS
SELECT a.* FROM dbo.vSMWorkOrderPOHB a











GO
GRANT SELECT ON  [dbo].[SMWorkOrderPOHB] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderPOHB] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderPOHB] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderPOHB] TO [public]
GO
