use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobPhases' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobPhases'
	DROP FUNCTION mers.mfnContractJobPhases
end
go

print 'CREATE FUNCTION mers.mfnContractJobPhases'
go

create function mers.mfnContractJobPhases
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Job		bJob
)
-- ========================================================================
-- mers.mfnContractJobPhases
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return

select
	jcjp.JCCo	
,	jcjp.Contract	
,	jcjp.Item as ContractItem
,	jcdm.Department as JCDepartment
,	jcdm.Description as JCDepartmentDescription
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentDescription
,	jcjp.Job	
,	jcjp.PhaseGroup	
,	jcjp.Phase as JobPhase
,	jcjp.Description as JobPhaseDescription	
,	jcjp.ProjMinPct	
,	jcjp.ActiveYN	
,	jcjp.Notes	
,	jcjp.InsCode	
--,	jcjp.udSellRate as SellRate
from
	JCJM jcjm  left outer join
	JCJP jcjp on
		jcjm.JCCo=jcjp.JCCo
	and jcjm.Job=jcjp.Job left outer join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item left outer join
	JCDM jcdm on
		jcci.JCCo=jcdm.JCCo
	and jcci.Department=jcdm.Department left outer join
	GLAC glac on
		jcdm.GLCo=glac.GLCo
	and jcdm.OpenRevAcct=glac.GLAcct left outer join
	GLPI glpi on
		glac.GLCo=glpi.GLCo
	and glac.Part3=glpi.Instance
	and glpi.PartNo=3
where
	jcjp.JCCo < 100
and	(jcjp.JCCo=@JCCo or @JCCo is null)
and (jcjp.Contract=@Contract or @Contract is null)
and (jcjp.Job=@Job or @Job is null)

go



--declare @JCCo bCompany
--declare @Contract bContract
--declare @Job bJob

--select @JCCo=1, @Contract=' 14345-', @Job=null
--select * from mers.mfnContractJobPhases(@JCCo,@Contract,@Job) order by 1,8,9,10

--select @JCCo=1, @Contract=' 14345-', @Job=' 14345-001'
--select * from mers.mfnContractJobPhases(@JCCo,@Contract,@Job)


--select @JCCo=1, @Contract=' 10353-', @Job=null
--select * from mers.mfnContractJobPhases(@JCCo,@Contract,@Job) order by 1,8,9,10

--select @JCCo=1, @Contract=' 10353-', @Job=' 10353-001'
--select * from mers.mfnContractJobPhases(@JCCo,@Contract,@Job)