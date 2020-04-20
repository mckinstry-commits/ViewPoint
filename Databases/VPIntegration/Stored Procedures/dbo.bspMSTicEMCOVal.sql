SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************/
CREATE   proc [dbo].[bspMSTicEMCOVal]
/*************************************
 * Created By:  GF 04/04/2001
 * Modified BY:
 *
 * USAGE:
 *	Validates EMCO.CO for MSTicEntry
 *
 * INPUT PARAMETERS
 *	@emco		EM Company
 *
 * OUTPUT PARAMETERS
 *  @glco           Default PR Company
 *  @emgroup        Default Equipment operator/employee
 *  @userateoride   Use rate override flag
 *	@msg 		    Equipment description or error message
 *
 * RETURN VALUE
 *	0 success
 *	1 error
 **************************************/
(@emco bCompany, @emgroup bGroup output, @userateoride bYN output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @emco = 0
	begin
	select @msg = 'Missing EM Company#', @rcode = 1
	goto bspexit
	end

select @emgroup=HQCO.EMGroup, @userateoride=EMCO.UseRateOride, @msg=HQCO.Name
from EMCO with (nolock) join HQCO with (nolock) on HQCO.HQCo=EMCO.EMCo where EMCO.EMCo=@emco
if @@rowcount = 0
	begin
	select @msg = 'Invalid EM Company', @rcode = 1
	goto bspexit
	end



bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicEMCOVal] TO [public]
GO
