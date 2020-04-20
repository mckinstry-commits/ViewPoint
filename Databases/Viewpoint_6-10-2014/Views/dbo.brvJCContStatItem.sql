SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   VIEW [dbo].[brvJCContStatItem] AS

/**************************************************
 * Usage:  Used by JC Project Status Report which sorts 
 *			by Company, Contract, and Contract Item.  
 *			Columns include Original Budget, Change Orders, 
 *			Through Change Order Number (Owner Change Order Number), 
 *			Current Budget,  Pending Change Orders, Budget, 
 *			Original Estimated Cost, Change Orders, 
 *			Current Estimated Cost, Projected Cost, 
 *			Pending Change Order for the estimate,
 *			Final Forecast, Projected Profit/Loss, and Job to Date Cost.
 *
 * ALTERED: HH 2010-11-15 - #133542 include only data with a status code 
 *			of "Display in Projections" or "Display and Calculate Projections".
 **************************************************/
  
SELECT	Company=JCCI.JCCo
		, Contract=JCCI.Contract
		, Item=JCCI.Item
		, Job=null,Month='1/1/1950'
		, OrigContractAmt=JCCI.OrigContractAmt
		, ContractAmt=sum(JCID.ContractAmt)
		, CO=(SELECT ACO=MAX(ACO) 
				FROM JCID i WITH (NOLOCK) 
				WHERE ACO IS NOT NULL
						AND JCCI.JCCo=i.JCCo 
						AND JCCI.Contract=i.Contract 
						AND JCCI.Item=i.Item 
				GROUP BY i.JCCo, i.Contract, i.Item)
		, PCOAmount= 0.00
		, ActualCost=0.00
		, CurrEstCost=0.00
		, OrigEstCost=0.00
		, ProjCost=0.00
		, CostPendCo=0.00
FROM JCCI
LEFT JOIN JCID ON JCCI.JCCo=JCID.JCCo 
			AND JCCI.Contract=JCID.Contract 
			AND JCCI.Item=JCID.Item
GROUP BY JCCI.JCCo
		, JCCI.Contract
		, JCCI.Item
		, JCCI.OrigContractUnits
		, JCCI.OrigContractAmt
		, JCCI.OrigUnitPrice
   
UNION ALL
   
SELECT	PMOI.PMCo
		, PMOI.Contract
		, PMOI.ContractItem
		, NULL
		,'1/1/1950'
		, NULL
		, NULL
		, NULL
		, CASE PMOI.FixedAmountYN 
			WHEN 'Y' 
				THEN SUM(PMOI.FixedAmount) 
			ELSE 
				SUM(PMOI.PendingAmount) 
		END
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
FROM PMOI
LEFT JOIN JCCI ON PMOI.PMCo=JCCI.JCCo 
			AND PMOI.Contract=JCCI.Contract 
			AND PMOI.ContractItem=JCCI.Item 
LEFT JOIN PMSC ON PMSC.[Status] = PMOI.[Status] --#133542
WHERE PMOI.ACO IS NULL
		AND PMSC.IncludeInProj IN ('Y','C') --#133542
GROUP BY PMOI.PMCo
		, PMOI.Contract
		, PMOI.ContractItem
		, PMOI.FixedAmountYN
   
UNION ALL
   
SELECT	JCJP.JCCo
		, JCJP.Contract
		, JCJP.Item
		, JCJP.Job
		, CASE 
			WHEN JCCP.Mth IS NULL
				THEN '1/1/1950' 
			ELSE 
				JCCP.Mth 
		END
		, NULL
		, NULL
		, NULL
		, NULL
		, JCCP.ActualCost
		, JCCP.CurrEstCost
		, JCCP.OrigEstCost
		, JCCP.ProjCost
		, NULL
FROM JCJP
LEFT JOIN JCCP ON JCJP.JCCo=JCCP.JCCo 
			AND JCJP.Job=JCCP.Job 
			AND JCJP.PhaseGroup=JCCP.PhaseGroup 
			AND JCJP.Phase=JCCP.Phase

UNION ALL
   
SELECT	JCJP.JCCo
		, JCJP.Contract
		, JCJP.Item
		, JCJP.Job
		, Month='1/1/1950'
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, PMOL.EstCost
FROM JCJP
LEFT JOIN PMOL ON JCJP.JCCo=PMOL.PMCo 
			AND JCJP.Job=PMOL.Project 
			AND JCJP.PhaseGroup=PMOL.PhaseGroup 
			AND JCJP.Phase=PMOL.Phase 
LEFT JOIN PMOI on PMOI.PMCo = PMOL.PMCo --#133542
			AND PMOI.PMCo = PMOL.PMCo 
			AND PMOI.Project = PMOL.Project 
			AND PMOI.PCOType = PMOL.PCOType 
			AND PMOI.PCO = PMOL.PCO 
			AND PMOI.PCOItem = PMOL.PCOItem 
LEFT JOIN PMSC on PMSC.[Status] = PMOI.[Status] --#133542
WHERE PMOL.ACO IS NULL
		AND PMSC.IncludeInProj in ('Y', 'C') --#133542


GO
GRANT SELECT ON  [dbo].[brvJCContStatItem] TO [public]
GRANT INSERT ON  [dbo].[brvJCContStatItem] TO [public]
GRANT DELETE ON  [dbo].[brvJCContStatItem] TO [public]
GRANT UPDATE ON  [dbo].[brvJCContStatItem] TO [public]
GRANT SELECT ON  [dbo].[brvJCContStatItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCContStatItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCContStatItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCContStatItem] TO [Viewpoint]
GO
