SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCOverridesCost] as
select JCJM.JCCo, JCJM.Job, JCJM.Description, JCOP.Month, JCOP.ProjCost, JCOP.OtherAmount
from bJCJM JCJM with (nolock)
left join bJCOP JCOP with (nolock)
on JCJM.JCCo = JCOP.JCCo and JCJM.Job = JCOP.Job

GO
GRANT SELECT ON  [dbo].[JCOverridesCost] TO [public]
GRANT INSERT ON  [dbo].[JCOverridesCost] TO [public]
GRANT DELETE ON  [dbo].[JCOverridesCost] TO [public]
GRANT UPDATE ON  [dbo].[JCOverridesCost] TO [public]
GRANT SELECT ON  [dbo].[JCOverridesCost] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCOverridesCost] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCOverridesCost] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCOverridesCost] TO [Viewpoint]
GO
