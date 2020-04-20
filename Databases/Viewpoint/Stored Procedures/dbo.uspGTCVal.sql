SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspGTCVal] /** User Defined Validation Procedure **/
(@GTC varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**Added to support Job Request form process.**/
if exists(select * from [udGenTerms] with (nolock) where   @GTC = [Code] )
begin
select @msg = isnull([Description],@msg) from [udGenTerms] with (nolock) where   @GTC = [Code] 
end
else
begin
select @msg = 'Not a valid selection', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspGTCVal] TO [public]
GO
