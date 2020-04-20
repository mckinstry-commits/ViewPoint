SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDDTSecureVal]
/***************************************
* Created: GG 06/13/07
* Modified: 
*
* Validates datatype for VA Data Security, must be secured.
*
* Inputs:
*	@datatype		Datatype 
*
* Outputs:
*	@msg			Error message
*
* Return code:
*	0 = success, 1 = error	
*
**************************************/
	(@datatype varchar(30) = null, @msg varchar(60) = null output)

as
set nocount on

declare @rcode int, @secure bYN
select @rcode = 0

if @datatype is null
	begin
	select @msg = 'Missing Datatype!', @rcode = 1
	goto vspexit
	end

select @msg = Description, @secure = Secure
from DDDTShared (nolock)
where Datatype = @datatype 
if @@rowcount = 0
	begin
	select @msg = 'Invalid Datatype', @rcode = 1
	goto vspexit
	end
if @secure <> 'Y' 
	begin
	select @msg = 'Datatype must first be set as secure.', @rcode = 1
	goto vspexit
	end  

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDTSecureVal] TO [public]
GO
