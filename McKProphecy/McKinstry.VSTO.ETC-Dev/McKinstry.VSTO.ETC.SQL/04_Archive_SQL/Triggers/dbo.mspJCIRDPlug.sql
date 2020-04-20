use ViewpointProphecy
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspJCIRDPlug' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE dbo.mspJCIRDPlug'
	DROP FUNCTION dbo.mspJCIRDPlug
end
go

print 'CREATE PROCEDURE dbo.mspJCIRDPlug'
go

CREATE procedure dbo.mspJCIRDPlug
(
	@Company	bCompany
,	@BatchId	bBatchID
,	@BatchSeq	int
)
-- ========================================================================
-- Project dbo.mspJCIRDPlug
-- Author:		Ziebell, Jonathan
-- Create date: 07/08/2016
-- Description:	Select SUM of projection values by Project Phase and Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
AS
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
