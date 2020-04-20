SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDMOVal]
/***********************************************************
* CREATED: TRL   08/03/2005 
* MODIFIED: 
*				  
* USAGE:
*	Validates Module, excludes DD and VP
*
* INPUT PARAMETERS
*   Module       Module to validate
*
* INPUT PARAMETERS
*   @msg        error message if something went wrong, otherwise description
*
* RETURN VALUE
*   0 Success
*   1 fail
************************************************************************/
  	(@Module varchar(2) = null, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0

if @Module is null
	begin
	select @msg = 'Missing Module!', @rcode = 1
	goto vspexit
	end

select @msg = Title
from dbo.vDDMO (nolock)
where Mod = @Module and Mod not in ('DD','VP','QA')	-- exclude DD and VP
if @@rowcount = 0
	begin
	select @msg = 'Module not on file!', @rcode = 1
	end
  
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDMOVal] TO [public]
GO
