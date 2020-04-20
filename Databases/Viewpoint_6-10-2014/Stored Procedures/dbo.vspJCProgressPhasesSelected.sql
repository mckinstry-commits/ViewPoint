SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCProgressPhasesSelected]
/****************************************************************************
 * Created By:	DANF 04/24/2006
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to popoulate Progress Selected Phase List
 *
 * INPUT PARAMETERS:
 * JC Company, month, batch id, job
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@jcco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @job bJob = null, @phasegroup bGroup = null)
as
set nocount on

declare @rcode int

select @rcode = 0

select Phase as 'Phase'
from dbo.bJCPPPhases with(nolock)
where Co = @jcco and [Month] = @mth and BatchId = @batchid and Job = @job and PhaseGroup = @phasegroup

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProgressPhasesSelected] TO [public]
GO
