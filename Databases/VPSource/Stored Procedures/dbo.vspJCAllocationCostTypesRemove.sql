SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCAllocationCostTypesRemove]
/****************************************************************************
 * Created By:	DANF 01/25/2007
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to Remove all Cost Types for a given Allocation code.
 *
 * INPUT PARAMETERS:
 * JC Company
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@jcco bCompany = null,  @alloccode tinyint = null, @exists bYN = null)
as
set nocount on

declare @rcode int,@phasegroup bGroup

select @rcode = 0

select @phasegroup = PhaseGroup
from HQCO with (nolock)
where HQCo = @jcco

delete JCAT 
where JCCo = @jcco and  AllocCode = @alloccode and  PhaseGroup = @phasegroup;

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationCostTypesRemove] TO [public]
GO
