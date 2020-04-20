SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE  proc [dbo].[bspPMCOJCCICheck]
/***********************************************************
 * Created By:	GF 04/10/2007 6.x 
 * Modified By:
 *
 * USAGE:
 * Called from the PM ACOS and PCOS to check if contract items
 * exist in JCCI before initialize is run. Need to have at least one.
 *
 *
 * INPUT PARAMETERS
 * JCCO			- JC Company
 * Contract		- Contract
 *
 *
 *
 * OUTPUT PARAMETERS
 *   @msg - error message if no contract items exist in JCCI
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@jcco bCompany = 0, @contract bContract = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 1, @msg = 'No contract items set up for contract. Cannot initialize CO Items from contract.'

---- get count of contract items
if exists(select JCCo from JCCI with (nolock) where JCCo=@jcco and Contract=@contract)
	begin
	select @rcode = 0, @msg = ''
	end



bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMCOJCCICheck] TO [public]
GO
