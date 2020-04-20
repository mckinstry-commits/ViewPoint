SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspOperatorVal] /** User Defined Validation Procedure **/
(@Company varchar(100), @Employee varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [PREHName] with (nolock) where   @Company = [PRCo] And  @Employee = [Employee] And [ActiveYN] = 'Y' )
begin
select @msg = isnull([FullName],@msg) from [PREHName] with (nolock) where   @Company = [PRCo] And  @Employee = [Employee] And [ActiveYN] = 'Y' 
end
else
begin
select @msg = 'Not a valid Employee', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspOperatorVal] TO [public]
GO
