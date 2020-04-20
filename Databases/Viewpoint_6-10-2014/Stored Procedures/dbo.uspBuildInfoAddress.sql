SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspBuildInfoAddress] /** User Defined Validation Procedure **/
(@Company varchar(100), @Project varchar(100), @Building varchar(100), @SameAddAs varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0, @msg = ''


/****/
if exists(SELECT 1 FROM udBuildingInfo WHERE @Company = Co AND @Project = Project AND @SameAddAs = BuildingNum AND SameAddAs IS NULL AND @SameAddAs <> @Building )
begin
select @msg = isnull([Add1],@msg) from [udBuildingInfo] with (nolock) where  @Company = Co AND @Project = Project AND @SameAddAs = BuildingNum
end
else
begin
select @msg = 'Not a valid Building', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspBuildInfoAddress] TO [public]
GO
