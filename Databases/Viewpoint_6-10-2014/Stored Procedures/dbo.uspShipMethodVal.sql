SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspShipMethodVal] /** User Defined Validation Procedure **/
(@Code varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udShipMethod] with (nolock) where   @Code = [Code] )
begin
select @msg = isnull([Description],@msg) from [udShipMethod] with (nolock) where   @Code = [Code] 
end
else
begin
select @msg = 'Not a valid Shipping Method.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspShipMethodVal] TO [public]
GO
