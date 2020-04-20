SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMGetNextCCO]
/***********************************************************
* CREATED BY:	GP	05/11/2011
* MODIFIED BY:	
*				
* USAGE:
* Used to get the next Contract Change Order ID.
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

(@PMCo bCompany, @Contract bContract, @CCO smallint output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @RecordCount smallint, @ApprovedCount smallint
select @rcode = 0, @RecordCount = 0, @ApprovedCount = 0


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


--Get next CCO
select @CCO = isnull(max(ID),0) + 1 from dbo.vPMContractChangeOrder where PMCo = @PMCo and [Contract] = @Contract	
	
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextCCO] TO [public]
GO
