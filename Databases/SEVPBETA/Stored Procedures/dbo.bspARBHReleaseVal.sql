SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBHReleaseVal    Script Date: 8/28/99 9:36:06 AM ******/
CREATE procedure [dbo].[bspARBHReleaseVal]
/*******************************************************************************************
* CREATED BY:   	CJW 10/14/97
* MODIFIED By :   	bc 05/21/99
*		JM 6/2/98 - Added @deptdead bDept, @custdead bCustomer, @retgdead bPct
*		 			declares, and added these as params to bspJCContractVal call to
*			 		make params match bsp call
*    	bc 10/25/00  removed code that combined @Amount + @Retainage when
*                	the receivable glacct = retainage glacct when updating ARBA.
*               	allow the two separate updates to ARBA to wash out and leave it at that for now.
*     	bc 03/08/01 - allow for an ARBL 10000 line for both contract item lines and non contract lines
*                 	within the same batch.
*		TJL 07/20/01 Lines > 10000 in ARBL later become the lines of a NEW Released Retainage invoice.
*					Modified description to 'Released Retainage' for consistency with ARTL
*    	bc 03/04/02 - GLCO should be that of the AR company we're posting in.
*		TJL 04/19/02 - Issue #17068, Add GLAcct validation with GLAcct SubType checks.
*		TJL 02/17/03 - Issue #19908, Validate Invoice Number for NULL
*		TJL 03/31/03 - Issue #20832, If Released Retg Invoice equals 0.00, give more user friendly msg.
*		TJL 01/18/04 - Issue #23477, Insert correct GLCo and GLRevAccount on the Released Retainage Invoice.
*		TJL 02/03/04 - Issue #23642, Insert TaxGroup on the Released Retainage Invoice
*		TJL 03/04/04 - Issue #23961, Reset Batch Lines on Customer Change
*		TJL 08/22/05 - Issue #28627, Remove unused code causing error when setting @retgpct
*		TJL 10/07/05 - Issue #29624, Correct GL Dist to use Form (New) RecType when distributing Debit to GLARAcct
*		TJL 02/26/07 - Issue #120561, Made adjustment pertaining to bHQCC Close Control entry handling
*		TJL 02/12/08 - Issue #126898, Allow Release Retg process to continue when Contract has been purged from JC
*		TJL 03/12/08 - Issue #126769, If ARCO Release Retg to AR is uncheck, Do not reduce JCID Retainage bucket
*		TJL 07/01/08 - Issue #128371, AR Release International Sales Tax
*		TJL 01/25/09 - Issue #132000, GLAcct amounts doubled when ARCompany "Post Taxes On Invoices" off.
*		TJL 02/27/09 - Issue #132354, TaxCode on Release (1st R) but not on Released (2nd R) transaction.
*		TJL 04/28/09 - Issue #132992, Contract allowed without JCCo. Causes Posting error
*		TJL 06/02/09 - Issue #133561, Do not generate RetgTax when no TaxCode on Contract Invoice & no TaxCode on Contract
*		MV	02/04/10 - Issue #136500 - bspHQTaxRateGetAll added NULL output param
*		MV	10/25/11 - TK-09243 - bspHQTaxRateGetAll added NULL output param
*
* USAGE:
* Validates each entry in bARBH and bARBL for a selected batch - must be called
* prior to posting the batch.
*
* After initial Batch and AR checks, bHQBC Status set to 1 (validation in progress)
* bHQBE (Batch Errors), (JC Detail Audit)
* entries are deleted.
*
* Creates a cursor on bARBH to validate each entry individually, then a cursor on bARBL for
* each item for the header record.
*
* Errors in batch added to bHQBE using bspHQBEInsert
* Job distributions added to
* GL Account distributions added to
*
* GL debit and credit totals must balance.
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
***************************************************************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource, @errmsg varchar(255) output
as
set nocount on
declare @rcode int, @cnt int, @errortext varchar(255), @seq int, @no_linecount int,
  	@status tinyint,@TmpCustomer varchar(15),@ReturnCustomer bCustomer, @artrans bTrans, @ARLine smallint,
  	@errorstart varchar(50), @i int, @errorAccount varchar(25), @transtype char(1), @artranstype char(1),
  	@custgroup bGroup, @SortName varchar(15), @customer bCustomer, @jcco bCompany, @AR_glco int,
  	@paymentjrnl bJrnl, @glpaylvl int, @itemglco bCompany, @Contract bContract, @ContractStatus int, @contstatus tinyint, 
   	@ContractItem bContractItem, @zero_jcco bCompany, @zero_contract bContract, @zero_item bContractItem,
   	@invoice char(10), @description bDesc, @transdate bDate, @RecType tinyint, @DueDate bDate,
	@Amount bDollar, @Retainage bDollar, @SumLineRetainage bDollar, @retgpct bPct, @PostAmount bDollar, 
   	@PostGLCo bCompany, @PostGLAcct bGLAcct, @GLARAcct bGLAcct, @GLRetainAcct bGLAcct,
   	@ncglco bCompany, @ncglrevacct bGLAcct,  @itemopenglrevacct bGLAcct, @itemcloseglrevacct bGLAcct,
   	@itemglrevacct bGLAcct, @releasetocurrent bYN, @retg_apply_line smallint, @applymth bMonth, 
   	@applytrans bTrans, @originvcustgrp bGroup, @originvcustomer bCustomer

/* International Sales Tax */
declare @arcotaxretg bYN, @arcoseparateretgtax bYN, @posttaxoninv bYN, @interfacetaxjc bYN		--AR Company flags, JC Contract flags

declare @origtransdate bDate, @LineRetgTax bDollar, @bogus int,
	@taxrate bRate, @gstrate bRate, @pstrate bRate, @newtaxrate bRate, @newgstrate bRate, @newpstrate bRate, 
	@HQTXcrdGLAcct bGLAcct, @HQTXcrdRetgGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct, @HQTXcrdRetgGLAcctPST bGLAcct,
	@newHQTXcrdGLAcct bGLAcct, @newHQTXcrdRetgGLAcct bGLAcct, @newHQTXcrdGLAcctPST bGLAcct, @newHQTXcrdRetgGLAcctPST bGLAcct,
	@TaxAmount bDollar, @RetgTax bDollar, @TaxAmountPST bDollar, @RetgTaxPST bDollar, 
	@newTaxAmount bDollar, @newRetgTax bDollar, @newTaxAmountPST bDollar, @newRetgTaxPST bDollar,
	@calculatedLineRetgTax bDollar, @amountrel bDollar, @taxamountrel bDollar, @retainagerel bDollar, @retgtaxrel bDollar
	 
declare	@HQCOtaxgroup bGroup, @ARBLtaxgroup bGroup, @ARBLtaxcode bTaxCode, @itemtaxgroup bGroup, @itemtaxcode bTaxCode,  -----
	@newtaxgroup bGroup, @newtaxcode bTaxCode, @custtaxcode bTaxCode 

/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'ARRelease', 'ARBH', @errmsg output, @status output
if @rcode <> 0
  	begin
  	select @errmsg = @errmsg, @rcode = 1
  	goto bspexit
  	end
   
if @status < 0 or @status > 3
  	begin
  	select @errmsg = 'Invalid Batch status', @rcode = 1
  	goto bspexit
  	end
  
/* set HQ Batch status to 1 (validation in progress) */
update bHQBC
set Status = 1
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
  	begin
  	select @errmsg = 'Unable to update HQ Batch Control status', @rcode = 1
  	goto bspexit
  	end
   
/* clear HQ Batch Errors */
delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid

/* clear JC Revenue Distributions Audit */
delete bARBI where ARCo = @co and Mth = @mth and BatchId = @batchid

/* clear GL Distribution list */
delete bARBA where Co = @co and Mth = @mth and BatchId = @batchid

/* clear the bARBL list for this trans */
delete bARBL where Co = @co and Mth = @mth and BatchId = @batchid and ARLine > 9999

/* get some company specific variables and do some validation*/
/*need to validate GLFY and GLJR if gl is going to be updated*/
select @releasetocurrent = a.RelRetainOpt, @paymentjrnl = a.PaymentJrnl, @glpaylvl = a.GLPayLev, 
  	@AR_glco = a.GLCo, @HQCOtaxgroup = h.TaxGroup, @arcotaxretg = a.TaxRetg, @arcoseparateretgtax = a.SeparateRetgTax,
	@posttaxoninv = a.InvoiceTax
from bARCO a with (nolock)
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where a.ARCo = @co

if @glpaylvl > 1
  	begin
  	exec @rcode = bspGLJrnlVal @AR_glco, @paymentjrnl, @errmsg output
  	if @rcode <> 0
  		begin
  	   	select @errortext = 'Payment Journal (' + isnull(RTrim(@paymentjrnl),'') +
                         ') is invalid. A valid journal must be setup in AR Company.'
      	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	   	if @rcode <> 0 goto bspexit
      	end
  	end
   
/***************************************/
/* AR Header Batch loop for validation */
/***************************************/
select @seq=Min(BatchSeq)
from bARBH with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid
while @seq is not null
  	begin
   	/* read batch header */
   	select @transtype=h.TransType, @artrans=h.ARTrans, @invoice=h.Invoice,
  		@source=h.Source, @artranstype=h.ARTransType, @custgroup=h.CustGroup, @customer=h.Customer,
  		@jcco=h.JCCo, @Contract=h.Contract, @transdate=h.TransDate, @RecType = h.RecType, @DueDate =h.DueDate,
		@custtaxcode = c.TaxCode
   	from bARBH h with (nolock)
	join bARCM c with (nolock) on c.CustGroup = h.CustGroup and c.Customer = h.Customer
   	where Co=@co and Mth=@mth and BatchId=@batchid and @seq=h.BatchSeq
   
   	select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
   
   	/* need to get the sortname for GL description purposes */
   	select @SortName = SortName
   	from bARCM with (nolock)
   	where CustGroup = @custgroup and Customer = @customer
   
   	if @transtype <> 'A'
      	begin
  	   	select @errortext = @errorstart + ' - invalid transaction type, must be (A)'
  	   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	   	if @rcode <> 0 goto bspexit
  	   	end
   
   	/* validation specific to ADD AR header */
   	if @transtype = 'A'
      	begin
      	if @artranstype = 'R'
			BEGIN
   			/* validate presence of an Invoice number.  We are just looking for the existence
   			  of an invoice number here.  The form has already checked for uniqueness or not
   			  and has given the appropriate warnings. */
   			if isnull(@invoice,'') = ''
   				begin
   				select @errortext = @errorstart + ' - Invoice number may not be NULL!'
   				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output			
   				if @rcode <> 0 goto bspexit
   				end
   	
      	 	/* validate customer */
            	select @TmpCustomer = convert(varchar(15),@customer)
            	exec @rcode = bspARCustomerVal @custgroup, @TmpCustomer, NULL, @ReturnCustomer output, @errmsg output
            	if @rcode <> 0
  	       		BEGIN
  	       		select @errortext = @errorstart + ' - Customer ' + isnull(convert(varchar(10),@customer),'') + ' is not valid!'
  	  	   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		   		if @rcode <> 0 goto bspexit
  	       		END
   
      		/* validate JCCo */
      		if @jcco is not null
      			begin
      	    	exec @rcode = bspJCCompanyVal @jcco, @errmsg output
      			if @rcode <> 0
      		    	begin
      		    	select @errortext = @errorstart + '- JCCo:' + isnull(convert (varchar(3),@jcco),'') +': ' + isnull(@errmsg,'')
      		   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		     	if @rcode <> 0 goto bspexit
      		     	end
   
      		 	select @errmsg = NULL
      		  	end
   
			if @Contract is not null and @jcco is null
				begin
      			select @errortext = @errorstart + 'Missing JCCo. JCCo required when Contract is used.'
      			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			if @rcode <> 0 goto bspexit
				end

			/* validate Contract */
			if @jcco is not null and @Contract is not null
				begin
				select 1
				from bJCCM with (nolock)
				where JCCo = @jcco and Contract = @Contract
				if @@rowcount = 0
					begin
      				select @errortext = @errorstart + '- Contract:' + @Contract +': ' + 'Not a valid contract.'
      		   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      				if @rcode <> 0 goto bspexit
					end
				end

  		 	/* Validate Receivable Form Type */
  		 	exec @rcode = bspRecTypeVal @co, @RecType, @errmsg output
  		 	if isnull(@RecType,0) = 0 select @rcode = 1
  		 	if @rcode <> 0
  		   		begin
  		   		select @errortext = @errorstart + '- Receivable Type:' + isnull(convert(varchar(3),@RecType),'')+ isnull(@errmsg,'')
  		   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		   		if @rcode <> 0 goto bspexit
  		   		end
  			else
  				begin
  				select @GLARAcct = bARRT.GLARAcct
  				from bARRT with (nolock)
  				where ARCo = @co and RecType = @RecType
  				end
   
            	select @errmsg = NULL
      	 	END /*transtype = R */
   
		end /*Transtype = A */
   
  	/*********************************************************************************************/
	/* Now need to spin through the lines for this header.  At this point we will deal only with */
	/* the 'Release' transaction.  This is the transaction whose lines will apply against the    */
	/* various invoices (There can be multiple) that retainage is being release from.			 */
	/*********************************************************************************************/
   	select @no_linecount = 0
  
   	select @ARLine = Min(ARLine)
   	from bARBL l with (nolock)
  	where Co = @co and Mth = @mth and BatchId= @batchid and BatchSeq= @seq and ARLine < 10000
   
   	if @ARLine is null
		begin
      	/* if no retainage has been released, no lines will have been inserted into ARBL */
      	select @errortext = @errorstart + ' - No lines exists for this header.'
      	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	if @rcode <> 0 goto bspexit
		select @no_linecount = 1
      	end
   
   	while @ARLine is not null
      	BEGIN
		/* Reset Line variables as needed here.  
 		   Retrieved as each Lines TaxCode gets validated.  Reset to avoid leftover value when TaxCode is invalid */
		select @HQTXcrdGLAcct = null, @HQTXcrdRetgGLAcct = null, @HQTXcrdGLAcctPST = null, @HQTXcrdRetgGLAcctPST = null,
			@newHQTXcrdGLAcct = null, @newHQTXcrdRetgGLAcct = null, @newHQTXcrdGLAcctPST = null, @newHQTXcrdRetgGLAcctPST = null,
			@TaxAmount = 0,	@TaxAmountPST = 0, @RetgTax = 0, @RetgTaxPST = 0,
			@newTaxAmount = 0,	@newTaxAmountPST = 0, @newRetgTax = 0, @newRetgTaxPST = 0,
			@taxrate = 0, @gstrate = 0, @pstrate = 0, @newtaxrate = 0, @newgstrate = 0, @newpstrate = 0, 
			@calculatedLineRetgTax = 0, @amountrel = 0, @taxamountrel = 0, @retainagerel = 0, @retgtaxrel = 0,
			@ARBLtaxgroup = null, @ARBLtaxcode = null, @itemtaxgroup = null, @itemtaxcode = null,
			@newtaxgroup = null, @newtaxcode = null

  	   	/* get GL Company and GLAcct from line along with other information. */
  	   	select @Amount = l.Amount, @Retainage = l.Retainage, @LineRetgTax = l.RetgTax,
  	    	@jcco = l.JCCo, @Contract = l.Contract, @ContractItem = l.Item, @description = l.Description,
  			@GLRetainAcct = r.GLRetainAcct, @applymth = l.ApplyMth, @applytrans = l.ApplyTrans,
			@ARBLtaxgroup = l.TaxGroup, @ARBLtaxcode = l.TaxCode, @origtransdate = th.TransDate
  	   	from bARBL l with (nolock)
		join bARTH th with (nolock) on th.ARCo = l.Co and th.Mth = l.ApplyMth and th.ARTrans = l.ApplyTrans
  	   	join bARRT r with (nolock) on r.ARCo = l.Co and r.RecType = l.RecType
  	   	where l.Co = @co and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @seq and l.ARLine = @ARLine

   		/****** LINE VALIDATION, RETRIEVE TAXCODE AMOUNTS ******/
   		if @transtype = 'A'
   	   	   	begin	/* Begin Line Validation */
   	       	if @artranstype = 'R'
   	         	begin
				/* This check cannot be done at the Header level because ApplyMth and ApplyTrans do not exist.
				   A single 'Release' transaction may cover multiple invoices and no single Header ApplyMth, ApplyTrans
				   applies until you get to the line level.  This check then becomes valid. */
   				select @originvcustgrp = CustGroup, @originvcustomer = Customer
   				from bARTH with (nolock)
   				where ARCo = @co and Mth = @applymth and ARTrans = @applytrans
   
   				if (@customer <> @originvcustomer) or (@custgroup <> @originvcustgrp)
   					begin
   	   	       		select @errortext = @errorstart + ' - Customer ' + isnull(convert(varchar(10),@originvcustomer),'') 
   					select @errortext = @errortext + ' is not Correct! One or more lines are associated with a different Customer.'
   	   	  	   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	   		   		if @rcode <> 0 goto bspexit
   					end

				if @posttaxoninv = 'N' or (@posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N'))
					begin	/* Begin Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
					/* No special setup required.  @Amount and @Retainage values already retrieved above. */
					select @newtaxgroup = isnull(@ARBLtaxgroup, @HQCOtaxgroup)
					select @newtaxcode = @ARBLtaxcode
					end		/* End Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'Y')
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
					/* Line TaxCode validation and info retrieval */
					if isnull(@LineRetgTax, 0) <> 0 and @ARBLtaxcode is null
						begin
						select @errortext = @errorstart + 'Line ' + isnull(convert(varchar(6),@ARLine),'') + 
							' must contain a TaxCode when tax amounts are not 0.00.'
						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						if @rcode <> 0 goto bspexit
						end
	   
					/*Validate Line Tax Group if there is a tax code */
					if @ARBLtaxcode is not null
						begin
						if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @co  and TaxGroup = @ARBLtaxgroup)
   							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @ARBLtaxgroup),'')
							select @errortext = @errorstart + ' - is not valid!'
							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end
						end
		   
					/* Validate Line TaxCode by getting the accounts for the tax code */
					if @ARBLtaxcode is not null
						begin
						exec @rcode = bspHQTaxRateGetAll @ARBLtaxgroup, @ARBLtaxcode, @origtransdate, null, @taxrate output, @gstrate output, @pstrate output, 
							@HQTXcrdGLAcct output, @HQTXcrdRetgGLAcct output, null, null, @HQTXcrdGLAcctPST output, 
							@HQTXcrdRetgGLAcctPST output, NULL, NULL,@errmsg output

						if @rcode <> 0
   							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @ARBLtaxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@ARBLtaxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						if @pstrate = 0
							begin
							/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
							   In any case:
							   a)  @taxrate is the correct value.  
							   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
							   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
							select @RetgTax = isnull(@LineRetgTax,0)
							end
						else
							begin
							/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
							if @taxrate <> 0
								begin
								select @RetgTax = (isnull(@LineRetgTax,0) * @gstrate) / @taxrate	--GST RetgTax
								select @RetgTaxPST = isnull(@LineRetgTax,0) - @RetgTax				--PST RetgTax
								end
							end
						end 
					/* End Line TaxCode validation and info retrieval */

					/* NEW TaxCode validation and info retrieval */
					if @jcco is not null and @Contract is not null and @ContractItem is not null
						begin
						/* Contract, ContractItem exists on this line.  Use Item TaxCode OR Line TaxCode to calculate NEW Retainage
						   tax amounts about to be released. */
						select @itemtaxgroup = isnull(TaxGroup, @ARBLtaxgroup), @itemtaxcode = isnull(TaxCode, @ARBLtaxcode)
						from bJCCI with (nolock)
						where JCCo = @jcco and Contract = @Contract and Item = @ContractItem

						if isnull(@LineRetgTax, 0) <> 0 and @itemtaxcode is null
							begin
							select @errortext = @errorstart + 'TaxCode must exist on Contract Item or original Invoice Line	to properly post NEW Released retainage tax amounts to GL. '
							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end
	   
						/*Validate Item Tax Group if there is a tax code */
						if @itemtaxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @co  and TaxGroup = @itemtaxgroup)
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @itemtaxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end
							
						select @newtaxgroup = @itemtaxgroup, @newtaxcode = @itemtaxcode
						end
					else
						begin
						/* When Contract is NULL, NEW TaxCode information must must come from another source.  Because ALL non-contract lines
						   are combined into a single line on the new 'Released' invoice, its best to use the Customer TaxCode values
						   first followed by individual Line values.  (Releasing Retg in AR in this manner is very rare if at all.) */
						select @newtaxgroup = isnull(@HQCOtaxgroup, @ARBLtaxgroup), @newtaxcode = isnull(@custtaxcode, @ARBLtaxcode)

						if isnull(@LineRetgTax, 0) <> 0 and @newtaxcode is null
							begin
							select @errortext = @errorstart + 'TaxCode must exist on Customer or original Invoice Line
									to properly post NEW Released retainage tax amounts to GL. '
							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end
		   
						/*Validate Item Tax Group if there is a tax code */
						if @newtaxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @co  and TaxGroup = @newtaxgroup)
   								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @newtaxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end
						end

					if @newtaxcode is not null
						begin
						/* Get NEW TaxCode information and rates */
						exec @rcode = bspHQTaxRateGetAll @newtaxgroup, @newtaxcode, @transdate, null, @newtaxrate output, @newgstrate output, @newpstrate output, 
							@newHQTXcrdGLAcct output, @newHQTXcrdRetgGLAcct output, null, null, @newHQTXcrdGLAcctPST output, 
							@newHQTXcrdRetgGLAcctPST output,NULL,NULL,@errmsg output

						if @rcode <> 0
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @newtaxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@newtaxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						if @newtaxrate <> @taxrate
							begin
							/* Old vs New Tax Rates are different due to different Tax Code or new effective date.  We must
							   calculate new retainage tax values. */
							if @newpstrate = 0
								begin
								/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
								   In any case:
								   a)  @taxrate is the correct value.  
								   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
								   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
								select @newRetgTax = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) * @newtaxrate
								end
							else
								begin
								/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
								if @newtaxrate <> 0
									begin
									select @calculatedLineRetgTax = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) * @newtaxrate
									select @newRetgTax = (@calculatedLineRetgTax * @newgstrate) / @newtaxrate	-- New GST RetgTax
									select @newRetgTaxPST = @calculatedLineRetgTax - @newRetgTax				-- New PST RetgTax
									end
								end
							end
						else
							begin
							/* Old Tax Rate is same as New Tax Rate.  To avoid rounding errors simply use Retainage Tax values
							   directly from Line. */
							select @newRetgTax = @RetgTax
							select @newRetgTaxPST = @RetgTaxPST
							end
						end
					/* End Item (New) TaxCode validation and info retrieval */
					end	/* End International Release Retainage distribution.  Retainage already taxed, now report separately.  */

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'N' and @arcoseparateretgtax = 'N')
					begin	/* Begin International Release Retainage distribution.  Tax Retainage at this time. */
					/* NEW TaxCode validation and info retrieval */
					if @jcco is not null and @Contract is not null and @ContractItem is not null
						begin
						/* Contract, ContractItem exists on this line.  Use Item TaxCode information.  Line and Customer TaxCode values are better
						   then nothing but not ideal.  */
						select @itemtaxgroup = isnull(TaxGroup, @ARBLtaxgroup), @itemtaxcode = isnull(TaxCode, @ARBLtaxcode)
						from bJCCI with (nolock)
						where JCCo = @jcco and Contract = @Contract and Item = @ContractItem

						--if @itemtaxcode is null
						--	begin
						--	select @errortext = @errorstart + 'TaxCode must exist on Contract Item, original Invoice Line, or Customer
						--		to properly post NEW Released retainage tax amounts to GL. '
						--	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						--	if @rcode <> 0 goto bspexit
						--	end

						/*Validate Item Tax Group if there is a tax code */
						if @itemtaxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @co  and TaxGroup = @itemtaxgroup)
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @itemtaxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end
						
						select @newtaxgroup = @itemtaxgroup, @newtaxcode = @itemtaxcode
						end
					else
						begin
						/* When Contract is NULL, NEW TaxCode information must must come from another source.  Because ALL non-contract lines
						   are combined into a single line on the new 'Released' invoice, its best to use the Customer TaxCode values
						   first followed by individual Line values.  (Releasing Retg in AR in this manner is very rare if at all.) */
						select @newtaxgroup = isnull(@HQCOtaxgroup, @ARBLtaxgroup), @newtaxcode = isnull(@custtaxcode, @ARBLtaxcode)

						--if @newtaxcode is null
						--	begin
						--	select @errortext = @errorstart + 'TaxCode must exist on Customer or original Invoice Line
						--			to properly post NEW Released retainage tax amounts to GL. '
						--	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						--	if @rcode <> 0 goto bspexit
						--	end				

						/*Validate Item Tax Group if there is a tax code */
						if @newtaxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @co  and TaxGroup = @newtaxgroup)
   								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @newtaxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end
						end

					if @newtaxcode is not null
						begin
						/* Get NEW TaxCode information and rates */
						exec @rcode = bspHQTaxRateGetAll @newtaxgroup, @newtaxcode, @transdate, null, @newtaxrate output, @newgstrate output, @newpstrate output, 
							@newHQTXcrdGLAcct output, @newHQTXcrdRetgGLAcct output, null, null, @newHQTXcrdGLAcctPST output, 
							@newHQTXcrdRetgGLAcctPST output,NULL,NULL,@errmsg output

						if @rcode <> 0
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @newtaxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@newtaxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						if @newpstrate = 0
							begin
							/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
							   In any case:
							   a)  @taxrate is the correct value.  
							   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
							   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
							select @newRetgTax = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) * @newtaxrate	--@LineRetgTax should be 0.00 here
							end
						else
							begin
							/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
							if @newtaxrate <> 0
								begin
								select @calculatedLineRetgTax = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) * @newtaxrate	--@LineRetgTax should be 0.00 here
								select @newRetgTax = (@calculatedLineRetgTax * @newgstrate) / @newtaxrate	-- New GST RetgTax
								select @newRetgTaxPST = @calculatedLineRetgTax - @newRetgTax				-- New PST RetgTax
								end
							end	
						end
					/* End Item (New) TaxCode validation and info retrieval */
					end		/* End International Release Retainage distribution.  Tax Retainage at this time. */
   				end
   			end		/* End Line Validation */
   
		/****** GL DISTRIBUTIONS ******/
		if @posttaxoninv = 'N' or (@posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N'))
			begin	/* Begin Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
  	   		if @releasetocurrent = 'Y'
  	     		begin
  	     		select @i=1 /*set first account */
  	     		while @i<=2
  	       			begin
   	   				/*Validate GL Accounts*/
      	   			/* spin through each type of GL account, check it and write GL Amount */
  		   			select @PostGLAcct = NULL, @PostAmount = 0
	  
  		   			/* AR Receivable Account - From RecType input on Release Form */
  		   			if @i=1 select @PostGLCo = @AR_glco, @PostGLAcct = @GLARAcct, @PostAmount = isnull(@Retainage,0),
  						@errorAccount = 'AR Receivable Account'
	  
         			/* Retainage Receivable Account - From original invoice line RecType */
      	     		if @i=2 select @PostGLCo = @AR_glco, @PostGLAcct = @GLRetainAcct, @PostAmount = -(isnull(@Retainage,0)), 
  						@errorAccount = 'AR Retainage Account'

					if @PostAmount <> 0
						begin
  		 				/* Lets first try to update to see if this GLAcct is already in batch */
  		 				update bARBA
          				set  ARTrans = @artrans, ARLine = @ARLine, ARTransType = @artranstype, Customer = @customer, 
  							SortName = @SortName, CustGroup = @custgroup, Invoice = @invoice, Contract = @Contract,
  							ContractItem = @ContractItem, ActDate = @transdate, Description = @description, 
  							Amount = @PostAmount + Amount
  						where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo and
  				 			GLAcct = @PostGLAcct and BatchSeq = @seq and OldNew = 0
		  
  						if @@rowcount = 0   /* If record is not already there then lets try to insert it */
   		 					begin
         	   				exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, 'R', @errmsg output
          	   				if @rcode <> 0
              					begin
              	   				select @errortext = @errorstart + '  GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
                  				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                  				if @rcode <> 0 goto bspexit
                  				end
		  
    		 				insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine,
  								ARTransType, Customer, SortName, CustGroup, Invoice, Contract,
  					  			ContractItem, ActDate, Description, Amount)
  							values(@co, @mth, @batchid, @PostGLCo, @PostGLAcct, @seq, 0, @artrans, @ARLine,
  			        			@artranstype, @customer, @SortName, @custgroup, @invoice, @Contract,
  			        			@ContractItem, @transdate, @description, @PostAmount)
		  
          	 				if @@rowcount = 0
              					begin
              					select @errmsg = 'Unable to add AR Detail audit - ' + @errortext , @rcode = 1
              					GoTo bspexit
              					end

							/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
							if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo)
   								begin
   								insert bHQCC (Co, Mth, BatchId, GLCo)
   								values (@co, @mth, @batchid, @PostGLCo)
   								end
            				end
						end

      	   			/* get next GL record */
          			select @i=@i+1, @errmsg=''
  	     			end /* gl accounts */
				
				select @amountrel = isnull(@Retainage,0)
				select @taxamountrel = 0
				select @retainagerel = 0
				select @retgtaxrel = 0
				exec @rcode = vspARBLSetReleased @co, @mth, @batchid, @seq, @jcco, @Contract, @ContractItem,
					@amountrel, @taxamountrel, @retainagerel, @retgtaxrel, @artrans, @RecType, @newtaxgroup, @newtaxcode,
					@errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					goto bspexit
					end
  	   			end	/* End Release to AR = Y */
			else
				begin
				select @amountrel = isnull(@Retainage,0)
				select @taxamountrel = 0
				select @retainagerel = isnull(@Retainage,0)
				select @retgtaxrel = 0
				exec @rcode = vspARBLSetReleased @co, @mth, @batchid, @seq, @jcco, @Contract, @ContractItem,
					@amountrel, @taxamountrel, @retainagerel, @retgtaxrel, @artrans, @RecType, @newtaxgroup, @newtaxcode,
					@errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					goto bspexit
					end
				end	/* End Release to AR = N */
			end		/* End Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */

		if @posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'Y')
			begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
  	   		if @releasetocurrent = 'Y'
   	     		begin
  	     		select @i=1 /*set first account */
  	     		while @i<=6
  	       			begin
   	   				/*Validate GL Accounts*/
      	   			/* spin through each type of GL account, check it and write GL Amount */
  		   			select @PostGLAcct = NULL, @PostAmount = 0
	  
  		   			/* AR Receivable Account - From RecType input on Release Form */
  		   			if @i=1 select @PostGLCo = @AR_glco, @PostGLAcct = @GLARAcct, 
						@PostAmount = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) + (@newRetgTax + @newRetgTaxPST), 
  						@errorAccount = 'AR Receivable Account'
	  
         			/* Retainage Receivable Account - From original invoice line RecType */
      	     		if @i=2 select @PostGLCo = @AR_glco, @PostGLAcct = @GLRetainAcct, @PostAmount = -(isnull(@Retainage,0)), 
  						@errorAccount = 'AR Retainage Account'

  					/* Tax account.  Standard US or GST */
  					if @i=3 select @PostGLCo=@AR_glco, @PostGLAcct=@newHQTXcrdGLAcct, @PostAmount = -(@newRetgTax),
						@errorAccount = 'AR Tax Account'
   
  					/* Tax account.  PST */
  					if @i=4 select @PostGLCo=@AR_glco, @PostGLAcct=@newHQTXcrdGLAcctPST, @PostAmount = -(@newRetgTaxPST),
						@errorAccount = 'AR Tax Account PST'

  					/* Retainage Tax account.  Standard US or GST */
  					if @i=5 select @PostGLCo=@AR_glco, @PostGLAcct=@HQTXcrdRetgGLAcct, @PostAmount = @RetgTax,
						@errorAccount = 'AR Retg Tax Account'

  					/* Retainage Tax account.  PST */
  					if @i=6 select @PostGLCo=@AR_glco, @PostGLAcct=@HQTXcrdRetgGLAcctPST, @PostAmount = @RetgTaxPST,
						@errorAccount = 'AR Retg Tax Account PST'

					if @PostAmount <> 0
						begin
  		 				/* Lets first try to update to see if this GLAcct is already in batch */
  		 				update bARBA
          				set  ARTrans = @artrans, ARLine = @ARLine, ARTransType = @artranstype, Customer = @customer, 
  							SortName = @SortName, CustGroup = @custgroup, Invoice = @invoice, Contract = @Contract,
  							ContractItem = @ContractItem, ActDate = @transdate, Description = @description, 
  							Amount = @PostAmount + Amount
  						where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo and
  				 			GLAcct = @PostGLAcct and BatchSeq = @seq and OldNew = 0
		  
  						if @@rowcount = 0   /* If record is not already there then lets try to insert it */
   		 					begin
         	   				exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, 'R', @errmsg output
          	   				if @rcode <> 0
              					begin
              	   				select @errortext = @errorstart + '  GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
                  				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                  				if @rcode <> 0 goto bspexit
                  				end
		  
    		 				insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine,
  								ARTransType, Customer, SortName, CustGroup, Invoice, Contract,
  					  			ContractItem, ActDate, Description, Amount)
  							values(@co, @mth, @batchid, @PostGLCo, @PostGLAcct, @seq, 0, @artrans, @ARLine,
  			        			@artranstype, @customer, @SortName, @custgroup, @invoice, @Contract,
  			        			@ContractItem, @transdate, @description, @PostAmount)
		  
          	 				if @@rowcount = 0
              					begin
              					select @errmsg = 'Unable to add AR Detail audit - ' + @errortext , @rcode = 1
              					GoTo bspexit
              					end

							/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
							if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo)
   								begin
   								insert bHQCC (Co, Mth, BatchId, GLCo)
   								values (@co, @mth, @batchid, @PostGLCo)
   								end
            				end
						end

      	   			/* get next GL record */
          			select @i=@i+1, @errmsg=''
  	     			end /* gl accounts */

				select @amountrel = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) + (@newRetgTax + @newRetgTaxPST)
				select @taxamountrel = @newRetgTax + @newRetgTaxPST
				select @retainagerel = 0
				select @retgtaxrel = 0
				exec @rcode = vspARBLSetReleased @co, @mth, @batchid, @seq, @jcco, @Contract, @ContractItem,
					@amountrel, @taxamountrel, @retainagerel, @retgtaxrel, @artrans, @RecType, @newtaxgroup, @newtaxcode,
					@errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					--goto bspexit
					end
  	   			end	/* End Release to AR = Y */
			else
				begin	/* Begin Release to AR = N */
  	     		select @i=1 /*set first account */
  	     		while @i<=6
  	       			begin
   	   				/*Validate GL Accounts*/
      	   			/* spin through each type of GL account, check it and write GL Amount */
  		   			select @PostGLAcct = NULL, @PostAmount = 0
	  
         			/* Retainage Receivable Account - From original invoice line RecType */
      	     		if @i=1 select @PostGLCo = @AR_glco, @PostGLAcct = @GLRetainAcct, @PostAmount = -(isnull(@Retainage,0)), 
--						@PostAmount = case when isnull(@LineRetgTax,0) <> (@newRetgTax + @newRetgTaxPST) 
--							then -(isnull(@Retainage,0)) else 0 end, 
  						@errorAccount = 'AR Retainage Account'

         			/* Retainage Receivable Account - From original invoice line RecType */
      	     		if @i=2 select @PostGLCo = @AR_glco, @PostGLAcct = @GLRetainAcct, 
						@PostAmount = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) + (@newRetgTax + @newRetgTaxPST), 
--						@PostAmount = case when isnull(@LineRetgTax,0) <> (@newRetgTax + @newRetgTaxPST) 
--							then (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) + (@newRetgTax + @newRetgTaxPST) else 0 end, 
  						@errorAccount = 'AR Retainage Account'

  					/* Retainage Tax account.  Standard US or GST */
  					if @i=3 select @PostGLCo=@AR_glco, @PostGLAcct=@HQTXcrdRetgGLAcct, @PostAmount = @RetgTax, 
--						@PostAmount = case when isnull(@LineRetgTax,0) <> (@newRetgTax + @newRetgTaxPST) 
--							then @RetgTax else 0 end, 
						@errorAccount = 'AR Retg Tax Account'

  					/* Retainage Tax account.  Standard US or GST */
  					if @i=4 select @PostGLCo=@AR_glco, @PostGLAcct=@newHQTXcrdRetgGLAcct, @PostAmount = -(@newRetgTax), 
--						@PostAmount = case when isnull(@LineRetgTax,0) <> (@newRetgTax + @newRetgTaxPST) 
--							then -(@newRetgTax) else 0 end, 
						@errorAccount = 'AR Retg Tax Account'

  					/* Retainage Tax account.  PST */
  					if @i=5 select @PostGLCo=@AR_glco, @PostGLAcct=@HQTXcrdRetgGLAcctPST, @PostAmount = @RetgTaxPST, 
--						@PostAmount = case when isnull(@LineRetgTax,0) <> (@newRetgTax + @newRetgTaxPST) 
--							then @RetgTaxPST else 0 end, 
						@errorAccount = 'AR Retg Tax Account PST'

  					/* Retainage Tax account.  PST */
  					if @i=6 select @PostGLCo=@AR_glco, @PostGLAcct=@newHQTXcrdRetgGLAcctPST, @PostAmount = -(@newRetgTaxPST), 
--						@PostAmount = case when isnull(@LineRetgTax,0) <> (@newRetgTax + @newRetgTaxPST) 
--							then -(@newRetgTaxPST) else 0 end, 
						@errorAccount = 'AR Retg Tax Account PST'

					if @PostAmount <> 0
						begin
  		 				/* Lets first try to update to see if this GLAcct is already in batch */
  		 				update bARBA
          				set  ARTrans = @artrans, ARLine = @ARLine, ARTransType = @artranstype, Customer = @customer, 
  							SortName = @SortName, CustGroup = @custgroup, Invoice = @invoice, Contract = @Contract,
  							ContractItem = @ContractItem, ActDate = @transdate, Description = @description, 
  							Amount = @PostAmount + Amount
  						where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo and
  				 			GLAcct = @PostGLAcct and BatchSeq = @seq and OldNew = 0
		  
  						if @@rowcount = 0   /* If record is not already there then lets try to insert it */
   		 					begin
         	   				exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, 'R', @errmsg output
          	   				if @rcode <> 0
              					begin
              	   				select @errortext = @errorstart + '  GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
                  				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                  				if @rcode <> 0 goto bspexit
                  				end
		  
    		 				insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine,
  								ARTransType, Customer, SortName, CustGroup, Invoice, Contract,
  					  			ContractItem, ActDate, Description, Amount)
  							values(@co, @mth, @batchid, @PostGLCo, @PostGLAcct, @seq, 0, @artrans, @ARLine,
  			        			@artranstype, @customer, @SortName, @custgroup, @invoice, @Contract,
  			        			@ContractItem, @transdate, @description, @PostAmount)
		  
          	 				if @@rowcount = 0
              					begin
              					select @errmsg = 'Unable to add AR Detail audit - ' + @errortext , @rcode = 1
              					GoTo bspexit
              					end

							/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
							if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo)
   								begin
   								insert bHQCC (Co, Mth, BatchId, GLCo)
   								values (@co, @mth, @batchid, @PostGLCo)
   								end
            				end
						end

      	   			/* get next GL record */
          			select @i=@i+1, @errmsg=''
  	     			end /* gl accounts */

				select @amountrel = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) + (@newRetgTax + @newRetgTaxPST)
				select @taxamountrel = 0
				select @retainagerel = (isnull(@Retainage,0) - isnull(@LineRetgTax,0)) + (@newRetgTax + @newRetgTaxPST)
				select @retgtaxrel = @newRetgTax + @newRetgTaxPST
				exec @rcode = vspARBLSetReleased @co, @mth, @batchid, @seq, @jcco, @Contract, @ContractItem,
					@amountrel, @taxamountrel, @retainagerel, @retgtaxrel, @artrans, @RecType, @newtaxgroup, @newtaxcode,
					@errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					goto bspexit
					end
				end		/* End Release to AR = N */
			end		/* End International Release Retainage distribution.  Retainage already taxed, now report separately.  */

		if @posttaxoninv = 'Y' and (@arcotaxretg = 'N' and @arcoseparateretgtax = 'N')
			begin	/* Begin International Release Retainage distribution.  Tax Retainage at this time. */
  	   		if @releasetocurrent = 'Y'
   	     		begin
  	     		select @i=1 /*set first account */
  	     		while @i<=4
  	       			begin
   	   				/*Validate GL Accounts*/
      	   			/* spin through each type of GL account, check it and write GL Amount */
  		   			select @PostGLAcct = NULL, @PostAmount = 0
	  
  		   			/* AR Receivable Account - From RecType input on Release Form */
  		   			if @i=1 select @PostGLCo = @AR_glco, @PostGLAcct = @GLARAcct, 
						@PostAmount = isnull(@Retainage,0) + (@newRetgTax + @newRetgTaxPST), 
  						@errorAccount = 'AR Receivable Account'
	  
         			/* Retainage Receivable Account - From original invoice line RecType */
      	     		if @i=2 select @PostGLCo = @AR_glco, @PostGLAcct = @GLRetainAcct, @PostAmount = -(isnull(@Retainage,0)), 
  						@errorAccount = 'AR Retainage Account'

  					/* Tax account.  Standard US or GST */
  					if @i=3 select @PostGLCo=@AR_glco, @PostGLAcct=@newHQTXcrdGLAcct, @PostAmount = -(@newRetgTax),
						@errorAccount = 'AR Tax Account'
   
  					/* Tax account.  PST */
  					if @i=4 select @PostGLCo=@AR_glco, @PostGLAcct=@newHQTXcrdGLAcctPST, @PostAmount = -(@newRetgTaxPST),
						@errorAccount = 'AR Tax Account PST'

					if @PostAmount <> 0
						begin
  		 				/* Lets first try to update to see if this GLAcct is already in batch */
  		 				update bARBA
          				set  ARTrans = @artrans, ARLine = @ARLine, ARTransType = @artranstype, Customer = @customer, 
  							SortName = @SortName, CustGroup = @custgroup, Invoice = @invoice, Contract = @Contract,
  							ContractItem = @ContractItem, ActDate = @transdate, Description = @description, 
  							Amount = @PostAmount + Amount
  						where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo and
  				 			GLAcct = @PostGLAcct and BatchSeq = @seq and OldNew = 0
		  
  						if @@rowcount = 0   /* If record is not already there then lets try to insert it */
   		 					begin
         	   				exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, 'R', @errmsg output
          	   				if @rcode <> 0
              					begin
              	   				select @errortext = @errorstart + '  GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
                  				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                  				if @rcode <> 0 goto bspexit
                  				end
		  
    		 				insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine,
  								ARTransType, Customer, SortName, CustGroup, Invoice, Contract,
  					  			ContractItem, ActDate, Description, Amount)
  							values(@co, @mth, @batchid, @PostGLCo, @PostGLAcct, @seq, 0, @artrans, @ARLine,
  			        			@artranstype, @customer, @SortName, @custgroup, @invoice, @Contract,
  			        			@ContractItem, @transdate, @description, @PostAmount)
		  
          	 				if @@rowcount = 0
              					begin
              					select @errmsg = 'Unable to add AR Detail audit - ' + @errortext , @rcode = 1
              					GoTo bspexit
              					end

							/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
							if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo)
   								begin
   								insert bHQCC (Co, Mth, BatchId, GLCo)
   								values (@co, @mth, @batchid, @PostGLCo)
   								end
            				end
						end

      	   			/* get next GL record */
          			select @i=@i+1, @errmsg=''
  	     			end /* gl accounts */

				select @amountrel = isnull(@Retainage,0) + (@newRetgTax + @newRetgTaxPST)
				select @taxamountrel = @newRetgTax + @newRetgTaxPST
				select @retainagerel = 0
				select @retgtaxrel = 0
				exec @rcode = vspARBLSetReleased @co, @mth, @batchid, @seq, @jcco, @Contract, @ContractItem,
					@amountrel, @taxamountrel, @retainagerel, @retgtaxrel, @artrans, @RecType, @newtaxgroup, @newtaxcode,
					@errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					goto bspexit
					end
  	   			end	/* End Release to AR = Y */
			else
				begin	/* Begin Release to AR = N */
  	     		select @i=1 /*set first account */
  	     		while @i<=4
  	       			begin
   	   				/*Validate GL Accounts*/
      	   			/* spin through each type of GL account, check it and write GL Amount */
  		   			select @PostGLAcct = NULL, @PostAmount = 0
	  
         			/* Retainage Receivable Account - From original invoice line RecType */
      	     		if @i=1 select @PostGLCo = @AR_glco, @PostGLAcct = @GLRetainAcct, @PostAmount = @newRetgTax + @newRetgTaxPST, 
  						@errorAccount = 'AR Retainage Account'

  					/* Retainage Tax account.  Standard US or GST */
  					if @i=2 select @PostGLCo=@AR_glco, @PostGLAcct=@newHQTXcrdRetgGLAcct, @PostAmount = -(@newRetgTax),
						@errorAccount = 'AR Retg Tax Account'
   
  					/* Retainage Tax account.  PST */
  					if @i=3 select @PostGLCo=@AR_glco, @PostGLAcct=@newHQTXcrdRetgGLAcctPST, @PostAmount = -(@newRetgTaxPST),
						@errorAccount = 'AR Retg Tax Account PST'

					if @PostAmount <> 0
						begin
  		 				/* Lets first try to update to see if this GLAcct is already in batch */
  		 				update bARBA
          				set  ARTrans = @artrans, ARLine = @ARLine, ARTransType = @artranstype, Customer = @customer, 
  							SortName = @SortName, CustGroup = @custgroup, Invoice = @invoice, Contract = @Contract,
  							ContractItem = @ContractItem, ActDate = @transdate, Description = @description, 
  							Amount = @PostAmount + Amount
  						where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo and
  				 			GLAcct = @PostGLAcct and BatchSeq = @seq and OldNew = 0
		  
  						if @@rowcount = 0   /* If record is not already there then lets try to insert it */
   		 					begin
         	   				exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, 'R', @errmsg output
          	   				if @rcode <> 0
              					begin
              	   				select @errortext = @errorstart + '  GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
                  				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                  				if @rcode <> 0 goto bspexit
                  				end
		  
    		 				insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine,
  								ARTransType, Customer, SortName, CustGroup, Invoice, Contract,
  					  			ContractItem, ActDate, Description, Amount)
  							values(@co, @mth, @batchid, @PostGLCo, @PostGLAcct, @seq, 0, @artrans, @ARLine,
  			        			@artranstype, @customer, @SortName, @custgroup, @invoice, @Contract,
  			        			@ContractItem, @transdate, @description, @PostAmount)
		  
          	 				if @@rowcount = 0
              					begin
              					select @errmsg = 'Unable to add AR Detail audit - ' + @errortext , @rcode = 1
              					GoTo bspexit
              					end

							/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
							if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo)
   								begin
   								insert bHQCC (Co, Mth, BatchId, GLCo)
   								values (@co, @mth, @batchid, @PostGLCo)
   								end
            				end
						end

      	   			/* get next GL record */
          			select @i=@i+1, @errmsg=''
  	     			end /* gl accounts */

				select @amountrel = isnull(@Retainage,0) + (@newRetgTax + @newRetgTaxPST)
				select @taxamountrel = 0
				select @retainagerel = isnull(@Retainage,0) + (@newRetgTax + @newRetgTaxPST)
				select @retgtaxrel = @newRetgTax + @newRetgTaxPST
				exec @rcode = vspARBLSetReleased @co, @mth, @batchid, @seq, @jcco, @Contract, @ContractItem,
					@amountrel, @taxamountrel, @retainagerel, @retgtaxrel, @artrans, @RecType, @newtaxgroup, @newtaxcode,
					@errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					goto bspexit
					end
				end	/* End Release to AR = N */
			end		/* End International Release Retainage distribution.  Tax Retainage at this time. */

      	/****** JC UPDATE = insert into bARBI ******/
  	 	if @jcco is not null and @Contract is not null and @ContractItem is not null	--Values that exist on Invoice
  	   		Begin
			select @interfacetaxjc = TaxInterface 
   			from bJCCM m with (nolock)
   			where m.JCCo = @jcco and m.Contract = @Contract

			/* We may be able to update JCID.  There are however, still some conditions that could prevent
			   this.  If some contract value has since been purged from the system, then we want to skip
			   the JC update altogether but still allow the release process to finish.  Unfortunately we
			   will not be able to process a Validation error to inform user.  Any attempt to do so will
			   abort the entire process.  The form should have warned the user in advance anyhow.  */
  	   		/* Check JCCO - Never going to fail. */
      		if not exists(select 1 from bJCCO with (nolock) where JCCo=@jcco)
    			begin
				goto ARBL_NEXT		--Skip JCID distribution for this line
    			end
  
      		/* Check Contract - If missing, then has been purged and cannot be reported to JCID */
	   		if not exists(select 1 from bJCCM with (nolock) where JCCo=@jcco and Contract = @Contract)
	     		begin
				goto ARBL_NEXT		--Skip JCID distribution for this line
         		end

			/* Check Contract Item - If missing, then has been purged and cannot be reported to JCID */
      		if not exists(select 1 from bJCCI with (nolock) where JCCo=@jcco and Contract = @Contract and Item = @ContractItem)
    			begin
				goto ARBL_NEXT		--Skip JCID distribution for this line
    			end
  
			if @releasetocurrent = 'Y'
				begin
				/* JCCo, Contract, and Item still exist in system.  OK to report distributions to JC. */
      			insert into bARBI(ARCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, Description,  ActualDate, ARTrans,
					Invoice, BilledUnits, BilledAmt, Retainage)
      			values (@co, @mth, @batchid, @jcco, @Contract, @ContractItem, @seq, @ARLine, 0, @description, @transdate, @artrans,
              		@invoice,  0,  0, 
					case when @interfacetaxjc = 'Y' then -(isnull(@Retainage,0)) else -(isnull(@Retainage,0) - isnull(@LineRetgTax,0)) end)
      			if @@rowcount = 0
    				begin
    				select @errortext = 'Unable to add AR Contract audit.'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    				if @rcode <> 0 goto bspexit
    				end
				end
			else
				begin
				/* TaxCode rate may have changed and a new RetgTax might have been recalculated.  The difference in RetgTax amount, as a result of
				   the tax rate change, may need to be reported to Job Cost.  */
				if (isnull(@LineRetgTax,0) <> (@newRetgTax + @newRetgTaxPST)) and @interfacetaxjc = 'Y'
					begin
      				insert into bARBI(ARCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, Description,  ActualDate, ARTrans,
						Invoice, BilledUnits, BilledAmt, Retainage)
      				values (@co, @mth, @batchid, @jcco, @Contract, @ContractItem, @seq, @ARLine, 0, 'Released Retg taxrate adjust', @transdate, @artrans,
              			@invoice,  0,  0, ((@newRetgTax + @newRetgTaxPST) - isnull(@LineRetgTax,0)))
      				if @@rowcount = 0
    					begin
    					select @errortext = 'Unable to add AR Contract audit.'
     					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    					if @rcode <> 0 goto bspexit
    					end
					end
				end
  	   		End 
    
      	/*** next line **/
	ARBL_NEXT:
      	select @ARLine = Min(ARLine)
       	from bARBL l with (nolock)
      	where Co = @co and Mth = @mth and BatchId= @batchid and BatchSeq= @seq and ARLine > @ARLine and ARLine < 10000
      	END /*ARBL LOOP */
   
  	if @no_linecount = 1
      	begin
      	select @no_linecount = 0
      	goto ARBH_NEXT /* added for when a header has no lines */
		end
   
ARBH_NEXT:
  	/*** next header ***/
  	select @seq=Min(BatchSeq)
  	from bARBH with (nolock)
  	where Co=@co and Mth = @mth and BatchId = @batchid and BatchSeq > @seq
  	END /* ARBH LOOP*/

-- make sure debits and credits balance
select @AR_glco = GLCo
from bARBA with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
group by GLCo
having isnull(sum(Amount),0) <> 0
if @@rowcount <> 0
	begin
	select @errortext =  'GL Company ' + isnull(convert(varchar(3), @AR_glco),'') + ' entries dont balance!'
  	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	end
  
/*** check HQ Batch Errors ***/
if exists(select 1 from bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
  	begin
  	select @status = 2	/* validation errors */
  	end
else
  	begin
  	select @status = 3	/* valid - ok to post */
  	end
   
/*** update HQ Batch Control status  ***/
print '<<Updating HQBC>>'
update bHQBC
set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
   
if @@rowcount <> 1
  	begin
  	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
  	goto bspexit
  	end

bspexit:

if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBHReleaseVal]'
return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspARBHReleaseVal] TO [public]
GO
