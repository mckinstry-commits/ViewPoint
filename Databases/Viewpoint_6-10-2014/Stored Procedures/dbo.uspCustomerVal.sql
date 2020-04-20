SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspCustomerVal] /** User Defined Validation Procedure **/
(@Company varchar(100), @Customer varchar(100), @msg varchar(255) output)
AS

declare @rcode INT, @CustGroup bGroup
select @rcode = 0, @CustGroup = CustGroup FROM HQCO WHERE HQCo = @Company


/**ERP Implementation - Added for JNRF requirements**/
if exists(select * from [ARCM] with (nolock) where   @CustGroup = [CustGroup] And  @Customer = [Customer] )
begin
select @msg = isnull([Name],@msg) from [ARCM] with (nolock) where   @CustGroup = [CustGroup] And  @Customer = [Customer] 
end
else
begin
select @msg = 'Customer is invalid', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspCustomerVal] TO [public]
GO
