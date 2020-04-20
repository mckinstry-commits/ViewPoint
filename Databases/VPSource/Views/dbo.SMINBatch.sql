SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE VIEW [dbo].[SMINBatch]
AS
SELECT     dbo.vSMINBatch.*, SMCo AS Co --Needed for vspHQBCTableRowCount
FROM         dbo.vSMINBatch












GO
GRANT SELECT ON  [dbo].[SMINBatch] TO [public]
GRANT INSERT ON  [dbo].[SMINBatch] TO [public]
GRANT DELETE ON  [dbo].[SMINBatch] TO [public]
GRANT UPDATE ON  [dbo].[SMINBatch] TO [public]
GO
