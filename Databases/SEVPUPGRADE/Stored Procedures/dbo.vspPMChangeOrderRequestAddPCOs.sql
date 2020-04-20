SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:	GP	05/06/2011
* MODIFIED BY:	GP	05/16/2011 - Added RecordAdded column to insert and totals
*				
* USAGE:
* Used in PM Change Order Requests to add PCOs.
*
* INPUT PARAMETERS
*   PMCo   
*	Project
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 
CREATE PROC [dbo].[vspPMChangeOrderRequestAddPCOs]
(@PMCo bCompany, @Contract bContract, @COR smallint, @KeyString varchar(max), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @KeyID bigint
set @rcode = 0


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

if @COR is null
begin
	select @msg = 'Missing COR.', @rcode = 1
	goto vspexit
end

if @KeyString is null
begin
	select @msg = 'Missing PCOs.', @rcode = 1
	goto vspexit
end


--Loop through each KeyID
while isnull(@KeyString,'') <> ''
begin
	--Get next KeyID
	if charindex(',',@KeyString) <> 0
	begin
		select @KeyID = cast(substring(@KeyString, 0, charindex(',',@KeyString)) as bigint)
		
		--Remove used KeyID
		select @KeyString = substring(@KeyString, charindex(',',@KeyString) + 1, len(@KeyString))
	end	
	else
	begin
		--Get last KeyID
		select @KeyID = cast(@KeyString	as bigint)
		set @KeyString = null
	end
		
	--Insert PCO record
	insert dbo.vPMChangeOrderRequestPCO (PMCo, [Contract], COR, Project, PCOType, PCO, 
		[Date], [Status], TotalCost, TotalRevenue, PurchaseAmount, ROMAmount, Date1, Date2, Date3, RecordAdded)
	select @PMCo, @Contract, @COR, op.Project, op.PCOType, op.PCO, 
		op.DateCreated, op.[Status], t.PCOPhaseCost + t.PCOAddonCost, t.PCORevTotal,
		dbo.vfPMPCOItemsGetCostDetailAmount(op.PMCo, op.Project, op.PCOType, op.PCO, (null), 'P'),
		op.ROMAmount, op.Date1, op.Date1, op.Date3, dbo.vfDateOnly()
	from dbo.PMOP op
	join dbo.PMOPTotals t on t.PMCo=op.PMCo and t.Project=op.Project and t.PCOType=op.PCOType and t.PCO=op.PCO
	where op.KeyID = @KeyID
end
		
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestAddPCOs] TO [public]
GO
