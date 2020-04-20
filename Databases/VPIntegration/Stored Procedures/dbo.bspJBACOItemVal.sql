SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBACOItemVal    Script Date: 8/28/99 9:35:09 AM ******/
    CREATE  proc [dbo].[bspJBACOItemVal]
   
    /***********************************************************
     * CREATED BY: bc 09/27/99
     * Modified by: kb 3/27/00 - validate billtype
     * USAGE:
     *   Validates JB Approved Change Order Item
     *   An error is returned if any of the following occurs
     * 	no company passed
     *	no project passed
     *      no ACO passed
     *      no ACO Item passed
     *	no matching ACO Item found in JCOI
     *
     * INPUT PARAMETERS
     *   JBCO- JC Company to validate against
     *   Job - job to validate against
     *   ACO -  Approved Change Order to validate
     *   ACOItem - ACO Item to validate
     *
     * OUTPUT PARAMETERS
     *   @Contract  from jcoi
     *   @UM        from jcci
     *   @UnitPrice from jcoi
     *   @msg - error message if error occurs otherwise Description of ACOItem in JCOI
     * RETURN VALUE
     *   0 - Success
     *   1 - Failure
     *****************************************************/
    (@jbco bCompany, @job bJob = null, @aco bACO = null, @acoitem bACOItem = null,
     @item bContractItem output, @um bUM = null output, @unitprice bUnitCost output,
     @units bUnits output, @amount bDollar output, @msg varchar(60) output)
    as
    set nocount on
   
    declare @rcode int, @contract bContract, @billtype char(1)
    select @rcode = 0
   
    if @jbco is null
    	begin
    	select @msg = 'Missing JB Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @job is null
    	begin
    	select @msg = 'Missing Job!', @rcode = 1
    	goto bspexit
    	end
   
    if @aco is null
    	begin
    	select @msg = 'Missing ACO!', @rcode = 1
    	goto bspexit
    	end
   
    if @acoitem is null
    	begin
    	select @msg = 'Missing ACO Item!', @rcode = 1
    	goto bspexit
    	end
   
    select @msg = Description, @contract = Contract, @item = Item, @unitprice = ContUnitPrice,
           @units = ContractUnits, @amount = ContractAmt
    from bJCOI
    where JCCo = @jbco and Job = @job and ACO=@aco and ACOItem=@acoitem
   
    if @@rowcount = 0
    	begin
    	select @msg = 'ACO Item not on file!', @rcode = 1
    	goto bspexit
    	end
   
    select @um = UM, @billtype = BillType
    from JCCI
    where JCCo = @jbco and Contract = @contract and Item = @item
   
    if @@rowcount = 0
    	begin
    	select @msg = 'Contract Item not on file!', @rcode = 1
    	goto bspexit
    	end
   
    if @billtype = 'T' or @billtype = 'N'
       begin
       select @msg = 'Invalid bill type.', @rcode = 1
       goto bspexit
       end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBACOItemVal] TO [public]
GO
