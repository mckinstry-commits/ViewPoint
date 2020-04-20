SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCIValWithUM    Script Date: 8/28/99 9:35:00 AM ******/
   CREATE   proc [dbo].[bspJCCIValWithUM]
   /***********************************************************
    * CREATED BY: JM   3/10/97
    * MODIFIED By : JM   9/11/97 - added return of default GLAcct
    *               MV  5/16/01 - allow adding new item if item
    *                             not found in JCCI.
    *				TV - 23061 added isnulls
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
    *   @um       	unit of measure for contract item
    *   @defglacct default GLAcct
    *   @msg      	error message if error occurs otherwise Description of Contract Item
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@jcco bCompany = 0, @contract bContract = null, @item bContractItem = null,
    @defglacct bGLAcct output, @um bUM output, @msg varchar(255) output)
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
   
   if @item is null
   	begin
   	select @msg = 'Missing Contract item!', @rcode = 1
   	goto bspexit
   	end
   
   --replaced following with next section to also return def glacct
   --select @um = UM, @msg = Description
   --	from bJCCI
   --	where JCCo = @jcco and Contract = @contract and Item = @item
   --
   --if @@rowcount = 0
   --	begin
   --	select @msg = 'Contract Item not on file!', @rcode = 1
   --	goto bspexit
   --	end
   
   select @defglacct = case c.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end,
   	   @um = UM, @msg = i.Description
   from bJCCI i with (nolock)
   join bJCCM c with (nolock) on c.JCCo = i.JCCo and c.Contract = i.Contract
   left join bJCDM d with (nolock) on d.JCCo = i.JCCo and d.Department = i.Department
   where i.JCCo = @jcco and i.Contract = @contract and i.Item = @item
   
   -- Modified to allow adding contract item to JCCI if not on file.
   /*if @@rowcount = 0
   	begin
   	select @msg = 'Contract Item not on file!', @rcode = 1
   	goto bspexit
   	end*/
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCIValWithUM] TO [public]
GO
