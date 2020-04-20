use ViewpointProphecy
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
-- ========================================================================

returns table as return  -- TODO: Change to explicityly defined return table
SELECT	
	--jcct.Abbreviation as CostTypeId
	jcct.Description AS 'Cost Type'
,	sum(jccp.CurrEstCost) AS CurrEstCost
,	sum(jccp.ActualCost) AS ActualCost
--,	sum(jccp.RemainCmtdCost) AS RemainCmtdCost
,   (sum(jccp.CurrEstCost) - sum(jccp.ActualCost)) AS RemainingCost
,	sum(jccp.ProjCost) AS 'Projected Cost'
FROM	JCJM jcjm 
	LEFT OUTER JOIN JCJP jcjp 
		ON	jcjm.JCCo=jcjp.JCCo
		AND jcjm.Job=jcjp.Job 
	LEFT OUTER JOIN JCCH jcch 
		ON jcjp.JCCo=jcch.JCCo
		AND jcjp.Job=jcch.Job
		AND jcjp.PhaseGroup=jcch.PhaseGroup
		AND jcjp.Phase=jcch.Phase 
	LEFT OUTER JOIN	JCCT jcct 
		ON jcch.PhaseGroup=jcct.PhaseGroup
		AND jcch.CostType=jcct.CostType 
	LEFT OUTER JOIN JCCI jcci 
		ON jcjp.JCCo=jcci.JCCo
		AND jcjp.Contract=jcci.Contract
		AND jcjp.Item=jcci.Item  
	LEFT OUTER JOIN	JCCP jccp 
		ON jcch.JCCo=jccp.JCCo
		and jcch.Job=jccp.Job
		and jcch.PhaseGroup=jccp.PhaseGroup
		and jcch.Phase=jccp.Phase
		and jcch.CostType=jccp.CostType
		and jccp.Mth <= @ProjectionMonth
where jcjm.JCCo < 100
and	( jcjm.JCCo = @JCCo	or @JCCo is null )
and ( jcjm.Contract=@Contract or @Contract is null )
and ( jcjm.Job=@Job or @Job is null )
group by
	jcct.Abbreviation --as CostTypeId
,	jcct.Description;