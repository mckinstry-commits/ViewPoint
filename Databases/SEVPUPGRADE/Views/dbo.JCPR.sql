SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPR] as select a.* From bJCPR a
GO
GRANT SELECT ON  [dbo].[JCPR] TO [public]
GRANT INSERT ON  [dbo].[JCPR] TO [public]
GRANT DELETE ON  [dbo].[JCPR] TO [public]
GRANT UPDATE ON  [dbo].[JCPR] TO [public]
GO
