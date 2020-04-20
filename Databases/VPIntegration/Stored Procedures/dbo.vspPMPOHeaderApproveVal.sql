SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMPOHeaderApproveVal]
/***********************************************************
* CREATED BY:	GP 08/11/2011
* MODIFIED BY:	NH 02/22/2012 - TK-12790 - allow approval of POs with POCO records
*				
* USAGE:
* Used in PM PO Header to make sure there are no related POCO records
* before allowing user to unapprove.
*
* INPUT PARAMETERS
*   PMCo
*	Project
*	POCo   
*   PO
*
* OUTPUT PARAMETERS
*	@msg	Error message.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @POCo bCompany, @PO varchar(30), @msg varchar(255) output)
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

if @POCo is null
begin
	select @msg = 'Missing PO Company.', @rcode = 1
	goto vspexit
end

if @PO is null
begin
	select @msg = 'Missing PO.', @rcode = 1
	goto vspexit
end

-- TK-12790 - Allows user to approve a PO when a POCO has already been assigned
if exists(select 1 from dbo.POHD where POCo = @POCo and PO = @PO and Approved = 'Y')
begin
	--Check for existing POCO records
	if exists (select 1 from dbo.PMPOCO where POCo = @POCo and PO = @PO)
	begin
		select @msg = 'Purchase Order has been assigned to a PO Change Order and cannot be unapproved. Delete the PO Change Order in order to unapprove the PO.', @rcode = 1
		goto vspexit
	END
end

vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMPOHeaderApproveVal] TO [public]
GO
