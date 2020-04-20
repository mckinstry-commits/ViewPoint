SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMWorkOrder] as select a.* From vSMWorkOrder a







GO
GRANT SELECT ON  [dbo].[SMWorkOrder] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrder] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrder] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrder] TO [public]
GO
