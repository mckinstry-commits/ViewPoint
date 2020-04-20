SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMSLHeaderApproveVal]
/***********************************************************
* CREATED BY:	GP	08/11/2011
* MODIFIED BY:	DAN SO 11/23/2011 - D-03765 - Allows User to Approve an SL when a SubCO has already been assigned --
*				
* USAGE:
* Used in PM Subcontract Header to make sure there are no related SubCO records
* before allowing user to unapprove.
*
* INPUT PARAMETERS
*   PMCo
*	Project
*	SLCo   
*   SL
*
* OUTPUT PARAMETERS
*	@msg	Error message.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @SLCo bCompany, @SL varchar(30), @msg varchar(255) output)
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

if @SLCo is null
begin
	select @msg = 'Missing SL Company.', @rcode = 1
	goto vspexit
end

if @SL is null
begin
	select @msg = 'Missing Subcontract.', @rcode = 1
	goto vspexit
end


-- D-03765 --
-- Allows User to Approve an SL when a SubCO has already been assigned --
IF EXISTS(SELECT TOP 1 1 FROM SLHDPM WHERE PMCo = @PMCo AND Project = @Project AND SLCo = @SLCo AND SL = @SL AND Approved = 'Y')
	BEGIN
		--Check for existing POCO records
		if exists (select top 1 1 from dbo.vPMSubcontractCO where PMCo = @PMCo and Project = @Project and SLCo = @SLCo and SL = @SL)
		begin
			select @msg = 'Subcontract has been assigned to a Subcontract Change Order and cannot be unapproved. Delete the Subcontract Change Order in order to unapprove the Subcontract.', @rcode = 1
			goto vspexit
		end
	END
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSLHeaderApproveVal] TO [public]
GO
