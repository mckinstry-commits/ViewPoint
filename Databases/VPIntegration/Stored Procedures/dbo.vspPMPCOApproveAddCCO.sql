SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMPCOApproveAddCCO]
/************************************
*Created by:	GP 04/05/2011
*Modified by:	GP 06/16/2011 - TK-06154 Updated header totals after all inserts/updates
*				GP 06/27/2011 - TK-06439 Added upadates for PMOL SendYN flag
*				GP 08/12/2011 - TK-07582 Change update of PMOL SendYN flag to PMOI Approved flag
*				TK 08/16/2011 - TK-07713 Changed how records are added to PMContractChangeOrderACO
*
*Purpose:	To check for ACO in PMContractChangeOrderACO
*			and add record, related records, and totals.
*************************************/
(@PMCo bCompany, @ApprovalID smallint, @Project bProject, @PCOType bPCOType, @PCO bPCO, @ACO bACO, 
@Contract bContract, @PCOItem bPCOItem, @ACOItem bACOItem, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @CCOOption varchar(10), @CCO smallint, @CCODesc bItemDesc, @VendorGroup bGroup, 
	@Status bStatus, @EstimateChange bDollar, @PurchaseChange bDollar, @ContractChange bDollar,@Seq int
select @rcode = 0

--VALIDATION
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @ApprovalID is null
begin
	select @msg = 'Missing Approval ID.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @PCOType is null
begin
	select @msg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @msg = 'Missing PCO.', @rcode = 1
	goto vspexit
end

if @ACO is null
begin
	select @msg = 'Missing ACO.', @rcode = 1
	goto vspexit
end

if @Contract is null
begin
	select @msg = 'Missing Contract.', @rcode = 1
	goto vspexit
end


--Get CCO Option
select @CCOOption = CCOOption 
from dbo.PMPCOApprove 
where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project and PCOType = @PCOType and PCO = @PCO

--Exit if not creating CCO
if @CCOOption = 'None'
begin
	--Set SendYN on items to Y
	update dbo.bPMOL
	set SendYN = 'Y'
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO and PCOItem = @PCOItem 
		and ACO = @ACO and ACOItem = @ACOItem and InterfacedDate is null

	goto vspexit
end

--Get CCO and Description
select @CCO = CCONew, @CCODesc = CCONewDesc
from dbo.PMPCOApprove
where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project and PCOType = @PCOType and PCO = @PCO
if @CCOOption = 'Existing'
begin
	select @CCO = CCO
	from dbo.PMPCOApprove
	where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project and PCOType = @PCOType and PCO = @PCO
end

--Check if CCO exists from previous insert
if exists (select top 1 1 from PMContractChangeOrder where PMCo = @PMCo and [Contract] = @Contract and ID = @CCO)
begin
	set @CCOOption = 'Existing'
end

if @CCOOption = 'New'
begin
	--Get vendor group
	select @VendorGroup = hq.VendorGroup 
	from dbo.PMCO pm
	join dbo.HQCO hq on hq.HQCo = pm.APCo
	where pm.PMCo = @PMCo
	
	--Insert main CCO record
	insert dbo.vPMContractChangeOrder (PMCo, [Contract], ID, [Description], [Date], VendorGroup)
	values (@PMCo, @Contract, @CCO, @CCODesc, dbo.vfDateOnly(), @VendorGroup)
end

--Get amount defaults
exec @rcode = dbo.vspPMContractChangeOrderACOVal @PMCo, @Project, @ACO, 
	@Status output, @EstimateChange output, @PurchaseChange output, @ContractChange output, @msg output
--Check for errors	
if @rcode = 1	goto vspexit	


--Insert main ACO record
if not exists (select top 1 1 from dbo.PMContractChangeOrderACO where PMCo=@PMCo and [Contract]=@Contract and ID=@CCO and Project=@Project and ACO=@ACO
and PCOType is Null)
	begin	
		--Only insert ACO Items not linked to PCO Items when Estimate, Purchase or Contract change amounts are equal to zero
		If  @EstimateChange <> 0 or @PurchaseChange <> 0 or @ContractChange <> 0
		begin
			insert dbo.vPMContractChangeOrderACO(PMCo, [Contract], ID, Seq, Project, ACO, [Status], EstimateChange, 
				PurchaseChange, ContractChange)
			select @PMCo, @Contract, @CCO, isnull(max(Seq),0) + 1, @Project, @ACO, @Status, isnull(@EstimateChange,0), 
				isnull(@PurchaseChange,0), isnull(@ContractChange,0)
			from dbo.PMContractChangeOrderACO
			where PMCo = @PMCo and [Contract] = @Contract and ID = @CCO 
		end
	end
else
	--Update changes that might have occured in ACO
	begin
			--Delete ACO Items changes that aren't linked to PCO's
			if  @EstimateChange = 0 and @PurchaseChange = 0 and @ContractChange = 0
				begin
					delete from   dbo.vPMContractChangeOrderACO
					where PMCo=@PMCo and [Contract]=@Contract and ID=@CCO and Project=@Project and ACO=@ACO
					and PCOType is null
				end
			else
				--Update changes from ACO Items not linked to PCO's
				begin
					Update dbo.vPMContractChangeOrderACO
					set  EstimateChange = @EstimateChange, PurchaseChange = @PurchaseChange, ContractChange=@ContractChange
					where PMCo=@PMCo and [Contract]=@Contract and ID=@CCO and Project=@Project and ACO=@ACO
					and PCOType is null
				end
	end

--This code gets called for every PCO Item being approved from vspPMPCOApproveItems (PM PCO Approve) 
--which causes PCO's to be repeated multiple times on CCO.  Each seq then has a different total
--Delete Contract/CCO/Project/ACO/PCO if it exists
select @Seq = null
if  exists (select top 1 1 from dbo.PMContractChangeOrderACO where PMCo=@PMCo and [Contract]=@Contract and ID=@CCO and Project=@Project and ACO=@ACO
and PCOType =@PCOType and PCO=@PCO)
begin
	--Get Seq for existing PCO,  Seq is used for re-inserting the Contract/CCO/Project/ACO/PCO
	select @Seq = Seq from dbo.PMContractChangeOrderACO where PMCo=@PMCo and [Contract]=@Contract and ID=@CCO and Project=@Project and ACO=@ACO
	and PCOType =@PCOType and PCO=@PCO
	--Delete Contract/CCO/Project/ACO/PCO if it exists
	delete from dbo.PMContractChangeOrderACO where PMCo=@PMCo and [Contract]=@Contract and ID=@CCO and Project=@Project and ACO=@ACO
	and PCOType =@PCOType and PCO=@PCO and Seq=@Seq
end

--If Contract/CCO/Project/ACO/PCO doesn't exist get the next higher Seq to be used for adding a record
If @Seq is null
begin
	--Get next Seq
	select @Seq = isnull(max(Seq),0)  + 1
	from dbo.PMContractChangeOrderACO 
	where PMCo = @PMCo and [Contract] = @Contract   and ID = @CCO
end

----Insert related ACO records grouped by PCOType/PCO
--Uses the similar code when adding ACO from PM Contract Change Orders
--Below code uses additional linking and where clause.
insert dbo.vPMContractChangeOrderACO (PMCo, [Contract], ID, Project, ACO, Seq, 
	PCOType, PCO, EstimateChange, PurchaseChange, ContractChange, RecordAdded)	
select @PMCo, @Contract, @CCO, @Project, @ACO, @Seq, 
	Amt.PCOType, Amt.PCO, Amt.ACOItemPhaseCost, Sum(Amt.PMSLAmount) + Sum(Amt.PMMFAmount), Amt.ACOItemRevTotal, dbo.vfDateOnly()
from
(
select DISTINCT i.PCOType, i.PCO, [ACOItemPhaseCost]= Sum(t.ACOItemPhaseCost), [PMSLAmount]=0, [PMMFAmount]=m.Amount, [ACOItemRevTotal]=Sum(t.ACOItemRevTotal)
from dbo.bPMOI i  
join dbo.PMOIACOTotals t on t.PMCo=i.PMCo and t.Project=i.Project and t.ACO=i.ACO and t.ACOItem=i.ACOItem
left join dbo.PMMF m on m.PMCo=i.PMCo and m.Project=i.Project and m.ACO=i.ACO and m.PCO=i.PCO
where i.PMCo = @PMCo and i.Project = @Project and i.ACO = @ACO 
and i.PCOType=@PCOType and i.PCO=@PCO
Group by i.PCOType,i.PCO,m.Amount
union
select DISTINCT i.PCOType, i.PCO, [ACOItemPhaseCost]=Sum(t.ACOItemPhaseCost), [PMSLAmount]=l.Amount,[PMMFAmount]=0, [ACOItemRevTotal]=Sum(t.ACOItemRevTotal)
from dbo.bPMOI i
join dbo.PMOIACOTotals t on t.PMCo=i.PMCo and t.Project=i.Project and t.ACO=i.ACO and t.ACOItem=i.ACOItem
left join dbo.PMSL l on l.PMCo=i.PMCo and l.Project=i.Project and l.ACO=i.ACO and l.PCO=i.PCO
where i.PMCo = @PMCo and i.Project = @Project and i.ACO = @ACO 
and i.PCOType=@PCOType and i.PCO=@PCO
Group by i.PCOType,i.PCO,l.Amount
)
Amt
left join dbo.PMContractChangeOrderACO a on a.PMCo=@PMCo and a.[Contract]=@Contract and a.ID=@CCO 
 and a.PCOType=Amt.PCO and a.PCO=Amt.PCO
group by a.PMCo, a.[Contract], a.ID, Amt.PCOType, Amt.PCO, Amt.ACOItemPhaseCost, Amt.ACOItemRevTotal	


--Update/Refresh Header Totals
exec @rcode = vspPMContractChangeOrderTotalUpdate @PMCo, @Contract, @CCO, 'N', @msg output

--Set Approved on items to N	
update dbo.PMOI
set Approved = 'N'
where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO and PCOItem = @PCOItem 
	and ACO = @ACO and ACOItem = @ACOItem and InterfacedDate is null 



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveAddCCO] TO [public]
GO
