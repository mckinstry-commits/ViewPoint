use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCParentPhaseSummary' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJCParentPhaseSummary'
	DROP FUNCTION mers.mfnJCParentPhaseSummary
end
go

print 'CREATE PROCEDURE mers.mfnJCParentPhaseSummary'
go

CREATE function [mers].[mfnJCParentPhaseSummary]
(
	@JCCo				bCompany
,	@Job				bJob
)
-- ========================================================================
-- mfnJCParentPhaseSummary
-- Author:		Ziebell, Jonathan
-- Create date: 07/29/2016
-- Description:	Select SUM of projection values by Project Phase and Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
---				J.Ziebell   8/4/2016   Sarahs Rediculous Change Request
-- ========================================================================

RETURNS TABLE
AS 
RETURN 
	WITH JCCP_Sum 
				( JCCo
				, ParentPhase
				, ParentPhaseDesc
				--, OrigEstHours
				--, OrigEstCost
				, CurrEstHours
				, CurrEstCost
				, ActualHours
				, ActualCost
				, ProjHours
				, ProjCost
				, TotalCmtdCost
				, RemainCmtdCost
				)
		AS (SELECT
				  CP.JCCo
				, PM2.Phase
				, PM2.Description
				--, SUM(CP.OrigEstHours)
				--, SUM(CP.OrigEstCost)
				, SUM(CP.CurrEstHours)
				, SUM(CP.CurrEstCost)
				, SUM(CP.ActualHours)
				, SUM(CP.ActualCost)
				, SUM(CP.ProjHours)
				, SUM(CP.ProjCost)
				, SUM(CP.TotalCmtdCost)
				, SUM(CP.RemainCmtdCost)
			FROM JCCP CP
				LEFT OUTER JOIN (JCPM PM
						INNER JOIN JCPM PM2
							ON PM.PhaseGroup = PM2.PhaseGroup
							AND PM.udParentPhase = PM2.Phase)
					ON CP.PhaseGroup = PM.PhaseGroup
					AND SUBSTRING(CP.Phase,1,10) = SUBSTRING(PM.Phase,1,10)
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
			GROUP BY CP.JCCo
				, PM2.Phase
				, PM2.Description
				),
		JCCP_PrevMonth 
				( JCCo
				, ParentPhase
				, ParentPhaseDesc
				, ProjHours
				, ProjCost
				)
		AS (SELECT
				  CP.JCCo
				, PM2.Phase
				, PM2.Description
				, SUM(CP.ProjHours)
				, SUM(CP.ProjCost)
			FROM JCCP CP
				LEFT OUTER JOIN (JCPM PM
						INNER JOIN JCPM PM2
							ON PM.PhaseGroup = PM2.PhaseGroup
							AND PM.udParentPhase = PM2.Phase)
					ON CP.PhaseGroup = PM.PhaseGroup
					AND SUBSTRING(CP.Phase,1,10) = SUBSTRING(PM.Phase,1,10)
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
				AND CP.Mth < ( DATEADD(MONTH,-1,SYSDATETIME()))
			GROUP BY CP.JCCo
				, PM2.Phase
				, PM2.Description
				)
SELECT
	  ISNULL(S.ParentPhase, 'NO PARENT') AS 'Parent Phase'
	, ISNULL(S.ParentPhaseDesc, 'NO PARENT') AS 'Parent Phase Desc'
	--, S.OrigEstHours AS 'Original Hours'
	--, S.OrigEstCost  AS 'Original Cost'
	, S.CurrEstHours AS 'Current Est Hours'
	, S.CurrEstCost AS 'Current Est Cost'
	, S.ActualHours AS 'Actual Hours'
	, S.ActualCost AS 'Actual Cost'
	, CASE WHEN S.ActualHours > 0 THEN CAST(ROUND((S.ActualCost / S.ActualHours),2) as numeric(36,2)) ELSE 0 END AS 'Cost/HR'
	, S.TotalCmtdCost AS 'Committed Cost' 
	, (S.ProjHours - S.ActualHours) AS 'Remaining Hours'
	, (S.ProjCost - S.ActualCost) AS 'Remaining Cost'
	, CASE WHEN ((S.ProjHours - S.ActualHours) > 0) THEN CAST(ROUND(((S.ProjCost - S.ActualCost) / (S.ProjHours - S.ActualHours)),2) as numeric(36,2)) ELSE 0 END AS 'Remaining Cost/HR'
	, S.RemainCmtdCost AS 'Open Committed Cost'
	, S.ProjHours AS 'Projected Hours'
	, S.ProjCost AS 'Projected Cost'
	, (S.ProjHours - P.ProjHours)  AS 'Change from Prev HAC'
	, (S.ProjCost - P.ProjCost)  As 'Change from Prev CAC'
	, (S.ProjHours - S.CurrEstHours) AS 'Over/Under Hours'
	, (S.ProjCost - S.CurrEstCost) AS 'Over/Under Cost'
FROM	JCCP_Sum S 
	INNER JOIN HQCO HQ
		ON HQ.HQCo = S.JCCo
	LEFT OUTER JOIN JCCP_PrevMonth P
		ON S.JCCo = P.JCCo
		AND S.ParentPhase = P.ParentPhase
		AND S.ParentPhaseDesc = P.ParentPhaseDesc
	WHERE ((S.CurrEstHours<>0)
			OR (S.CurrEstCost<>0)
			OR (S.ActualHours<>0)
			OR (S.ActualCost<>0)
			OR (S.ProjHours<>0)
			OR (S.ProjCost<>0)
			OR (S.TotalCmtdCost<>0)
			OR (S.RemainCmtdCost<>0)
			OR (P.ProjHours<>0)
			OR (P.ProjCost<>0))


GO