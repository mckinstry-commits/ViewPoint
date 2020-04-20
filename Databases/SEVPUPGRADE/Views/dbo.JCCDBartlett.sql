SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[JCCDBartlett]  as select JCCo, Job, Phase, CostType, Mth, 'ActualCost'=sum(isnull(ActualCost,0))
from JCCD
Group By JCCo, Job, Phase, CostType, Mth


GO
GRANT SELECT ON  [dbo].[JCCDBartlett] TO [public]
GRANT INSERT ON  [dbo].[JCCDBartlett] TO [public]
GRANT DELETE ON  [dbo].[JCCDBartlett] TO [public]
GRANT UPDATE ON  [dbo].[JCCDBartlett] TO [public]
GO
