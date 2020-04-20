use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractRevenueProjectionByMonth' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractRevenueProjectionByMonth'
	DROP FUNCTION mers.mfnContractRevenueProjectionByMonth
end
go

print 'CREATE FUNCTION mers.mfnContractRevenueProjectionByMonth'
go

create function mers.mfnContractRevenueProjectionByMonth
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
)
-- ========================================================================
-- mers.mfnContractRevenueProjectionByMonth
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return

select
	jcip.JCCo
,	jcip.Contract
,	jcip.Item
,	jcip.Mth
,	jcip.OrigContractAmt	
,	jcip.OrigContractUnits	
,	jcip.OrigUnitPrice	
,	jcip.ContractAmt	
,	jcip.ContractUnits	
,	jcip.CurrentUnitPrice	
,	jcip.BilledUnits	
,	jcip.BilledAmt	
,	jcip.ReceivedAmt	
,	jcip.CurrentRetainAmt	
,	jcip.BilledTax	
,	jcip.ProjUnits	
,	jcip.ProjDollars	
,	jcip.ProjPlug	
from	
	mers.mfnContractItem(@JCCo,@Contract) contract_item left outer join
	JCIP jcip on
		contract_item.JCCo=jcip.JCCo
	and	contract_item.Contract = jcip.Contract 
	and	contract_item.ContractItem = jcip.Item 
	and jcip.Mth <= @Month
go


/*
declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth

select @JCCo=1, @Contract=' 14345-', @Month='12/1/2015'

--select * from mers.mfnContractRevenueProjection(@JCCo, @Contract, @Month)
select * from mers.mfnContractRevenueProjectionByMonth(@JCCo, @Contract, @Month)


select @JCCo=1, @Contract=' 10353-', @Month='12/1/2015'
--select * from mers.mfnContractRevenueProjection(@JCCo, @Contract, @Month)
select * from mers.mfnContractRevenueProjectionByMonth(@JCCo, @Contract, @Month)
*/