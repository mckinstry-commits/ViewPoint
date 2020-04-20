SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBJE] as select a.* From bJBJE a

GO
GRANT SELECT ON  [dbo].[JBJE] TO [public]
GRANT INSERT ON  [dbo].[JBJE] TO [public]
GRANT DELETE ON  [dbo].[JBJE] TO [public]
GRANT UPDATE ON  [dbo].[JBJE] TO [public]
GO
