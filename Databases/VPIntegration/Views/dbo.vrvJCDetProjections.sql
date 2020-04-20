SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[vrvJCDetProjections]
 
AS 

Select Src = 'PR'	
, KeyID	
, JCCo	
, Mth	
, ResTrans	
, Job	
, PhaseGroup	
, Phase	
, CostType	
, PostedDate	
, ActualDate	
, JCTransType	
, Source	
, BudgetCode	
, EMCo	
, Equipment	
, PRCo	
, Craft	
, Class	
, Employee	
, Description	
, DetMth	
, FromDate	
, Quantity	
, ToDate	
, UM	
, Units	
, UnitHours	
, Hours	
, Rate	
, UnitCost	
, Amount	
, BatchId	
, InUseBatchId	
, Notes	
, UniqueAttchID	
, NULL AS ActualCost	
, NULL AS OrigEstHours	
, NULL AS OrigEstUnits	
, NULL AS OrigEstCost	
, NULL AS CurrEstHours	
, NULL AS CurrEstUnits	
, NULL AS CurrEstCost	
, NULL AS ProjHours	
, NULL AS ProjUnits	
, NULL AS ProjCost	
, NULL AS ForecastHours	
, NULL AS ForecastUnits	
, NULL AS ForecastCost	
, NULL AS TotalCmtdUnits	
, NULL AS TotalCmtdCost	
, NULL AS RemainCmtdUnits	
, NULL AS RemainCmtdCost	
, NULL AS RecvdNotInvcdUnits	
, NULL AS RecvdNotInvcdCost	
, NULL AS ProjPlug	
From JCPR with (nolock)	
		
Union All

Select distinct 'CP'
, NULL AS KeyID
, JCCP.JCCo
, JCCP.Mth
, NULL AS ResTrans
, JCCP.Job
, JCCP.PhaseGroup
, JCCP.Phase
, JCCP.CostType
, NULL AS PostedDate
, NULL AS ActualDate
, NULL AS JCTransType
, NULL AS Source
, NULL AS BudgetCode
, NULL AS EMCo
, NULL AS Equipment
, NULL AS PRCo
, NULL AS Craft
, NULL AS Class
, NULL AS Employee
, NULL AS Description
, NULL AS DetMth
, NULL AS FromDate
, NULL AS Quantity
, NULL AS ToDate
, NULL AS UM
, JCCP.ActualUnits
, NULL AS UnitHours
, JCCP.ActualHours
, NULL AS Rate
, NULL AS UnitCost
, NULL AS Amount
, NULL AS BatchId
, NULL AS InUseBatchId
, NULL AS Notes
, NULL AS UniqueAttchID
, JCCP.ActualCost
, JCCP.OrigEstHours
, JCCP.OrigEstUnits
, JCCP.OrigEstCost
, JCCP.CurrEstHours
, JCCP.CurrEstUnits
, JCCP.CurrEstCost
, JCCP.ProjHours
, JCCP.ProjUnits
, JCCP.ProjCost
, JCCP.ForecastHours
, JCCP.ForecastUnits
, JCCP.ForecastCost
, JCCP.TotalCmtdUnits
, JCCP.TotalCmtdCost
, JCCP.RemainCmtdUnits
, JCCP.RemainCmtdCost
, JCCP.RecvdNotInvcdUnits
, JCCP.RecvdNotInvcdCost
, JCCP.ProjPlug
From JCCP

--Left Outer Join JCPR with (nolock) on JCCP.JCCo=JCPR.JCCo
--	and JCCP.Job=JCPR.Job
--	and JCCP.Phase=JCPR.Phase
--	and JCCP.PhaseGroup=JCPR.PhaseGroup
--	and JCCP.CostType=JCPR.CostType


GO
GRANT SELECT ON  [dbo].[vrvJCDetProjections] TO [public]
GRANT INSERT ON  [dbo].[vrvJCDetProjections] TO [public]
GRANT DELETE ON  [dbo].[vrvJCDetProjections] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCDetProjections] TO [public]
GO
