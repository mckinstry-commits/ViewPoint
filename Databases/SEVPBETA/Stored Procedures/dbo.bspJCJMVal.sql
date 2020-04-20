SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCJMVal    Script Date: 8/28/99 9:32:58 AM ******/
CREATE proc [dbo].[bspJCJMVal]
/***********************************************************
* CREATED BY: SE   11/10/96
* MODIFIED By : LM 12/10/96
*				TV - 23061 added isnulls
*				DANF 04/20/06 6.X replaced old style joins
*				CHS	01/22/2009 - issue #26087
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
	@contractdesc bItemDesc = null output, @msg varchar(60) output)
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
   
   select @msg = j.Description, @contract=isnull(j.Contract,''), @contractdesc=isnull(c.Description ,'')
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
GRANT EXECUTE ON  [dbo].[bspJCJMVal] TO [public]
GO
