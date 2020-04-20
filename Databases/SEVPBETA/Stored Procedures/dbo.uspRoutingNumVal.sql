SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspRoutingNumVal] /** User Defined Validation Procedure **/
(@RouteNum varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**ERP Implementation - Added to fulfill Action Item 702.  Validation for Routing Number lookup field.**/
if exists(select * from [udRoutingNum] with (nolock) where   @RouteNum = [RTENum] )
begin
select @msg = isnull([Description],@msg) from [udRoutingNum] with (nolock) where   @RouteNum = [RTENum] 
end
else
begin
select @msg = 'Invalid Routing Number', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspRoutingNumVal] TO [public]
GO
