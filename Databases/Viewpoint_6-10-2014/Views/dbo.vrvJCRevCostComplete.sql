SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[vrvJCRevCostComplete]

as

With RevData

as

-- Revenue
(SELECT  
	JCIP.JCCo
,	JCIP.Contract
,	JCIP.Item
,	JCIP.Mth
,	Row_Number() OVER (Partition BY JCCo,Contract,Item
							 ORDER BY JCCo,Contract,Item, Mth) AS RowNumber
,	JCIP.ContractAmt
,	JCIP.ProjDollars

FROM
	JCIP With (NoLock)),

CostData

as

(SELECT 
	JCCP.JCCo
,	JCJP.Contract
,	JCJP.Item
,	JCCP.Mth    
,	JCCP.Job
,	JCCP.PhaseGroup
,	JCCP.Phase
,	JCCP.CostType
,	Row_Number() OVER (Partition BY JCCP.JCCo, JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType
				    	 ORDER BY JCCP.JCCo, JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType, JCCP.Mth) AS RowNumber
,	JCCP.ActualCost
,	JCCP.CurrEstCost
,	JCCP.ProjCost
,	JCCP.ProjPlug


FROM 
	JCCP With (NoLock)
		INNER JOIN 
	JCJP With (NoLock) 
		ON  JCCP.JCCo		= JCJP.JCCo 
		AND JCCP.Job		= JCJP.Job 
		AND JCCP.Phase		= JCJP.Phase 
		AND JCCP.PhaseGroup = JCJP.PhaseGroup 
),


Revenue_with_Previous

as

(Select a.JCCo, a.Contract, a.Item, a.Mth
		
		,max(a.ContractAmt) as ContractAmt
		,max(a.ProjDollars) as ProjDollars
		,sum(Prev.ContractAmt) as ContractAmtPrev
		,sum(Prev.ProjDollars) as ProjDollarsPrev
		,case when max(a.ProjDollars)+isnull(sum(Prev.ProjDollars),0)<>0
				  then max(a.ProjDollars)+isnull(sum(Prev.ProjDollars),0)
		      else max(a.ContractAmt) + isnull(sum(Prev.ContractAmt),0)
		 end as EstRevComplete
		,case when isnull(sum(Prev.ProjDollars),0)<>0
				  then isnull(sum(Prev.ProjDollars),0)
			  else isnull(sum(Prev.ContractAmt),0)
		  end as EstRevCompletePrev	
		--,(max(a.ContractAmt)+isnull(sum(Prev.ContractAmt),0)) - isnull(sum(Prev.ContractAmt),0) as ContractAmtToDate
		--,(max(a.ProjDollars)+isnull(sum(Prev.ProjDollars),0)) - isnull(sum(Prev.ProjDollars),0) as ProjDollarsToDate
		/*, case when max(a.ProjDollars)<>0 and isnull(sum(Prev.ProjDollars),0)=0 
					then max(a.ProjDollars) - isnull(sum(Prev.ContractAmt),0)
			   when max(a.ProjDollars) + isnull(sum(Prev.ProjDollars),0) = 0 and max(a.ProjDollars)<>0
					then isnull(sum(Prev.ContractAmt),0) - isnull(sum(Prev.ProjDollars),0)
			   when isnull(sum(Prev.ProjDollars),0)<>0 
					then max(a.ProjDollars)
			   else max(a.ContractAmt)
		   end as EstRevComplete */


 From RevData a
 Left Outer Join RevData Prev
	ON  a.JCCo=Prev.JCCo
	AND a.Contract=Prev.Contract
	AND a.Item=Prev.Item
	AND a.RowNumber > Prev.RowNumber
  Group by a.JCCo, a.Contract, a.Item, a.Mth),

Cost_with_Previous

as

(Select a.JCCo, a.Contract, a.Item, a.Job, a.PhaseGroup, a.Phase, a.CostType, a.Mth
		,max(a.CurrEstCost) as CurrEstCost
		,max(a.ActualCost) as ActualCost
		,max(a.ProjCost) as ProjCost
		,max(a.ProjPlug) as ProjPlug
		,sum(Prev.CurrEstCost) as CurrEstCostPrev
		,sum(Prev.ActualCost) as ActualCostPrev
		,max(a.ActualCost) + isnull(sum(Prev.ActualCost),0) as ActualCostToDate
		,sum(Prev.ProjCost) as ProjCostPrev
		,max(Prev.ProjPlug) as ProjPlugPrev
		,case when (max(a.ProjPlug)='Y' or isnull(max(Prev.ProjPlug),'N')='Y' 
					 or max(a.ProjCost)+isnull(sum(Prev.ProjCost),0)<>0)
					then max(a.ProjCost) + isnull(sum(Prev.ProjCost),0)
			  else  max(a.CurrEstCost) + isnull(sum(Prev.CurrEstCost),0)
		 end as EstCostComplete	
		,case when    isnull(max(Prev.ProjPlug),'N')='Y'
				    or  isnull(sum(Prev.ProjCost),0)<>0
				   	then isnull(sum(Prev.ProjCost),0)
			   else isnull(sum(Prev.CurrEstCost),0)
		 end  as EstCostCompletePrev
		/*, case when (max(a.ProjCost)<>0 /*or max(a.ProjPlug)='Y'*/) and isnull(sum(Prev.ProjCost),0)=0 and isnull(max(Prev.ProjPlug),'N')='N'
					then max(a.ProjCost) - isnull(sum(Prev.CurrEstCost),0)

			   when max(a.ProjPlug)='Y' and isnull(max(Prev.ProjPlug),'N')='N' and isnull(sum(Prev.ProjCost),0)=0 
					then max(a.ProjCost) - isnull(sum(Prev.CurrEstCost),0)
			   
			   when max(a.ProjCost) + isnull(sum(Prev.ProjCost),0) = 0 and max(a.ProjCost)<>0 and max(a.ProjPlug)='N'
					then isnull(sum(Prev.CurrEstCost),0) - isnull(sum(Prev.ProjCost),0)
											   
			   when max(a.ProjCost) + isnull(sum(Prev.ProjCost),0) = 0 and max(a.ProjCost)<>0 and max(a.ProjPlug)='Y'
					then max(a.ProjCost)			   
	
			   when isnull(sum(Prev.ProjCost),0)<>0 
					then max(a.ProjCost)

			   when max(Prev.ProjPlug)='Y'
					then max(a.ProjCost)

			   else max(a.CurrEstCost)
		   end as EstCostComplete */

  From CostData a
	Left Outer Join CostData Prev
	ON  a.JCCo=Prev.JCCo
	AND a.Job=Prev.Job
	AND a.PhaseGroup=Prev.PhaseGroup
	AND a.Phase=Prev.Phase
	AND a.CostType=Prev.CostType
	AND a.RowNumber > Prev.RowNumber

 Group By a.JCCo, a.Contract, a.Item, a.Job, a.PhaseGroup, a.Phase, a.CostType, a.Mth),

CostRev

as

(select    r.JCCo
		, r.Contract
		, r.Item
		, r.Mth
		, NULL as Job
		, NULL as PhaseGroup
		, NULL as Phase
		, NULL as CostType
		, r.ContractAmt
		, r.ProjDollars
		, r.ContractAmtPrev
		, r.ProjDollarsPrev
		, r.EstRevComplete
		, r.EstRevCompletePrev
		, r.EstRevComplete - r.EstRevCompletePrev as EstRevCompleteMth
		, 0 as CurrEstCost
		, 0 as ProjCost
		, 0 as CurrEstCostPrev
		, 0 as ProjCostPrev
		, NULL as ProjPlug
		, NULL as ProjPlugPrev
		, 0 as EstCostComplete
		, 0 as EstCostCompletePrev
		, 0 as EstCostCompleteMth
		, 0 as ActualCost
		, 0 as ActualCostPrev
		, 0 as ActualCostToDate
from Revenue_with_Previous r

union all

select    c.JCCo
		, c.Contract
		, c.Item
		, c.Mth
		, c.Job
		, c.PhaseGroup
		, c.Phase
		, c.CostType
		, 0 as ContractAmt
		, 0 as ProjDollars
		, 0 as ContractAmtPrev
		, 0 as ProjDollarsPrev
		, 0 as EstRevComplete
		, 0 as EstRevCompletePrev
		, 0 as EstRevCompleteMth
		, c.CurrEstCost
		, c.ProjCost
		, c.CurrEstCostPrev
		, c.ProjCostPrev
		, c.ProjPlug
		, c.ProjPlugPrev
		, c.EstCostComplete
		, c.EstCostCompletePrev
		, c.EstCostComplete - c.EstCostCompletePrev as EstCostCompleteMth
		, c.ActualCost
		, c.ActualCostPrev
		, c.ActualCostToDate
from Cost_with_Previous c),

RevCostCompleteToDate

as


(SELECT   JCCo
		, Contract
		, Mth
		, Row_Number() OVER (Partition BY JCCo,Contract
							 ORDER BY JCCo,Contract, Mth) AS RowNumber
		, sum(EstRevCompleteMth) as EstRevComplete
		, sum(EstCostCompleteMth) as EstCostComplete
		, sum(ActualCost) as ActualCost
		/*, case when sum(EstRevComplete) - sum(EstCostComplete) <= 0
					then sum(EstRevComplete) + sum(ActualCostToDate) - sum(EstCostComplete)
	 		   when sum(EstCostComplete)<>0 
					then (sum(ActualCostToDate)/sum(EstCostComplete))*sum(EstRevComplete)
		  end
		 as EarnedRevenueToDate*/

 From CostRev
 Group By JCCo, Contract, Mth
)


SELECT	  a.JCCo
		, a.Contract
		, a.Mth
		, Row_Number() OVER (Partition BY a.JCCo,a.Contract
							 ORDER BY a.JCCo,a.Contract, a.Mth) AS RowNumberByMth
		, max(a.EstRevComplete) as EstRevComplete
		, max(a.EstCostComplete) as EstCostComplete
		, max(a.ActualCost) as ActualCost
		, sum(Prev.ActualCost) as ActualCostToDate
		--, max(a.EarnedRevenueToDate) as EarnedRevenueToDate
		--, sum(Prev.EarnedRevenueToDate) as EarnedRevenuePrevious
		, sum(Prev.EstRevComplete) as EstRevCompleteToDate
		, sum(Prev.EstCostComplete) as EstCostCompleteToDate
		, case when sum(Prev.EstRevComplete) - sum(Prev.EstCostComplete) <=0
				  then sum(Prev.ActualCost) + sum(Prev.EstRevComplete) - sum(Prev.EstCostComplete)
			   when sum(Prev.EstCostComplete)<> 0
				  then (sum(Prev.ActualCost)/sum(Prev.EstCostComplete))*sum(Prev.EstRevComplete)
		  end as EarnRevToDate
From RevCostCompleteToDate a
Left Join RevCostCompleteToDate Prev
	ON  a.JCCo=Prev.JCCo
	AND a.Contract=Prev.Contract
	AND a.RowNumber >= Prev.RowNumber


Group By  a.JCCo
		, a.Contract
		, a.Mth

 


	
	


		




GO
GRANT SELECT ON  [dbo].[vrvJCRevCostComplete] TO [public]
GRANT INSERT ON  [dbo].[vrvJCRevCostComplete] TO [public]
GRANT DELETE ON  [dbo].[vrvJCRevCostComplete] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCRevCostComplete] TO [public]
GRANT SELECT ON  [dbo].[vrvJCRevCostComplete] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCRevCostComplete] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCRevCostComplete] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCRevCostComplete] TO [Viewpoint]
GO
