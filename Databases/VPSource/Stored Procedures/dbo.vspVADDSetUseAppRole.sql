SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  procedure [dbo].[vspVADDSetUseAppRole]
/***********************************************************
* CREATED BY: MJ 04/12/05
* MODIFIED By : AL 3/10/07 added check for redundancy
*					
* USAGE:
* sets the flag to use or not use app role security
*
* NOTE:
* As of VP6.0 we will have the Viewpoint application role created but it will not be used unless
* the UseAppRole field is set to "Y".
*
* INPUT PARAMETERS
*	@useapprole  a YN value used to determine is security will be implemented or not.
*					
*   
* OUTPUT PARAMETERS
*   @msg        error message if something went wrong, otherwise description
*
* RETURN VALUE
*   0 success
*   1 fail
************************************************************************/

-- TODO:  Pass in the password to use.?????

(@useapprole bYN, @msg varchar(60) output)

as
set nocount on
declare @gate varchar(60), @rcode int, @currapprole bYN

select @rcode = 0

-- get current App Role setting
select @currapprole = UseAppRole
from dbo.vDDVS (nolock)
if @@rowcount = 0
	begin
	select @msg = 'Unable to obtain current Application Role security setting.', @rcode = 1
	goto bspexit
	end
if @currapprole = @useapprole
	begin
	select @msg = 'Application Role security is already configured.', @rcode = 1
	goto bspexit
	end

-- update Application Role setting
update dbo.vDDVS
set UseAppRole = @useapprole  
if @@rowcount = 0 
	begin
  	select @msg = 'Application Role Security was not updated!', @rcode = 1
  	end

bspexit:
  	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspVADDSetUseAppRole] TO [public]
GO
