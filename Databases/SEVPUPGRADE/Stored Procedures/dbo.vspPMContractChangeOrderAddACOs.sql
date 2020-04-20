SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:	GP	05/06/2011
* MODIFIED BY:	GP	05/16/2011 - Added RecordAdded column to insert and totals
*				GP/GPT 06/06/2011 - TK-05795 Reused ACOVal code to get totals, removed last insert by fixing keystring iteration
*				TRl 07/25/20011 - TK-07036   Moved  Insert of first ACO record with out PCO to be executed after @@rowcount
*				
* USAGE:
* Used in PM Contract Change Orders to add ACOs.
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
CREATE PROC [dbo].[vspPMContractChangeOrderAddACOs]
(@PMCo bCompany, @Contract bContract, @ID smallint, @KeyString varchar(max), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @KeyID bigint, @Seq int, @Project bProject, @ACO bACO, 
	@Status bStatus, @EstimateChange bDollar, @PurchaseChange bDollar, @ContractChange bDollar
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

if @ID is null
begin
	select @msg = 'Missing ID.', @rcode = 1
	goto vspexit
end

if @KeyString is null
begin
	select @msg = 'Missing ACOs.', @rcode = 1
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
	
	--Get next Seq
	select @Seq = isnull(max(Seq),0) + 1 
	from dbo.PMContractChangeOrderACO 
	where PMCo = @PMCo and [Contract] = @Contract and ID = @ID
	
	----Insert ACO record
	select @Project = Project, @ACO = ACO from dbo.PMOH where KeyID = @KeyID
	
	exec @rcode = dbo.vspPMContractChangeOrderACOVal @PMCo, @Project, @ACO, 
		@Status output, @EstimateChange output, @PurchaseChange output, @ContractChange output, @msg output

	
	--Insert ACO detail records (PCOs)
	if @@rowcount > 0
	begin

		If IsNull(@EstimateChange,0) <> 0 or  IsNull(@PurchaseChange,0) <> 0 or IsNull( @ContractChange,0) <> 0 
		begin 
				insert dbo.vPMContractChangeOrderACO (PMCo, [Contract], ID, Seq, Project, ACO, [Status], 
					EstimateChange, PurchaseChange, ContractChange)	
				values (@PMCo, @Contract, @ID, @Seq, @Project, @ACO, @Status, @EstimateChange, @PurchaseChange, @ContractChange)	
		end

		exec @rcode = dbo.vspPMContractChangeOrderACOAddPCOs @PMCo, @Project, @ACO, @Contract, @ID, @msg output
	end	
end
	
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderAddACOs] TO [public]
GO
