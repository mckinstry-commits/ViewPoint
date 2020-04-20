SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMContractVal    Script Date: 8/28/99 9:33:03 AM ******/
   CREATE proc [dbo].[bspPMContractVal]
   /*************************************
   * CREATED BY:	JRE  12/7/97
   * MODIFIED BY:	JRE  12/7/97
   *				DC   6/12/03  - Check Job History when new Job or Contract is added.
   * validates PM Firm Types
   *
   * Pass:
   *	PM Co, Contract
   *
   * Since you can't access Closed Contracts in PM then validate wether
   * this contract can be accessed in the Contract form
   *
   * Success returns:
   *	0
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   (@PMCo bCompany, @Contract bContract, @Pending bYN, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @Pending='Y'
   begin
       if exists (select 1 from bJCCM where JCCo=@PMCo and Contract=@Contract 
   	and ContractStatus>1)
   	begin
   	select @msg = 'Contract is closed, access is not allowed.', @rcode = 1
   	goto bspexit
   	end
   end
   else
   begin
       if exists (select 1 from bJCCM where JCCo=@PMCo and Contract=@Contract 
   	and ContractStatus<1)
   	begin
   	select @msg = 'Contract is Pending, access is not allowed.', @rcode = 1
   	goto bspexit
   	end
   end
   ---DC Issue 18385 ---START-----------------------------------------------------
   IF exists(select 1 from bJCHC where Contract = @Contract and JCCo = @PMCo)
   	BEGIN
   	select @msg = 'Contract ' + isnull(@Contract,'') + ' was previously used.  Cannot use Contract' + char(13) + @Contract + ' until the contract is purged from Contract/Job' + char(13) + 'History- use JC Contract Purge form to purge contract.', @rcode = 1
   	goto bspexit
   	END
   -------------------END-------------------------------------------------------
   
   select @msg = ''
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMContractVal] TO [public]
GO
