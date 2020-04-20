use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJobHeaderSM' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJobHeaderSM'
	DROP FUNCTION mers.mfnJobHeaderSM
end
go

print 'CREATE FUNCTION mers.mfnJobHeaderSM'
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
--				J.Ziebell   8/12/2017  Cost Null Results
--				J.Ziebell   8/18/2017  Column Rename
--				J.Ziebell   8/25/2017  Correction for Jobs without Phases
--              J.Ziebell   9/23/2016  Add Audit History of Batch Posting
--				J.Ziebell   10/6/2016  ReAdd GMAX Field Selection
--              J.Ziebell   10/10/2016 Fix Audit User ID
--              J.Ziebell   10/10/2016 Add Last Payroll Date
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
				),
		Last_Post
				(JCCo
				, Job
				, VPUserName
				, DateTime
				)
		AS (SELECT
				  L.JCCo
				, L.Job
				, L.VPUserName AS VPUserName
				, L.DateTime AS DateTime
			FROM mers.ProphecyLog L
			WHERE L.JCCo = @JCCo
				AND L.Job = @Job
				AND L.Action ='POST COST'
				AND L.DateTime = (Select MAX(L1.DateTime) FROM mers.ProphecyLog L1
									WHERE L.JCCo = L1.JCCo
									AND L.Job = L1.Job
									AND L1.Action ='POST COST')
				)
SELECT
		  R.ProjDollars AS 'Projected PRG Contract Value'
		, C.ProjCost AS 'Projected Final Cost'
		, CASE WHEN (R.ProjDollars) > 0 THEN ((R.ProjDollars-C.ProjCost)/R.ProjDollars) 
				WHEN (R.ProjDollars) = 0 THEN -1
				WHEN (R.ProjDollars) < 0 THEN -1
				ELSE 0 END AS 'Margin %'
		, CASE WHEN (C.ProjCost) > 0 THEN ((C.ActualCost)/C.ProjCost) 
				WHEN (C.ProjCost) = 0 THEN 0
				WHEN (C.ProjCost) < 0 THEN -1
				ELSE 0 END AS '% Complete'
		, MP_POC.Name AS 'Contract POC'
		, LP.DateTime AS 'Last Projection'
		, SUBSTRING(LP.VPUserName, CHARINDEX('\', LP.VPUserName) + 1, LEN(LP.VPUserName)) AS 'Projection by'
		--, DCI.DisplayValue as JobStatus
		, MP.Name as 'Project Manager'
		, CI.Department AS 'JC Department'
		, DM.Description AS 'JC Department Desc'
		, J.udProjStart AS 'Project Start Date'
		, J.udProjEnd AS 'Project End Date'
		, mers.mckfnGetLastPayrollWeekEnd() AS 'Payroll Through'
		, 'No' /*CASE WHEN (J.udGMAXYN = 'Y') THEN 'Yes' ELSE 'No' END*/ AS 'GMAX'
	FROM	JCJM J 
		INNER JOIN HQCO HQ
			ON HQ.HQCo = J.JCCo
		INNER JOIN JCCM CM
			ON J.JCCo = CM.JCCo
			AND J.Contract = CM.Contract
		LEFT OUTER JOIN JCCI CI
			ON J.JCCo = CI.JCCo
			AND J.Contract = CI.Contract
			AND CI.Item = (Select MIN(JP.Item) from JCJP JP
							WHERE JP.Job = J.Job
							AND JP.JCCo = J.JCCo)
		LEFT OUTER JOIN JCCP_Cost C
			ON C.JCCo = J.JCCo
			AND C.Job = J.Job
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
		LEFT OUTER JOIN Last_Post LP
			ON J.JCCo = LP.JCCo
			AND J.Job = LP.Job
		--LEFT OUTER JOIN	DDCIShared DCI 
		--	ON DCI.ComboType='JCJMJobStatus'
		--	AND	cast(J.JobStatus as varchar(10)) = DCI.DatabaseValue 
	WHERE J.JCCo = @JCCo
		AND J.Job = @Job

GO

Grant SELECT ON mers.mfnJobHeaderSM TO [MCKINSTRY\Viewpoint Users]
