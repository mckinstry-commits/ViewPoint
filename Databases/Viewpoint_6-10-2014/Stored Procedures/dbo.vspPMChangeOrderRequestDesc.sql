SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMChangeOrderRequestDesc]
/***********************************************************
* CREATED BY:	GP	03/14/2011
* MODIFIED BY:	DAN SO 03/24/2011 - TK-03226 - Return CORState
*				
* USAGE:
* Used in PM Change Order Request to return the desc for existing COR's.
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*
* OUTPUT PARAMETERS
*	@CORState	(N)ew (E)xists
*   @msg		Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Contract bContract, @COR smallint, 
 @CORState char(1) output, @msg varchar(255) output)
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
	
-- TK-03226 -- (N)ew (E)xists
if @@rowcount = 0 set @CORState = 'N' else set @CORState = 'E'
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestDesc] TO [public]
GO
