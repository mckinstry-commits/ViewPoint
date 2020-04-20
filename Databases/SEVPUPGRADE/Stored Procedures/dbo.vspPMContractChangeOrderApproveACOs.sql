SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMContractChangeOrderApproveACOs]
/***********************************************************
* CREATED BY:	GP	04/14/2011
* MODIFIED BY:	GP	07/20/2011 - TK-06975 Added @Approve output and ability to unapprove ACOs, also clear CCO approved date.
*				GP	08/11/2011 - TK-07582 Added ability to change PMOI.Approved flag
*				
* USAGE:
* Used in PM Contract Change Order to approve ACOs.
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*	ID
*	Approve (Y - approve or N - unapprove)
*
* OUTPUT PARAMETERS
*   @msg		Errors if found.
*
* RETURN VALUE
*   0			Success
*   1			Failure
*****************************************************/ 

(@PMCo bCompany, @Contract bContract, @ID smallint, @ACOCount smallint output, @Approve bYN output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @Status varchar(20)
select @rcode = 0, @ACOCount = 0, @Approve = 'Y'


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


--get current status and set @Approve
exec @rcode = dbo.vspPMContractChangeOrderACOStatus @PMCo, @Contract, @ID, @Status output, @msg output

--if all ACOs are approved, flip @Approve flag to unapprove
if upper(@Status) = 'APPROVED'
begin
	set @Approve = 'N'
end


--Set ACOs to interface state
update l
set l.[SendYN] = @Approve
from dbo.vPMContractChangeOrderACO a
join dbo.bPMOL l on l.PMCo=a.PMCo and l.Project=a.Project 
	and isnull(l.PCOType,'1')=isnull(a.PCOType,'1') and isnull(l.PCO,'1')=isnull(a.PCO,'1') 
	and l.ACO=a.ACO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.ID = @ID

update h
set h.[ReadyForAcctg] = @Approve
from dbo.vPMContractChangeOrderACO a
join dbo.bPMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.ID = @ID

update i
set i.[Approved] = @Approve
from dbo.vPMContractChangeOrderACO a
join dbo.bPMOI i on i.PMCo=a.PMCo and i.Project=a.Project and i.ACO=a.ACO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.ID = @ID 

--Clear approve date on the current CCO
update dbo.vPMContractChangeOrder
set DateApproved = null
where PMCo = @PMCo and [Contract] = @Contract and ID = @ID

--Get ACO count
select @ACOCount = count(distinct(ACO))
from dbo.PMContractChangeOrderACO 
where PMCo = @PMCo and [Contract] = @Contract and ID = @ID

	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderApproveACOs] TO [public]
GO
