SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMContractChangeOrderIDVal]
/***********************************************************
* CREATED BY:	GP	05/04/2011
* MODIFIED BY:	GP	08/15/2011 - TK-07582 Added check for CCO status
*				
* USAGE:
* Used in to validate and return PM Contract Change Order ID. On
* PM PCO Approve also ensures the ACO is not being added to an
* approved CCO.
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

(@PMCo bCompany, @Contract bContract, @ID smallint, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @Status varchar(20)
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


--Get Description
select @msg = [Description] from dbo.PMContractChangeOrder where PMCo = @PMCo and [Contract] = @Contract and ID = @ID
if @@rowcount = 0
begin
	select @msg = 'Invalid Contract Change Order.', @rcode = 1
	goto vspexit
end	

--Check status, cannot add an ACO to an approved CCO
exec dbo.vspPMContractChangeOrderACOStatus @PMCo, @Contract, @ID, @Status output, null
if @Status = 'Approved'
begin
	select @msg = 'This CCO is already approved.', @rcode = 1
	goto vspexit
end
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderIDVal] TO [public]
GO
