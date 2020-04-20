use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnContractPostRefresh' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mckfnContractPostRefresh'
	DROP FUNCTION mers.mckfnContractPostRefresh
end
go

print 'CREATE FUNCTION mers.mckfnContractPostRefresh'
go

CREATE function [mers].[mckfnContractPostRefresh]
(
	@JCCo				bCompany
,	@Contract			bContract
)
-- ========================================================================
-- mers.mckfnContractPostRefresh
-- Author:		Ziebell, Jonathan
-- Create date: 07/29/2016
-- Description:	Used to speed up Prophecy Revenue Posting Process by not rebuilding Job Worksheets
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================

RETURNS TABLE
AS 
RETURN 
	WITH JCID_Sum 
				( JCCo
			    , Contract
				, Job
				, ProjDollars
				)
		AS (SELECT
				  CI.JCCo
				, CI.Contract
				, CI.udPRGNumber
				, SUM(ID.ProjDollars)
			FROM JCCI CI 
				INNER JOIN JCID ID
					ON CI.JCCo = ID.JCCo
					AND CI.Contract = ID.Contract
					AND CI.Item = ID.Item
					AND CI.Contract = @Contract
					AND CI.JCCo = @JCCo
			GROUP BY CI.JCCo
				, CI.Contract
				, CI.udPRGNumber
				),
		JCCP_Cost 
				( JCCo
				, Contract
				, Job
				, ProjCost
				)
		AS (SELECT
				  JP.JCCo
				, JP.Contract
				, JP.Job 
				, SUM(CP.ProjCost) as ProjCost
			FROM JCJP JP 
			INNER JOIN JCCP CP
				ON CP.JCCo = JP.JCCo 
				AND CP.Job = JP.Job 
				AND CP.PhaseGroup = JP.PhaseGroup 
				AND CP.Phase = JP.Phase
			WHERE JP.JCCo = @JCCo
				AND JP.Contract = @Contract
			GROUP BY  JP.JCCo
					, JP.Contract
					, JP.Job
				)
	SELECT
		--  CM.JCCo
		--, CM.Contract
		  R.Job
		, SUBSTRING(R.Job, CHARINDEX('-', R.Job), LEN(R.Job)) As JobPart
		, R.ProjDollars AS 'Revenue'
		--, C.ProjCost AS 'Cost'
		, CASE WHEN (R.ProjDollars) > 0 THEN ((R.ProjDollars-C.ProjCost)/R.ProjDollars) 
				WHEN (R.ProjDollars) = 0 THEN -1
				WHEN (R.ProjDollars) < 0 THEN -1
				ELSE 0 END AS 'Margin'
	FROM JCCM CM
		INNER JOIN HQCO HQ
			ON HQ.HQCo = CM.JCCo
		INNER JOIN JCID_Sum R
			ON CM.JCCo = R.JCCo
			AND CM.Contract = R.Contract
		LEFT OUTER JOIN JCCP_Cost C
			ON C.JCCo = CM.JCCo
			AND C.Contract = CM.Contract
			AND C.Job = R.Job
	WHERE CM.JCCo = @JCCo
		AND CM.Contract = @Contract

GO

Grant SELECT ON mers.mckfnContractPostRefresh TO [MCKINSTRY\Viewpoint Users]
