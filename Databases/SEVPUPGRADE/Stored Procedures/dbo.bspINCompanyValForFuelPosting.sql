SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspINCompanyValForFuelPosting]
/***********************************************************
* CREATED BY: JM 12/12/01
* MODIFIED By : JM 4/16/02 - Removed return of GLOffsetAcct
*		04/27/07 - Issue #27990, 6x Rewrite EMFuelPosting.  Add more outputs from INCO.  Added output to all using this procedure
*
* USAGE:
*   validates IN Company number and returns INCo's MatlGroup
*
* INPUT PARAMETERS
*   INCo   IN Co to Validate
*
* OUTPUT PARAMETERS
*   @msg If Error, error message, otherwise description of Company
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@INCo bCompany = null, @INCoMatlGroup bGroup output, @INCoOverrideGL bYN output,
	@INCoGLCo bCompany output, @negwarnyn bYN output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @INCo is null
	begin
	select @msg = 'Missing IN Company!', @rcode = 1
	goto bspexit
	end

select @INCoOverrideGL = OverrideGL, @INCoGLCo = GLCo, @negwarnyn = NegWarn
from INCO with (nolock) 
where INCo = @INCo
if @@rowcount=0
	begin
	select @msg = 'Not a valid IN Company', @rcode = 1
	goto bspexit
	end

select @msg = Name, @INCoMatlGroup = MatlGroup from bHQCO where HQCo = @INCo

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCompanyValForFuelPosting] TO [public]
GO
