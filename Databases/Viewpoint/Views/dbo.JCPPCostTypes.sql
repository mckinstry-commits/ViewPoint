SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPPCostTypes] as select a.* From bJCPPCostTypes a
GO
GRANT SELECT ON  [dbo].[JCPPCostTypes] TO [public]
GRANT INSERT ON  [dbo].[JCPPCostTypes] TO [public]
GRANT DELETE ON  [dbo].[JCPPCostTypes] TO [public]
GRANT UPDATE ON  [dbo].[JCPPCostTypes] TO [public]
GO
