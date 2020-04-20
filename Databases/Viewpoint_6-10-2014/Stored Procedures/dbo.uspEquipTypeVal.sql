SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspEquipTypeVal] /** User Defined Validation Procedure **/
(@Attribute varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udEquipAttTypes] with (nolock) where   @Attribute = [Type] )
begin
select @msg = isnull([Description],@msg) from [udEquipAttTypes] with (nolock) where   @Attribute = [Type] 
end
else
begin
select @msg = 'Not a valid Equip Attribute', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspEquipTypeVal] TO [public]
GO
