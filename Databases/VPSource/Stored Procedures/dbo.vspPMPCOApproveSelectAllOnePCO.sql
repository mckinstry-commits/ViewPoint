SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMPCOApproveSelectAllOnePCO]
/************************************
*Created by:	GP 3/26/2011
*Modified by:
*
*Purpose:	Selects or deselects all items for
*			the current header record in PMPCOApprove.
*************************************/
(@PMCo bCompany, @ApprovalID smallint, @Project bProject, @PCOType bPCOType, @PCO bPCO, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @SelectAll char(1), @ACO bACO, @Counter int, @LastItem int, @ACOItem bACOItem, 
	@ItemKeyID bigint, @ApprovalDate bDate
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

--SELECT ALL
if not exists (select * from dbo.PMPCOApproveItem where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project and PCOType = @PCOType and PCO = @PCO and Approve = 'N')
begin
	set @SelectAll = 'N'
end

update dbo.vPMPCOApproveItem
set Approve = @SelectAll
where PMCo = @PMCo and ApprovalID = @ApprovalID 
and Project = @Project and PCOType = @PCOType 
and PCO = @PCO

--GET ACO ITEMS
if @SelectAll = 'Y'
begin
	--Get header aco
	select @ACO = ACO, @ApprovalDate = ApprovalDate
	from dbo.PMPCOApprove 
	where PMCo = @PMCo and ApprovalID = @ApprovalID  and Project = @Project and PCOType = @PCOType and PCO = @PCO

	--Get all rows that need aco items
	select row_number() OVER (ORDER BY PMCo, Project, PCOType, PCO, PCOItem) as RowNumber, * 
	into #ItemsToApprove
	from dbo.PMPCOApproveItem
	where PMCo = @PMCo and ApprovalID = @ApprovalID  and Project = @Project and PCOType = @PCOType and PCO = @PCO
	
	--Get last item seq
	select @LastItem = max(RowNumber) from #ItemsToApprove
	
	--Loop through items
	while @Counter <= @LastItem
	begin
		--Reset parameter values
		select @ItemKeyID = null, @ACOItem = null
	
		--Set values to pass into get aco item stored procedure
		select @ItemKeyID = KeyID  from #ItemsToApprove where RowNumber = @Counter
		
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
else --@SelectAll = 'N'
begin
	--Clear aco items
	update dbo.vPMPCOApproveItem
	set ACOItem = null, ApprovalDate = null
	where PMCo = @PMCo and ApprovalID = @ApprovalID 
	and Project = @Project and PCOType = @PCOType 
	and PCO = @PCO
end

--Drop temp table
if object_id('tempdb.dbo.#ItemsToApprove') is not null
begin
	drop table #ItemsToApprove
end	



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveSelectAllOnePCO] TO [public]
GO
