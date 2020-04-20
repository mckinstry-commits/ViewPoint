SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMACOStatus]
/***********************************************************
* CREATED BY:	GP	06/15/2011
* MODIFIED BY:	GP	08/10/2011 - TK-07582 changed status to look at PMOI Approved flag, CCO status groups ACOs
*				
* USAGE:
* Used in PM ACO to return a Status for display in System Status Label.
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

(@PMCo bCompany, @Contract bContract, @Project bProject, @ACO bACO, @Status varchar(40) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @ItemCount smallint, @ApprovedItemCount smallint, @CCO smallint, @CCOItemCount smallint, @CCOApprovedItemCount smallint
select @rcode = 0, @ItemCount = 0, @ApprovedItemCount = 0, @CCOItemCount = 0, @CCOApprovedItemCount = 0


--Get record count of items for the ACO
select @ItemCount = count(1) 
from dbo.PMOI 
where PMCo = @PMCo and Project = @Project and ACO = @ACO

--Get record count of approved items for the ACO
select @ApprovedItemCount = count(1) 
from dbo.PMOI 
where PMCo = @PMCo and Project = @Project and ACO = @ACO and Approved = 'Y'

--Find out if ACO belongs to a Contract Change Order (CCO)
select top 1 @CCO = ID from dbo.PMContractChangeOrderACO where PMCo = @PMCo and [Contract] = @Contract and Project = @Project and ACO = @ACO
if @CCO is not null
begin	
	select @CCOItemCount = count(i.KeyID) 
	from dbo.PMOI i 
	join dbo.PMContractChangeOrderACO c on c.PMCo = i.PMCo and c.[Contract] = i.[Contract] and c.ACO = i.ACO
	where i.PMCo = @PMCo and i.Project = @Project and c.ID = @CCO

	select @CCOApprovedItemCount = count(i.KeyID) 
	from dbo.PMOI i 
	join dbo.PMContractChangeOrderACO c on c.PMCo = i.PMCo and c.[Contract] = i.[Contract] and c.ACO = i.ACO
	where i.PMCo = @PMCo and i.Project = @Project and i.Approved = 'Y' and c.ID = @CCO
end

	
--Set status based on above values	
if @ItemCount = 0
begin
	set @Status = 'No Detail Records' 
end
else if @CCO is not null and (@CCOItemCount = @CCOApprovedItemCount)
begin
	set @Status = 'Approved Contract Change Order'
end
else if @CCO is not null and (@CCOItemCount <> @CCOApprovedItemCount)
begin
	set @Status = 'Pending Contract Change Order'
end
else if @ItemCount = @ApprovedItemCount
begin
	set @Status = 'Approved'
end
else
begin
	set @Status = 'Not Approved'
end

	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMACOStatus] TO [public]
GO
