SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPunchListFromVal    Script Date: 06/21/2005 ******/
CREATE   proc [dbo].[vspPMPunchListFromVal]
/****************************************
 * Created By:	GF 06/21/2005
 * Modified By:
 *
 * validates from punch list for punch list copy form. Must be existing
 * and not be same as to punch list.
 *
 * Pass the from Punch List value
 *
 * Success returns:
 * 0 and Description from PMPU
 *
 * Error returns:
 * 1 and an error message
 *****************************************/
(@pmco bCompany, @project bProject, @punchlist bDocument, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @pmco is null
	begin
	select @msg = 'Missing PM Company', @rcode = 1
	goto bspexit
	end

if @project is null
	begin
	select @msg = 'Missing Project', @rcode = 1
	goto bspexit
	end

if @punchlist is null
	begin
  	select @msg = 'Missing from Punch List', @rcode = 1
  	goto bspexit
  	end


-- -- -- verify to punch list
select @msg = Description
from PMPU with (nolock) where PMCo=@pmco and Project=@project and PunchList=@punchlist
if @@rowcount = 0
	begin
	select @msg = 'Invalid from punch list.', @rcode = 1
	goto bspexit
	end





bspexit:
  	if @rcode <> 0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPunchListFromVal] TO [public]
GO
