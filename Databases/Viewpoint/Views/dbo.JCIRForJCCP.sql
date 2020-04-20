SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
* Created By:	GF 06/16/2008
* Modfied By:	GF 12/19/2009 - issue #137146
*
* Provides a view of Future Change Orders from JC and PM for Revenue Projections.
*
*****************************************/

CREATE view [dbo].[JCIRForJCCP] as
	select JCIR.Co, JCIR.Mth, JCIR.Contract, JCIR.Item, cast(isnull(sum(JCCP.ProjCost),0) as numeric(20,2)) as ProjCost
from dbo.JCIR JCIR with (nolock)
join dbo.JCJM JCJM with (nolock) on JCJM.JCCo=JCIR.Co and JCJM.Contract=JCIR.Contract
left join dbo.JCJP JCJP with (nolock) on JCJP.JCCo=JCIR.Co and JCJP.Job=JCJM.Job and JCJP.Item=JCIR.Item
left join dbo.JCCP JCCP with (nolock) on JCCP.JCCo=JCIR.Co and JCCP.Job=JCJM.Job and JCCP.Mth<=JCIR.Mth and JCCP.Phase=JCJP.Phase
group by JCIR.Co, JCIR.Mth, JCIR.Contract, JCIR.Item


GO
GRANT SELECT ON  [dbo].[JCIRForJCCP] TO [public]
GRANT INSERT ON  [dbo].[JCIRForJCCP] TO [public]
GRANT DELETE ON  [dbo].[JCIRForJCCP] TO [public]
GRANT UPDATE ON  [dbo].[JCIRForJCCP] TO [public]
GO
