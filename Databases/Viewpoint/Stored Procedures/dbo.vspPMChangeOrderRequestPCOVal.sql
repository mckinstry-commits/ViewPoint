SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMChangeOrderRequestPCOVal]
/***********************************************************
* CREATED BY:	GP	03/14/2011
* MODIFIED BY:	GP	06/16/2011 - TK-06119 Added validation for final status
*				
* USAGE:
* Used in PM Change Order Request PCO tab to validate the PCO.
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*	COR
*	Project
*	PCOType
*	PCO
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @PCOType bPCOType, @PCO bPCO, 
@Date bDate output, @Status bStatus output, 
@TotalCost bDollar output, @PurchaseAmount bDollar output, @TotalRevenue bDollar output, @ROMAmount bDollar output, 
@Date1 bDate output, @Date2 bDate output, @Date3 bDate output, 
@msg varchar(255) output)
as
set nocount on

declare @rcode int, @RecordCount int, @ApprovedCount int
select @rcode = 0, @RecordCount = 0, @ApprovedCount = 0


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

if @PCOType is null
begin
	select @msg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @msg = 'Missing PCO.', @rcode = 1
	goto vspexit
end

--Get record counts, check for approved PCOs
select @RecordCount = count(distinct(KeyID))
from dbo.PMOL
where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO

select @ApprovedCount = count(distinct(KeyID))
from dbo.PMOL
where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO and ACO is not null

if @RecordCount <> 0 and @RecordCount = @ApprovedCount
begin
	select @msg = 'PCO already approved.', @rcode = 1
	goto vspexit
end

--Get Description, Status, Date, ROMAmount, Date1, Date2, Date3
select @msg = [Description], @Status = [Status], @Date = DateCreated, @ROMAmount = ROMAmount,
	@Date1 = Date1, @Date2 = Date2, @Date3 = Date3
from dbo.PMOP 
where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO

if @@rowcount = 0
begin
	select @msg = 'Invalid PCO.', @rcode = 1
	goto vspexit
end	


--Get total cost, total revenue
select @TotalCost = PCOPhaseCost + PCOAddonCost, @TotalRevenue = PCORevTotal from dbo.PMOPTotals where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO

--Get purchase amount
select @PurchaseAmount = dbo.vfPMPCOItemsGetCostDetailAmount(@PMCo, @Project, @PCOType, @PCO, (null), 'P')


	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestPCOVal] TO [public]
GO
