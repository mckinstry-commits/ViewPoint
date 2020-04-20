SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPPPhases] as select a.* From bJCPPPhases a
GO
GRANT SELECT ON  [dbo].[JCPPPhases] TO [public]
GRANT INSERT ON  [dbo].[JCPPPhases] TO [public]
GRANT DELETE ON  [dbo].[JCPPPhases] TO [public]
GRANT UPDATE ON  [dbo].[JCPPPhases] TO [public]
GO
