use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCProjPhaseSummary' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mfnJCProjPhaseSummary'
	DROP FUNCTION dbo.mfnJCProjPhaseSummary
end
go

print 'CREATE FUNCTION dbo.mfnJCProjPhaseSummary'
go


CREATE function [dbo].[mfnJCProjPhaseSummary]
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
--				J.Ziebell   10/11/2016 Add new Actual vs Projected Column
--				J.Ziebell   11/08/2016 Include All Non-Closed Months in Projection Period
--				J.Ziebell   11/22/2016 Change of Lock Month Logic
--				J.Ziebell   11/28/2016 Batch MTD Column Headers
--				J.Ziebell   01/04/2017 Add New Column for JTD + Remaining Committed, Pull ETC Values
--              J.Ziebell   06/09/2017 Updated Total Committed and Remaining Committed, Add Remaining Hours
--				J.Ziebell   07/13/2017 Update View and Hours Reference 
--				J.Ziebell   10/18/2017 Man Weeks Enhancement Changes
--				J.Ziebell	11/20/2017 Actuals Column Reorder
--				J.Ziebell	11/28/2017 Zero out Non Labor Hours Actuals
--				J.Ziebell	04/03/2018 Fix for Cross Company POs
--				J.Ziebell   06/29/2018 Further Fix for Cross Company POs
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
								AND CP.Mth = @ProjectionMonth --CONCAT(DATEPART(YYYY,@ProjectionMonth),'-',DATEPART(MM,@ProjectionMonth),'-01')
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
				, PTDHours
				)
			AS (SELECT    CH.JCCo
						, CH.Job
						, CH.PhaseGroup
						, CH.Phase
						, CH.CostType
						, SUM(CP.ActualCost) AS PTDCost
						, SUM(CP.ActualHours) AS PTDHours
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
								--AND CP.Mth < CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01')
								AND CP.Mth <=(SELECT LastMthSubClsd from dbo.GLCO where GLCo = @JCCo)
					GROUP BY CH.JCCo
						, CH.Job
						, CH.PhaseGroup
						, CH.Phase
						, CH.CostType),
		PO_Cost_Sum AS (SELECT
					  		  --POF.JCCo
							  POF.Job
							, POF.PhaseGroup
							, POF.Phase
							, POF.CostType
							, SUM(POF.CurCost) AS CurCost
							, SUM(POF.RemainCommit) AS 'RemainCommit'
					FROM dbo.mckvwPOJobFlat POF
					WHERE /*POF.JCCo = @JCCo
							AND*/ POF.Job= @Job
					GROUP BY /*POF.JCCo
							,*/ POF.Job
							, POF.PhaseGroup
							, POF.Phase
							, POF.CostType),
		SL_Cost_Sum	AS(SELECT /*SLF.SLCo
						,*/ SLF.Job
						, SLF.PhaseGroup
						, SLF.Phase
						, SLF.CostType
						, SUM(SLF.CurrentAmount) AS CurCost
						, SUM(SLF.RemainingCommitted) As RemainCommit
					FROM dbo.mckvwSLJobFlat SLF
						WHERE /*SLF.SLCo = @JCCo
							AND*/ SLF.Job = @Job
							AND SLF.CostType = 3
						GROUP BY /*SLF.SLCo
						,*/ SLF.Job
						, SLF.PhaseGroup
						, SLF.Phase
						, SLF.CostType)
SELECT
	  'X' AS 'Used'
	, ISNULL(PM2.Description, 'NO PARENT') AS 'Parent Phase Description'
	, PB.Phase as 'Phase Code'
	, REPLACE(JP.Description,'"','-') as 'Phase Description'
	, CT.Abbreviation AS 'Cost Type'
	, CASE WHEN PB.OrigEstHours > 0 THEN CAST((PB.OrigEstHours/40) AS numeric(9,4)) ELSE 0 END AS 'Original Manweeks'
	, PB.OrigEstHours AS 'Original Hours'
	, PB.OrigEstCost AS 'Original Cost'
	, (PB.CurrEstHours - PB.OrigEstHours) AS 'Appr CO Hours'
	, (PB.CurrEstCost - PB.OrigEstCost)  AS 'Appr CO Cost'
	, ISNULL(PCO.COEstHours,0) AS 'PCO Hours' 
	, ISNULL(PCO.COEstCost,0) AS 'PCO Cost'
	, CASE WHEN PB.CurrEstHours > 0 THEN CAST((PB.CurrEstHours/40) AS numeric(9,4)) ELSE 0 END AS 'Curr Est Manweeks'
	, PB.CurrEstHours AS 'Curr Est Hours'
	, PB.CurrEstCost AS 'Curr Est Cost'
	--, MTD.MTDHours AS 'Batch MTD Actual Hours'
	, CASE WHEN PB.CostType = 1 THEN MTD.MTDHours ELSE 0 END AS 'Batch MTD Actual Hours'
	, MTD.MTDCost AS 'Batch MTD          Actual Cost'
	--PTD.PTDHours AS 'Total Hours - All Closed Months' --New
	, CASE WHEN PB.CostType = 1 THEN PTD.PTDHours ELSE 0 END AS 'Total Hours - All Closed Months' --New
	, PTD.PTDCost AS 'Total Cost - All Closed Months' --LM Actual Cost
	--, CASE WHEN JTD.JTDHours > 0 THEN CAST((JTD.JTDHours/40) AS numeric(7,2)) ELSE 0 END AS 'JTD Actual Manweeks'
	, CASE WHEN ((PB.CostType = 1) AND (JTD.JTDHours > 0)) THEN CAST((JTD.JTDHours/40) AS numeric(9,4)) ELSE 0 END AS 'JTD Actual Manweeks'
	--, JTD.JTDHours AS 'JTD Actual Hours'
	, CASE WHEN PB.CostType = 1 THEN JTD.JTDHours ELSE 0 END AS 'JTD Actual Hours'
	, JTD.JTDCost As 'JTD Actual Cost'
	, CASE WHEN JTD.JTDHours > 0 THEN CAST(ROUND((JTD.JTDCost / JTD.JTDHours),2) as numeric(36,2)) ELSE 0 END AS 'Actual CST/HR'
	, (ISNULL(PO.CurCost,0) + ISNULL(SL.CurCost,0)) AS 'Total Committed Cost' 
	, 'X' AS 'Projected Remaining Manweeks'
	, 'X' AS 'Projected Remaining Hours'
	, 'X' AS 'Projected Remaining Total Cost'
	, 'X' AS 'Remaining CST/HR' 
	, (ISNULL(PO.RemainCommit,0) + ISNULL(SL.RemainCommit,0)) AS 'Remaining Committed Cost'
	--, (ISNULL(PB.CurrEstHours,0) - JTD.JTDHours) AS 'Remaining Est Hours'
	, CASE WHEN PB.CostType = 1 THEN (ISNULL(PB.CurrEstHours,0) - JTD.JTDHours) ELSE 0 END AS 'Remaining Est Hours'
	, (JTD.JTDCost + (ISNULL(PO.RemainCommit,0) + ISNULL(SL.RemainCommit,0))) AS 'JTD + Remaining Committed'
	, ETC.Hours AS 'Manual ETC Hours'
	, CASE WHEN ETC.Rate IS NOT NULL THEN ETC.Rate
		WHEN ((CT.Abbreviation='L') AND (PB.OrigEstHours >0)) THEN (PB.OrigEstCost/PB.OrigEstHours) 
		ELSE 0 END AS 'Manual ETC CST/HR'
	, ETC.Amount AS 'Manual ETC Cost'
	, 'X' AS 'Projected Hours'
	, 'X' AS 'Projected Cost'
	, 'X' AS 'Actual Cost > Projected Cost'
	, PB.PrevProjHours AS 'Prev Projected Hours'
	, PB.PrevProjCost As 'Prev Projected Cost'
	, 'X'  AS 'Change in Hours'
	, 'X'  As 'Change in Cost'
	, LM.ProjectedHours AS 'LM Projected Hours'
	, LM.ProjectedCost AS 'LM Projected Cost'
	, 'X'  AS 'Change from LM Projected Hours'
	, 'X'  AS 'Change from LM Projected Cost'
	, 'X' AS 'Over/Under Hours'
	, 'X' AS 'Over/Under Cost'
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
	LEFT OUTER JOIN PO_Cost_Sum PO
		--ON PB.Co = PO.JCCo
		ON PB.Job = PO.Job
		AND PB.PhaseGroup = PO.PhaseGroup
		AND PB.Phase = PO.Phase
		AND PB.CostType = PO.CostType
	LEFT OUTER JOIN SL_Cost_Sum SL
		--ON PB.Co = SL.SLCo
		ON PB.Job = SL.Job
		AND PB.PhaseGroup = SL.PhaseGroup
		AND PB.Phase = SL.Phase
		AND PB.CostType = SL.CostType
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
	LEFT OUTER JOIN mckJCPBETC ETC
		ON PB.Co = ETC.JCCo
		AND PB.Mth = ETC.Mth
		AND PB.BatchId = ETC.BatchId 
		AND PB.Job = ETC.Job
		--AND PB.PhaseGroup = ETC.PhaseGroup
		AND PB.Phase = ETC.Phase
		AND PB.CostType = ETC.CostType
WHERE 	PB.Co = @JCCo
	AND PB.Job = @Job

GO
	
Grant SELECT ON dbo.mfnJCProjPhaseSummary TO [MCKINSTRY\Viewpoint Users]