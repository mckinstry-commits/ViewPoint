SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspPMIssueVal] /** User Defined Validation Procedure **/
(@PMCo varchar(100), @Project varchar(100), @Issue varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**Used for validating PM Issues sub-forms.**/
if exists(select * from [PMIM] with (nolock) where   @PMCo = [PMCo] And  @Project = [Project] And  @Issue = [Issue] )
begin
select @msg = isnull([Description],@msg) from [PMIM] with (nolock) where   @PMCo = [PMCo] And  @Project = [Project] And  @Issue = [Issue] 
end
else
begin
select @msg = 'Not a valid issue for this job', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMIssueVal] TO [public]
GO
