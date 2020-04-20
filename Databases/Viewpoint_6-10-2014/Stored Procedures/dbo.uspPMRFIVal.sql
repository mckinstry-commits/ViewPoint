SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspPMRFIVal] /** User Defined Validation Procedure **/
(@PMCo varchar(100), @Project varchar(100), @RFIType varchar(100), @RFI varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [PMRI] with (nolock) where   @PMCo = [PMCo] And  @Project = [Project] And  @RFIType = [RFIType] And  @RFI = [RFI] )
begin
select @msg = isnull([Subject],@msg) from [PMRI] with (nolock) where   @PMCo = [PMCo] And  @Project = [Project] And  @RFIType = [RFIType] And  @RFI = [RFI] 
end
else
begin
select @msg = 'Not a valid RFI.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMRFIVal] TO [public]
GO
