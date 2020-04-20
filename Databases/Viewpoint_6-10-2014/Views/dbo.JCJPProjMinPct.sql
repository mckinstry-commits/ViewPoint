SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 10/16/2008 - view to replace user-defined function
* Modfied By:	GF 11/14/2008 - issue #131089 use base tables instead of views
*
*
* Provides a view of Phase ProjMinPct from JCJP, JCJM, JCCO
* returned to JC Cost Projections form
*
*****************************************/
   
CREATE view [dbo].[JCJPProjMinPct] as 
select p.JCCo, p.Job, p.Phase,
		'ProjMinPct' = case when isnull(p.ProjMinPct,0) <> 0 then p.ProjMinPct
						    when isnull(j.ProjMinPct,0) <> 0 then j.ProjMinPct
						    when isnull(c.ProjMinPct,0) <> 0 then c.ProjMinPct
						    else 0 end
from bJCJP p with (nolock)
join bJCJM j with (nolock) on j.JCCo=p.JCCo and j.Job=p.Job
join bJCCO c with (nolock) on c.JCCo=p.JCCo

GO
GRANT SELECT ON  [dbo].[JCJPProjMinPct] TO [public]
GRANT INSERT ON  [dbo].[JCJPProjMinPct] TO [public]
GRANT DELETE ON  [dbo].[JCJPProjMinPct] TO [public]
GRANT UPDATE ON  [dbo].[JCJPProjMinPct] TO [public]
GRANT SELECT ON  [dbo].[JCJPProjMinPct] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCJPProjMinPct] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCJPProjMinPct] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCJPProjMinPct] TO [Viewpoint]
GO
