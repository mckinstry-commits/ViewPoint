SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCFirstJob    Script Date: 05/03/2005 ******/
CREATE  proc [dbo].[vspJCFirstJob]
/*************************************
 * Created By:	DANF 08/16/06
 * Modified By:
 *
 *
 * USAGE:
 * Called from JC to return the first job
 *
 *
 * INPUT PARAMETERS
 * @jcco			JC Company
 * @job				JC Job
 *
 * Success returns:
 *	The first job
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@jcco bCompany, @job bJob output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@jcco,'') = ''
	begin
   	select @msg = 'Missing the Job Cost Company', @rcode = 1
   	goto bspexit
	end

-- -- -- get the first job 
select @job= Job
from JCJM with (nolock) 
where JCCo=@jcco and Job=@job and JobStatus > 0 --in (1,2)
if @@rowcount <> 1 select @job = ''

if isnull(@job,'') = ''
	begin
		-- -- -- get the first job 
		select top 1 @job= Job
		from JCJM with (nolock) 
		where JCCo=@jcco and JobStatus > 0 --in (1,2)
		order by JCCo, Job
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCFirstJob] TO [public]
GO
