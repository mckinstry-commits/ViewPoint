SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMContractChangeOrderACOVal]
/***********************************************************
* CREATED BY:	GP	04/12/2011
* MODIFIED BY:	GP/GPT 06/06/2011 - TK-05795 Added code to get PurchaseChange amount and fix Estimate and Contract amounts
*				
* USAGE:
* Used in PM Contract Change Orders - ACO tab to get defaults from ACO.
*
* INPUT PARAMETERS
*   PMCo   
*	Project
*	ACO
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @ACO bACO, 
@Status bStatus output, @EstimateChange bDollar output, @PurchaseChange bDollar output, @ContractChange bDollar output, 
@msg varchar(255) output)
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

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @ACO is null
begin
	select @msg = 'Missing ACO.', @rcode = 1
	goto vspexit
end


--Get description
exec @rcode = dbo.bspPMACOVal @PMCo, @Project, @ACO, null, null, null, null, @msg output
if @rcode = 1	goto vspexit

--Get status
--<CODE HERE>

--Get estimated change
select @EstimateChange = isnull(sum(t.ACOItemPhaseCost),0)
from PMOIACOTotals t
join dbo.PMOI i on i.PMCo=t.PMCo and i.Project=t.Project and i.ACO=t.ACO and i.ACOItem=t.ACOItem
where t.PMCo = @PMCo and t.Project = @Project and t.ACO = @ACO and i.PCO is null

--Get purchase change
select @PurchaseChange = isnull(sum(sl.Amount), 0)
from dbo.PMSL sl
where sl.PMCo = @PMCo and sl.Project = @Project and sl.ACO = @ACO and sl.PCO is null

select @PurchaseChange = @PurchaseChange + isnull(sum(mf.Amount), 0)
from dbo.PMMF mf
where mf.PMCo = @PMCo and mf.Project = @Project and mf.ACO = @ACO and mf.PCO is null

--Get contract change
select @ContractChange = isnull(sum(t.ACOItemRevTotal),0)
from PMOIACOTotals t
join dbo.PMOI i on i.PMCo=t.PMCo and i.Project=t.Project and i.ACO=t.ACO and i.ACOItem=t.ACOItem
where t.PMCo = @PMCo and t.Project = @Project and t.ACO = @ACO and i.PCO is null
	
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderACOVal] TO [public]
GO
