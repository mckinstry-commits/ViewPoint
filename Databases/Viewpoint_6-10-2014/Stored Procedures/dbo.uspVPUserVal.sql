SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspVPUserVal] /** User Defined Validation Procedure **/
(@VPUserName varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**Used for other User Name validation.**/
if exists(select * from [DDUP] with (nolock) where   @VPUserName = [VPUserName] )
begin
select @msg = isnull([FullName],@msg) from [DDUP] with (nolock) where   @VPUserName = [VPUserName] 
end
else
begin
select @msg = 'Not a valid user name', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspVPUserVal] TO [public]
GO
