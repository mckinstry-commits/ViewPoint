SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspJCContractValForJobInChangeMode]

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
   *   @msg      error message if error occurs otherwise Description of Contract
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
  
  	(@jcco bCompany = 0, @contract bContract = null, @job bJob = null,  @msg varchar(255) output)
  
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0
  
  
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
  
  if @job is null
  	begin
  	select @msg = 'Missing Contract!', @rcode = 1
  	goto bspexit
  	end


  if exists( select top 1 1 from JCJM with (nolock) where JCCo = @jcco and Job = @job)
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


  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCContractValForJobInChangeMode] TO [public]
GO
