SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspJCPMVal] /** User Defined Validation Procedure **/
(@PhaseGroup varchar(100), @Phase varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [JCPM] with (nolock) where   @PhaseGroup = [PhaseGroup] And  @Phase = [Phase] )
begin
select @msg = isnull([Description],@msg) from [JCPM] with (nolock) where   @PhaseGroup = [PhaseGroup] And  @Phase = [Phase] 
end
else
begin
select @msg = 'Not a valid phase from JCPM', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspJCPMVal] TO [public]
GO
