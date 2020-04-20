SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARFCInvoiceVal]
/***********************************************************
* CREATED BY:	TJL 05/09/05 - Issue #27704, Rewrite for 6x
* MODIFIED BY:	GF 09/06/2010 - issue #141031 change to use function vfDateOnly
*
* USAGE:
* Validates AR Invoice for Finance Charge Purposes.
* 	ON ACCOUNT
* 		Checks ARBH and JBIN for the presence of the Invoice Number and warns user if it exists elsewhere
* 		If it doesn't exist (As should be the case for ON ACCOUNT finance charges), will Assign a Unique finance charge description.
*	ON INVOICE
*		Check if duplicate Invoice number
*		Check for existence in ARTH and returns description
*		Returns Applied ARTrans and Applied Month
*		Returns Invoice RecType and Description
*		Returns JCCo
*		Returns Contract and Description
*		Returns Orig Inv Amt, Curr Inv Amt, and Invoice AmtDue
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*					
*
* RETURN VALUE
*   0         success
*   1         Failure  'if Fails Address, City, State and Zip are ''
*****************************************************/
(@arco bCompany = 0, @mth bMonth = null, @batchid bBatchID = null, @seq int = null, @type varchar(1) = null,
	@customer bCustomer = null, @invoice varchar(10) = null, @applymthIN bMonth = null, @applytransIN bTrans = null, 
	@OrigInvAmt bDollar output, @CurrInvAmt bDollar output, @AmtDue bDollar output, @ApplyMthOUT bMonth output, 
   	@ApplyTransOUT bTrans output, @RecType int output, @PayTerms bPayTerms output, @JCCo bCompany output, 
	@Contract varchar(30) output, @ContractDesc varchar(100) output, @msg varchar(255) output)
  
as
set nocount on
  
/* Working declares here */
declare @rcode int, @jbco bCompany, @custgrp bGroup, @reccount int, @todaydate bDate,
	@fcrectype int

select @rcode = 0, @reccount = 0
----#141031
select @todaydate = dbo.vfDateOnly()
  
if @arco = 0 or @mth is null or @batchid is null or @seq is null
 	begin
 	select @msg = 'Missing BatchMth, BatchId, or BatchSeq information.' , @rcode = 1
 	goto vspexit
 	end

if @invoice is null
 	begin
	select @msg = 'Invoice number required for this Field.', @rcode = 1
 	goto vspexit
	end

if @customer is null
 	begin
	select @msg = 'Customer required.', @rcode = 1
 	goto vspexit
	end

if @type <> 'I' and @type <> 'A' and @type <> 'R'
	begin
	select @msg = 'Finance Charges should not be applied to this customer.', @rcode = 1
	goto vspexit
	end

/* Collect Required Information Here. */
select @custgrp = CustGroup
from bHQCO with (nolock)
where HQCo = @arco
  
/* Begin Validation for On Account Invoice Numbers. */
if @type = 'A' or @type = 'R'
  	begin
  
  	/* Need to return a Generic Invoice Description */
  	--if @type = 'A' select @InvDesc = 'AR Acct Finance Chg'
  	--if @type = 'R' select @InvDesc = 'AR RecType Finance Chg'
  
  	/* Check for duplicate Posted AR Invoice numbers for this Company */
  	select @rcode = 1, @msg = 'Invoice ' + isnull(ltrim(@invoice),'') + ' already exists in AR ' +
  		'for Customer ' + isnull(ltrim(convert(varchar(10),Customer)),'')
  	from bARTH with (nolock)
  	where ARCo = @arco and Invoice = @invoice 		--and CustGroup = @custgrp and Customer = @customer
  	
  	/* Check for duplicate Un-Posted AR Invoice numbers for this Company in any batch or Sequence
  	   except this Batch and Seq */
  	select @rcode = 1, @msg = 'Invoice ' + isnull(ltrim(@invoice),'') + ' is in use by AR batch  Month: ' +
  	  	substring(convert(varchar(12),Mth,3),4,5) + ' ID: ' + ltrim(convert(varchar(10),BatchId)) +
  		' Seq: ' + ltrim(convert(varchar(10),BatchSeq)) 
  	from bARBH with (nolock)
  	where Co=@arco and Invoice=@invoice 			--and CustGroup = @custgrp and Customer = @customer
  	     and not (Mth=@mth and BatchId=@batchid and BatchSeq=@seq)
  	
  	/* Check Un-Interfaced Bills in JB that may be interfaced to this AR Company.  
  	   We only care about those bills that have not yet been interfaced since any others
  	   would have been identified by the ARTH check above.  Also multiple JBCo may be using
  	   this ARCo and so we need to look at all JBCo using this AR Company. */
  	select @rcode = 1, @msg ='Invoice ' + isnull(ltrim(@invoice),'') + ' already exists in Job Billing ' +
  		'for Customer ' + isnull(ltrim(convert(varchar(10),n.Customer)),'')
  	from bJBIN n with (nolock)
  	join bJCCO c with (nolock) on c.JCCo = n.JBCo
  	where c.ARCo = @arco and n.Invoice = @invoice 	--and CustGroup = @custgrp and Customer = @customer
  		and n.InvStatus in ('A','C','D')
  
  	goto vspexit
  	end  /* End ON ACCOUNT and BY RECTYPE Invoice validation */

/* Begin Validation for BY INVOICE, Invoice Numbers. */
if @type = 'I'
  	begin

  	/* If a user has not selected a specific invoice from an F4 lookup window
  	   then there will not be an associated ApplyMth and ApplyTrans.  In this case,
  	   if this is a duplicate invoice number, then the program has no way to identify
  	   the desired ApplyMth and ApplyTrans in order to process the Finance Charge.
  	   Therefore, the user must be told to select the invoice from an F4 lookup. 
  	   Likewise, if the Invoice number does not exist at all. */

  	ProcessARTrans:
  	if @applymthIN is null or @applytransIN is null
  		begin
  		select  @reccount = count(*)
  		from bARTH with (nolock)
  		where ARCo = @arco and (ltrim(Invoice) = ltrim(@invoice))
  			and CustGroup = @custgrp and Customer = @customer
  			and Mth = AppliedMth and ARTrans = AppliedTrans 
  			and ARTransType not in ('P', 'M', 'A', 'C', 'W')
  
  		if @reccount = 0
  			begin
  			select @msg = 'This ApplyTo Invoice Number ' + isnull(@invoice,'') + ' does not exist.', @rcode = 1
  			goto vspexit
  			end
  
  		if @reccount > 1
  			begin
  			select @msg = 'This is a Duplicate Invoice Number. You must select correct Invoice from F4 Lookup Display.', @rcode = 1
  			goto vspexit
  			end
 
		/* This Invoice number does exist to apply against and it is not a duplicate number. */
  		select  @applytransIN = ARTrans, @applymthIN = Mth 
  		from bARTH with (nolock)
  		where ARCo = @arco and (ltrim(Invoice) = ltrim(@invoice))
  			and CustGroup = @custgrp and Customer = @customer
  			and Mth = AppliedMth and ARTrans = AppliedTrans 
  		end

	/* At this point, if applytrans is not null it is either a valid value or User changed Invoice
	   value on form after validation occurred.  If Invoice has been changed then the Apply values
	   passed into this procedure may no longer be valid for this Invoice number.

	   The following check will determine that the Invoice number is no longer relative to the "Apply.."
	   information and reset @applymthIN and @applytransIN and restart the search for the 
	   correct values relative to this Invoice value.  Trust me, this can happen and this will resolve it, 
	   since Invoice, Mth and ARTrans are related and must match up. */
  	select @reccount = count(*)
  	from bARTH h with (nolock)
  	where h.ARCo = @arco and h.Mth = @applymthIN and h.ARTrans = @applytransIN
  		and ltrim(h.Invoice) = ltrim(@invoice) 
  		and h.CustGroup = @custgrp and h.Customer=@customer
  		and h.Mth = h.AppliedMth and h.ARTrans = h.AppliedTrans
  
  	if @reccount = 0
  		begin
  		select @applymthIN = null, @applytransIN = null
  		goto ProcessARTrans
  		end

	/* WE HAVE VALID INVOICE APPLY INFORMATION.  Get Invoice related information now. */
  	/* If we are here then, Invoice-ApplyTrans-ApplyMth match, Invoice is valid, and not a Duplicate */
  	select @ApplyTransOUT = @applytransIN, @ApplyMthOUT = @applymthIN, 
  		@RecType = h.RecType, @PayTerms = h.PayTerms, @JCCo = h.JCCo, @Contract = h.Contract, 
  		@ContractDesc = j.Description
  	from bARTH h with (nolock)
  	left join bJCCM j on isnull(h.JCCo, '') = isnull(j.JCCo, '') and isnull(h.Contract, '') = isnull(j.Contract, '')
  	join bARRT r on h.ARCo = r.ARCo and h.RecType = r.RecType
  	where h.ARCo = @arco and ltrim(h.Invoice) = ltrim(@invoice) and h.Mth = @applymthIN and h.ARTrans = @applytransIN
  		and h.CustGroup = @custgrp and h.Customer=@customer
  		and h.Mth = h.AppliedMth and h.ARTrans = h.AppliedTrans

  	/* Need to return dollar values relative to this Invoice.  These are displayed to the user. */
  	exec @rcode = bspARFCAmtDue @arco, @mth, @applytransIN, @custgrp, @customer, @todaydate, @todaydate,
  		@applymthIN, @type, @OrigInvAmt output, @AmtDue output, @CurrInvAmt output
 
  	end	/* End On Invoice, Invoice validation */
  
vspexit:
if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[dbo.vspARFCInvoiceVal]'  
  
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARFCInvoiceVal] TO [public]
GO
