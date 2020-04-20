SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCContractValForPM    Script Date: 1/30/2004 12:00:23 PM ******/
   
   
   
   CREATE     proc [dbo].[bspJCContractValForPM]
   	(@jcco bCompany = 0, @contract bContract = null, @status tinyint output,
   	 @department bDept=null output, @customer bCustomer=null output, @retg bPct=0 output,
   	 @startmonth bMonth=null output, @msg varchar(60) output)
   as
   set nocount on
   
   /***********************************************************
    * CREATED BY:  GF 02/05/2001
    * MODIFIED By:  DC 01/30/2004 : 18385 - Check Job History when new Job or Contract is added.
    *				TV - 23061 added isnulls
    * USAGE:
    * validates JC contract for PM Projects
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
   
   
   	declare @rcode int
   	select @rcode = 0, @status=0
   
   
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
   	BEGIN
   	goto bspexit
   	END
   
   select @retg=0
   select @msg = Description, @status=ContractStatus, @department=Department, @startmonth=StartMonth, @customer=Customer,
   	@retg=isnull(RetainagePCT,0)
   	from bJCCM
   	where JCCo = @jcco and Contract = @contract
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Contract not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCContractValForPM] TO [public]
GO
