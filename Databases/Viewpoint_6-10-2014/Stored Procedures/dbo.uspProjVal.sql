SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspProjVal] /** User Defined Validation Procedure **/
(@JCCo varchar(100), @Job varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [JCJM] with (nolock) where   @JCCo = [JCCo] And  @Job = [Job] )
begin
select @msg = isnull([Description],@msg) from [JCJM] with (nolock) where   @JCCo = [JCCo] And  @Job = [Job] 
end
else
begin
select @msg = 'Not a valid Project/Job.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspProjVal] TO [public]
GO
