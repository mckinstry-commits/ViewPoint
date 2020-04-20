use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCProjPhaseSummary' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJCProjPhaseSummary'
	DROP FUNCTION mers.mfnJCProjPhaseSummary
end
go

print 'CREATE FUNCTION mers.mfnJCProjPhaseSummary'
go

CREATE function [mers].[mfnJCProjPhaseSummary]
(
	@JCCo				bCompany
,	@Job				bJob
,	@ProjectionMonth	bMonth
)  
-- ========================================================================
-- mfnJCProjPhaseSummary
-- Author:		Ziebell, Jonathan
-- Create date: 06/29/2016
-- Description:	Select SUM of projection values by Project Phase and Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   6/09/2016  Update to Remove Duplicate Project Header Information
--				J.Ziebell   7/08/2016  Add Filter Field
--              J.Ziebell	7/11/2016  Substring Join of Parent Phase Code
--              J.Ziebell   7/15/2016  CostType As Abbreviation
--              J.Ziebell   7/29/2016  Override Columns
--				J.Ziebell   8/18/2016  Updated Column Headers
--				J.Ziebell   8/31/2016  Reaming Cmtd Cost Labeel
--				J.Ziebell   9/07/2016  MTD Actual Cost, Prior Month Actual Cost
--				J.Ziebell   9/15/2016  Actual Rate  using JTD values
--              J.Ziebell   9/20/2016  Reapply Budgeted Rate Fix for Override
--              J.Ziebell   9/23/2016  Actual Committed Set to ZERO for Labor
--              J.Ziebell   9/29/2016  Change Actual CMtd Cost to Total Cmtd Cost
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
				),
		MTD_Actuals 
				(JCCo
				, Job
				, PhaseGroup
				, Phase
				, CostType
				, MTDCost
				, MTDHours
				)
			AS (SELECT    CH.JCCo
						, CH.Job
						, CH.PhaseGroup
						, CH.Phase
						, CH.CostType
						, CP.ActualCost AS MTDCost
						, CP.ActualHours AS MTDHours
					FROM JCCH CH
							LEFT OUTER JOIN JCCP CP 
								ON CH.JCCo = @JCCo
								AND CH.Job =  @Job
								AND	CP.JCCo = CH.JCCo
								AND CP.Job = CH.Job 
								AND CP.PhaseGroup = CH.PhaseGroup
								AND CP.Phase = CH.Phase
								AND CP.CostType = CH.CostType
								--AND CP.Mth = '01-JUN-2016'
								AND CP.Mth = CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01')
								),
		JTD_Actuals 
				(JCCo
				, Job
				, PhaseGroup
				, Phase
				, CostType
				, JTDCost
				, JTDHours
				)
			AS (SELECT    CH.JCCo
						, CH.Job
						, CH.PhaseGroup
						, CH.Phase
						, CH.CostType
						, SUM(CP.ActualCost) AS JTDCost
						, SUM(CP.ActualHours) AS JTDHours
					FROM JCCH CH
							LEFT OUTER JOIN JCCP CP 
								ON CH.JCCo = @JCCo
								AND CH.Job =  @Job
								AND	CP.JCCo = CH.JCCo
								AND CP.Job = CH.Job 
								AND CP.PhaseGroup = CH.PhaseGroup
								AND CP.Phase = CH.Phase
								AND CP.CostType = CH.CostType
								--AND CP.Mth <= '01-JUN-2016'
								AND CP.Mth <= CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01')
					GROUP BY CH.JCCo
						, CH.Job
						, CH.PhaseGroup
						, CH.Phase
						, CH.CostType),
		Prior_Actuals 
				(JCCo
				, Job
				, PhaseGroup
				, Phase
				, CostType
				, PTDCost
				)
			AS (SELECT    CH.JCCo
						, CH.Job
						, CH.PhaseGroup
						, CH.Phase
						, CH.CostType
						, SUM(CP.ActualCost) AS PTDCost
					FROM JCCH CH
							LEFT OUTER JOIN JCCP CP 
								ON CH.JCCo = @JCCo
								AND CH.Job =  @Job
								AND	CP.JCCo = CH.JCCo
								AND CP.Job = CH.Job 
								AND CP.PhaseGroup = CH.PhaseGroup
								AND CP.Phase = CH.Phase
								AND CP.CostType = CH.CostType
								--AND CP.Mth < '01-JUN-2016'
								AND CP.Mth < CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01')
					GROUP BY CH.JCCo
						, CH.Job
						, CH.PhaseGroup
						, CH.Phase
						, CH.CostType)
SELECT
	  --PB.PhaseGroup
	  /*CASE WHEN (PB.OrigEstCost <> 0) THEN 'Y' 
			WHEN (PB.CurrEstCost <> 0) THEN 'Y'
			WHEN (PB.ActualCost <> 0) THEN 'Y'
			WHEN (PB.ActualCmtdCost <> 0) THEN 'Y'
			WHEN (PB.RemainCmtdCost<> 0) THEN 'Y'
			WHEN (PB.PrevProjCost <> 0) THEN 'Y'
			WHEN (LM.ProjectedCost <> 0) THEN 'Y'
			WHEN (PCO.COEstHours > 0) THEN 'Y'
			WHEN (PCO.COEstCost >0) THEN 'Y'
			ELSE*/ 
	  'N' AS 'Used'
	, ISNULL(PM2.Description, 'NO PARENT') AS 'Parent Phase Description'
	, PB.Phase as 'Phase Code'
	, REPLACE(JP.Description,'"','-') as 'Phase Description'
	, CT.Abbreviation AS 'Cost Type'
	, PB.OrigEstHours AS 'Original Hours'
	, PB.OrigEstCost AS 'Original Cost'
	, (PB.CurrEstHours - PB.OrigEstHours) AS 'Appr CO Hours'
	, (PB.CurrEstCost - PB.OrigEstCost)  AS 'Appr CO Cost'
	, ISNULL(PCO.COEstHours,0) AS 'PCO Hours' 
	, ISNULL(PCO.COEstCost,0) AS 'PCO Cost'
	, PB.CurrEstHours AS 'Curr Est Hours'
	, PB.CurrEstCost AS 'Curr Est Cost'
	, JTD.JTDHours AS 'JTD Actual Hours'
	, JTD.JTDCost As 'JTD Actual Cost'
	, MTD.MTDHours AS 'MTD Actual Hours'
	, MTD.MTDCost AS 'MTD Actual Cost'
	, PTD.PTDCost AS 'LM Actual Cost'
	, CASE WHEN JTD.JTDHours > 0 THEN CAST(ROUND((JTD.JTDCost / JTD.JTDHours),2) as numeric(36,2)) ELSE 0 END AS 'Actual CST/HR'
	, CASE WHEN (CT.Abbreviation<>'L') THEN (PB.TotalCmtdCost) ELSE 0 END AS 'Total Committed Cost' 
	, 'CALCME' AS 'Remaining Hours'
	, 'CALCME' AS 'Remaining Cost'
	, 'CALCME' AS 'Remaining CST/HR' 
	, PB.RemainCmtdCost AS 'Remaining Committed Cost'
	, 0 AS 'Manual ETC Hours'
	, CASE WHEN ((CT.Abbreviation='L') AND (PB.OrigEstHours >0)) THEN (PB.OrigEstCost/PB.OrigEstHours) ELSE 0 END AS 'Manual ETC CST/HR'
	, 'CALCME' AS 'Manual ETC Cost'
	, 'CALCME' AS 'Projected Hours'
	, 'CALCME' AS 'Projected Cost'
	, PB.PrevProjHours AS 'Prev Projected Hours'
	, PB.PrevProjCost As 'Prev Projected Cost'
	, 'CALCME'  AS 'Change in Hours'
	, 'CALCME'  As 'Change in Cost'
	, LM.ProjectedHours AS 'LM Projected Hours'
	, LM.ProjectedCost AS 'LM Projected Cost'
	, 'CALCME'  AS 'Change from LM Projected Hours'
	, 'CALCME'  AS 'Change from LM Projected Cost'
	, 'CALCME' AS 'Over/Under Hours'
	, 'CALCME' AS 'Over/Under Cost'
FROM	JCPB PB 
	INNER JOIN HQCO HQ
		ON PB.Co = HQ.HQCo
		AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
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
	LEFT OUTER JOIN MTD_Actuals MTD
		ON PB.Co = MTD.JCCo
		AND PB.Job = MTD.Job
		AND PB.PhaseGroup = MTD.PhaseGroup
		AND PB.Phase = MTD.Phase
		AND PB.CostType = MTD.CostType
	LEFT OUTER JOIN JTD_Actuals JTD
		ON PB.Co = JTD.JCCo
		AND PB.Job = JTD.Job
		AND PB.PhaseGroup = JTD.PhaseGroup
		AND PB.Phase = JTD.Phase
		AND PB.CostType = JTD.CostType
	LEFT OUTER JOIN Prior_Actuals PTD
		ON PB.Co = PTD.JCCo
		AND PB.Job = PTD.Job
		AND PB.PhaseGroup = PTD.PhaseGroup
		AND PB.Phase = PTD.Phase
		AND PB.CostType = PTD.CostType
WHERE 	PB.Co = @JCCo
	AND PB.Job = @Job

GO

Grant SELECT ON mers.mfnJCProjPhaseSummary TO [MCKINSTRY\Viewpoint Users]