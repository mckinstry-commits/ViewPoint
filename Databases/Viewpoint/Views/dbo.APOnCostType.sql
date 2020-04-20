SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[APOnCostType]
AS
SELECT     *
FROM         dbo.vAPOnCostType

GO
GRANT SELECT ON  [dbo].[APOnCostType] TO [public]
GRANT INSERT ON  [dbo].[APOnCostType] TO [public]
GRANT DELETE ON  [dbo].[APOnCostType] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostType] TO [public]
GO
