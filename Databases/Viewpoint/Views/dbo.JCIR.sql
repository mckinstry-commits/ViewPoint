SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCIR] as select a.* From bJCIR a

GO
GRANT SELECT ON  [dbo].[JCIR] TO [public]
GRANT INSERT ON  [dbo].[JCIR] TO [public]
GRANT DELETE ON  [dbo].[JCIR] TO [public]
GRANT UPDATE ON  [dbo].[JCIR] TO [public]
GO
