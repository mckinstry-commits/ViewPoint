SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCProgressLinkCostTypes]
/****************************************************************************
* Created By:		DANF	04/04/2006
*
* USAGE:
* Used to populate Progress Link Cost Type List. Maintained in JC Progress Entry.
*
* INPUT PARAMETERS:
* JC Company, Phase Group, Month, Batch
*
* OUTPUT PARAMETERS:
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@jcco bCompany = null, @phasegroup bGroup = null, @mth bMonth = null, @batchid int = null)
as
set nocount on

declare @rcode int

select @rcode = 0


insert into bJCPPCostTypes
(Co, Mth, BatchId, PhaseGroup, CostType, LinkProgress)
select @jcco, @mth, @batchid, @phasegroup, CostType, LinkProgress
from bJCCT c with (nolock)
where PhaseGroup = @phasegroup and
not exists (select 1 from bJCPPCostTypes t with (nolock)
			where Co = @jcco and Mth = @mth and BatchId = @batchid and t.CostType = c.CostType)


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProgressLinkCostTypes] TO [public]
GO
