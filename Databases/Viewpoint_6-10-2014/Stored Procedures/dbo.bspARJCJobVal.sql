SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARJCJobVal    Script Date: 8/28/99 9:34:12 AM ******/
CREATE  proc [dbo].[bspARJCJobVal]
   /***********************************************************
    * CREATED BY: JM   1/15/98
    * MODIFIED By :  bc 11/12/98
	*				GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
	*
    *
    * USAGE:
    * 	Validates JC Job and returns Status, MiscDistCode,
    *	and MiscDistCodeDesc for Job's Customer.
    * 	An error is returned if any of the following occurs
    *		no JCCo passed
    * 		no Job passed
    *		Job not found in JCCM
    *
    * INPUT PARAMETERS
    *   JCCo   JCCo to validate against
    *   Job    Job to validate
    *
    * OUTPUT PARAMETERS
    *   @status   		JCJM.Status (Open, SoftClose,Close)
    *   @miscdistcode 	ARCM.MiscDistCode for CustGrp/Customer
    *   @miscdistcodedesc  ARMC.MiscDistCodeDesc for CustGrp/MiscDistCode
    *   @lockphases	JCJM.LockPhases
    *   @msg      		error message if error occurs, otherwise
    *			Description of Job
   
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
(@jcco bCompany = 0, @job bJob = null, @status tinyint output,
 @miscdistcode varchar(10) output, @miscdistcodedesc bDesc output, @lockphases bYN output,
 @msg varchar(60) output)
as
set nocount on

declare @rcode int, @contract bContract, @postclosedjobs varchar(1),
		@customer bCustomer, @custgroup bGroup, @postsoftclosedjobs varchar(1)

select @rcode = 0, @contract='',@customer = null, @custgroup = null

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
   /* get Desc, Contract, and Status from Job Master for JCCo and Job */
   select @msg = Description, @contract=Contract, @status=JobStatus, @lockphases = LockPhases
   	from JCJM
   	where JCCo = @jcco and Job = @job
   	if @@rowcount = 0
   		begin
   		select @msg = 'Job not on file!', @rcode = 1
   		goto bspexit
   		end
   	if @status = 0
   		begin
   		select @msg = 'Job is pending.  Cannot process!', @rcode = 1
   		goto bspexit
   		end
   /* get Customer from Customer Master for JCCo and Customer */
   select @customer = Customer, @custgroup = CustGroup
   	from JCCM
   	where JCCo = @jcco and Contract = @contract
   /* Get ARMC.MiscDistCode and its description from ARMC */
   select  @miscdistcode = MiscDistCode
   	from ARCM
   	where CustGroup = @custgroup and Customer = @customer
   select @miscdistcodedesc = Description
   	from ARMC
   	where CustGroup = @custgroup and MiscDistCode = @miscdistcode

---- return closed msg if status soft or hard closed and ok to post to closed job
select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs = PostSoftClosedJobs
from bJCCO where JCCo = @jcco

if @status = 2 and @postsoftclosedjobs = 'N'
	begin
	select @msg = 'Job is soft-closed!', @rcode = 1
	goto bspexit
	end

if @status = 3 and @postclosedjobs = 'N'
	begin
	select @msg='Job is hard-closed!', @rcode=1
	goto bspexit
	end

bspexit:
   	if @rcode <> 0 select @msg=@msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARJCJobVal] TO [public]
GO
