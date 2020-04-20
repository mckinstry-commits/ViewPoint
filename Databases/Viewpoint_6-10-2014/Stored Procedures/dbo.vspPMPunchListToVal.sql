SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPunchListToVal    Script Date: 06/21/2005 ******/
CREATE proc [dbo].[vspPMPunchListToVal]
/****************************************
 * Created By:	GF 06/21/2005
 * Modified By:
 *
 * validates to punch list for punch list copy form. Must be new or not
 * have any punch list items assigned.
 *
 * Pass the to Punch List value
 *
 * Success returns:
 * 0 and Description from PMPU or 'New Punch List'
 *
 * Error returns:
 * 1 and an error message
 *****************************************/
(@pmco bCompany, @project bProject, @punchlist bDocument, @frompunchlist bDocument, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = 'New Punch List'

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
  	select @msg = 'Missing Punch List', @rcode = 1
  	goto bspexit
  	end

if @frompunchlist is null
	begin
  	select @msg = 'Missing To Punch List', @rcode = 1
  	goto bspexit
  	end

if @punchlist = @frompunchlist
	begin
	select @msg = 'From punch list must not be the same as to punch list.', @rcode = 1
	goto bspexit
	end

-- -- -- verify to punch list
select @msg = Description
from PMPU with (nolock) where PMCo=@pmco and Project=@project and PunchList=@punchlist
if @@rowcount = 0 goto bspexit


-- -- -- when to punch list exists check for existance of items
if exists(select 1 from PMPI with (nolock) where PMCo=@pmco and Project=@project and PunchList=@punchlist)
	begin
	select @msg = 'To punch list must not have any existing items.', @rcode = 1
	goto bspexit
	end




bspexit:
  	if @rcode <> 0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPunchListToVal] TO [public]
GO
