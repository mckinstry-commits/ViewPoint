SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMWorkOrderScopeTask]
AS
SELECT *
FROM dbo.vSMWorkOrderScopeTask


GO
GRANT SELECT ON  [dbo].[SMWorkOrderScopeTask] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderScopeTask] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderScopeTask] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderScopeTask] TO [public]
GO
