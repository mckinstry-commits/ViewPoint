SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMChangeOrderRequestVal]
/***********************************************************
* CREATED BY:	GP	04/12/2011
* MODIFIED BY:	
*				
* USAGE:
* Used to validate PM Change Order Request.
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*	COR
*
* OUTPUT PARAMETERS
*   @msg		Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Contract bContract, @COR smallint, @msg varchar(255) output)
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

if @COR is null
begin
	select @msg = 'Missing COR.', @rcode = 1
	goto vspexit
end


--Get Description
select @msg = [Description] from dbo.PMChangeOrderRequest where PMCo = @PMCo and [Contract] = @Contract and COR = @COR
if @@rowcount = 0
begin
	select @msg = 'Invalid COR.', @rcode = 1
	goto vspexit
end
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestVal] TO [public]
GO
