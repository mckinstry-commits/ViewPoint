SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPurgeContractVal    Script Date: 6/6/2003 3:58:24 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspJCPurgeContractVal    Script Date: 6/6/2003 3:11:10 PM ******/
   
   CREATE   proc [dbo].[bspJCPurgeContractVal]
   	(@jcco bCompany = 0, @contract bContract = null, @msg varchar(60) output)
   
   as
   set nocount on
   
   /***********************************************************
    * CREATED BY: 	DC 06/06/03
    * MODIFIED By  TV - 23061 added isnulls
    *
    * USAGE:
    * validates JC contract in history tables
    * an error is returned if any of the following occurs
    * no contract passed, no contract found in JCHC.
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against
    *   Contract  Contract to validate
   
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Contract
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   
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
   
   select @msg = ContractDesc from bJCHC
   	where JCCo = @jcco and Contract = @contract
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Contract does not exist in History!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPurgeContractVal] TO [public]
GO
