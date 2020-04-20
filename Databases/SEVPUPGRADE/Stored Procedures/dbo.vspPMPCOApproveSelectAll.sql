SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMPCOApproveSelectAll]
/************************************
*Created by:	GP 3/26/2011
*Modified by:
*
*Purpose:	Selects or deselects all items for
*			the current header record in PMPCOApprove.
*************************************/
(@PMCo bCompany, @ApprovalID smallint, @ACO bACO, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @SelectAll char(1), @Counter int, @LastItem int, @ACOItem bACOItem, 
	@ItemKeyID bigint, @ApprovalDate bDate, @Project bProject, @PCOType bPCOType, @PCO bPCO
select @rcode = 0, @SelectAll = 'Y', @Counter = 1

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


--Clear existing aco items so the next aco item doesn't build off existing values
update dbo.vPMPCOApproveItem
set ACO = null, ACOItem = null, ApprovalDate = null
where PMCo = @PMCo and ApprovalID = @ApprovalID

--SELECT ALL
update dbo.vPMPCOApproveItem
set Approve = 'Y'
where PMCo = @PMCo and ApprovalID = @ApprovalID 

--GET ACO ITEMS
if @SelectAll = 'Y'
begin
	--Get all rows that need aco items
	select row_number() OVER (ORDER BY PMCo, Project, PCOType, PCO, PCOItem) as RowNumber, * 
	into #ItemsToApprove
	from dbo.PMPCOApproveItem
	where PMCo = @PMCo and ApprovalID = @ApprovalID
	
	--Get last item seq
	select @LastItem = max(RowNumber) from #ItemsToApprove
	
	--Loop through items
	while @Counter <= @LastItem
	begin
		--Reset parameter values
		select @ItemKeyID = null, @ACOItem = null, @Project = null, @PCOType = null, @PCO = null
	
		--Set values to pass into get aco item stored procedure
		select @ItemKeyID = KeyID, @Project = Project, @PCOType = PCOType, @PCO = PCO 
		from #ItemsToApprove 
		where RowNumber = @Counter
		
		--Update items with new ACO
		update dbo.vPMPCOApproveItem
		set ACO = @ACO
		where KeyID = @ItemKeyID
		
		--Get header aco
		select @ApprovalDate = ApprovalDate
		from dbo.PMPCOApprove 
		where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project and PCOType = @PCOType and PCO = @PCO		
				
		--Get next aco item
		exec @rcode = dbo.vspPMPCOApproveGetNextACOItem @PMCo, @Project, @ACO, @ApprovalID, @ACOItem output, @msg output
		if @rcode = 0 and @ACOItem is not null
		begin
			update dbo.vPMPCOApproveItem
			set ACOItem = @ACOItem, ApprovalDate = @ApprovalDate
			where KeyID = @ItemKeyID and ACOItem is null
		end
		
		--Increment counter
		set @Counter = @Counter + 1
	end
end

--Drop temp table
if object_id('tempdb.dbo.#ItemsToApprove') is not null
begin
	drop table #ItemsToApprove
end	



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveSelectAll] TO [public]
GO
