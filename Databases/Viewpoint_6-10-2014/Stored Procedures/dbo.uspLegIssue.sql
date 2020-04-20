SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspLegIssue] /** User Defined Validation Procedure **/
(@Issue varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udLegalGuide] with (nolock) where   @Issue = [Issue] )
begin
select @msg = isnull([Guideline],@msg) from [udLegalGuide] with (nolock) where   @Issue = [Issue] 
end
else
begin
select @msg = 'Not a valid legal issue.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspLegIssue] TO [public]
GO
