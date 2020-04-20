SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBCC] as select a.* From bJBCC a

GO
GRANT SELECT ON  [dbo].[JBCC] TO [public]
GRANT INSERT ON  [dbo].[JBCC] TO [public]
GRANT DELETE ON  [dbo].[JBCC] TO [public]
GRANT UPDATE ON  [dbo].[JBCC] TO [public]
GO
