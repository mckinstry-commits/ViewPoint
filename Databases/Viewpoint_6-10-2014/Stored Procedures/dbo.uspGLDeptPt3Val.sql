SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspGLDeptPt3Val] /** User Defined Validation Procedure **/
(@GLCo varchar(100), @Instance varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [GLPI] with (nolock) where   @GLCo = [GLCo] And  @Instance = [Instance] )
begin
select @msg = isnull([Description],@msg) from [GLPI] with (nolock) where   @GLCo = [GLCo] And  @Instance = [Instance] 
end
else
begin
select @msg = 'Not a valid part 3 Code.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspGLDeptPt3Val] TO [public]
GO
