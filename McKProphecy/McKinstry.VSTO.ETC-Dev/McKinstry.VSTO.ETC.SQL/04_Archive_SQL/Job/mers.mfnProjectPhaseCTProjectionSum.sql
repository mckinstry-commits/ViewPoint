use ViewpointProphecy
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnProjectPhaseCTProjectionSum' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnProjectPhaseCTProjectionSum'
	DROP FUNCTION mers.mfnProjectPhaseCTProjectionSum
end
go

print 'CREATE FUNCTION mers.mfnProjectPhaseCTProjectionSum'
go
CREATE function [mers].[mfnProjectPhaseCTProjectionSum]
(
	@JCCo				bCompany
,	@Contract			bContract
,	@Job				bJob
,	@ProjectionMonth	bMonth
)
-- ========================================================================
-- Project Phase Cost Type Projection Sum
-- Author:		Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	Select SUM of projection values by Project Phase and Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   6/09/2016  Update to Remove Duplicate Project Header Information
-- ========================================================================

returns table as return  -- TODO: Change to explicityly defined return table
select 
	jcjm.Job
,	jcjp.Item as ContractItem
--,	jcci.Description as ContractItemDesc
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description as JobPhaseDesc
--,	jcct.Abbreviation as CostTypeId
,	jcct.Description as CostType
,	jcch.OrigCost
,	jcch.OrigHours
,	jcch.OrigUnits
,	@ProjectionMonth as ThroughMonth --  jccp.Mth
,	sum(jccp.ActualHours) as 	ActualHours
--,	sum(jccp.ActualUnits) as ActualUnits	
,	sum(jccp.ActualCost) as 	ActualCost
,	sum(jccp.OrigEstHours) as 	OrigEstHours
--,	sum(jccp.OrigEstUnits) as 	OrigEstUnits
,	sum(jccp.OrigEstCost) as 	OrigEstCost
,	sum(jccp.CurrEstHours) as 	CurrEstHours
--,	sum(jccp.CurrEstUnits) as 	CurrEstUnits
,	sum(jccp.CurrEstCost) as 	CurrEstCost
,	sum(jccp.ProjHours) as 	ProjHours
--,	sum(jccp.ProjUnits) as 	ProjUnits
,	sum(jccp.ProjCost) as 	ProjCost
,	sum(jccp.ForecastHours) as 	ForecastHours
--,	sum(jccp.ForecastUnits) as 	ForecastUnits
,	sum(jccp.ForecastCost) as 	ForecastCost
--,	sum(jccp.TotalCmtdUnits) as 	TotalCmtdUnits
,	sum(jccp.TotalCmtdCost) as 	TotalCmtdCost
--,	sum(jccp.RemainCmtdUnits) as 	RemainCmtdUnits
,	sum(jccp.RemainCmtdCost) as 	RemainCmtdCost
--,	sum(jccp.RecvdNotInvcdUnits) as 	RecvdNotInvcdUnits
,	sum(jccp.RecvdNotInvcdCost) as 	RecvdNotInvcdCost
--,	jccp.ProjPlug	
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
and	( jcjm.JCCo = @JCCo	/*or @JCCo is null*/ )
and ( jcjm.Contract=@Contract /*or @Contract is null*/ )
and ( jcjm.Job=@Job/* or @Job is null*/ )
group by
	jcjm.Job
,	jcjp.Item --as ContractItem
--,	jcci.Description --as ContractItemDesc
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description --as JobPhaseDesc
--,	jcct.Abbreviation --as CostTypeId
,	jcct.Description --as CostType
,	jcch.OrigCost
,	jcch.OrigHours
,	jcch.OrigUnits
