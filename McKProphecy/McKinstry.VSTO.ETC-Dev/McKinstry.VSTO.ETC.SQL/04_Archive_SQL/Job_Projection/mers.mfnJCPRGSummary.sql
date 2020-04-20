use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCPRGSummary' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJCPRGSummary'
	DROP FUNCTION mers.mfnJCPRGSummary
end
go

print 'CREATE PROCEDURE mers.mfnJCPRGSummary'
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
-- ========================================================================

RETURNS TABLE
AS 
RETURN 
WITH JCIP_Sum 
				( JCCo
				, Contract
				, udPRGNumber
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
				--, CI.udPRGDescription 
				) ,
	JCCP_Cost 
				( JCCo 
				, udPRGNumber
				, ProjectedCost
				, OrigEstCost
				)
		AS (SELECT 
				  JM.JCCo
				, CI.udPRGNumber
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
					, CI.udPRGNumber), 
	WIP_Lock 
				( JCCo
				, Contract 
				, udPRGNumber
				, JTDEarnedRev
				, JTDBilled
				, OUBilled
				, LockMargin
				)
		AS (SELECT 
				  WIP.JCCo
				, WIP.Contract
				, WIP.PRGNumber AS udPRGnumber
				, MAX(WIP.JTDEarnedRev)
				, MAX(WIP.JTDBilled)
				, MAX(WIP.JTDBilled-WIP.JTDEarnedRev) AS OUBilled
				, MAX(ProjFinalGMPerc) AS LockMargin
			FROM mckWipArchiveJC3 WIP
			WHERE WIP.JCCo = @JCCo
				AND WIP.Contract = @Contract
				AND WIP.ThroughMonth = '01-MAY-2016'
			GROUP BY 
				  WIP.JCCo
				, WIP.Contract
				, WIP.PRGNumber
				) 
SELECT
		  S.udPRGNumber AS 'PRG'
		, S.udPRGDescription AS 'PRG Desc'
		, C.ProjectedCost AS 'Projected Cost'
		, S.OrigContractAmt AS 'Original Contract Value'
		, TOT.PMFutureCO AS 'Future CO Contract Value'
		, S.ContractAmt As 'Current Contract Value'
		, W.JTDBilled AS 'Billed to Date'
		, W.OUBilled AS 'Projected OU Billed'
		, (S.ProjDollars-S.ContractAmt) as 'Calculated Pending CO'
		, CASE WHEN (C.OrigEstCost) <= 0 THEN 1 
				WHEN (S.OrigContractAmt) > 0 THEN ((S.OrigContractAmt-C.OrigEstCost)/S.OrigContractAmt)
				WHEN (S.OrigContractAmt) = 0 THEN -1
				ELSE -1 END AS 'Original Margin'
		--, (S.ContractAmt-C.ProjectedCost) AS 'Current Margin Dollars'
		, CASE WHEN (C.ProjectedCost) <= 0 THEN 1 
				WHEN (S.ContractAmt) > 0 THEN ((S.ContractAmt-C.ProjectedCost)/S.ContractAmt)
				WHEN (S.ContractAmt) = 0 THEN -1
				ELSE -1 END AS 'Current Margin'
		, W.LockMargin AS 'Previous Period Margin'
		, (S.ProjDollars - C.ProjectedCost) AS 'Projected Margin Dollars'
		, CASE WHEN (C.ProjectedCost) <= 0 THEN 1 
				WHEN (S.ProjDollars) > 0 THEN ((S.ProjDollars-C.ProjectedCost)/S.ProjDollars) 
				WHEN (S.ProjDollars) = 0 THEN -1
				ELSE -1 END AS 'Projected Margin'
		, 'CALCME' AS 'JAC Margin Variance'
		, W.JTDEarnedRev AS 'JTD Earned Revenue'
		, S.ProjDollars as 'Projected CV'
	FROM JCIP_Sum S
		INNER JOIN HQCO HQ
			ON S.JCCo = HQ.HQCo
		LEFT OUTER JOIN PMJCJMTotals TOT
			ON TOT.PMCo = S.JCCo
			AND TOT.Project = S.udPRGNumber
		LEFT OUTER JOIN JCCP_Cost C
			ON S.JCCo = C.JCCo
			AND S.udPRGNumber = C.udPRGNumber
		LEFT OUTER JOIN WIP_Lock W
			ON W.JCCo = S.JCCo
			AND W.Contract = S.Contract
			AND W.udPRGNumber = S.udPRGNumber
	WHERE S.JCCo = @JCCo
		AND S.Contract = @Contract
	

GO
