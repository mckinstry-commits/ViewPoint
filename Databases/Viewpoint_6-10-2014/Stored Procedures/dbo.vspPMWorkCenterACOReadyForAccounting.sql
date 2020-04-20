SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMWorkCenterACOReadyForAccounting]
/*********************************************************************
* CREATED BY:	NH	10/31/2012
* MODIFIED BY:	
*				
* USAGE:
* Used to set ReadyForAcctg flag in ACO Item Header (PMOH)
* when ACO Ready for Accounting task is executed from the Work Center.
*
* INPUT PARAMETERS
*   PMCo   
*   Project
*	ACO
*	Ready (Ready for Accounting at ACO header)
*
* OUTPUT PARAMETERS
*   @msg		Error message if found
*
* RETURN VALUE
*   0         Success
*   1         Failure
*********************************************************************/

(@PMCo bCompany, @Project bProject, @ACO bACO, @Ready bYN, @msg varchar(255) output)
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

if @Ready is null
begin
	select @msg = 'Missing Ready Flag.', @rcode = 1
	goto vspexit
end
else if @Ready not in ('Y','N')
begin
	set @Ready = 'Y'
end

--UPDATE ITEM DETAIL
update dbo.bPMOH
set ReadyForAcctg = @Ready
where PMCo = @PMCo and Project = @Project and ACO = @ACO
	
vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMWorkCenterACOReadyForAccounting] TO [public]
GO
