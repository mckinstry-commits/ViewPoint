SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspProjectManVal] /** User Defined Validation Procedure **/
(@@JCCo varchar(100), @@PM varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [JCMP] with (nolock) where   @@JCCo = [JCCo] And  @@PM = [ProjectMgr] )
begin
select @msg = isnull([Name],@msg) from [JCMP] with (nolock) where   @@JCCo = [JCCo] And  @@PM = [ProjectMgr] 
end
else
begin
select @msg = 'Not a valid Project Manager', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspProjectManVal] TO [public]
GO
