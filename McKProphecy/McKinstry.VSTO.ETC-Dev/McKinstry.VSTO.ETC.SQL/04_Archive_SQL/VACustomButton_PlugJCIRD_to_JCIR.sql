--use Viewpoint

alter procedure mspJCIRDPlug
(
	@Company	bCompany
,	@BatchId	bBatchID
,	@BatchSeq	int
)
as
begin

	declare @rcode int
	declare @ProjDollarsSum	bDollar
	declare @ProjUnitsSum	bUnits

	select
		@ProjDollarsSum=sum(jcird.ProjDollars)
	--,	@ProjUnitsSum=sum(jcird.ProjUnits)
	from
		udJCIRD jcird
	where
		jcird.Co=@Company
	and jcird.BatchId=@BatchId
	and jcird.BatchSeq=@BatchSeq

	update JCIR
	set 
		RevProjDollars=@ProjDollarsSum
	,	
	--,	Rev=@ProjUnitsSum
	where
		JCIR.Co=@Company
	and JCIR.BatchId=@BatchId
	and JCIR.BatchSeq=@BatchSeq

	if @@ROWCOUNT < = 0
	begin
		SET @rcode = 1
	end
	else
	begin 
		SET @rcode = 0
	end

	return @rcode

end
go

-- Create Trigger so that when bJCIR Posts to bJCIP, the contents of budJCIRD are inserted/updated to budJCIPD

-- Create Trigger so that when Contract is added to bJCIR, the previous month budJCIPD records are added to budJCIRD with the Batch Month

