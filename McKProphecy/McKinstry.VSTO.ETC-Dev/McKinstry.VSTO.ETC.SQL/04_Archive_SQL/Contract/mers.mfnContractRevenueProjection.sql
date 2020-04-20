use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractRevenueProjection' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractRevenueProjection'
	DROP FUNCTION mers.mfnContractRevenueProjection
end
go

print 'CREATE FUNCTION mers.mfnContractRevenueProjection'
go

create function mers.mfnContractRevenueProjection
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
)
-- ========================================================================
-- mers.mfnContractRevenueProjection
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return

select
	jcipd.JCCo
,	jcipd.Contract
,	jcipd.Item
,	@Month as Mth
,	sum(jcipd.OrigContractAmt) as OrigContractAmt
,	sum(jcipd.OrigContractUnits) as OrigContractUnits
,	avg(jcipd.OrigUnitPrice) as OrigUnitPrice
,	sum(jcipd.ContractAmt) as ContractAmt
,	sum(jcipd.ContractUnits) as ContractUnits
,	avg(jcipd.CurrentUnitPrice) as 	CurrentUnitPrice
,	sum(jcipd.BilledUnits) as BilledUnits
,	sum(jcipd.BilledAmt) as BilledAmt
,	sum(jcipd.ReceivedAmt) as ReceivedAmt
,	sum(jcipd.CurrentRetainAmt) as CurrentRetainAmt
,	sum(jcipd.BilledTax) as BilledTax
,	sum(jcipd.ProjUnits) as ProjUnits
,	sum(jcipd.ProjDollars) as ProjDollars
--,	jcipd.ProjPlug	
from	
	mers.mfnContractRevenueProjectionByMonth(@JCCo,@Contract, @Month) jcipd 
group by 
	jcipd.JCCo
,	jcipd.Contract
,	jcipd.Item
--,	jcipd.ProjPlug
go

declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth

select @JCCo=1, @Contract=' 14345-', @Month='12/1/2015'

select * from mers.mfnContractRevenueProjection(@JCCo, @Contract, @Month)
--select * from mers.mfnContractRevenueProjectionByMonth(@JCCo, @Contract, @Month)


select @JCCo=1, @Contract=' 10353-', @Month='12/1/2015'
select * from mers.mfnContractRevenueProjection(@JCCo, @Contract, @Month)
--select * from mers.mfnContractRevenueProjectionByMonth(@JCCo, @Contract, @Month)