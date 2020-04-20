SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[vrvJCProjectionByContractMonth]

/***
 CREATED:  10/14/2011 DH
 MODIFIED:  

 USAGE:  View returns projected, estimated, and contract amounts by contract and month.  Used in the Monthly
 Project Trend SSRS report part for BI.
 
 
 ****/

AS

--cteCostRevenue:  Get Cost and Revenue from JCIP and JCCP
WITH 
 

cteCostRevenue 

AS

(SELECT
	JCIP.JCCo,
	JCIP.Contract,
	JCIP.Mth,
	JCIP.ProjDollars,
	JCIP.ContractAmt,
	JCIP.BilledAmt,
	0 as CurrEstCost,
	0 as ProjCost

FROM 
	JCIP
WHERE
	JCIP.ContractAmt<>0		
	
UNION ALL

SELECT
	JCCP.JCCo,
	JCJP.Contract,
	JCCP.Mth,
	0 as ProjDollars,
	0 as ContractAmt,
	0 as BilledAmt,
	JCCP.CurrEstCost,
	JCCP.ProjCost
	
FROM
	JCCP
	
		INNER JOIN
	JCJP
		ON  JCJP.JCCo = JCCP.JCCo
		AND JCJP.Job = JCCP.Job
		AND JCJP.PhaseGroup = JCCP.PhaseGroup
		AND JCJP.Phase = JCCP.Phase
WHERE
	JCCP.CurrEstCost<>0 or JCCP.ProjCost<>0		
		
		
		
			
)

/***
  Summarize cteCostRevenue by Contract and Month.  

***/  

SELECT
	a.JCCo,
	a.Contract,
	a.Mth,
	SUM(a.ContractAmt) as ContractAmount,
	SUM(a.CurrEstCost) as CurrEstCost,
	SUM(a.ProjCost) as ProjectedCost		 
	
FROM cteCostRevenue a


GROUP BY
	a.JCCo,
	a.Contract,
	a.Mth	




	
	

	
		

GO
GRANT SELECT ON  [dbo].[vrvJCProjectionByContractMonth] TO [public]
GRANT INSERT ON  [dbo].[vrvJCProjectionByContractMonth] TO [public]
GRANT DELETE ON  [dbo].[vrvJCProjectionByContractMonth] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCProjectionByContractMonth] TO [public]
GRANT SELECT ON  [dbo].[vrvJCProjectionByContractMonth] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCProjectionByContractMonth] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCProjectionByContractMonth] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCProjectionByContractMonth] TO [Viewpoint]
GO
