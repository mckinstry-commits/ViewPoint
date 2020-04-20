SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspContractVal] /** User Defined Validation Procedure **/
(@JCCo varchar(100), @Contract varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [JCCM] with (nolock) where   @JCCo = [JCCo] And  @Contract = [Contract] )
begin
select @msg = isnull([Description],@msg) from [JCCM] with (nolock) where   @JCCo = [JCCo] And  @Contract = [Contract] 
end
else
begin
select @msg = 'Not a valid contract', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspContractVal] TO [public]
GO
