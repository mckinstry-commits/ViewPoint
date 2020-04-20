SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspVendorVal] /** User Defined Validation Procedure **/
(@VGroup varchar(100), @Vendor varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [APVM] with (nolock) where   @VGroup = [VendorGroup] And  @Vendor = [Vendor] AND (udEmployeeYN <> 'Y' OR udEmployeeYN IS NULL))
begin
select @msg = isnull([Name],@msg) from [APVM] with (nolock) where   @VGroup = [VendorGroup] And  @Vendor = [Vendor] 
end
else
begin
select @msg = 'Not a valid Vendor', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspVendorVal] TO [public]
GO
