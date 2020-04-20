SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspAuthCode] /** User Defined Validation Procedure **/
(@Code varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udAuthType] with (nolock) where   @Code = [Code] )
begin
select @msg = isnull([Description],@msg) from [udAuthType] with (nolock) where   @Code = [Code] 
end
else
begin
select @msg = 'Not a valid Authorization Type', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspAuthCode] TO [public]
GO
