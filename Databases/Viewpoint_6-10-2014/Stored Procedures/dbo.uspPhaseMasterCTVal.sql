SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspPhaseMasterCTVal] /** User Defined Validation Procedure **/
(@PhaseGroup varchar(100), @Phase varchar(100), @CostType varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**Phase Master Cost Type Validation.  Prevent selection of Cost Types that are not associated with the Phase Master.**/
if exists(select * from [JCPC] with (nolock) where   @PhaseGroup = [PhaseGroup] And  LEFT(@Phase,10) = LEFT([Phase],10) And  @CostType = [CostType] )
begin
select @msg = isnull(JCCT.Abbreviation,@msg) from [JCPC] with (nolock) 
     JOIN JCCT ON JCCT.PhaseGroup = JCPC.PhaseGroup AND JCCT.CostType = JCPC.CostType
where   @PhaseGroup = [JCPC].[PhaseGroup] And  LEFT(@Phase,10) = LEFT([JCPC].[Phase],10) And  @CostType = [JCPC].[CostType] 
end
else
begin
select @msg = 'Not valid CT for this phase', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPhaseMasterCTVal] TO [public]
GO
