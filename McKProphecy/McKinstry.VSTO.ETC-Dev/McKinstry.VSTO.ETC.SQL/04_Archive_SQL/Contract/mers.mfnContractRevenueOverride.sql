use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractRevenueOverride' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractRevenueOverride'
	DROP FUNCTION mers.mfnContractRevenueOverride
end
go

print 'CREATE FUNCTION mers.mfnContractRevenueOverride'
go

create function mers.mfnContractRevenueOverride
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
)
-- ========================================================================
-- mers.mfnContractRevenueOverride
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return

select
	@JCCo as JCCo
,	@Contract as Contract
,	@Month as Month
,	coalesce(jcor.RevCost,0) as RevCost
,	coalesce(jcor.OtherAmount,0) as OtherAmount
from
	mers.mfnContractHeader(@JCCo,@Contract) contract_header left outer join
	JCOR jcor on
		contract_header.JCCo=jcor.JCCo
	and	contract_header.Contract = jcor.Contract 
	and jcor.Month=@Month
go

declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth

select @JCCo=1, @Contract=' 14345-', @Month='12/1/2015'

select * from mers.mfnContractRevenueOverride(@JCCo, @Contract, @Month)

select @JCCo=1, @Contract=' 10353-', @Month='12/1/2015'

select * from mers.mfnContractRevenueOverride(@JCCo, @Contract, @Month)