SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCMC] as select a.* From bJCMC a

GO
GRANT SELECT ON  [dbo].[JCMC] TO [public]
GRANT INSERT ON  [dbo].[JCMC] TO [public]
GRANT DELETE ON  [dbo].[JCMC] TO [public]
GRANT UPDATE ON  [dbo].[JCMC] TO [public]
GO
