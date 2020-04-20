SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspJCContractValForJob]

  /***********************************************************
   * CREATED BY: Danf
   * MODIFIED By :   DC 1/30/2004:  18385 - Check Job History when new Job or Contract is added.
   *				TV - 23061 added isnulls
   * USAGE:
   * validates JC contract
   * an error is returned if any of the following occurs
   * no contract passed, no contract found in JCCM.
   *
   * INPUT PARAMETERS
   *   JCCo   JC Co to validate against
   *   Contract  Contract to validate
  
   *
   * OUTPUT PARAMETERS
  
   *   @status      Status of the contract
   *   @department  Department of the contract
   *   @customer    Customer of the contract
   *   @startmonth  StartMonth of the contract
   *   @msg      error message if error occurs otherwise Description of Contract
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
  
  	(@jcco bCompany = 0, @contract bContract = null, @status tinyint output,
  	 @department bDept=null output, @customer bCustomer=null output, @retg bPct=0 output,
  	 @startmonth bMonth=null output, @exists bYN = null output, @jbtemplate varchar(10) = null output,
	 @msg varchar(255) output)
  
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @status=1, @exists = 'N'
  
  
  if @jcco is null
  	begin
  	select @msg = 'Missing JC Company!', @rcode = 1
  	goto bspexit
  	end
  
  if @contract is null
  	begin
  	select @msg = 'Missing Contract!', @rcode = 1
  	goto bspexit
  	end
  
  --DC 18385
  --Check Contract history to see if this contract number has been used
  exec @rcode = dbo.bspJCJMJobVal @jcco, @contract, 'C', @msg output
  if @rcode = 1 
  	begin
  	goto bspexit
  	end
/* -- May be used instead of trigger.
  if @form = 'JCJM' and exists( select top 1 1 from JCJM with (nolock) where JCCo = @jcco and Job = @job)
	begin
  
        -- can't change Contract if found in Close
        if exists(select top 1 1 from bJCCC j with (nolock) where j.Co = @jcco and j.Job = @job)
            begin
            select @msg = 'Contract is marked to be closed, contract may not be changed ', @rcode = 1
            goto bspexit
            end
    
        -- can't change Contract if found in Job History
        if exists(select * from bJCHJ j with (nolock) where j.JCCo = @jcco and j.Job = @job)
            begin
            select @msg = 'Job History exist, contract may not be changed', @rcode = 1
            goto bspexit
            end
    
        -- can't change Contract if found in JC Change orders
        if exists(select top 1 1 from bJCOH j with (nolock) where j.JCCo = @jcco and j.Job = @job)
            begin
            select @msg = 'Change orders exist, contract may not be changed', @rcode = 1
            goto bspexit
            end
	end
*/	
  
  select @retg=0
  select @msg = Description, @status=ContractStatus, 
		@department=Department, @startmonth=StartMonth, 
		@customer=Customer,	@retg=isnull(RetainagePCT,0),
		@jbtemplate = JBTemplate
  	from dbo.bJCCM with (nolock)
  	where JCCo = @jcco and Contract = @contract
  
  if @@rowcount = 0
  	begin
  	select @msg = 'Contract not on file!', @rcode = 1
  	goto bspexit
  	end

select @exists = 'Y'



  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCContractValForJob] TO [public]
GO
