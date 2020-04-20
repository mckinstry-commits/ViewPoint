SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBInvoiceUnique]
   /***********************************************************
   * CREATED BY	: bc 10/16/99
   * MODIFIED BY	: kb 3/21/01 - changed datatype of billnum from int to varchar - Issue #12695
   *		TJL 09/05/02 - Issue #18319, On NEW Bill, Warn if Invoice Number exists on Active Bill. (Not Interfaced)
   *		TJL 10/10/02 - Issue #16370, Warn if duplicate Inv# exists. Where depends on JBCO.InvoiceOpt
   *		TJL 08/13/03 - Issue #22093, Modify Duplicate Invoice Message text only
   *
   * USAGE:
   * validates AR to insure that it is unique.  Checks ARBH, ARTH, JBAR and JBIN
   *
   * INPUT PARAMETERS
   *   JBCo      JB Co to validate against
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs otherwise Description of Location
   * RETURN VALUE
   *   0         success
   *   1         Failure  'if Fails Address, City, State and Zip are ''
   *****************************************************/
   (@jbco bCompany, @arco bCompany, @billmth bMonth, @billnumber varchar(9), @invoice varchar(10), 
   	@msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @invopt char(1)
   
   select @rcode = 0, @msg = 'New Invoice'
   
   if @jbco is null or @arco is null
   	begin
       select @msg = 'Missing information - bspJBInvoiceUnique' , @rcode = 1
       goto bspexit
       end
   
   if @invoice is null
       begin
       select @msg = 'Invoice number required.', @rcode = 1
       goto bspexit
       end
   
   select @invopt = InvoiceOpt
   from bJBCO
   where JBCo = @jbco
   
   if @invopt is null or @invopt = 'A'
   	begin	--Begin InvoiceOpt NULL or 'A'
   	select @msg='Invoice ' + isnull(ltrim(convert(varchar(10),@invoice)),'') + ' already exists in AR ' +
   		'for Customer ' + isnull(ltrim(convert(varchar(10),Customer)),'')
   	from bARTH
   	where ARCo=@arco and Invoice=@invoice
   	if @msg <> 'New Invoice'
   		begin
   		select @rcode = 1
   		goto bspexit
   		end
   
   	select @msg='Invoice ' + isnull(ltrim(convert(varchar(10),@invoice)),'') + ' is in use by AR batch Month:' + 
   		isnull(substring(convert(varchar(12),Mth,3),4,5),'') + ' ID:' + isnull(ltrim(convert(varchar(10),BatchId)),'') +
   		' Seq: ' + isnull(ltrim(convert(varchar(10),BatchSeq)),'')
   	from bARBH
   	where Co=@arco and Invoice=@invoice
   	if @msg <> 'New Invoice'
   		begin
   		select @rcode = 1
   		goto bspexit
   		end
   
   	/* Issue #16370:  Rem'd since there should be no reason check bJBAR because anything in
   	   bJBAR already exists in bJBIN anyway. */
   	/* select @msg='Invoice ' + convert(varchar(10),@invoice) + ' is in use by JB batch Month:' + substring(convert(varchar(12),Mth,3),4,5) + ' ID:' + convert(varchar(10),BatchId)
   	from bJBAR
   	where Co=@jbco and Invoice=@invoice
   	if @msg <> 'New Invoice'
   		begin
   		select @rcode = 1
   		goto bspexit
   		end */
   	
   	/* Check Un-Interfaced Bills in JB that may be interfaced to this AR Company.  
   	   We only care about those bills that have not yet been interfaced since any others
   	   would have been identified by the ARTH check above.  Also multiple JBCo may be using
   	   this ARCo and so we need to look at all JBCo using this AR Company. */
   	if @billnumber = 'NEW'
   		begin
   		select @msg='Invoice ' + isnull(ltrim(convert(varchar(10),@invoice)),'') + ' already exists in Job Billing ' +
   			'for Customer ' + isnull(ltrim(convert(varchar(10),n.Customer)),'')
   		from bJBIN n
   		join bJCCO c on c.JCCo = n.JBCo
   		where c.ARCo = @arco and n.Invoice=@invoice 	
   			and n.InvStatus in ('A','C','D')
   		if @msg <> 'New Invoice'
   			begin
   			select @rcode = 1
   			goto bspexit
   			end
   		end
   	else
   		--if @billnumber <> 'NEW'
   	   	begin
   	  	select @msg='Invoice ' + isnull(ltrim(convert(varchar(10),@invoice)),'') + ' already exists in Job Billing ' +
   			'for Customer ' + isnull(ltrim(convert(varchar(10),n.Customer)),'')
   		from bJBIN n
   		join bJCCO c on c.JCCo = n.JBCo
   		where c.ARCo = @arco and n.Invoice=@invoice and n.InvStatus in ('A','C','D')
   			and (BillMonth <> @billmth or (BillMonth = @billmth and BillNumber <> convert(int,@billnumber)))
   		if @msg <> 'New Invoice'
   			begin
   			select @rcode = 1
   			goto bspexit
   			end
   		end
   	end		--End InvoiceOpt NULL or 'A'
   Else
   	begin	--Begin InvoiceOpt 'J'
   	/* As with MS, if JBCO.InvoiceOpt is set to 'J' then Unique Invoice validation only
   	   needs to be concerned with duplicate invoices with the JBCo.  */
   	if @billnumber = 'NEW'
   		begin
   	   	select @msg='Invoice ' + isnull(ltrim(convert(varchar(10),@invoice)),'') + ' already exists in Job Billing ' +
   			'for Customer ' + isnull(ltrim(convert(varchar(10),Customer)),'')
   	   	from bJBIN
   	   	where JBCo=@jbco and Invoice=@invoice
   	 	if @msg <> 'New Invoice'
   	 		begin
   	 		select @rcode = 1
   	 		goto bspexit
   	 		end
   	 	end
   	 else
   	 --if @billnumber <> 'NEW'
   	 	begin
   	   	select @msg='Invoice ' + isnull(ltrim(convert(varchar(10),@invoice)),'') + ' already exists in Job Billing ' +
   			'for Customer ' + isnull(ltrim(convert(varchar(10),Customer)),'')
   	   	from bJBIN
   	   	where JBCo=@jbco and Invoice=@invoice 
   			and (BillMonth <> @billmth or (BillMonth = @billmth and BillNumber <> convert(int,@billnumber)))
   	 	if @msg <> 'New Invoice'
   	 		begin
   	 		select @rcode = 1
   	 		goto bspexit
   	 		end
   	 	end
   	end 	--End InvoiceOpt 'J'
   
   bspexit:
   if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[dbo.bspJBInvoiceUnique]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBInvoiceUnique] TO [public]
GO
