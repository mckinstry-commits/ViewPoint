SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspPMDLogVal] /** User Defined Validation Procedure **/
(@PMCo varchar(100), @Project varchar(100), @LogDate varchar(100), @DailyLog varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**PM Daily Log Validation for Daily Log sub-forms.**/
if exists(select * from [PMDL] with (nolock) where   @PMCo = [PMCo] And  @Project = [Project] And  @LogDate = [LogDate] And  @DailyLog = [DailyLog] )
begin
select @msg = isnull([Description],@msg) from [PMDL] with (nolock) where   @PMCo = [PMCo] And  @Project = [Project] And  @LogDate = [LogDate] And  @DailyLog = [DailyLog] 
end
else
begin
select @msg = 'Not a valid Daily Log', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMDLogVal] TO [public]
GO
