SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspProcVehicle] /** User Defined Validation Procedure **/
(@ProcVeh varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udProcVeh] with (nolock) where   @ProcVeh = [Seq] )
begin
select @msg = isnull([Description],@msg) from [udProcVeh] with (nolock) where   @ProcVeh = [Seq] 
end
else
begin
select @msg = 'Not a valid Procurement Veh.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspProcVehicle] TO [public]
GO
