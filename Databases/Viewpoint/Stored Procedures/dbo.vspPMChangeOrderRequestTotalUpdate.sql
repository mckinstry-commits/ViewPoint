SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMChangeOrderRequestTotalUpdate]
/***********************************************************
* CREATED BY:	GP	05/13/2011
* MODIFIED BY:	GP	05/16/2011 - Added RefreshDetail code
*				
* USAGE:
* Used in PM Change Order Request to update the totals on the Info tab.
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*	ID (COR)
*
* OUTPUT PARAMETERS
*   @msg		Description of Department if found.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Contract bContract, @ID smallint, @RefreshDetail char(1), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @OriginalContractAmount bDollar, @PrevApprovedCOAmount bDollar, 
	@CurrentCOAmount bDollar, @CurrentContractAmount bDollar, @ApprovedPCOAmount bDollar,
	@TotalCost bDollar, @TotalRevenue bDollar, @PurchaseAmount bDollar, @ROMAmount bDollar,
	@KeyID int, @Project bProject, @PCOType bPCOType, @PCO bPCO
select @rcode = 0, @OriginalContractAmount = 0, @PrevApprovedCOAmount = 0, 
	@CurrentCOAmount = 0, @CurrentContractAmount = 0, @ApprovedPCOAmount = 0


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
	select @msg = 'Missing COR.', @rcode = 1
	goto vspexit
end


--UPDATE DETAIL
if @RefreshDetail = 'Y'
begin
	--loop through each pco
	select * into #TempPCOs from dbo.vPMChangeOrderRequestPCO where PMCo = @PMCo and [Contract] = @Contract and COR = @ID order by KeyID
	select @KeyID = min(KeyID) from #TempPCOs
	
	while @KeyID is not null
	begin
		select @TotalCost = 0, @TotalRevenue = 0, @PurchaseAmount = 0, @ROMAmount = 0
		select @Project = Project, @PCOType = PCOType, @PCO = PCO from #TempPCOs where KeyID = @KeyID

		select @ROMAmount = ROMAmount
		from dbo.PMOP 
		where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO

		select @TotalCost = PCOPhaseCost + PCOAddonCost, @TotalRevenue = PCORevTotal from dbo.PMOPTotals where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO

		select @PurchaseAmount = dbo.vfPMPCOItemsGetCostDetailAmount(@PMCo, @Project, @PCOType, @PCO, (null), 'P')

		update dbo.vPMChangeOrderRequestPCO
		set TotalCost = @TotalCost,
			TotalRevenue = @TotalRevenue,
			PurchaseAmount = @PurchaseAmount,
			ROMAmount = @ROMAmount,
			RecordAdded = dbo.vfDateOnly()
		where KeyID = @KeyID
		
		select @KeyID = min(KeyID) from #TempPCOs where KeyID > @KeyID
	end
		
	drop table #TempPCOs	
end


--UPDATE HEADER
--Original Contract Amount
select @OriginalContractAmount = isnull(OrigContractAmt, 0)
from dbo.JCCM 
where JCCo = @PMCo and [Contract] = @Contract

--Current Contract Change Order
select @CurrentCOAmount = isnull(sum(TotalRevenue), 0) 
from dbo.PMChangeOrderRequestPCO
where PMCo = @PMCo and [Contract] = @Contract and COR = @ID

--Previously Authorized Contract Changes
select @PrevApprovedCOAmount = PrevApprovedCOAmount 
from dbo.PMChangeOrderRequest 
where PMCo = @PMCo and [Contract] = @Contract and COR = @ID 
--Only update approved amount if not brought in previously
if @PrevApprovedCOAmount is null or @RefreshDetail = 'Y'
begin
	--Approved PCO Amount in current COR
	select @ApprovedPCOAmount = isnull(sum(i.ApprovedAmt), 0)
	from dbo.PMOI i
	join dbo.PMChangeOrderRequestPCO p on p.PMCo=i.PMCo and p.[Contract]=i.[Contract] 
		and p.Project=i.Project and p.PCOType=i.PCOType and p.PCO=i.PCO
	where p.PMCo = @PMCo and p.[Contract] = @Contract and p.COR = @ID

	select @PrevApprovedCOAmount = isnull(sum(ApprovedAmt), 0) - @ApprovedPCOAmount
	from dbo.PMOI 
	where PMCo = @PMCo and [Contract] = @Contract
end

--Current Contract Amount
select @CurrentContractAmount = @OriginalContractAmount + @CurrentCOAmount + @PrevApprovedCOAmount	

--UPDATE TOTALS
update dbo.vPMChangeOrderRequest
set OriginalContractAmount = @OriginalContractAmount,
	PrevApprovedCOAmount = @PrevApprovedCOAmount,
	CurrentCOAmount = @CurrentCOAmount,
	CurrentContractAmount = @CurrentContractAmount
where PMCo = @PMCo and [Contract] = @Contract and COR = @ID


	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestTotalUpdate] TO [public]
GO
