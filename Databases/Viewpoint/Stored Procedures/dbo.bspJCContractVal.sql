SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCContractVal    Script Date: 8/28/99 9:32:57 AM ******/
   CREATE   proc [dbo].[bspJCContractVal]
   
   	(@jcco bCompany = 0, @contract bContract = null, @status tinyint output,
   	 @department bDept=null output, @customer bCustomer=null output, @retg bPct=0 output,
   	 @startmonth bMonth=null output, @msg varchar(60) output)
   
   as
   set nocount on
   
   /***********************************************************
    * CREATED BY: SE   10/2/96
    * MODIFIED By : SE 9/28/97
    *               JE 4/7/98 - added Retainage issue #1808
    *               GR 7/7/99
    *				 TV - 23061 added isnulls
    *
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
   
   select @retg=0
   select @msg = Description, @status=ContractStatus, @department=Department, @startmonth=StartMonth, @customer=Customer,
   	@retg=isnull(RetainagePCT,0)
   	from JCCM
   	where JCCo = @jcco and Contract = @contract
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Contract not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCContractVal] TO [public]
GO
