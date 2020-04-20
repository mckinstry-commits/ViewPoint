SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[vrvJCLastMonthOfActivityByContract]

/***
 CREATED:  9/7/11 DH
 MODIFIED:
 
 USAGE:
	View selects the last Mth from either JCIP or JCCP.  Used by
	Net Cash Flow SSRS report parts to join the last month of
	revenue or cost activity by contract to vrvJCNetCashFlow view.
	
 ****/	

AS

WITH cteCostRev

as

(
	SELECT
		JCCo,
		Contract,
		Mth
	FROM
		JCIP
	
 UNION ALL
  
	SELECT
		JCJP.JCCo,
		JCJP.Contract,
		JCCP.Mth
	FROM JCCP
		INNER JOIN
	JCJP
		ON  JCJP.JCCo = JCCP.JCCo
		AND JCJP.Job = JCCP.Job
		AND JCJP.PhaseGroup = JCCP.PhaseGroup
		AND JCJP.Phase = JCCP.Phase

)				
	 			

SELECT
	JCCo,
	Contract,
	max(Mth) as LastMonthOfActivity
FROM cteCostRev
GROUP BY JCCo,
		 Contract
	


	
GO
GRANT SELECT ON  [dbo].[vrvJCLastMonthOfActivityByContract] TO [public]
GRANT INSERT ON  [dbo].[vrvJCLastMonthOfActivityByContract] TO [public]
GRANT DELETE ON  [dbo].[vrvJCLastMonthOfActivityByContract] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCLastMonthOfActivityByContract] TO [public]
GO
