SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBContractValProcGroup]
   /***********************************************************
     * CREATED BY:   kb 7/1/2 
     * MODIFIED By:	GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
     *
     * USAGE:
     * validates a contract for the Process Group form.
     *
     * INPUT PARAMETERS
     *   JBCo      JB Co to validate against
     *   Contract  Contract to validate
   
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Contract
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
   
      @jbco bCompany, @contract bContract, @customer bCustomer output, 
   	@template varchar(10) output, @oldprocgroup varchar(10) output, 
   	@msg varchar(255) output

as
Set nocount on

declare @rcode int, @processgroup varchar(20), @status tinyint, @postclosedjobs bYN,
		@billtype char(1), @postsoftclosedjobs bYN

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
   
select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs = PostSoftClosedJobs
from JCCO with (nolock)
where JCCo = @jbco

select @msg = Description, @status = ContractStatus, @customer = Customer,
		@template = JBTemplate, @oldprocgroup = ProcessGroup
from JCCM
where JCCo = @jbco and Contract = @contract
if @@rowcount = 0
    	begin
    	select @msg = 'Contract not on file!', @rcode = 1
    	goto bspexit
    	end

if @status = 0
      begin
      select @msg = 'Cannot bill pending contracts.', @rcode = 1
      goto bspexit
      end

if @status = 2 and @postsoftclosedjobs = 'N'
	begin
	select @msg = 'Contract is soft-closed.', @rcode = 1
	goto bspexit
	end

if @status = 3 and @postclosedjobs <> 'Y'
	begin
	select @msg = 'Contract is hard-closed.', @rcode = 1
	goto bspexit
	end

bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBContractValProcGroup] TO [public]
GO
