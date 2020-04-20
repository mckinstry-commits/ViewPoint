use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractRevenueProjectionDetail' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractRevenueProjectionDetail'
	DROP FUNCTION mers.mfnContractRevenueProjectionDetail
end
go

print 'CREATE FUNCTION mers.mfnContractRevenueProjectionDetail'
go

create function mers.mfnContractRevenueProjectionDetail
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
)
-- ========================================================================
-- mers.mfnContractRevenueProjectionDetail
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return

select
	contract_item.JCCo
,	contract_item.Contract
,	contract_item.ContractDesc
,	contract_item.ContractItem
,	contract_item.ContractItemDesc
,	@Month as Mth
,	jcipd.FromDate
,	jcipd.ToDate
,	jcipd.ProjDollars
,	jcipd.ProjUnits
from	
	mers.mfnContractItem(@JCCo,@Contract) contract_item left outer join
	udJCIPD jcipd on
		contract_item.JCCo=jcipd.Co
	and	contract_item.Contract = jcipd.Contract 
	and	contract_item.ContractItem = jcipd.Item 
	and jcipd.Mth = @Month
go


/*
declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth

select @JCCo=1, @Contract=' 14345-', @Month='12/1/2015'

--select * from mers.mfnContractRevenueProjection(@JCCo, @Contract, @Month)
select * from mers.mfnContractRevenueProjectionDetail(@JCCo, @Contract, @Month)


select @JCCo=1, @Contract=' 10353-', @Month='12/1/2015'
--select * from mers.mfnContractRevenueProjection(@JCCo, @Contract, @Month)
select * from mers.mfnContractRevenueProjectionDetail(@JCCo, @Contract, @Month)
*/
