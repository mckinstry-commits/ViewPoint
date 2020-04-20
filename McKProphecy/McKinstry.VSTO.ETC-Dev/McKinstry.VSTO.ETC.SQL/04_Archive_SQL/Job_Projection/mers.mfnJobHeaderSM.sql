use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJobHeaderSM' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJobHeaderSM'
	DROP FUNCTION mers.mfnJobHeaderSM
end
go

print 'CREATE PROCEDURE mers.mfnJobHeaderSM'
go

CREATE function [mers].[mfnJobHeaderSM]
(
	@JCCo				bCompany
,	@Job				bJob
)
-- ========================================================================
-- mfnJobHeaderSM
-- Author:		Ziebell, Jonathan
-- Create date: 07/29/2016
-- Description:	Select SUM of projection values by Project Phase and Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
--              J.Ziebell   8/2/2017   Add PErcent Complete
--              J.Ziebell   8/2/2017   Add POC
-- ========================================================================

RETURNS TABLE
AS 
RETURN 
	WITH JCID_Sum 
				( JCCo
				, Job
				, ProjDollars
				)
		AS (SELECT
				  CI.JCCo
				, CI.udPRGNumber
				, SUM(ID.ProjDollars)
			FROM JCCI CI 
				INNER JOIN JCID ID
					ON CI.JCCo = ID.JCCo
					AND CI.Contract = ID.Contract
					AND CI.Item = ID.Item
					AND CI.udPRGNumber = @Job
					AND CI.JCCo = @JCCo
			GROUP BY CI.JCCo
				, CI.udPRGNumber
				),
		JCCP_Cost 
				( JCCo
				, Job
				, ProjCost
				, ActualCost
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job 
				, SUM(CP.ProjCost)
				, SUM(CP.ActualCost)
			FROM JCCP CP
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
				--AND CP.Mth < ( DATEADD(MONTH,-1,SYSDATETIME()))
			GROUP BY CP.JCCo
				, CP.Job
				)
	SELECT
		  R.ProjDollars AS 'Project Revenue'
		, C.ProjCost AS 'Project Cost'
		, CASE WHEN (R.ProjDollars) > 0 THEN ((R.ProjDollars-C.ProjCost)/R.ProjDollars) 
				WHEN (R.ProjDollars) = 0 THEN -1
				ELSE -1 END AS 'Margin %'
		, CASE WHEN (C.ProjCost) > 0 THEN ((C.ActualCost)/C.ProjCost) 
				WHEN (C.ProjCost) = 0 THEN -1
				ELSE -1 END AS '% Complete'
		, DCI.DisplayValue as JobStatus
		, MP.Name as ProjectMgrName
		, CI.Department
		, DM.Description AS 'Dept Desc'
		, J.udProjStart AS 'Project Start Date'
		, J.udProjEnd AS 'Project End Date'
		, MP_POC.Name AS 'Contract POC'
	FROM	JCJM J 
		INNER JOIN HQCO HQ
			ON HQ.HQCo = J.JCCo
		INNER JOIN JCCP_Cost C
			ON C.JCCo = J.JCCo
			AND C.Job = J.Job
		INNER JOIN JCCI CI
			ON J.JCCo = CI.JCCo
			AND J.Contract = CI.Contract
			AND CI.Item = (Select MIN(JP.Item) from JCJP JP
							WHERE JP.Job = J.Job
							AND JP.JCCo = J.JCCo)
		INNER JOIN JCCM CM
			ON CI.JCCo = CM.JCCo
			AND CI.Contract = CM.Contract
		LEFT OUTER JOIN JCID_Sum R
			ON J.JCCo = R.JCCo
			AND J.Job = R.Job
		LEFT OUTER JOIN	JCDM DM
			ON J.JCCo = DM.JCCo
			AND CI.Department = DM.Department 
		LEFT OUTER JOIN	JCMP MP_POC 
			ON CM.JCCo = MP_POC.JCCo
			AND CM.udPOC = MP_POC.ProjectMgr 
		LEFT OUTER JOIN	JCMP MP 
			ON J.JCCo = MP.JCCo
			AND J.ProjectMgr = MP.ProjectMgr 
		LEFT OUTER JOIN	DDCIShared DCI 
			ON DCI.ComboType='JCJMJobStatus'
			AND	cast(J.JobStatus as varchar(10)) = DCI.DatabaseValue 
	WHERE J.JCCo = @JCCo
		AND J.Job = @Job

GO