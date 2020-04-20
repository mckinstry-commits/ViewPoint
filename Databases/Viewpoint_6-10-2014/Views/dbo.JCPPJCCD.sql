SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPPJCCD] as 
/***********************************
* Created By:	GF 01/30/2009
* Modified By:
*
* Used to accumulate JCCD EstUnits, ProjUnits, ActualUnits for display
* in JC Prgress Entry form.
*
***************************************/

select top 100 percent
		JCPP.Co, JCPP.Mth, JCPP.BatchId, JCPP.BatchSeq, JCPP.Job, JCPP.PhaseGroup, JCPP.Phase, JCPP.CostType,
		isnull(sum(JCCD.EstUnits),0) as [CurrentEstimated],
		isnull(sum(JCCD.ProjUnits),0) as [CurrentProjected],
		isnull(sum(JCCD.ActualUnits),0) as [CurrentCompleted]
from dbo.bJCPP JCPP with (nolock)
join dbo.bJCCH JCCH with (nolock) on JCCH.JCCo=JCPP.Co and JCCH.Job=JCPP.Job and JCCH.PhaseGroup=JCPP.PhaseGroup
and JCCH.Phase=JCPP.Phase and JCCH.CostType=JCPP.CostType
left join dbo.bJCCD JCCD with (nolock) on JCCD.JCCo=JCPP.Co and JCCD.Job=JCPP.Job and JCCD.PhaseGroup=JCPP.PhaseGroup
and JCCD.Phase=JCPP.Phase and JCCD.CostType=JCPP.CostType and JCCH.UM=JCCD.UM and JCCD.ActualDate<=JCPP.ActualDate
group by JCPP.Co, JCPP.Mth, JCPP.BatchId, JCPP.BatchSeq, JCPP.Job, JCPP.Phase, JCPP.PhaseGroup, JCPP.CostType

GO
GRANT SELECT ON  [dbo].[JCPPJCCD] TO [public]
GRANT INSERT ON  [dbo].[JCPPJCCD] TO [public]
GRANT DELETE ON  [dbo].[JCPPJCCD] TO [public]
GRANT UPDATE ON  [dbo].[JCPPJCCD] TO [public]
GRANT SELECT ON  [dbo].[JCPPJCCD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPPJCCD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPPJCCD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPPJCCD] TO [Viewpoint]
GO
