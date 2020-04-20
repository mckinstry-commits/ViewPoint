SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMACOReadyForAccountingUpdate]
/***********************************************************
* CREATED BY:	GP	07/26/2011 - TK-07027
* MODIFIED BY:	
*				
* USAGE:
* Used to set Interface (SendYN) flag in ACO Item Detail (PMOL)
* when ACO Ready for Accounting flag is changed.
*
* INPUT PARAMETERS
*   PMCo   
*   Project
*	ACO
*	Approved (Ready for Accounting at ACO header)
*
* OUTPUT PARAMETERS
*   @msg		Error message if found
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @ACO bACO, @Approved bYN, @msg varchar(255) output)
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

if @Approved is null
begin
	select @msg = 'Missing Approved Flag.', @rcode = 1
	goto vspexit
end
else if @Approved not in ('Y','N')
begin
	set @Approved = 'Y'
end


--UPDATE ITEM DETAIL
update dbo.bPMOL 
set SendYN = @Approved
where PMCo = @PMCo and Project = @Project and ACO = @ACO and InterfacedDate is null

	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMACOReadyForAccountingUpdate] TO [public]
GO
