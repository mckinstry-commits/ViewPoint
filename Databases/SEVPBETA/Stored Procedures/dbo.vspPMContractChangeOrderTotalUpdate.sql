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
	@KeyID int, @Project bProject, @PCOType bPCOType, @PCO bPCO
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
	--loop through each pco
	select * into #TempACOs from dbo.vPMContractChangeOrderACO where PMCo = @PMCo and [Contract] = @Contract and ID = @ID order by KeyID
	select @KeyID = min(KeyID) from #TempACOs
	
	while @KeyID is not null
	begin
		select @EstimateChange = 0, @PurchaseChange = 0, @ContractChange = 0
		select @Project = Project, @PCOType = PCOType, @PCO = PCO from #TempACOs where KeyID = @KeyID
				
		select @EstimateChange = isnull(sum(t.ACOItemPhaseCost),0), @PurchaseChange = isnull(sum(l.Amount),0) + isnull(sum(m.Amount),0), 
			@ContractChange = isnull(sum(t.ACOItemRevTotal),0)
		from dbo.PMContractChangeOrderACO a
		join dbo.PMOI i on i.PMCo=a.PMCo and i.Project=a.Project and (i.PCOType=a.PCOType OR i.PCOType IS NULL) and (i.PCO=a.PCO OR i.PCO IS NULL) and i.ACO=a.ACO
		join dbo.PMOIACOTotals t on t.PMCo=i.PMCo and t.Project=i.Project and t.ACO=i.ACO and t.ACOItem=i.ACOItem
		left join dbo.PMSL l on l.PMCo=i.PMCo and l.Project=i.Project and l.ACO=i.ACO and l.ACOItem=i.ACOItem
		left join dbo.PMMF m on m.PMCo=i.PMCo and m.Project=i.Project and m.ACO=i.ACO and m.ACOItem=i.ACOItem
		where a.KeyID = @KeyID and (i.PCOType = @PCOType OR i.PCOType IS NULL) and (i.PCO = @PCO OR i.PCO IS NULL)
	
		update dbo.vPMContractChangeOrderACO
		set EstimateChange = @EstimateChange,
			PurchaseChange = @PurchaseChange,
			ContractChange = @ContractChange,
			RecordAdded = dbo.vfDateOnly()
		where KeyID = @KeyID
		
		select @KeyID = min(KeyID) from #TempACOs where KeyID > @KeyID
	end
		
	drop table #TempACOs	
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
