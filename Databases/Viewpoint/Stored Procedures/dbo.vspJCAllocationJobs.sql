SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCAllocationJobs]
/****************************************************************************
 * Created By:	DANF 01/25/2007
 * Modified By:	Jacob Van Houten 04/03/2009
 *
 *
 *
 * USAGE:
 * Used to populate Allocation Job List
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
(@jcco bCompany = null, @alloccode tinyint = null, @exists bYN = null, @includeSoftClosed BIT = 1, @includeHardClosed BIT = 1)
as
set nocount on

declare @rcode int

select @rcode = 0

IF @exists = 'N'
	begin
	select JCJM.Job as 'Job', JCJM.Description as 'Description'
	--, case isnull(JCAJ.Job,'') when '' then 'N' else 'Y' end as 'Exists'
	from JCJM JCJM with (nolock) 
	left join JCAJ with (nolock)
	on JCJM.JCCo = JCAJ.JCCo and JCJM.Job = JCAJ.Job and JCAJ.AllocCode = @alloccode
	where JCJM.JCCo = @jcco and isnull(JCAJ.Job,'') <> ''
		AND (JobStatus <> 2 OR @includeSoftClosed = 1)
		AND (JobStatus <> 3 OR @includeHardClosed = 1)
	end
else
	begin
	select JCJM.Job as 'Job', JCJM.Description as 'Description'
	--, case isnull(JCAJ.Job,'') when '' then 'N' else 'Y' end as 'Exists'
	from JCJM JCJM with (nolock) 
	left join JCAJ with (nolock)
	on JCJM.JCCo = JCAJ.JCCo and JCJM.Job = JCAJ.Job and JCAJ.AllocCode = @alloccode
	where JCJM.JCCo = @jcco and isnull(JCAJ.Job,'') = ''
		AND (JobStatus <> 2 OR @includeSoftClosed = 1)
		AND (JobStatus <> 3 OR @includeHardClosed = 1)
	end

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationJobs] TO [public]
GO
