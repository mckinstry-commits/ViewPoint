SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCPurgeCostTypes]
/****************************************************************************
 * Created By:	DANF 09/20/2006
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to popoulate Purge Cost Type List
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
(@jcco bCompany = null)
as
set nocount on

declare @rcode int,@phasegroup bGroup

select @rcode = 0

select @phasegroup = PhaseGroup
from HQCO
where HQCo = @jcco

select dbo.bfMuliPartFormat(CostType,'3R') as 'Cost Type', 
		Description as 'Description'
from JCCT with (nolock) 
where PhaseGroup = @phasegroup and  TrackHours = 'Y'

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPurgeCostTypes] TO [public]
GO
