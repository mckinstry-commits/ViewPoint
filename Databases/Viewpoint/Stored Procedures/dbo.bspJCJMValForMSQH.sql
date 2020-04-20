SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJCJMValForMSQH]
/***********************************************************
* CREATED BY: GF   11/02/2000
* MODIFIED By : GF 12/19/2000
*				GF 02/22/2002 - Changed to pull contact=name from JCMP - Project Manager
*				GF 03/15/2004 - issue #24036 - added locked flag to output params
*				TV - 23061 added isnulls
*				CHS 4/23/2008 - issue #126600
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
*   @contact returns the customer contact
*   @phone returns the contact phone
*   @pricetemplate
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   (@jcco bCompany = 0, @job bJob = null, @contract bContract = null output,
    @contractdesc bItemDesc = null output, @contact bDesc = null output,
    @phone bPhone = null output, @pricetemplate smallint = null output, 
    @lockphases bYN = 'N' output, @jobstatus bStatus = null output, 
	@msg varchar(255) output)

   as
   set nocount on
   
   declare @rcode int, @custgroup bGroup, @customer bCustomer, @projectmgr int
   
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
   
   select @msg=j.Description, @contract=j.Contract, @contractdesc=isnull(c.Description,''),
          @custgroup=c.CustGroup, @customer=c.Customer, @pricetemplate=j.PriceTemplate,
          @phone=j.JobPhone, @projectmgr=ProjectMgr, @lockphases=j.LockPhases, @jobstatus =j.JobStatus
   from JCJM j with (nolock)
   left join JCCM c with (nolock) on j.JCCo=c.JCCo and j.Contract=c.Contract
   where j.JCCo=@jcco and j.Job=@job 
   if @@rowcount = 0
   	begin
   	select @msg = 'Job not on file, or no associated contract!', @rcode = 1
   	goto bspexit
   	end
   
   -- get Project Manager Name
   if isnull(@projectmgr,'') <> ''
   	begin
   	select @contact=Name
   	from JCMP with (nolock) where JCCo=@jcco and ProjectMgr=@projectmgr
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJMValForMSQH] TO [public]
GO
