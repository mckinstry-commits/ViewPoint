SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspCSIDivVal] /** User Defined Validation Procedure **/
(@CSIDiv varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udCSIPhaseSeg] with (nolock) where   @CSIDiv = [CSI] )
begin
select @msg = isnull([Description],@msg) from [udCSIPhaseSeg] with (nolock) where   @CSIDiv = [CSI] 
end
else
begin
select @msg = 'Not a valid CSI Division.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspCSIDivVal] TO [public]
GO
