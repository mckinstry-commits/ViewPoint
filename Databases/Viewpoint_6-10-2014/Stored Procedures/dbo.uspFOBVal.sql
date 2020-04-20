SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspFOBVal] /** User Defined Validation Procedure **/
(@FOB varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udFOB] with (nolock) where   @FOB = [Code] )
begin
select @msg = isnull([Description],@msg) from [udFOB] with (nolock) where   @FOB = [Code] 
end
else
begin
select @msg = 'Not a valid FOB.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspFOBVal] TO [public]
GO
