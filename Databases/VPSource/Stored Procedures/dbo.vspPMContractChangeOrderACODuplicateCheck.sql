SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMContractChangeOrderACODuplicateCheck]
/***********************************************************
* CREATED BY:	GP	04/19/2011
* CODE REVIEW:	DS	04/19/2011
* MODIFIED BY:	
*				
* USAGE:
* Used in PM Contract Change Order to check for duplicate ACOs.
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*	ID
*	Project
*	ACO
*
* OUTPUT PARAMETERS
*   @msg		Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Contract bContract, @ID smallint, @Project bProject, @ACO bACO, @msg varchar(255) output)
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

if @Contract is null
begin
	select @msg = 'Missing Contract.', @rcode = 1
	goto vspexit
end

if @ID is null
begin
	select @msg = 'Missing ID.', @rcode = 1
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


--Check for duplicate
if exists (select top 1 1 from dbo.PMContractChangeOrderACO where PMCo = @PMCo and [Contract] = @Contract
	and ID = @ID and Project = @Project and ACO = @ACO)
begin
	select @msg = 'Records already exist for this Project and ACO.', @rcode = 1
	goto vspexit
end
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderACODuplicateCheck] TO [public]
GO
