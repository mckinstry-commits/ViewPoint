SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBCE] as select a.* From bJBCE a

GO
GRANT SELECT ON  [dbo].[JBCE] TO [public]
GRANT INSERT ON  [dbo].[JBCE] TO [public]
GRANT DELETE ON  [dbo].[JBCE] TO [public]
GRANT UPDATE ON  [dbo].[JBCE] TO [public]
GO
