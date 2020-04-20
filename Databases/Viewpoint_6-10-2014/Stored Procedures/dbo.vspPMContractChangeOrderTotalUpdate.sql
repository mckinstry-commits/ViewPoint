SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMContractChangeOrderTotalUpdate]
/***********************************************************
* CREATED BY:	GP	04/11/2011
* MODIFIED BY:	GP	05/12/2011 - Fixed amounts for accuracy, also to match design of COR totals.
*				GP	05/16/2011 - Added RefreshDetail code
*				GP	08/30/2012 - TK-17460 Modified the select in the ACO loop to allow PCOType and PCO to be NULL
*										  Added sum to @EstimateChange and @ContractChange.
*				GP	07/22/2013 - TFS-56454 When refreshing detail, code was using different amounts than
*				
* USAGE:
* Used in PM Contract Change Order to update the totals on the Info tab.
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*	ID
*
* OUTPUT PARAMETERS
*   @msg		Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Contract bContract, @ID smallint, @RefreshDetail char(1), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @OriginalContractAmount bDollar, @PrevApprovedCOAmount bDollar, 
	@CurrentCOAmount bDollar, @CurrentContractAmount bDollar,
	@EstimateChange bDollar, @PurchaseChange bDollar, @ContractChange bDollar,
	@TempACOCounter int, @ACOKeyID bigint, @ACOKeyIDString varchar(max)
select @rcode = 0, @OriginalContractAmount = 0, @PrevApprovedCOAmount = 0, 
	@CurrentCOAmount = 0, @CurrentContractAmount = 0


--Validate
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Contract is null
begin
	select @msg = 'Missing Contract.', @rcode = 1
	goto vspexit
end

if @ID is null
begin
	select @msg = 'Missing ID.', @rcode = 1
	goto vspexit
end


--UPDATE DETAIL
if @RefreshDetail = 'Y'
begin
	declare @TempACOs table
	(
		Seq int identity(1,1),
		Project bProject,
		ACO bACO,
		ACOKeyID bigint
	)

	--get all distinct ACO records currently on ACOs tab
	insert @TempACOs (Project, ACO, ACOKeyID)
	select distinct cco.Project, cco.ACO, aco.KeyID 
	from dbo.vPMContractChangeOrderACO cco
	left join dbo.PMOH aco on aco.PMCo = cco.PMCo and aco.Project = cco.Project and aco.ACO = cco.ACO
	where cco.PMCo = @PMCo and cco.[Contract] = @Contract and cco.ID = @ID
	order by cco.Project, cco.ACO

	--clear ACOs tab
	delete dbo.vPMContractChangeOrderACO
	where PMCo = @PMCo and [Contract] = @Contract and ID = @ID

	--loop through each aco and build ACOKeyIDString
	select @TempACOCounter = 1, @ACOKeyIDString = ''
	while @TempACOCounter <= (select max(Seq) from @TempACOs)
	begin
		select @ACOKeyID = ACOKeyID from @TempACOs where Seq = @TempACOCounter

		set @ACOKeyIDString = @ACOKeyIDString + cast(@ACOKeyID as varchar(10))
		if @TempACOCounter <> (select max(Seq) from @TempACOs)
		begin
			set @ACOKeyIDString = @ACOKeyIDString + ','
		end
		
		set @TempACOCounter = @TempACOCounter + 1
	end	

	--call stored procedure to add ACO records back, same proc used by form action 'Tasks - Add ACOs'
	if @ACOKeyIDString <> ''
	begin
		execute @rcode = dbo.vspPMContractChangeOrderAddACOs @PMCo, @Contract, @ID, @ACOKeyIDString, @msg output
	end
end


--UPDATE HEADER
--Original Contract Amount
select @OriginalContractAmount = isnull(OrigContractAmt, 0)
from dbo.JCCM 
where JCCo = @PMCo and [Contract] = @Contract

--Current Contract Change Order
select @CurrentCOAmount = isnull(sum(ContractChange), 0) 
from dbo.PMContractChangeOrderACO 
where PMCo = @PMCo and [Contract] = @Contract and ID = @ID

--Previously Authorized Contract Changes
select @PrevApprovedCOAmount = PrevApprovedCOAmount 
from dbo.PMContractChangeOrder
where PMCo = @PMCo and [Contract] = @Contract and ID = @ID 
--Only update approved amount if not brought in previously
if @PrevApprovedCOAmount is null or @RefreshDetail = 'Y'
begin
	--Approved PCO Amount in current COR
	select @PrevApprovedCOAmount = isnull(sum(ApprovedAmt), 0) - @CurrentCOAmount
	from dbo.PMOI 
	where PMCo = @PMCo and [Contract] = @Contract
end

--Current Contract Amount
select @CurrentContractAmount = @OriginalContractAmount + @CurrentCOAmount + @PrevApprovedCOAmount	

--UPDATE TOTALS
update dbo.vPMContractChangeOrder
set OriginalContractAmount = @OriginalContractAmount,
	PrevApprovedCOAmount = @PrevApprovedCOAmount,
	CurrentCOAmount = @CurrentCOAmount,
	CurrentContractAmount = @CurrentContractAmount
where PMCo = @PMCo and [Contract] = @Contract and ID = @ID



	
vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderTotalUpdate] TO [public]
GO
