SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspSINVal] /** User Defined Validation Procedure **/
(@SIN varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udSinNum] with (nolock) where   @SIN = [SINNum] )
begin
select @msg = isnull([Agency],@msg) from [udSinNum] with (nolock) where   @SIN = [SINNum] 
end
else
begin
select @msg = 'Not a valid SIN number', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspSINVal] TO [public]
GO
