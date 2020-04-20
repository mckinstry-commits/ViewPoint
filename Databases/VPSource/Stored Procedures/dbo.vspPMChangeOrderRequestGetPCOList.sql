SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:	GP	05/06/2011
* MODIFIED BY:	GP	05/17/2011 - Does not show PCOs already on the tab
*				GP	06/16/2011 - TK-06119 Filtered results to look at unapproved items only
*				
* USAGE:
* Used in PM Change Order Requests to get a list of all valid PCOs
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
CREATE PROC [dbo].[vspPMChangeOrderRequestGetPCOList]
(@PMCo bCompany, @Contract bContract, @COR smallint, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @PMSCFinalStatus bStatus, @PMCOFinalStatus bStatus
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


--Get PCOs
select p.Project, p.PCOType, p.PCO, min(p.[Description]) as [Description], min(p.KeyID) as [KeyID]
from dbo.PMOP p
left join dbo.PMOL l on l.PMCo=p.PMCo and l.Project=p.Project and l.PCOType=p.PCOType and l.PCO=p.PCO
where p.PMCo = @PMCo and p.[Contract] = @Contract and l.ACO is null
	and not exists (select top 1 1 from dbo.PMChangeOrderRequestPCO where PMCo=@PMCo and [Contract]=@Contract
					and COR=@COR and Project=p.Project and PCOType=p.PCOType and PCO=p.PCO)
group by p.Project, p.PCOType, p.PCO

	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestGetPCOList] TO [public]
GO
