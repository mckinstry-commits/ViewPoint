SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBIS] as select a.* From bJBIS a
GO
GRANT SELECT ON  [dbo].[JBIS] TO [public]
GRANT INSERT ON  [dbo].[JBIS] TO [public]
GRANT DELETE ON  [dbo].[JBIS] TO [public]
GRANT UPDATE ON  [dbo].[JBIS] TO [public]
GO
