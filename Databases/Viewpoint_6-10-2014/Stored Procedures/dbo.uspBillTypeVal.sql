SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspBillTypeVal] /** User Defined Validation Procedure **/
(@BillType varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select TOP 1 1 from [udBillTypes] with (nolock) where   @BillType = [BillType] )
begin
select @msg = isnull([Description],@msg) from [udBillTypes] with (nolock) where   @BillType = [BillType] 
end
else
begin
select @msg = 'Not a valid Bill Type.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspBillTypeVal] TO [public]
GO
