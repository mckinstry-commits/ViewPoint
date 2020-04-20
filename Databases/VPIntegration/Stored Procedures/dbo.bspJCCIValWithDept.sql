SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCIValWithDept    Script Date: 8/28/99 9:32:57 AM ******/
   CREATE   proc [dbo].[bspJCCIValWithDept]
   
   	(@jcco bCompany = 0, @contract bContract = null, @item bContractItem = null, 
   	@dept bDept output, @msg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: JM   4/16/97
    * MODIFIED By : TV - 23061 added isnulls
    *
    * USAGE:
    * validates JC contract item
    * an error is returned if any of the following occurs
    * no contract passed, no item passed, no item found in JCCI.
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against 
    *   Contract  Contract to validate against
    *   Item      Contract item to validate
    *
    * OUTPUT PARAMETERS
    *   @dept     department for contract item
    *   @msg      error message if error occurs otherwise Description of Contract Item
    * RETURN VALUE
    *   0         Success
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
   
   if @item is null
   	begin
   	select @msg = 'Missing Contract item!', @rcode = 1
   	goto bspexit
   	end
   
   select @dept = Department, @msg = Description 
   	from bJCCI
   	where JCCo = @jcco and Contract = @contract and Item = @item
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Contract Item not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCIValWithDept] TO [public]
GO
