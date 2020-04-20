SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE  proc [dbo].[bspPMOZDelete]
/***********************************************************
 * Created By:	GF 04/10/2007 6.x 
 * Modified By:
 *
 * USAGE:
 * Called from the PM change order item initialize to clear work table
 *
 *
 * INPUT PARAMETERS
 * PMCO			- PM Company
 * UserId		- User Id
 * Contract		- Contract
 *
 *
 *
 * OUTPUT PARAMETERS
 * @msg - error message if records still exist after delete
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @userid bVPUserName = null, @contract bContract = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

---- delete rows from PMOZ
delete from PMOZ where PMCo=@pmco and UserId=@userid and Contract=@contract

---- check if rows still exist
if exists(select PMCo from PMOZ where PMCo=@pmco and UserId=@userid and Contract=@contract)
	begin
	select @msg = 'Error occurred deleting contract items from work table.', @rcode = 1
	goto bspexit
	end




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMOZDelete] TO [public]
GO
