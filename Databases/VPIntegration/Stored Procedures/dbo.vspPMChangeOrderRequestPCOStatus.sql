SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMChangeOrderRequestPCOStatus]
/***********************************************************
* CREATED BY:	GP	05/11/2011
* MODIFIED BY:	
*				
* USAGE:
* Used in PM Change Order Request to return the overall status of PCOs.
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

if @ID is null
begin
	select @msg = 'Missing COR.', @rcode = 1
	goto vspexit
end

--Get record counts
select @RecordCount = count(distinct(l.KeyID))
from dbo.PMChangeOrderRequestPCO a
join dbo.PMOL l on l.PMCo=a.PMCo and l.Project=a.Project and l.PCOType=a.PCOType and l.PCO=a.PCO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.COR = @ID

select @ApprovedCount = count(distinct(l.KeyID))
from dbo.PMChangeOrderRequestPCO a
join dbo.PMOL l on l.PMCo=a.PMCo and l.Project=a.Project and l.PCOType=a.PCOType and l.PCO=a.PCO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.COR = @ID and l.ACO is not null
	
--Compare counts to set status
if @RecordCount = 0
begin
	set @Status = 'No PCOs'
end
else if @RecordCount = @ApprovedCount
begin
	set @Status = 'Approved'
end	
else if @ApprovedCount <> 0 and @RecordCount > @ApprovedCount
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
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestPCOStatus] TO [public]
GO
