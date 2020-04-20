SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create proc [dbo].[vspPMPCOApproveItems]
/************************************
*Created by:	GP 3/26/2011
*Modified by:	GP 4/5/2011 - TK-04873 Added ability to assign ACO to an existing contract change order.
*				GP 6/14/2011 - TK-05844 Set SendYN flag in PMOL back to N after approved.
*				GP 06/27/2011 - TK-06439 Removed upadates for PMOL SendYN flag.
*				TL 11/17/2011 TK-09994 add parameter @ReadyForAccounting
*				TL  01/11/2012 TK-11599 changed Status code update, Gets Status code from PMCO, then from Existing PCO' Document categorys
*				DAN SO 03/12/2012 TK-13118 - Added @CreateChangeOrders and @CreateSingleChangeOrder
*
*Purpose:	Approves PCO Items for PMPCOApprove form.
*************************************/
(@PMCo bCompany, @ApprovalID smallint, @Username bVPUserName, 
@CurrentProject bProject, @CurrentPCOType bPCOType, @CurrentPCO bPCO,
@ApprovedItemCount int output, @ErrorItemCount int output, @ReadyForAccounting bYN = null, 
-- TK-13118 --
@CreateChangeOrders bYN = NULL, @CreateSingleChangeOrder bYN = NULL,
@msg varchar(255) output)
as
set nocount on

declare @rcode int, @LastItem int, @Counter int, @ItemErrorMsg varchar(255),
	@FinalStatus bStatus, @StatusItemCount int,
	@Project bJob, @PCOType bDocType, @PCO bPCO,
	@ACO bACO, @ACODesc bItemDesc, @ApprovedDate bDate, @AdditionalDays smallint,
	@Seq int, @NewCompletionDate bDate, @Approver varchar(30), @ACOItem bACOItem,
	@ACOItemDesc bItemDesc, @ItemDate bDate, @ApprovedAmount bDollar, @ContractItem bContractItem,
	@UM bUM, @Units bUnits, @CallingForm tinyint, @HeaderStatus varchar(10),
	@PCOItem bPCOItem, @ItemKeyID as bigint, @Contract bContract
 
select @rcode = 0, @Counter = 1, @ApprovedItemCount = 0, @ErrorItemCount = 0

--------------
--VALIDATION--
--------------
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

if @Username is null
begin
	select @msg = 'Missing Username.', @rcode = 1
	goto vspexit
end


-----------------
--APPROVE ITEMS--
-----------------
--Get data for all items marked for approval
select row_number() OVER (ORDER BY i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem) as RowNumber,
	a.PMCo, a.ApprovalID, a.Project, a.PCOType, a.PCO, a.ACO, a.ACODesc, a.ApprovalDate,
	a.CompletionDate, a.AdditionalDays, a.ReportSeqNum, a.Username, a.[Contract], a.COR, a.KeyID as [HeaderKeyID],
	i.PCOItem, i.Approve, i.ACOItem, i.ACOItemDesc, i.ApprovalDate as [ItemApprovalDate], i.ContractItem, i.ApprovedAmount,
	i.AdditionalDays as [ItemAdditionalDays], i.UM, i.Units, i.KeyID as [ItemKeyID]
into #ItemsToApprove	
from dbo.PMPCOApprove a
join dbo.PMPCOApproveItem i on i.PMCo=a.PMCo and i.ApprovalID=a.ApprovalID and i.Project=a.Project and i.PCOType=a.PCOType and i.PCO=a.PCO
where a.PMCo = @PMCo and a.ApprovalID = @ApprovalID and a.Username = @Username and a.ACO is not null and i.Approve = 'Y' and i.ACOItem is not null

--Get last item seq
select @LastItem = max(RowNumber) from #ItemsToApprove
--Check for items to approve
if @LastItem is null
begin
	select @msg = 'The PCO contains no items to approve.', @rcode = 1
	goto vspexit
end

--Loop through items
while @Counter <= @LastItem
begin
	--Reset parameter values
	select @rcode = 0, @HeaderStatus = null, @ItemErrorMsg = null, @StatusItemCount = null,
		@Project = null, @PCOType = null, @PCO = null, @ACO = null, @ACODesc = null, @ApprovedDate = null, 
		@AdditionalDays = null, @Seq = null, @NewCompletionDate = null, @Approver = null, @ACOItem = null, @ACOItemDesc = null, 
		@ItemDate = null, @ApprovedAmount = null, @ContractItem = null, @UM = null, @Units = null, @CallingForm = null, 
		@HeaderStatus = null, @PCOItem = null, @Contract = null

	--Set values to pass into approval stored procedure
	select @Project = Project, @PCOType = PCOType, @PCO = PCO, @ACO = ACO, @ACODesc = ACODesc, @ApprovedDate = ApprovalDate, 
		@AdditionalDays = ItemAdditionalDays, @NewCompletionDate = CompletionDate, @Approver = cast(@Username as varchar(30)), 
		@ACOItem = ACOItem, @ACOItemDesc = ACOItemDesc, @ItemDate = ItemApprovalDate, @ApprovedAmount = ApprovedAmount, 
		@ContractItem = ContractItem, @UM = UM, @Units = Units, @CallingForm = 2, @PCOItem = PCOItem, @ItemKeyID = ItemKeyID,
		@Contract = [Contract]
	from #ItemsToApprove 
	where RowNumber = @Counter
	
	--Dates cannot be null
	if @ApprovedDate is null	set @ApprovedDate = dbo.vfDateOnly()
	if @ItemDate is null		set @ItemDate = dbo.vfDateOnly()
	
	--Set aco status
	if not exists (select top 1 1 from dbo.PMOH where PMCo = @PMCo and Project = @Project and ACO = @ACO)
	begin
		set @HeaderStatus = 'new'
	end

	--Approve item
	exec @rcode = dbo.bspPMPCOApprove @PMCo, @Project, @PCOType, @PCO, @ACO, @ACODesc, @ApprovedDate, @AdditionalDays,
		@Seq, @NewCompletionDate, @Approver, @ACOItem, @ACOItemDesc, @ItemDate, @ApprovedAmount, @ContractItem,
		@UM, @Units, @CallingForm, @HeaderStatus, @PCOItem,  @ReadyForAccounting,
		-- TK-13118 --
		@CreateChangeOrders, @CreateSingleChangeOrder,
		@ItemErrorMsg output	
	
	--Check for errors
	if @rcode = 0
	begin
		--Check CCO option and add record
		exec @rcode = dbo.vspPMPCOApproveAddCCO @PMCo, @ApprovalID, @Project, @PCOType, @PCO, @ACO, @Contract, @PCOItem, @ACOItem, @msg output
		if @rcode = 1	goto vspexit
	
		--Delete item record from work table once approved
		delete dbo.vPMPCOApproveItem
		where KeyID = @ItemKeyID
		
		set @ApprovedItemCount = @ApprovedItemCount + 1
	end
	else
	begin
		update dbo.vPMPCOApproveItem
		set Error = @ItemErrorMsg
		where KeyID = @ItemKeyID and @ItemErrorMsg is not null
		
		set @ErrorItemCount = @ErrorItemCount + 1
	end
	
	--Set pco header status to final once all items approved	
	select @StatusItemCount = count(1) 
	from dbo.PMOI 
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO 
		and ACO is null and ACOItem is null
	if @StatusItemCount = 0
	begin	
		select @FinalStatus = FinalStatus from dbo.PMCO where PMCo = @PMCo and FinalStatus is not null

		if @FinalStatus is null		
		begin
			select @FinalStatus = min([Status]) from dbo.PMSC where CodeType = 'F' and DocCat = 'PCO'

			if @FinalStatus is null		
			begin
				select @FinalStatus = min([Status]) from dbo.PMSC where CodeType = 'F' and ActiveAllYN = 'Y'
			end
		end

		update dbo.bPMOP
		set [Status] = @FinalStatus
		where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
	end	
	
	--Increment counter
	set @Counter = @Counter + 1	
end

--Drop temp table
if object_id('tempdb.dbo.#ItemsToApprove') is not null
begin
	drop table #ItemsToApprove
end	


vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveItems] TO [public]
GO
