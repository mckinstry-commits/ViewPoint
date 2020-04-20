SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBCX] as select a.* From bJBCX a

GO
GRANT SELECT ON  [dbo].[JBCX] TO [public]
GRANT INSERT ON  [dbo].[JBCX] TO [public]
GRANT DELETE ON  [dbo].[JBCX] TO [public]
GRANT UPDATE ON  [dbo].[JBCX] TO [public]
GO
