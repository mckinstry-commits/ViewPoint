SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspJCCIRevTypeVal] /** User Defined Validation Procedure **/
(@RevType varchar(100), @Amt bDollar, @Markup bRate, @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if @RevType = 'N' And  @Amt <> 0
begin
select @msg = 'Revenue Type cannot be "Non Revenue" unless the Contract Item Amount is zero.', @rcode = 1
goto spexit
end


if @RevType = 'M' And  @Markup = 0
BEGIN
  select @msg = 'Revenue Type cannot be "Cost+Markup" unless the Contract Item markup is not equal to zero.', @rcode = 1
END
else
begin
goto spexit
end


spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspJCCIRevTypeVal] TO [public]
GO
