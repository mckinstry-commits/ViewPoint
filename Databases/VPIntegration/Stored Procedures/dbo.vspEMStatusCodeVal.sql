SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspEMStatusCodeVal]


/***********************************************************
* CREATED BY: JM 9/20/98
* MODIFIED By : JM 7/26/99 - added output of StatusType
*					TV 10/18/05 - moved to 6X
*
* USAGE:
* 	Validates EM Status Code vs EMWS and returns StatusType.
* 	Error returned if any of the following occurs
*
* 	No EMGroup passed
*	No StatusCode passed
*	StatusCode not found in EMWS
*
* INPUT PARAMETERS
*	EMGroup   	EMGroup to validate against
* 	StatusCode 	Status Code to validate
*
* OUTPUT PARAMETERS
*	@msg      	Error message if error occurs, otherwise
*			Description of StatusCode from EMWS
*
* RETURN VALUE
*	0		success
*	1		Failure
*****************************************************/

(@emgroup bGroup = null, @statuscode bCostCode = null,
@statustype char(1) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0

if @emgroup is null
	begin
	select @msg = 'Missing EM Group!', @rcode = 1
	goto bspexit

	end

if @statuscode is null
	begin
	select @msg = 'Missing Status Code!', @rcode = 1
	goto bspexit
	end

select @msg = Description, @statustype = StatusType
from bEMWS
where EMGroup = @emgroup and StatusCode = @statuscode

if @@rowcount = 0
	begin
	select @msg = 'Status Code not on file!', @rcode = 1
	goto bspexit
	end

bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMStatusCodeVal] TO [public]
GO
