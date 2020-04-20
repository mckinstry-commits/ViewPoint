SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspBOClassVal] /** User Defined Validation Procedure **/
(@BOClass varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udBandOClass] with (nolock) where   @BOClass = [BOClassCode] )
begin
select @msg = isnull([Description],@msg) from [udBandOClass] with (nolock) where   @BOClass = [BOClassCode] 
end
else
begin
select @msg = 'Not a valid B&O Classification', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspBOClassVal] TO [public]
GO
