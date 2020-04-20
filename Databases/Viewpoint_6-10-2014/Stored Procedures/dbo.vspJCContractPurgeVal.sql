SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCContractPurgeVal    Script Date: 8/28/99 9:32:57 AM ******/
   CREATE   proc [dbo].[vspJCContractPurgeVal]
   
   	(@jcco bCompany = 0, @contract bContract = null, @msg varchar(60) output)
   
   as
   set nocount on
   
   /***********************************************************
    * CREATED BY: DANF 10/04/2006
    * MODIFIED By : 
    *
    * USAGE:
    * validates JC contract for the purge program,
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
   
   
   	declare @rcode int, @status tinyint
   	select @rcode = 0

   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @contract is null
   	begin
   	select @msg = ''
   	goto bspexit
   	end
   

   select @msg = Description, @status = ContractStatus
   	from JCCM
   	where JCCo = @jcco and Contract = @contract
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Contract not on file!', @rcode = 1
   	goto bspexit
   	end

  if @status <> 3
	begin
   	select @msg = 'Contract has not been closed.  Cannot purge.', @rcode = 1
   	goto bspexit
	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCContractPurgeVal] TO [public]
GO
