SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspARInvoiceUnique    Script Date: 8/28/99 9:34:12 AM ******/
   CREATE  proc [dbo].[bspARInvoiceUnique]
   /***********************************************************
   * CREATED BY	: CJW 6/5/97
   * MODIFIED BY	: bc  03/16/99 - add jb validation
   * 		jre 5/18/99 change bCust to bCustomer
   *  		bc  02/20/01 - add customer group
   *    	bc  06/12/01 - included Type 'R' as a vaild type that needs to be validated
   *		TJL 06/13/01 - included Type 'F' as a valid type that needs to be validated
   *		TJL 10/10/02 - Issue #16370, Warn if duplicate Inv# exists within this entire ARCo
   *		TJL 08/13/03 - Issue #22093, Modify Duplicate Invoice Message text only
   *
   * USAGE:
   * validates AR to insure that it is unique.  Checks ARBH and ARTH
   *
   * INPUT PARAMETERS
   *   ARCo      AR Co to validate against
   *   AR        AR to Validate
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs otherwise Description of Location
   * RETURN VALUE
   *   0         success
   *   1         Failure  'if Fails Address, City, State and Zip are ''
   *****************************************************/
   (@arco bCompany = 0, @mth bMonth = null, @batchid bBatchID = null, @seq int, @type varchar(10),
    @invoice varchar(10) = null, @customer bCustomer = null, @msg varchar(255) output )
   as
   set nocount on
   
   declare @rcode int, @jbco bCompany, @custgrp bGroup
   
   select @rcode = 0, @msg = 'AR Unique'
   
   if @arco = 0 or @mth is null or @batchid is null or @seq is null
   	begin
   	select @msg = 'Missing information - bspARUnique' , @rcode = 1
   	goto bspexit
   	end
   
   if @invoice is null
   	begin
   	select @msg = 'Invoice number required.', @rcode = 1
   	goto bspexit
   	end
   
   --select @custgrp = CustGroup
   --from bHQCO
   --where HQCo = @arco
   
   if @type not in ('I','R','F') goto bspexit
   
   /* Check for duplicate Posted AR Invoice numbers for this Company */
   select @rcode=1, @msg='Invoice ' + ltrim(@invoice) + ' already exists in AR ' +
   	'for Customer ' + ltrim(convert(varchar(10),Customer))
   from bARTH with (nolock)
   where ARCo=@arco and Invoice=@invoice 	--and CustGroup = @custgrp and Customer = @customer
   
   /* Check for duplicate Un-Posted AR Invoice numbers for this Company in any batch or Sequence
      except this Batch and Seq */
   select @rcode=1, @msg='Invoice ' + ltrim(@invoice) + ' is in use by AR batch  Month: ' +
     	substring(convert(varchar(12),Mth,3),4,5) + ' ID: ' + ltrim(convert(varchar(10),BatchId)) +
   	' Seq: ' + ltrim(convert(varchar(10),BatchSeq)) 
   from bARBH with (nolock)
   where Co=@arco and Invoice=@invoice 	--and CustGroup = @custgrp and Customer = @customer
        and not (Mth=@mth and BatchId=@batchid and BatchSeq=@seq)
   
   --select @jbco = JCCo
   --from ARCO
   --where ARCo = @arco
   
   /* Check Un-Interfaced Bills in JB that may be interfaced to this AR Company.  
      We only care about those bills that have not yet been interfaced since any others
      would have been identified by the ARTH check above.  Also multiple JBCo may be using
      this ARCo and so we need to look at all JBCo using this AR Company. */
   select @rcode=1, @msg='Invoice ' + ltrim(@invoice) + ' already exists in Job Billing ' +
   	'for Customer ' + ltrim(convert(varchar(10),n.Customer))
   from bJBIN n with (nolock)
   join bJCCO c with (nolock) on c.JCCo = n.JBCo
   where c.ARCo = @arco and n.Invoice=@invoice 	--and CustGroup = @custgrp and Customer = @customer
   	and n.InvStatus in ('A','C','D')
   
   select @rcode=1, @msg='Invoice ' + ltrim(@invoice) + ' already exists in Service Managment ' +
   	'for Customer ' + ltrim(convert(varchar(10),n.BillToARCustomer))
   from SMInvoiceSession n with (nolock)
   join SMCO c with (nolock) on c.SMCo = n.SMCo
   where c.ARCo = @arco and n.InvoiceNumber=@invoice
   
   bspexit:
   	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[dbo.bspARInvoiceUnique]'
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspARInvoiceUnique] TO [public]
GO
