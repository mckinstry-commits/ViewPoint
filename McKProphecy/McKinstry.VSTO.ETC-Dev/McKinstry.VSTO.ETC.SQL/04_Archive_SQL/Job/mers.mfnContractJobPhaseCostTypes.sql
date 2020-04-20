use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobPhaseCostTypes' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobPhaseCostTypes'
	DROP FUNCTION mers.mfnContractJobPhaseCostTypes
end
go

print 'CREATE FUNCTION mers.mfnContractJobPhaseCostTypes'
go

create function mers.mfnContractJobPhaseCostTypes
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Job		bJob
)
-- ========================================================================
-- mers.mfnContractJobPhaseCostTypes
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return

select
	jcch.JCCo	
,	jcch.Job	
,	jcch.PhaseGroup	
,	jcch.Phase	
,	jcch.CostType	
,	jcct.Abbreviation as CostTypeAbbr
,	jcct.Description as CostTypeDescription
,	jcch.UM	
,	jcch.BillFlag	
,	jcch.ItemUnitFlag	
,	jcch.PhaseUnitFlag	
,	jcch.BuyOutYN	
,	jcch.LastProjDate	
,	jcch.Plugged	
,	jcch.ActiveYN	
,	jcch.OrigHours	
,	jcch.OrigUnits	
,	jcch.OrigCost	
,	jcch.ProjNotes	
,	jcch.SourceStatus	
,	jcch.InterfaceDate	
,	jcch.Notes	
,	jcch.udDateCreated	as DateCreated
,	jcch.udDateChanged	as DateChanged
,	jcch.udSellRate	as SellRate
,	jcch.udMarkup as Markup
from
	mers.mfnContractJobPhases(@JCCo,@Contract,@Job) contract_job_phases  left outer join
	JCCH jcch on
		contract_job_phases.JCCo=jcch.JCCo
	and contract_job_phases.Job=jcch.Job 
	and contract_job_phases.PhaseGroup=jcch.PhaseGroup
	and contract_job_phases.JobPhase=jcch.Phase left outer join
	JCCT jcct on
		jcch.PhaseGroup=jcct.PhaseGroup
    and	jcch.CostType = jcct.CostType
where
	(jcch.JCCo=@JCCo or @JCCo is null)
and (jcch.Job=@Job or @Job is null)

go

/*
declare @JCCo bCompany
declare @Contract bContract
declare @Job bJob

select @JCCo=1, @Contract=' 14345-', @Job=null
select * from mers.mfnContractJobPhaseCostTypes(@JCCo,@Contract,@Job) order by 1,2,3,4,5

select @JCCo=1, @Contract=' 14345-', @Job=' 14345-003'
select * from mers.mfnContractJobPhaseCostTypes(@JCCo,@Contract,@Job) order by 1,2,3,4,5


select @JCCo=1, @Contract=' 10353-', @Job=null
select * from mers.mfnContractJobPhaseCostTypes(@JCCo,@Contract,@Job) order by 1,2,3,4,5

select @JCCo=1, @Contract=' 10353-', @Job=' 10353-001'
select * from mers.mfnContractJobPhaseCostTypes(@JCCo,@Contract,@Job) order by 1,2,3,4,5
*/