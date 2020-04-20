SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspEMEquipVal] /** User Defined Validation Procedure **/
(@EMGroup varchar(100), @Equip varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**Created validation for UD Equipment Attributes tab.**/
if exists(select * from [EMEM] with (nolock) where   @EMGroup = [EMGroup] And  @Equip = [Equipment] )
begin
select @msg = isnull([Description],@msg) from [EMEM] with (nolock) where   @EMGroup = [EMGroup] And  @Equip = [Equipment] 
end
else
begin
select @msg = 'Not a valid Equipment Record', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspEMEquipVal] TO [public]
GO
