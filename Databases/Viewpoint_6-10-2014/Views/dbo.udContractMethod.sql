SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udContractMethod] as select a.* From budContractMethod a
GO
GRANT SELECT ON  [dbo].[udContractMethod] TO [public]
GRANT INSERT ON  [dbo].[udContractMethod] TO [public]
GRANT DELETE ON  [dbo].[udContractMethod] TO [public]
GRANT UPDATE ON  [dbo].[udContractMethod] TO [public]
GRANT SELECT ON  [dbo].[udContractMethod] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udContractMethod] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udContractMethod] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udContractMethod] TO [Viewpoint]
GO
