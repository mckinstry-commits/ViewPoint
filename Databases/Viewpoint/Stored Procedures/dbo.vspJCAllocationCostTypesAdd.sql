SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCAllocationCostTypesAdd]
/****************************************************************************
 * Created By:	DANF 01/25/2007
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to Add Cost Types to the Allocation Cost Type List
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
(@jcco bCompany = null,  @alloccode tinyint = null, @costtype bJCCType = null, @exists bYN = null)
as
set nocount on

declare @rcode int,@phasegroup bGroup

select @rcode = 0

select @phasegroup = PhaseGroup
from HQCO with (nolock)
where HQCo = @jcco

INSERT INTO JCAT (JCCo, AllocCode, PhaseGroup, CostType)
VALUES ( @jcco, @alloccode, @phasegroup, @costtype);

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationCostTypesAdd] TO [public]
GO
