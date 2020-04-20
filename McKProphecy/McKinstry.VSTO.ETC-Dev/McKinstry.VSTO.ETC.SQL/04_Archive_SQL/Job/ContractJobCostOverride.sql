use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobCostOverride' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobCostOverride'
	DROP FUNCTION mers.mfnContractJobCostOverride
end
go

print 'CREATE FUNCTION mers.mfnContractJobCostOverride'
go

create function mers.mfnContractJobCostOverride
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
,	@Job		bJob
)
-- ========================================================================
-- mers.mfnContractJobCostOverride
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return

select
jcop.*
from
	mers.mfnContractJobs(@JCCo,@Contract, @Job) contract_jobs left outer join
	JCOP jcop on
		contract_jobs.JCCo=jcop.JCCo
	and contract_jobs.Job=jcop.Job
where
	(jcop.JCCo=@JCCo or @JCCo is null)
and (jcop.Job=@Job or @Job is null)
and jcop.Month=@Month
go

/*
declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth
declare @Job bJob

select @JCCo=1, @Contract=' 14345-', @Job=null, @Month='12/1/2015'
select * from mers.mfnContractJobCostOverride(@JCCo,@Contract,@Month,@Job)

select @JCCo=1, @Contract=' 14345-', @Job=' 14345-003', @Month='12/1/2015'
select * from mers.mfnContractJobCostOverride(@JCCo,@Contract,@Month,@Job)

select @JCCo=1, @Contract=' 10353-', @Month='12/1/2015', @Job=null
select * from mers.mfnContractJobCostOverride(@JCCo,@Contract,@Month,@Job)

select @JCCo=1, @Contract=' 10353-', @Month='12/1/2015', @Job=' 10353-001'
select * from mers.mfnContractJobCostOverride(@JCCo,@Contract,@Month,@Job)
*/