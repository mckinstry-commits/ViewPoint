SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspMastSubVal] /** User Defined Validation Procedure **/
(@VendorGroup varchar(100), @Vendor varchar(100), @Seq int, @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**Added to support custom Master Subcontracts UD.**/
if exists(select * from [udMSA] with (nolock) where   @VendorGroup = [VendorGroup] And  @Vendor = [Vendor] And  @Seq = [Seq] )
begin
select @msg = isnull([Title],@msg) from [udMSA] with (nolock) where   @VendorGroup = [VendorGroup] And  @Vendor = [Vendor] And  @Seq = [Seq] 
end
else
begin
select @msg = 'Not a valid Master Subcontract', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspMastSubVal] TO [public]
GO
