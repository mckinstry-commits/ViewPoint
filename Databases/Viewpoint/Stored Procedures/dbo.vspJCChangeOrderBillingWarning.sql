SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspJCChangeOrderBillingWarning]

  /***********************************************************
   * CREATED BY: Dan F
   * MODIFIED By : 
   *
   * USAGE:
   * Displays error message when changing a contract item and the when the old Item had already been billed.
   *
   * INPUT PARAMETERS
   *  	JCCo   	JC Co to validate against
   *   	Job  	Job to validate
   *   	Item	Contract Item
   * 	ACO		Apporved Change Order
   *	ACOItem	Apporved Change Order Item
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs otherwise Description of Contract
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
 
  	(@jbco bCompany = 0, @job bJob = null, @item bContractItem = null, 
	 @aco bACO = null, @acoitem bACOItem = null, @msg varchar(255) output)
  
  as
  set nocount on
  
  	declare @billmonth smalldatetime, @billnumber int, @rcode int
  	select @rcode = 0,@msg=''
  
  
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

  if @item is null
  	begin
  	select @msg = 'Missing Contract Item!', @rcode = 1
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


	select @billmonth= BillMonth, @billnumber = BillNumber 
	from JBIS with (nolock)
	where JBCo= @jbco and Job= @job and Item= @item and ACO= @aco and ACOItem= @acoitem
	if @@rowcount<>0
		begin
		set @rcode =1
		select @msg = 'Warning! Change Order Item has been billed in JB for Month:' + convert(varchar(10),@billmonth,101) + ' BillNumber: ' + convert(varchar(10),@billnumber) + ' for old contract item.'
        end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCChangeOrderBillingWarning] TO [public]
GO
