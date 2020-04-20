use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobCostProjection' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobCostProjection'
	DROP FUNCTION mers.mfnContractJobCostProjection
end
go

print 'CREATE FUNCTION mers.mfnContractJobCostProjection'
go

create function mers.mfnContractJobCostProjection
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
,	@Job		bJob
)
returns table as 
-- ========================================================================
-- Object Name: mers.mfnContractJobCostProjection
-- Author:		BillO
-- Create Date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
return

select
	jccpd.JCCo	
,	jccpd.Job	
,	jccpd.PhaseGroup	
,	jccpd.Phase	
,	jccpd.CostType	
,	@Month as Month	
,	sum(jccpd.ActualHours) as 	ActualHours
,	sum(jccpd.ActualUnits) as 	ActualUnits
,	sum(jccpd.ActualCost) as 	ActualCost
,	sum(jccpd.OrigEstHours) as 	OrigEstHours
,	sum(jccpd.OrigEstUnits) as 	OrigEstUnits
,	sum(jccpd.OrigEstCost) as 	OrigEstCost
,	sum(jccpd.CurrEstHours) as 	CurrEstHours
,	sum(jccpd.CurrEstUnits) as 	CurrEstUnits
,	sum(jccpd.CurrEstCost) as 	CurrEstCost
,	sum(jccpd.ProjHours) as	ProjHours
,	sum(jccpd.ProjUnits) as 	ProjUnits
,	sum(jccpd.ProjCost) as 	ProjCost
,	sum(jccpd.ForecastHours) as 	ForecastHours
,	sum(jccpd.ForecastUnits) as ForecastUnits	
,	sum(jccpd.ForecastCost) as 	ForecastCost
,	sum(jccpd.TotalCmtdUnits) as TotalCmtdUnits	
,	sum(jccpd.TotalCmtdCost) as 	TotalCmtdCost
,	sum(jccpd.RemainCmtdUnits) as 	RemainCmtdUnits
,	sum(jccpd.RemainCmtdCost) as 	RemainCmtdCost
,	sum(jccpd.RecvdNotInvcdUnits) as 	RecvdNotInvcdUnits
,	sum(jccpd.RecvdNotInvcdCost) as 	RecvdNotInvcdCost
--,	jccpd.ProjPlug	
from	
	mers.mfnContractJobCostProjectionRaw(@JCCo,@Contract, @Month, @Job) jccpd 
group by 
	jccpd.JCCo	
,	jccpd.Job	
,	jccpd.PhaseGroup	
,	jccpd.Phase	
,	jccpd.CostType	
--,	jccpd.ProjPlug	
go