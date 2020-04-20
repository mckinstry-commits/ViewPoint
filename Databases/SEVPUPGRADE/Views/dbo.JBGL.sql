SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBGL] as select a.* From bJBGL a

GO
GRANT SELECT ON  [dbo].[JBGL] TO [public]
GRANT INSERT ON  [dbo].[JBGL] TO [public]
GRANT DELETE ON  [dbo].[JBGL] TO [public]
GRANT UPDATE ON  [dbo].[JBGL] TO [public]
GO
