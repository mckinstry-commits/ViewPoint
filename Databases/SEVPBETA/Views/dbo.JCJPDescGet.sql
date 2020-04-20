SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 02/15/2008 - issue #126933
* Modfied By:
*
*
*****************************************/

CREATE view [dbo].[JCJPDescGet] as 
select JCCo, Job, PhaseGroup, Phase, Description
from dbo.JCJP with (nolock)
union
select '' as JCCo, '' as Job, PhaseGroup, Phase, Description
from dbo.JCPM with (nolock)
union
select top 1 1 JCCo, Job, PhaseGroup, Phase, Description
from dbo.JCJP with (nolock)
join JCCO with (nolock) on JCCO.JCCo=JCJP.JCCo
where isnull(JCCO.ValidPhaseChars,0) <> 0 and Phase like substring(Phase,1,JCCO.ValidPhaseChars) + '%'

GO
GRANT SELECT ON  [dbo].[JCJPDescGet] TO [public]
GRANT INSERT ON  [dbo].[JCJPDescGet] TO [public]
GRANT DELETE ON  [dbo].[JCJPDescGet] TO [public]
GRANT UPDATE ON  [dbo].[JCJPDescGet] TO [public]
GO
