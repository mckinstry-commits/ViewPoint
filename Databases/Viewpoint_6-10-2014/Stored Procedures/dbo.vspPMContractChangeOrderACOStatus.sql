SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMContractChangeOrderACOStatus]
/***********************************************************
* CREATED BY:	GP	04/15/2011
* MODIFIED BY:	GPT 6/27/2011 Added count for items with no detail.
*				GP	7/26/2011 - TK-07027 Changed the entire criteria for CCO header status
*				GP	8/9/2011 - TK-07582 Changed status to look at Approved flag in PMOI
*				
* USAGE:
* Used in PM Contract Change Order to return the overall status of ACOs.
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

(@PMCo bCompany, @Contract bContract, @ID smallint, @Status varchar(20) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @ACOCount smallint, @ApprovedACOCount smallint
select @rcode = 0, @ACOCount = 0, @ApprovedACOCount = 0


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


--Get record count of ACO Items
select @ACOCount = count(distinct(i.KeyID))
from dbo.PMContractChangeOrderACO a
join dbo.PMOI i on i.PMCo=a.PMCo and i.Project=a.Project and i.ACO=a.ACO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.ID = @ID

--Get record count of ACO Items (Approved=Y)
select @ApprovedACOCount = count(distinct(i.KeyID))
from dbo.PMContractChangeOrderACO a
join dbo.PMOI i on i.PMCo=a.PMCo and i.Project=a.Project and i.ACO=a.ACO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.ID = @ID and i.Approved = 'Y'

		
--Compare counts to set status
if @ACOCount = 0
begin
	set @Status = 'No ACOs'
end
else if @ACOCount = @ApprovedACOCount
begin
	set @Status = 'Approved'
end	
else if @ACOCount <> @ApprovedACOCount and @ApprovedACOCount <> 0
begin
	set @Status = 'Partially Approved'
end
else
begin
	set @Status = 'Not Approved'
end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderACOStatus] TO [public]
GO
