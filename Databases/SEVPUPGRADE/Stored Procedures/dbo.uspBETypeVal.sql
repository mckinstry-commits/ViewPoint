SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspBETypeVal] /** User Defined Validation Procedure **/
(@BET varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**ERP Implementation - Added for JNRF requirements**/
if exists(select * from [udBuildEnvmnt] with (nolock) where   @BET = [BETId] )
begin
select @msg = isnull([Description],@msg) from [udBuildEnvmnt] with (nolock) where   @BET = [BETId] 
end
else
begin
select @msg = 'Not a valid Building Environme', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspBETypeVal] TO [public]
GO
