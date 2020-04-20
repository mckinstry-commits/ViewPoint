SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udOrgDistribution] as select a.* From budOrgDistribution a
GO
GRANT SELECT ON  [dbo].[udOrgDistribution] TO [public]
GRANT INSERT ON  [dbo].[udOrgDistribution] TO [public]
GRANT DELETE ON  [dbo].[udOrgDistribution] TO [public]
GRANT UPDATE ON  [dbo].[udOrgDistribution] TO [public]
GO
