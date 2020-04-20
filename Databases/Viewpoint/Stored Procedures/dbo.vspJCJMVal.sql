SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspJCJMVal]
/***********************************************************
* CREATED BY:	CHS 04/24/2008 Copied from bspJCJMVal for #126600
* MODIFIED By:	CHS 01/22/2009 - issue #26087
*
* USAGE:
* validates JC Job
* and returns contract and Contract Description
* an error is returned if any of the following occurs
* no job passed, no job found in JCJM, no contract found in JCCM
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against 
*   Job    Job to validate
*
* OUTPUT PARAMETERS
*   @contract returns the contract for this job.  
*   @contractdesc returns the contract desc for this contract                       
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
   (@jcco bCompany = 0, @job bJob = null, @contract bContract = null output,
    @contractdesc bItemDesc = null output, @jobstatus bStatus = null output, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @contract='', @contractdesc=''
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @job is null
   	begin
   	select @msg = 'Missing Job!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = j.Description, @jobstatus = JobStatus, @contract=isnull(j.Contract,''), @contractdesc=isnull(c.Description ,'')
   from JCJM j with (nolock)
   left join JCCM c with (nolock) on j.JCCo = c.JCCo and j.Contract=c.Contract
   where j.JCCo = @jcco  and j.Job = @job 
   if @@rowcount = 0
   	begin
   	select @msg = 'Job not on file, or no associated contract!' , @rcode = 1
   	goto bspexit
   	end
     
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJMVal] TO [public]
GO
