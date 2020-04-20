SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCOverrides] as
select JCCo, Month, Month as MonthFilter
from JCOP with (nolock) where JCOP.Month is not null
union
select JCCo, Month, Month
from JCOR with (nolock) where JCOR.Month is not null
union
select GLCo as JCCo, Mth as Month, Mth as Month
from GLFP with (nolock) where GLFP.Mth is not null
----union
----select JCCo, StartMonth as Month, StartMonth as Month
----from JCCM with (nolock) where JCCM.StartMonth is not null

GO
GRANT SELECT ON  [dbo].[JCOverrides] TO [public]
GRANT INSERT ON  [dbo].[JCOverrides] TO [public]
GRANT DELETE ON  [dbo].[JCOverrides] TO [public]
GRANT UPDATE ON  [dbo].[JCOverrides] TO [public]
GO
