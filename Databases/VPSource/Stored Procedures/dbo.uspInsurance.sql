SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspInsurance] /** User Defined Validation Procedure **/
(@Seq varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udInsurance] with (nolock) where   @Seq = [Seq] )
begin
select @msg = isnull([CoverageLev],@msg) from [udInsurance] with (nolock) where   @Seq = [Seq] 
end
else
begin
select @msg = 'Not a valid Insurance Code', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspInsurance] TO [public]
GO
