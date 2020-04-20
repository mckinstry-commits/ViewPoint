SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspPMDailyLogDateVal] /** User Defined Validation Procedure **/
(@PMCo varchar(100), @Project varchar(100), @LogDate varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**Validate PM Daily Log Date for sub-forms.**/
if exists(select * from [PMDL] with (nolock) where   @PMCo = [PMCo] And  @Project = [Project] And  @LogDate = [LogDate] )
begin
select @msg = isnull(null,@msg) from [PMDL] with (nolock) where   @PMCo = [PMCo] And  @Project = [Project] And  @LogDate = [LogDate] 
end
else
begin
select @msg = 'Not a valid daily log date.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMDailyLogDateVal] TO [public]
GO
