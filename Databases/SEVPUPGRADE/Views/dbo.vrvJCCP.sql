SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view

[dbo].[vrvJCCP]

as

select JCCP.*, JCJP.Contract, JCJP.Item From JCCP
Join JCJP on JCJP.JCCo=JCCP.JCCo and JCJP.Job=JCCP.Job and
  JCJP.PhaseGroup=JCCP.PhaseGroup and JCJP.Phase= JCCP.Phase


GO
GRANT SELECT ON  [dbo].[vrvJCCP] TO [public]
GRANT INSERT ON  [dbo].[vrvJCCP] TO [public]
GRANT DELETE ON  [dbo].[vrvJCCP] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCCP] TO [public]
GO
