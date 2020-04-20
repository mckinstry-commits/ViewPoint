SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDDTSecurableVal]
/***************************************
* Created: 11/21/06 JRK
* Modified: 02/11/07 JonathanP - Removed "and Secure = 'Y'" from the WHERE clause below. This was
*								   causing the user to be unable to select unsecurred datatypes.
* Modified: 02/15/07 JonathanP - Added "@secure" parameter.
* Modified: 02/16/07 JonathanP - Removed "@secure" parameter.
*
* Similar to vspDDDTVal but using the view that limits datatypes to the securable ones.
*
**************************************/
(@datatype char(30) = null, @lookup varchar(30) = null output,
 @setupform varchar(30) = null output, @msg varchar(60) = null output)

as
set nocount on

declare @rcode int
select @rcode = 0

if @datatype is null
	begin
	select @msg = 'Missing Datatype!', @rcode = 1
	goto vspexit
	end

select @msg = Description, @lookup = Lookup, @setupform = SetupForm
from dbo.DDDTSecurable (nolock)
where Datatype = @datatype
if @@rowcount = 0
	begin
	select @msg = 'Datatype is not securable or does not exist', @rcode = 1
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDTSecurableVal] TO [public]
GO
