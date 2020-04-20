SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCAllocationJobsAdd]
/****************************************************************************
 * Created By:	DANF 01/25/2007
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to add Job to Allocation Job List
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
(@jcco bCompany = null, @alloccode tinyint = null, @job bJob = null, @exists bYN = null)
as
set nocount on

declare @rcode int

select @rcode = 0

INSERT INTO JCAJ (JCCo, AllocCode, Job)
VALUES ( @jcco, @alloccode, @job);

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationJobsAdd] TO [public]
GO
