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
returns table as 
-- ========================================================================
-- Object Name: mers.mfnContractJobCostProjectionRaw
-- Author:		BillO
-- Create Date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
return

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
