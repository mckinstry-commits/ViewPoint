SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspEmployeeVal] /** User Defined Validation Procedure **/
(@@PRCo varchar(100), @@Employee varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [PREHName] with (nolock) where   @@PRCo = [PRCo] And  @@Employee = [Employee] )
begin
select @msg = isnull([FullName],@msg) from [PREHName] with (nolock) where   @@PRCo = [PRCo] And  @@Employee = [Employee] 
end
else
begin
select @msg = 'Employee does not exist', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspEmployeeVal] TO [public]
GO
