SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspHQCOVal] /** User Defined Validation Procedure **/
(@HQCo varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [HQCO] with (nolock) where   @HQCo = [HQCo] )
begin
select @msg = isnull([Name],@msg) from [HQCO] with (nolock) where   @HQCo = [HQCo] 
end
else
begin
select @msg = 'Not a valid company', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspHQCOVal] TO [public]
GO
