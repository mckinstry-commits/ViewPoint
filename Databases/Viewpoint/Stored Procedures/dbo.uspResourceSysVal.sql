SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspResourceSysVal] /** User Defined Validation Procedure **/
(@Resource varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**ERP Implementation - Added for JNRF requirements.**/
if exists(select * from [udResourceSys] with (nolock) where   @Resource = [Description] )
begin
select @msg = isnull(null,@msg) from [udResourceSys] with (nolock) where   @Resource = [Description] 
end
else
begin
select @msg = 'Resource System is invalid', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspResourceSysVal] TO [public]
GO
