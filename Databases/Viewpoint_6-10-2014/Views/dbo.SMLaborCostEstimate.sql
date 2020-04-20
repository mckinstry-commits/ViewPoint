SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMLaborCostEstimate] 
AS
SELECT *
FROM dbo.vSMLaborCostEstimate

GO
GRANT SELECT ON  [dbo].[SMLaborCostEstimate] TO [public]
GRANT INSERT ON  [dbo].[SMLaborCostEstimate] TO [public]
GRANT DELETE ON  [dbo].[SMLaborCostEstimate] TO [public]
GRANT UPDATE ON  [dbo].[SMLaborCostEstimate] TO [public]
GRANT SELECT ON  [dbo].[SMLaborCostEstimate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMLaborCostEstimate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMLaborCostEstimate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMLaborCostEstimate] TO [Viewpoint]
GO
