SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCAllocationCostTypes]
/****************************************************************************
 * Created By:	DANF 01/25/2007
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to populate Allocation Cost Type List
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

IF @exists = 'N'
	begin
	select dbo.bfMuliPartFormat(JCCT.CostType,'3R') as 'Cost Type', JCCT.Description as 'Description'
	--,	case isnull(JCAT.CostType,'') when '' then 'N' else 'Y' end as 'Exists'
	from JCCT JCCT with (nolock) 
	left join JCAT JCAT with (nolock)
	on JCCT.PhaseGroup = JCAT.PhaseGroup and JCCT.CostType = JCAT.CostType and JCAT.AllocCode = @alloccode and JCAT.JCCo = @jcco
	where JCCT.PhaseGroup = @phasegroup and isnull(JCAT.CostType,'') <> ''
	end
else
	begin
	select dbo.bfMuliPartFormat(JCCT.CostType,'3R') as 'Cost Type', JCCT.Description as 'Description'
	--,case isnull(JCAT.CostType,'') when '' then 'N' else 'Y' end as 'Exists'
	from JCCT JCCT with (nolock) 
	left join JCAT JCAT with (nolock)
	on JCCT.PhaseGroup = JCAT.PhaseGroup and JCCT.CostType = JCAT.CostType and JCAT.AllocCode = @alloccode and JCAT.JCCo = @jcco
	where JCCT.PhaseGroup = @phasegroup and isnull(JCAT.CostType,'')  = ''
	end

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationCostTypes] TO [public]
GO
