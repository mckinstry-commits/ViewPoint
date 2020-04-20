use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCProjPhaseSummary' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJCProjPhaseSummary'
	DROP FUNCTION mers.mfnJCProjPhaseSummary
end
go

print 'CREATE PROCEDURE mers.mfnJCProjPhaseSummary'
go

CREATE function [mers].[mfnJCProjPhaseSummary]
(
	@JCCo				bCompany
,	@Job				bJob
,	@ProjectionMonth	bMonth
)  
-- ========================================================================
-- Project Phase Cost Type Projection Sum
-- Author:		Ziebell, Jonathan
-- Create date: 06/29/2016
-- Description:	Select SUM of projection values by Project Phase and Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   6/09/2016  Update to Remove Duplicate Project Header Information
--				J.Ziebell   7/08/2016  Add Filter Field
--              J.Ziebell	7/11/2016  Substring Join of Parent Phase Code
--              J.Ziebell   7/15/2016  CostType As Abbreviation
--              J.Ziebell   7/29/2016  Override Columns
-- ========================================================================

RETURNS TABLE
AS 
RETURN 
	WITH LastMonthProjection 
				( JCCo
				, Job
				, PhaseGroup
				, Phase
				, CostType
				, ProjectedHours
				, ProjectedCost
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job
				, CP.PhaseGroup
				, CP.Phase
				, CP.CostType
				, SUM(CP.ProjHours)
				, SUM(CP.ProjCost)
			FROM JCCP CP
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
				AND CP.Mth < @ProjectionMonth
			GROUP BY CP.JCCo
				, CP.Job
				, CP.PhaseGroup
				, CP.Phase
				, CP.CostType
				),
	 PendingChangeOrders
				( JCCo
				, Job
				, PhaseGroup
				, Phase
				, CostType
				, COEstHours 
				, COEstCost
				)
		AS (SELECT 
				A.PMCo
				, A.Project
				, A.PhaseGroup
				, A.Phase
				, A.CostType
				, SUM(A.EstHours) AS 'CO EstHours'
				, SUM(A.EstCost) AS 'CO EstCost'
			FROM PMOL A
				INNER JOIN PMOI B
					ON A.PMCo = B.PMCo
					AND A.Project = B.Project
					AND A.PCOType = B.PCOType
					AND A.PCO = B.PCO
					AND A.PCOItem = B.PCOItem
					AND ((A.ACO = B.ACO) OR (A.ACO iS NULL))
					AND ((A.ACOItem = B.ACOItem) OR (A.ACOItem IS NULL))
			WHERE B.Status <> ('RJNPCO')
				AND B.InterfacedDate IS NULL
				AND A.Project = @Job
				AND A.PMCo = @JCCo
				AND A.Project = @Job
			GROUP BY 
				A.PMCo
				, A.Project
				, A.PhaseGroup
				, A.Phase
				, A.CostType
				)
SELECT
	  --PB.PhaseGroup
	  CASE WHEN (PB.OrigEstCost <> 0) THEN 'Y' 
			WHEN (PB.CurrEstCost <> 0) THEN 'Y'
			WHEN (PB.ActualCost <> 0) THEN 'Y'
			WHEN (PB.ActualCmtdCost <> 0) THEN 'Y'
			WHEN (PB.RemainCmtdCost<> 0) THEN 'Y'
			WHEN (PB.PrevProjCost <> 0) THEN 'Y'
			WHEN (LM.ProjectedCost <> 0) THEN 'Y'
			WHEN (PCO.COEstHours > 0) THEN 'Y'
			WHEN (PCO.COEstCost >0) THEN 'Y'
			ELSE 'N' END AS 'Used Filter'
	, ISNULL(PM2.Description, 'NO PARENT') AS 'Parent Phase'
	, PB.Phase as 'Phase Code'
	, REPLACE(JP.Description,'"','-') as 'Phase Description'
	, CT.Abbreviation AS 'Cost Type'
	, PB.OrigEstHours
	, PB.OrigEstCost
	, (PB.CurrEstHours - PB.OrigEstHours) AS 'Appr CO Hours'
	, (PB.CurrEstCost - PB.OrigEstCost)  AS 'Appr CO Cost'
	, ISNULL(PCO.COEstHours,0) AS 'Outstanding CO Hours' 
	, ISNULL(PCO.COEstCost,0) AS 'Outstanding CO Cost'
	, PB.CurrEstHours
	, PB.CurrEstCost
	, PB.ActualHours
	, PB.ActualCost
	, CASE WHEN PB.ActualHours > 0 THEN CAST(ROUND((PB.ActualCost / PB.ActualHours),2) as numeric(36,2)) ELSE 0 END AS 'Cost/HR'
	, PB.ActualCmtdCost AS 'Actual Committed Cost' 
	, 'CALCME' AS 'Remaining Hours'
	, 'CALCME' AS 'Remaining Cost'
	, 'CALCME' AS 'Remaining Cost/Hour' 
	, PB.RemainCmtdCost AS 'Open Committed Cost'
	, 0 AS 'Override Hours'
	, 0 AS 'Override Cost/Hour'
	, 'CALCME' AS 'Override Cost'
	, 'CALCME' AS 'Projected Hours'
	, 'CALCME' AS 'Projected Cost'
	, PB.PrevProjHours AS 'Prev Projected Hours'
	, PB.PrevProjCost As 'Prev Projected Cost'
	, 'CALCME'  AS 'Change from Prev Projected Hours'
	, 'CALCME'  As 'Change from Prev Projected Cost'
	, LM.ProjectedHours AS 'LM Projected Hours'
	, LM.ProjectedCost AS 'LM Projected Cost'
	, 'CALCME'  AS 'Change from LM Projected Hours'
	, 'CALCME'  AS 'Change from LM Projected Cost'
	, 'CALCME' AS 'OverUnder Hours'
	, 'CALCME' AS 'OverUnder Cost'
FROM	JCPB PB 
	INNER JOIN JCJP JP 
		ON	PB.Co=JP.JCCo
		AND PB.Job=JP.Job 
		AND PB.PhaseGroup = JP.PhaseGroup
		AND PB.Phase = JP.Phase
	INNER JOIN	JCCT CT 
		ON PB.PhaseGroup = CT.PhaseGroup
		AND PB.CostType = CT.CostType 
	LEFT OUTER JOIN (JCPM PM
						INNER JOIN JCPM PM2
							ON PM.PhaseGroup = PM2.PhaseGroup
							AND PM.udParentPhase = PM2.Phase)
		ON PB.PhaseGroup = PM.PhaseGroup
		AND SUBSTRING(PB.Phase,1,10) = SUBSTRING(PM.Phase,1,10)
	LEFT OUTER JOIN PendingChangeOrders PCO
		ON 	PB.Co = PCO.JCCo
		AND PB.Job = PCO.Job
		AND PB.PhaseGroup = PCO.PhaseGroup
		AND PB.Phase = PCO.Phase
		AND PB.CostType = PCO.CostType
	LEFT OUTER JOIN	LastMonthProjection LM 
		ON PB.Co = LM.JCCo
		AND PB.Job = LM.Job
		AND PB.PhaseGroup = LM.PhaseGroup
		AND PB.Phase = LM.Phase
		AND PB.CostType = LM.CostType
WHERE PB.Co < 100
	AND PB.Co = @JCCo
	AND PB.Job = @Job;

