use Viewpoint

declare @JCCo		bCompany
declare @Contract	bContract
declare @Job		bJob
declare @Mth		bMonth
declare @Login		sysname

set @Contract=' 14345-'

select @JCCo=mers.mfnGetContractCompany(@Contract) 
select @JCCo as JCCo, @Contract as Contract

select * from mers.mfnGetUserProfile(@JCCo,@Login)

select * from mers.mfnJCBatchMinMaxDates(@JCCo)

select * from mers.mfnJCBatchAllowedDates(@JCCo)
select @Mth=max(batchmonth) from mers.mfnJCBatchAllowedDates(@JCCo)

--select * from mers.mfnContractSelectorList(@JCCo, @Contract)
select * from mers.mfnContractSelectorList(@JCCo, '1434')
--select * from mers.mfnContractSelectorList(null, '055[0,1]')
--select * from mers.mfnContractSelectorList(null, null)

select * from mers.mfnContractHeader(@JCCo, @Contract)
select * from mers.mfnContractItems(@JCCo, @Contract)

select @JCCo as JCCo, @Contract as Contract, @Mth as BatchMonth

select * from mers.mfnContractRevenueOverride(@JCCo, @Contract, @Mth)
select * from mers.mfnContractRevenueProjectionByMonth(@JCCo, @Contract, @Mth)
select * from mers.mfnContractRevenueProjection(@JCCo, @Contract, @Mth)
select * from mers.mfnContractRevenueProjectionDetail(@JCCo, @Contract, @Mth)
exec mers.mspGetRevenueProjectionPivot @JCCo=@JCCo, @Contract=@Contract


exec mers.mspGetRevenueProjectionBatchPivot @JCCo=@JCCo, @Contract=@Contract

--Create Cursor for each Job and loop through job execution.

select * from mers.mfnContractJobs(@JCCo,@Contract, @Job)

go