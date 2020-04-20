SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCProgressCostTypes]
/****************************************************************************
 * Created By:	DANF 04/04/2006
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to popoulate Progress Cost Type List
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
from HQCO with (nolock)
where HQCo = @jcco

select dbo.bfMuliPartFormat(CostType,'3R') as 'Cost Type', Description as 'Description'
from JCCT with (nolock) 
where PhaseGroup = @phasegroup

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProgressCostTypes] TO [public]
GO
