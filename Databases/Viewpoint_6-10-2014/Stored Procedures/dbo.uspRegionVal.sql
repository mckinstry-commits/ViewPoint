SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspRegionVal] /** User Defined Validation Procedure **/
(@Region varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udRegion] with (nolock) where   @Region = [Region] )
begin
select @msg = isnull([Name],@msg) from [udRegion] with (nolock) where   @Region = [Region] 
end
else
begin
select @msg = 'Not a valid Region', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspRegionVal] TO [public]
GO
