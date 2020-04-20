SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBPG] as select a.* From bJBPG a

GO
GRANT SELECT ON  [dbo].[JBPG] TO [public]
GRANT INSERT ON  [dbo].[JBPG] TO [public]
GRANT DELETE ON  [dbo].[JBPG] TO [public]
GRANT UPDATE ON  [dbo].[JBPG] TO [public]
GO
