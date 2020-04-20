SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBMO] as select a.* From bJBMO a

GO
GRANT SELECT ON  [dbo].[JBMO] TO [public]
GRANT INSERT ON  [dbo].[JBMO] TO [public]
GRANT DELETE ON  [dbo].[JBMO] TO [public]
GRANT UPDATE ON  [dbo].[JBMO] TO [public]
GO
