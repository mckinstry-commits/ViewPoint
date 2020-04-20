SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMContractChangeOrderIDValNew]
/***********************************************************
* CREATED BY:	GP	05/09/2011
* MODIFIED BY:	
*				
* USAGE:
* Used in to validate that a CCO is new.
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

declare @rcode int
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
if @@rowcount <> 0
begin
	select @msg = 'Contract Change Order already exists.', @rcode = 1
	goto vspexit
end	
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderIDValNew] TO [public]
GO
