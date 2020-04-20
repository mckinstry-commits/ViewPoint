SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJBJobVal]
    /***********************************************************
     * CREATED BY: kb 8/9/00
     * MODIFIED By :
     *
     * USAGE:
     * validates a job for t&m bills to make sure the job uses the contract
     * that the bill is for
     *
     * INPUT PARAMETERS
     *   JBCo      JB Co to validate against
     *   Contract  Contract for bill
     *   Job       Job to validate
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Contract
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
   
    	(@jbco bCompany = 0, @contract bContract, @job bJob,
       @msg varchar(60) output)
   
    as
    set nocount on
   
    	declare @rcode int, @jobcontract bContract
    	select @rcode = 0
   
   
    if @jbco is null
    	begin
    	select @msg = 'Missing JC Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @contract is null
    	begin
    	select @msg = 'Missing Contract!', @rcode = 1
    	goto bspexit
    	end
   
    if @job is null
    	begin
    	select @msg = 'Missing Job!', @rcode = 1
    	goto bspexit
    	end
   
    select @jobcontract = Contract from JCJM where JCCo = @jbco and Job = @job
    if @@rowcount = 0
       begin
       select @msg = 'Invalid Job.', @rcode = 1
       goto bspexit
       end
   
    if @jobcontract <> @contract
       begin
       select @msg = 'Job contract does not match the contract in the bill.', @rcode = 1
       goto bspexit
       end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBJobVal] TO [public]
GO
