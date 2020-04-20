SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfJCParentOfLinkedCT]
(@phasegroup bGroup = null, @costtype bJCCType = null)
returns char(1)
/***********************************************************
* CREATED BY	: DANF
* MODIFIED BY	
*
* USAGE:
* 	Returns Flag to indicate if the cost type is linked from other cost types.
*
* INPUT PARAMETERS:
*	Phase Group, Cost Type.
*
* OUTPUT PARAMETERS:
*	Flag to return if this cost type is a parent on other linked cost types.
*	
*
*****************************************************/
as
begin

declare @parentlinkedct bYN

set @parentlinkedct = 'N'

   -- -- -- Parent Linked Cost Type.
  if exists(select top 1 1 from bJCCT where PhaseGroup = @phasegroup and LinkProgress = @costtype)
         begin
         set @parentlinkedct = 'Y'
         end

exitfunction:
  			
return @parentlinkedct
end

GO
GRANT EXECUTE ON  [dbo].[vfJCParentOfLinkedCT] TO [public]
GO
