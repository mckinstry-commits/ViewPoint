SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCIVal    Script Date: 8/28/99 9:32:56 AM ******/
   CREATE   proc [dbo].[bspJCCIVal]
   
   	(@jcco bCompany = null, @contract bContract = null, @item bContractItem = null, @msg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: SE   11/12/96
    * MODIFIED By : SE 11/12/96
    *				TV - 23061 added isnulls
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
    *   @msg      error message if error occurs otherwise Description of Contract Item
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
   
   if @item is null
   	begin
   	select @msg = 'Missing Contract item!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description 
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
GRANT EXECUTE ON  [dbo].[bspJCCIVal] TO [public]
GO