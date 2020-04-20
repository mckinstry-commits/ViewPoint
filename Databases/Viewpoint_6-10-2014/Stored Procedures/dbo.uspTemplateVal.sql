SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspTemplateVal] /** User Defined Validation Procedure **/
(@Company varchar(100), @Template varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [PMTH] with (nolock) where   @Company = [PMCo] And  @Template = [Template] )
begin
select @msg = isnull([Description],@msg) from [PMTH] with (nolock) where   @Company = [PMCo] And  @Template = [Template] 
end
else
begin
select @msg = 'Not a valid template', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspTemplateVal] TO [public]
GO
