use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnProjectCTSum' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnProjectCTSum'
	DROP FUNCTION mers.mfnProjectCTSum
end
go

print 'CREATE FUNCTION mers.mfnProjectCTSum'
go
CREATE function [mers].[mfnProjectCTSum]
(
	@JCCo				bCompany
,	@Contract			bContract
,	@Job				bJob
,	@ProjectionMonth	bMonth
)
-- ========================================================================
-- mers.mfnProjectCTSum
-- Author:		Ziebell, Jonathan
-- Create date: 06/15/2016
-- Description:	Select SUM of Of Project Values by Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
--              Ziebell, J.	07/26/2016 New Design Requirements
--              Ziebell, J.	08/05/2016 New Design Requirements           
--              Ziebell, J.	08/05/2016 Hide Null Rows          
--              Ziebell, J.	08/18/2016 Change Column Headers  
--				Ziebell, J. 08/22/2016 Concat Cost Type with Description
--				Ziebell, J. 08/25/2016 Correction for Jobs without Phases
--				Ziebell, J. 08/30/2016 Correction for Phase without Cost Type
-- ========================================================================

returns table as return  -- TODO: Change to explicityly defined return table
SELECT	
	--jcct.Abbreviation as CostTypeId
	CONCAT(jcct.CostType,'-',jcct.Description) AS 'Cost Type'
,	sum(jccp.CurrEstCost) AS 'Current Estimate'
,	sum(jccp.ActualCost) AS 'Actual'
--,	sum(jccp.RemainCmtdCost) AS RemainCmtdCost
,   (sum(jccp.CurrEstCost) - sum(jccp.ActualCost)) AS 'Total Remaining'
,	sum(jccp.ProjCost) AS 'Projected Final Cost'
FROM	JCJM jcjm 
	INNER JOIN HQCO HQ
		ON jcjm.JCCo = HQ.HQCo
		AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
	LEFT OUTER JOIN (JCJP jcjp 
						INNER JOIN JCCH jcch 
							ON jcjp.JCCo=jcch.JCCo
							AND jcjp.Job=jcch.Job
							AND jcjp.PhaseGroup=jcch.PhaseGroup
							AND jcjp.Phase=jcch.Phase) 
		ON	jcjm.JCCo=jcjp.JCCo
		AND jcjm.Job=jcjp.Job 
	LEFT OUTER JOIN	JCCT jcct 
		ON jcch.PhaseGroup=jcct.PhaseGroup
		AND jcch.CostType=jcct.CostType 
	--LEFT OUTER JOIN JCCI jcci 
	--	ON jcjp.JCCo=jcci.JCCo
	--	AND jcjp.Contract=jcci.Contract
	--	AND jcjp.Item=jcci.Item  
	LEFT OUTER JOIN	JCCP jccp 
		ON jcjm.JCCo=jccp.JCCo
		and jcjm.Job=jccp.Job
		and jcjp.PhaseGroup = jccp.PhaseGroup
		and jcjp.Phase = jccp.Phase
		and jcch.CostType = jccp.CostType
		--and jccp.Mth <= @ProjectionMonth
where ( jcjm.JCCo = @JCCo	or @JCCo is null )
and ( jcjm.Contract=@Contract or @Contract is null )
and ( jcjm.Job=@Job or @Job is null )
group by
	jcct.Abbreviation --as CostTypeId
	, jcct.CostType
	,	jcct.Description

GO

Grant SELECT ON mers.mfnProjectCTSum TO [MCKINSTRY\Viewpoint Users]

