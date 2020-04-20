SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspWorkTypeVal] /** User Defined Validation Procedure **/
(@WorkType varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udWorkypes] with (nolock) where   @WorkType = [WorkType] )
begin
select @msg = isnull(null,@msg) from [udWorkypes] with (nolock) where   @WorkType = [WorkType] 
end
else
begin
select @msg = 'Not a valid work type.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspWorkTypeVal] TO [public]
GO
