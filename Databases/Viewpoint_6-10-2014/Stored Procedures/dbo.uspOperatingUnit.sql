SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspOperatingUnit] /** User Defined Validation Procedure **/
(@Co varchar(100), @OperatingUnit varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udOperatingUnit] with (nolock) where   @Co = [Co] And  @OperatingUnit = [OperatingUnit] )
begin
select @msg = isnull([UnitName],@msg) from [udOperatingUnit] with (nolock) where   @Co = [Co] And  @OperatingUnit = [OperatingUnit] 
end
else
begin
select @msg = 'Not a valid operating unit', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspOperatingUnit] TO [public]
GO
