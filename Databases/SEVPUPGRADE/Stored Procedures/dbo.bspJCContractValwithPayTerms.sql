SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCContractValwithPayTerms    Script Date: 8/28/99 9:32:57 AM ******/
   CREATE   proc [dbo].[bspJCContractValwithPayTerms]
   
   	(@jcco bCompany = 0, @contract bContract = null, @status tinyint output,
   	      @DaysTillDisc tinyint output, @DaysTillDue tinyint output, @Customer bCustomer output, @msg varchar(60) output)
   as
   set nocount on
   
   /***********************************************************
    * CREATED BY: CJW
    * MODIFIED By : CJW 05/19/97
    *				TV - 23061 added isnulls
    * USAGE:
    * validates JC contract - returns STATUS, DAYS UNTIL DISCOUNT, DAYS UNTIL DUE, and Customer
    * an error is returned if any of the following occurs
    * no contract passed, no contract found in JCCM.
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against
    *   Contract  Contract to validate
   
    *
    * OUTPUT PARAMETERS
    *   @status   Status of the contract
    *   @DaysTillDisc	days until discount in HQPT
    *   @DaysTillDue	days until due in HQPT
    *   @msg      error message if error occurs otherwise Description of Contract
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   
   	declare @rcode int
   	select @rcode = 0, @status=1
   
   
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
   
   select @msg = JCCM.Description, @status=JCCM.ContractStatus, @DaysTillDisc=HQPT.DaysTillDisc, @DaysTillDue=HQPT.DaysTillDue,
   	@Customer = JCCM.Customer
   	from JCCM
   	join HQPT on HQPT.PayTerms = JCCM.PayTerms
   	where JCCo = @jcco and Contract = @contract
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Contract not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCContractValwithPayTerms] TO [public]
GO
