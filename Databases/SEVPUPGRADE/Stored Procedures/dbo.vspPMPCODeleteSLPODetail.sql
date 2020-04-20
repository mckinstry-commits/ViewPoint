SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMPCODeleteSLPODetail]
/***********************************************************
* Created By:	GP	06/28/2011 - TK-06444
* Modified By:	JG	07/12/2011 - TK-05785 - Clearing out the rest of the detail fields
*
* Called from PM PCO to remove all related detail 
* for a PCO by Impact Type (SL or PO).
*****************************************************/
(@PMCo bCompany, @Project bJob, @PCOType bPCOType, @PCO bPCO, @ImpactType varchar(10), @msg varchar(255) output)
as
set nocount on
   
declare @rcode int
select @rcode = 0

--------------
--VALIDATION--
--------------
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

if isnull(@ImpactType,'') = ''
begin
	select @msg = 'Missing Impact Type.', @rcode = 1
	goto vspexit
end

-----------------   
--DELETE DETAIL--
-----------------

if @ImpactType = 'SL'
begin
	--PCO Item Detail - Set SL and Item to NULL
	update dbo.bPMOL
	set Subcontract = null, POSLItem = NULL
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO and Subcontract is not null
end
else if @ImpactType = 'PO'
begin
	--PCO Item Detail - Set PO and Item to NULL
	update dbo.bPMOL
	set PO = null, POSLItem = NULL
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO and PO is not NULL
END
ELSE IF @ImpactType = 'None'
BEGIN
	--PCO Item Detail - Set PO and Item to NULL
	update dbo.bPMOL
	set Subcontract = NULL, PO = null, POSLItem = NULL, MaterialCode = NULL, PurchaseUM = 'LS', PurchaseUnits = 0, PurchaseUnitCost = 0, ECM = 'E', Vendor = NULL
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
END
   
vspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCODeleteSLPODetail] TO [public]
GO
