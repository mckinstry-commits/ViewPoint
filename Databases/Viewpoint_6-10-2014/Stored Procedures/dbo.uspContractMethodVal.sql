SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspContractMethodVal] /** User Defined Validation Procedure **/
(@Sequence varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udContractMethod] with (nolock) where   @Sequence = [Seq] )
begin
select @msg = isnull([Description],@msg) from [udContractMethod] with (nolock) where   @Sequence = [Seq] 
end
else
begin
select @msg = 'Method does not exist', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspContractMethodVal] TO [public]
GO
