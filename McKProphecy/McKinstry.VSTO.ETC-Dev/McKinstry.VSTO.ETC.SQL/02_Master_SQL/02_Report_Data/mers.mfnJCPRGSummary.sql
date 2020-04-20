use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCPRGSummary' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJCPRGSummary'
	DROP FUNCTION mers.mfnJCPRGSummary
end
go

print 'CREATE FUNCTION mers.mfnJCPRGSummary'
go

CREATE function [mers].[mfnJCPRGSummary]
(
	@JCCo				bCompany
,	@Contract			bContract
)
-- ========================================================================
-- mfnJCPRGSummary
-- Author:		Ziebell, Jonathan
-- Create date: 07/27/2016
-- Description:	Select SUM of projection values by Project Phase and Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	08/04/2016 WIP Changes
--				J.Ziebell	08/05/2016 Sum Cost By Contract Item before Join	
--              J.Ziebell   08/12/2016 Ad JC Dept and Desc	
--				J.Ziebell   08/15/2016 Field Reorder
--				J.Ziebell   08/31/2016 Prior Month WIP Row, Curr Month Addition, Field Renaming
--				J.Ziebell   09/16/2016 Temp Hide of JTD Earned
--              J.Ziebell   09/23/2016 Temp Hide of JTD Billed 
-- ========================================================================

RETURNS TABLE
AS 
RETURN 
WITH JCIP_Sum 
				( JCCo
				, Contract
				, udPRGNumber
				, Department
				, udPRGDescription
				, OrigContractAmt
				, ContractAmt
				, BilledAmt
				, ProjDollars
				)
		AS (SELECT
				  CI.JCCo
				, CI.Contract
				, CI.udPRGNumber
				, CI.Department
				, MAX(CI.udPRGDescription) 
				, SUM(IP.OrigContractAmt)
				, SUM(IP.ContractAmt)
				, SUM(IP.BilledAmt)
				, SUM(IP.ProjDollars)
		FROM JCCI CI
			INNER JOIN JCIP IP
				ON CI.JCCo = IP.JCCo
				AND CI.Contract = IP.Contract
				AND CI.Item = IP.Item
			WHERE CI.JCCo = @JCCo
				AND CI.Contract = @Contract
			GROUP BY  CI.JCCo
				, CI.Contract
				, CI.udPRGNumber
				, CI.Department
				--, CI.udPRGDescription 
				) ,
	JCCP_Cost 
				( JCCo 
				, Contract
				, udPRGNumber
				, Department
				, ProjectedCost
				, OrigEstCost
				)
		AS (SELECT 
				  JM.JCCo
				, CI.Contract
				, CI.udPRGNumber
				, CI.Department
				, sum(CP.ProjCost) AS ProjectedCost 
				, sum(CP.OrigEstCost) AS OrigEstCost
			FROM JCJM JM
			INNER JOIN JCJP JP 
				ON JP.JCCo = JM.JCCo 
				AND JP.Job = JM.Job 
				AND JP.Contract = JM.Contract
			INNER JOIN JCCP CP
				ON CP.JCCo = JP.JCCo 
				AND CP.Job = JP.Job 
				AND CP.PhaseGroup = JP.PhaseGroup 
				AND CP.Phase = JP.Phase
			INNER JOIN JCCI CI
				ON 	JM.JCCo = CI.JCCo
				AND JP.Contract = CI.Contract
				AND JP.Item = CI.Item
			WHERE JM.JCCo = @JCCo
				AND JM.Contract = @Contract
			GROUP BY  JM.JCCo
					, CI.Contract
					, CI.udPRGNumber
					, CI.Department), 
	WIP_Lock 
				( JCCo
				, Contract 
				, udPRGNumber
				, Department
				, JTDEarnedRev
				--, JTDBilled
				--, OUBilled
				, LockMargin
				)
		AS (SELECT 
				  WIP.JCCo
				, WIP.Contract
				, WIP.PRGNumber AS udPRGnumber
				, WIP.JCCIDepartment
				, MAX(WIP.JTDEarnedRev)
				--, MAX(WIP.JTDBilled)
				--, MAX(WIP.JTDBilled-WIP.JTDEarnedRev) AS OUBilled
				, MAX(ProjFinalGMPerc) AS LockMargin
			FROM mckWipArchiveJC3 WIP
			WHERE WIP.JCCo =  @JCCo
				AND WIP.Contract =  @Contract
				AND WIP.ThroughMonth = (SELECT MAX(WIP2.ThroughMonth) 
											FROM mckWipArchiveJC3 WIP2
											WHERE WIP.JCCo = WIP2.JCCo
											AND WIP.Contract = WIP2.Contract
											AND ((WIP.PRGNumber = WIP2.PRGNumber) OR ((WIP.PRGNumber IS NULL) AND  (WIP2.PRGNumber iS NULL)))
											AND ((WIP.JCCIDepartment = WIP2.JCCIDepartment) OR ((WIP.JCCIDepartment IS NULL) AND (WIP2.JCCIDepartment iS NULL)))
											AND WIP2.ThroughMonth <= DATEADD(Month,-1,SYSDATETIME())
											--AND WIP2.ThroughMonth >='01-MAY-2016'
											)
			GROUP BY 
				  WIP.JCCo
				, WIP.Contract
				, WIP.PRGNumber
				, WIP.JCCIDepartment
				),
		WIP_Cur
				( JCCo
				, Contract 
				, udPRGNumber
				, Department
				, JTDBilled
				, OUBilled
				)
			AS (SELECT 
				  WIPC.JCCo
				, WIPC.Contract
				, WIPC.PRGNumber AS udPRGnumber
				, WIPC.JCCIDepartment
				, MAX(WIPC.JTDBilled)
				, MAX(WIPC.JTDBilled-WIPC.JTDEarnedRev) AS OUBilled
			FROM mckWipArchiveJC3 WIPC
			WHERE WIPC.JCCo =  @JCCo
				AND WIPC.Contract =  @Contract
				AND WIPC.ThroughMonth = (SELECT MAX(WIP2C.ThroughMonth) 
											FROM mckWipArchiveJC3 WIP2C
											WHERE WIPC.JCCo = WIP2C.JCCo
											AND WIPC.Contract = WIP2C.Contract
											AND ((WIPC.PRGNumber = WIP2C.PRGNumber) OR ((WIPC.PRGNumber IS NULL) AND  (WIP2C.PRGNumber iS NULL)))
											AND ((WIPC.JCCIDepartment = WIP2C.JCCIDepartment) OR ((WIPC.JCCIDepartment IS NULL) AND (WIP2C.JCCIDepartment iS NULL)))
											AND WIP2C.ThroughMonth <= SYSDATETIME()
											--AND WIP2C.ThroughMonth >='01-MAY-2016'
											)
			GROUP BY 
				  WIPC.JCCo
				, WIPC.Contract
				, WIPC.PRGNumber
				, WIPC.JCCIDepartment
				)  

SELECT
		  S.udPRGNumber AS 'PRG'
		, S.udPRGDescription AS 'PRG Description'
		, S.Department AS 'JC Dept'
		, DM.Description AS 'JC Dept Description'
		, C.ProjectedCost AS 'Projected Cost'
		, S.OrigContractAmt AS 'Original Contract'
		, S.ContractAmt As 'Current Contract'
		, S.ProjDollars as 'Projected Contract'
		, (S.ProjDollars-S.ContractAmt) as 'Unbooked Contract Adjustments'
		, TOT.PMFutureCO AS 'Future CO'
		, '' /*W.JTDEarnedRev*/ AS 'Last Month Earned Revenue'   --'JTD Earned Revenue'
		, '' /*R.JTDBilled*/ AS 'Billed to Date'
		, '' /*R.OUBilled*/ AS 'Estimated Over/(Under) Billed'
		, CASE WHEN (C.OrigEstCost) <= 0 THEN 1 
				WHEN (S.OrigContractAmt) > 0 THEN ((S.OrigContractAmt-C.OrigEstCost)/S.OrigContractAmt)
				WHEN (S.OrigContractAmt) = 0 THEN -1
				ELSE -1 END AS 'Original Margin'
		--, (S.ContractAmt-C.ProjectedCost) AS 'Current Margin Dollars'
		, CASE WHEN (C.ProjectedCost) <= 0 THEN 1 
				WHEN (S.ContractAmt) > 0 THEN ((S.ContractAmt-C.ProjectedCost)/S.ContractAmt)
				WHEN (S.ContractAmt) = 0 THEN -1
				ELSE -1 END AS 'Current Margin'
		, CAST(W.LockMargin AS DECIMAL(18,10)) AS 'Last Month Margin'  --'Last Closed Margin'
		, (S.ProjDollars - C.ProjectedCost) AS 'Projected Margin $'
		, CASE WHEN (C.ProjectedCost) <= 0 THEN 1 
				WHEN (S.ProjDollars) > 0 THEN ((S.ProjDollars-C.ProjectedCost)/S.ProjDollars) 
				WHEN (S.ProjDollars) = 0 THEN -1
				ELSE -1 END AS 'Projected Margin %'
		, 'CALCME' AS 'Margin Variance'
	FROM JCIP_Sum S
		INNER JOIN HQCO HQ
			ON S.JCCo = HQ.HQCo
			AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
		LEFT OUTER JOIN	JCDM DM
			ON S.JCCo = DM.JCCo
			AND S.Department = DM.Department 
		LEFT OUTER JOIN PMJCJMTotals TOT
			ON TOT.PMCo = S.JCCo
			AND TOT.Project = S.udPRGNumber
		LEFT OUTER JOIN JCCP_Cost C
			ON S.JCCo = C.JCCo
			AND S.Contract = C.Contract
			AND S.udPRGNumber = C.udPRGNumber
			AND S.Department = C.Department
		LEFT OUTER JOIN WIP_Lock W
			ON W.JCCo = S.JCCo
			AND W.Contract = S.Contract
			AND W.udPRGNumber = S.udPRGNumber
			AND W.Department = S.Department
		LEFT OUTER JOIN WIP_Cur R
			ON R.JCCo = S.JCCo
			AND R.Contract = S.Contract
			AND R.udPRGNumber = S.udPRGNumber
			AND R.Department = S.Department
	WHERE S.JCCo = @JCCo
		AND S.Contract = @Contract

GO

Grant SELECT ON mers.mfnJCPRGSummary TO [MCKINSTRY\Viewpoint Users]