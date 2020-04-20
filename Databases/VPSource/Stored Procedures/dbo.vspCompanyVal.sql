SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspCompanyVal] 
/************************************************************************
* Created: GG 07/18/07
* Modified: 
*
* Usage:
* Checks for the existence of a specific Co# within a Module.  
*
* Inputs:
*	@co				Company # to validate
*	@mod			Module
*
* Outputs:
*	@msg			Error message
*
* Return code:
*	0 = success, 1 = error w/messsge
*
**************************************************************************/
(@co bCompany = null, @mod char(2) = null,  @msg varchar(512) output)

as

set nocount on 

declare @rcode integer, @tsql nvarchar(4000)

select @rcode = 0

if @mod is null
	begin
	select @msg = 'Missing Module!',@rcode = 1
	goto vspexit
	end
if not exists(select top 1 1 from DDMO where Mod = @mod)
	begin
	select @msg = 'Invalid Module!', @rcode = 1
	goto vspexit
	end
if @mod not in ('AP','AR','CM','EM','GL','HQ','HR','IN','JB','JC','MS','PM','PO','PR','RQ','SL')
	begin
	select @msg = 'Cannot validate Co# within the ' + @mod + ' module!', @rcode = 1
	goto vspexit
	end

select @tsql = 'select top 1 1 from dbo.' + @mod + 'CO (nolock) where ' + @mod + 'Co = ' + convert(varchar,@co)

execute(@tsql)
if @@rowcount = 0
	begin
	select @msg = 'Company# ' + convert(varchar,@co) + ' not setup in ' + @mod, @rcode = 1
	goto vspexit
	end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCompanyVal] TO [public]
GO
