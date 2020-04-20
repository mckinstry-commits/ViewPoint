SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCAllocationJobsRemove]
/****************************************************************************
 * Created By:	DANF 01/25/2007
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to Remove all Jobs from an Allocation code.
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
(@jcco bCompany = null, @alloccode tinyint = null, @exists bYN = null)
as
set nocount on

declare @rcode int

select @rcode = 0

delete JCAJ
where JCCo = @jcco and  AllocCode = @alloccode

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationJobsRemove] TO [public]
GO