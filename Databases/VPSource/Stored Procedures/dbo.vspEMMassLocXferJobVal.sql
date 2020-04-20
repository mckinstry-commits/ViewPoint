SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMMassLocXferJobVal]
/***********************************************************
* CREATED BY:	CHS		08/04/2008 - Issue #128061
* MODIFIED By:	
*
* USAGE:
*	Returns JC Job Status
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = null, @job bJob = null, @jobstatus bStatus = null output, @msg varchar(255) = '' output)

as
set nocount on


declare @rcode int

select @rcode = 0

/* Validate Job */   
select @msg = Description, @jobstatus = JobStatus
from JCJM with (nolock)
where JCCo = @jcco and Job = @job

if @jobstatus=0
	begin
	select @msg='Job Status cannot be Pending!', @rcode=1
	goto vspexit
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMMassLocXferJobVal] TO [public]
GO
