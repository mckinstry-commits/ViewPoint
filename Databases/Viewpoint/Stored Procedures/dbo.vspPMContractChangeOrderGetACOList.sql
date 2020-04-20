SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:	GP	05/17/2011
* MODIFIED BY:	GP	05/17/2011 - Does not show PCOs already on the tab
*				
* USAGE:
* Used in PM Contract Change Orders to get a list of all valid ACOs
* for the specified PMCo and Contract.
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
CREATE PROC [dbo].[vspPMContractChangeOrderGetACOList]
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

--Get ACOs
select Project, ACO, [Description], KeyID 
from dbo.PMOH 
where PMCo = @PMCo and [Contract] = @Contract
	and not exists (select top 1 1 from dbo.PMContractChangeOrderACO where PMCo=@PMCo and [Contract]=@Contract
					and ID=@ID and Project=PMOH.Project and ACO=PMOH.ACO)
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderGetACOList] TO [public]
GO
