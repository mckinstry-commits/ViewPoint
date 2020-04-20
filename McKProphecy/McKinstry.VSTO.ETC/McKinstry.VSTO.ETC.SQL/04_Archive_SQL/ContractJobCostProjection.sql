use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobCostProjectionRaw' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobCostProjectionRaw'
	DROP FUNCTION mers.mfnContractJobCostProjectionRaw
end
go

print 'CREATE FUNCTION mers.mfnContractJobCostProjectionRaw'
go

create function mers.mfnContractJobCostProjectionRaw
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
,	@Job		bJob
)
returns table as return

select
	jccp.JCCo	
,	jccp.Job	
,	jccp.PhaseGroup	
,	jccp.Phase	
,	jccp.CostType	
,	jccp.Mth	
,	jccp.ActualHours	
,	jccp.ActualUnits	
,	jccp.ActualCost	
,	jccp.OrigEstHours	
,	jccp.OrigEstUnits	
,	jccp.OrigEstCost	
,	jccp.CurrEstHours	
,	jccp.CurrEstUnits	
,	jccp.CurrEstCost	
,	jccp.ProjHours	
,	jccp.ProjUnits	
,	jccp.ProjCost	
,	jccp.ForecastHours	
,	jccp.ForecastUnits	
,	jccp.ForecastCost	
,	jccp.TotalCmtdUnits	
,	jccp.TotalCmtdCost	
,	jccp.RemainCmtdUnits	
,	jccp.RemainCmtdCost	
,	jccp.RecvdNotInvcdUnits	
,	jccp.RecvdNotInvcdCost	
,	jccp.ProjPlug	
from
	mers.mfnContractJobPhaseCostTypes(@JCCo,@Contract,@Job) contract_job_phase_costtypes  left outer join
	JCCP jccp on
		contract_job_phase_costtypes.JCCo=jccp.JCCo
	and contract_job_phase_costtypes.Job=jccp.Job
	and contract_job_phase_costtypes.PhaseGroup=jccp.PhaseGroup
	and contract_job_phase_costtypes.Phase=jccp.Phase
	and contract_job_phase_costtypes.CostType=jccp.CostType
where
	jccp.Mth <= @Month
and	(jccp.JCCo=@JCCo or @JCCo is null)
and (jccp.Job=@Job or @Job is null)
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
returns table as return

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

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobCostProjectionByCostType' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobCostProjectionByCostType'
	DROP FUNCTION mers.mfnContractJobCostProjectionByCostType
end
go

print 'CREATE FUNCTION mers.mfnContractJobCostProjectionByCostType'
go

create function mers.mfnContractJobCostProjectionByCostType
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
,	@Job		bJob
)
returns table as return

select
	jccpd.JCCo	
,	jccpd.Job	
--,	jccpd.PhaseGroup	
--,	jccpd.Phase	
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
--,	jccpd.PhaseGroup	
--,	jccpd.Phase	
,	jccpd.CostType	
--,	jccpd.ProjPlug	
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobCostProjectionByPhase' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobCostProjectionByPhase'
	DROP FUNCTION mers.mfnContractJobCostProjectionByPhase
end
go

print 'CREATE FUNCTION mers.mfnContractJobCostProjectionByPhase'
go

create function mers.mfnContractJobCostProjectionByPhase
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
,	@Job		bJob
)
returns table as return

select
	jccpd.JCCo	
,	jccpd.Job	
,	jccpd.PhaseGroup	
,	jccpd.Phase	
--,	jccpd.CostType	
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
--,	jccpd.CostType	
--,	jccpd.ProjPlug	
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobCostProjectionByMonth' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobCostProjectionByMonth'
	DROP FUNCTION mers.mfnContractJobCostProjectionByMonth
end
go

print 'CREATE FUNCTION mers.mfnContractJobCostProjectionByMonth'
go

create function mers.mfnContractJobCostProjectionByMonth
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
,	@Job		bJob
)
returns table as return

select
	jccpd.JCCo	
,	jccpd.Job	
--,	jccpd.PhaseGroup	
--,	jccpd.Phase	
--,	jccpd.CostType	
,	jccpd.Mth as Month	
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
,	jccpd.Mth
--,	jccpd.PhaseGroup	
--,	jccpd.Phase	
--,	jccpd.CostType	
--,	jccpd.ProjPlug	
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobCostProjectionDetail' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobCostProjectionDetail'
	DROP FUNCTION mers.mfnContractJobCostProjectionDetail
end
go

print 'CREATE FUNCTION mers.mfnContractJobCostProjectionDetail'
go

create function mers.mfnContractJobCostProjectionDetail
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
,	@Job		bJob
)
returns table as return

select
	jccpd.JCCo	
,	jccpd.Job	
,	jccpd.PhaseGroup	
,	jccpd.Phase	
,	jccpd.CostType	
,	jccpd.Mth	
,	jcpr.ResTrans	
,	jcpr.PostedDate	
,	jcpr.ActualDate	
,	jcpr.JCTransType	
,	jcpr.Source	
,	jcpr.BudgetCode	
,	jcpr.EMCo	
,	jcpr.Equipment	
,	jcpr.PRCo	
,	jcpr.Craft	
,	jcpr.Class	
,	jcpr.Employee	
,	jcpr.Description	
,	jcpr.DetMth	
,	jcpr.FromDate	
,	jcpr.ToDate	
,	jcpr.Quantity	
,	jcpr.UM	
,	jcpr.Units	
,	jcpr.UnitHours	
,	jcpr.Hours	
,	jcpr.Rate	
,	jcpr.UnitCost	
,	jcpr.Amount	
,	jcpr.BatchId	
,	jcpr.InUseBatchId	
,	jcpr.Notes	
,	jcpr.UniqueAttchID	
,	jcpr.PMCostProjection	
,	jcpr.ProjectionCode
from
	mers.mfnContractJobCostProjectionRaw(@JCCo, @Contract, @Month, @Job) jccpd left outer join 
	JCPR jcpr on
		jccpd.JCCo=jcpr.JCCo
	and	jccpd.Job=jcpr.Job
	and	jccpd.PhaseGroup=jcpr.PhaseGroup
	and	jccpd.Phase=jcpr.Phase
	and	jccpd.CostType=jcpr.CostType
	and	jccpd.Mth=jcpr.Mth
where
	jcpr.Mth=@Month
go

declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth
declare @Job bJob

--select @JCCo=1, @Contract=' 14345-', @Month='12/1/2015', @Job=null

--select * from mers.mfnContractJobCostProjectionRaw(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjection(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjectionByCostType(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjectionByPhase(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjectionByMonth(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjectionDetail(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5

	

--select @JCCo=1, @Contract=' 14345-', @Month='12/1/2015', @Job=' 14345-001'

--select * from mers.mfnContractJobCostProjectionRaw(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjection(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjectionByCostType(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjectionByPhase(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjectionByMonth(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
--select * from mers.mfnContractJobCostProjectionDetail(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5

select @JCCo=1, @Contract=' 10353-', @Month='12/1/2015', @Job=' 10353-001'

select * from mers.mfnContractJobCostProjectionDetail(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
select * from mers.mfnContractJobCostProjectionRaw(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
select * from mers.mfnContractJobCostProjection(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
select * from mers.mfnContractJobCostProjectionByCostType(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
select * from mers.mfnContractJobCostProjectionByPhase(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
select * from mers.mfnContractJobCostProjectionByMonth(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
select * from mers.mfnContractJobCostProjectionDetail(@JCCo, @Contract, @Month, @Job) order by 1,2,3,4,5
