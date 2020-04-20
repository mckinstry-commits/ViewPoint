SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspPMCoVal] /** User Defined Validation Procedure **/
(@HQCo varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [HQCO] with (nolock) 
INNER JOIN PMCO ON HQCo = PMCo
where   @HQCo = [HQCo] )
begin
select @msg = isnull([Name],@msg) from [HQCO] with (nolock) where   @HQCo = [HQCo] 
end
else
begin
select @msg = 'Not a valid PM Company', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMCoVal] TO [public]
GO
