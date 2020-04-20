SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBARReleaseVal    Script Date: 8/28/99 9:36:06 AM ******/
CREATE procedure [dbo].[bspJBARReleaseVal]
/***********************************************************
* CREATED BY: 	bc 02/16/00
* MODIFIED By :  bc 05/11/00
*     	bc 05/08/01 - fixed the validation that check to make sure we are not releasing more retainage
*                	than there is available in AR
*     	kb 6/11/1   - issue #12332
*     	bc 07/03/01 - issue #13903
*     	bc 07/18/01 - issue #14039
*     	bc 11/13/01 - issue #15258
*     	bc 12/14/01 - issue #15597
*		TJL 04/28/03 - Issue #20936, Reverse Release Retainage
*		TJL 07/02/03 - Issue #21680, More descriptive err msg when not enough Retainage in AR, Performance Mods
*		TJL 09/05/03 - Issue #22359, More descriptive err msg when changing Normal RelRetg to Rev RelRetg
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 02/02/04 - Issue #23611, Insert correct GLCo and GLRevAccount on the Released Retainage Invoice.
*		TJL 02/05/04 - Issue #23666, Skip 'R'eleased (2nd R) invoices when calculating AR Retainage due
*		TJL 02/11/04 - Issue #23750, Correct Check determining how much Released Retg is available to Reverse
*		TJL 02/23/04 - Issue #23832, Use JCCo ARCo.GLCo for GL reporting of Release Retg.  (Not JC GLCo)
*		TJL 02/24/04 - Issue #18917, Use orig invoice RecType for 'Release' transaction not new bills JBIN RecType
*		TJL 08/13/04 - Issue #25364, When determining OpenRetg, exclude credits against 'Released' Invoices
*		TJL 09/14/04 - Issue #25518, Loosen 'Not enough Retainage in AR' validation
*		TJL 03/11/05 - Issue #27370, Improve on Negative Open Retainage, Release Retainage processing
*		TJL 03/22/05 - Issue #27332, Expand on Reverse Release Retainage validation error messages.
*		TJL 10/03/05 - Issue #29832, Skip Release Validation for Closed Mth Headers @batchmth <> @batchmth
*		TJL 01/02/08 - Issue #120880, Correct error when Releasing Retg for Non-Contract Customer with 0.00 Open Retg anywhere
*		TJL 01/07/08 - Issue #120443, Post JBIN Notes and JBIT Notes to Released (2nd R or Credit Invoice) in ARTH, ARTL
*		TJL 03/12/08 - Issue #126769, If ARCO Release Retg to AR is uncheck, Do not reduce JCID Retainage bucket
*		TJL 08/15/08 - Issue #128370, JB International Sales Tax
*		TJL 01/25/09 - Issue #131934, GLAcct amounts doubled when ARCompany "Post Taxes On Invoices" off.
*		TJL	01/25/09 - Issue #131908, Correct ErrorText to remove "Customer" reference only.  Error itself fixed by #131934
*		TJL 03/18/09 - Issue #132525, Not Releasing leftover amounts to Last Line of Last Invoice.  Erroring instead
*		TJL 04/27/09 - Issue #133442, Potential Divide By Zero error correction
*		TJL 09/17/09 - Issue #135562, Deleted Billings not reversing Release Retg in GL correctly when Negative AR Invoice lines exist
*		TJL 10/15/09 - Issue #136046, Missing Retainage GLAcct when Release Invoice Customer different than Posted AR Invoice's Customer,
*									  also AR GLAcct missing Debit when Retainage gets released caused by NULL values in GL computations.
*		MV	02/04/10 - Issue #136500 - bspHQTaxRateGetAll added NULL output param.
*		MV/TJL 05/16/11 - Issue #140708 - Tax Group/Tax code missing on AR released retainage records if an item is invoiced and released retainage on the same bill
*		CHS	10/14/2011	- D-02573 Reverse release sending unbalanced GL entry
*		MV	10/25/11 - TK-09243 - bspHQTaxRateGetAll added NULL output param.
*		MV	05/30/12 - D-04589 Isnull wrap TaxGroup and TaxCode in select from ARTL for Reverse Release 1st 'R' Transactions
*		TJL 06/07/12 - D-04589/145852, Missing AR Retainage GL due to Missing TaxCode value.  Incorrect AR Retainage GL due to duplicate Bill Invoice Dates
*
* USAGE:
*
*
* INPUT PARAMETERS
*   JBCo        AR Co
*   BillMonth   Month of batch
*   BatchId     Batch ID to validate
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@jbco bCompany, @batchmth bMonth, @batchid bBatchID, @errmsg varchar(255) output
as
set nocount on

/* General Variables*/
declare @rcode int, @errortext varchar(255), @tablename char(20), @seq int, 
	@arco bCompany, @TmpCustomer varchar(15),@ReturnCustomer bCustomer, 
	@errorstart varchar(50), @SortName varchar(15), @i int, @releasetocurrent bYN,
	@RelRetgTrans bTrans, @OrigInvTrans bTrans, @AmtChange bYN, @changed bYN,
	@opencursorJBAR int, @opencursorJBAL int, @opencursor_ARTL_R2 int, @opencursor_ARTL_I int, 
	@opencursorARTL_V int, @OrigInvRecType tinyint, @currentbill bYN, @ARGLCo bCompany,
	@100_pct bYN, @oppositeopenretgflag bYN, @distamtstilloppositeflag bYN, @distamttaxstilloppositeflag bYN,
	@oppositerelretgflag bYN, @oppositerelretgtaxflag bYN, @oldglonly bYN, @revoldglVonly bYN, @revoldglonly bYN

/* International Sales Tax */
declare @arcotaxretg bYN, @arcoseparateretgtax bYN, @posttaxoninv bYN, @interfacetaxjc bYN		--AR Company flags, JC Contract flags

declare	@JBALtaxgroup bGroup, @JBALtaxcode bTaxCode,@HQCOtaxgroup bGroup, @itemtaxgroup bGroup, @itemtaxcode bTaxCode, 
	@newtaxgroup bGroup, @newtaxcode bTaxCode, @custtaxcode bTaxCode, @invlinetaxgroup bGroup, @invlinetaxcode bTaxCode,
	@R2taxgroup bGroup, @R2taxcode bTaxCode 
	
declare @originvtransdate bDate, @R2date bDate, 
	@taxrate bRate, @gstrate bRate, @pstrate bRate, @newtaxrate bRate, @newgstrate bRate, @newpstrate bRate, 
	@R2taxrate bRate, @R2gstrate bRate, @R2pstrate bRate,
	@HQTXcrdGLAcct bGLAcct, @HQTXcrdRetgGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct, @HQTXcrdRetgGLAcctPST bGLAcct,
	@newHQTXcrdGLAcct bGLAcct, @newHQTXcrdRetgGLAcct bGLAcct, @newHQTXcrdGLAcctPST bGLAcct, @newHQTXcrdRetgGLAcctPST bGLAcct,
	@R2HQTXcrdGLAcct bGLAcct, @R2HQTXcrdRetgGLAcct bGLAcct, @R2HQTXcrdGLAcctPST bGLAcct, @R2HQTXcrdRetgGLAcctPST bGLAcct
	  
declare @RetgTax bDollar, @RetgTaxPST bDollar, @oldRetgTax bDollar, @oldRetgTaxPST bDollar, 
	@newTax bDollar, @newTaxPST bDollar, @oldTax bDollar, @oldTaxPST bDollar,
	@calculatednewlinetax bDollar, @calculatedoldlinetax bDollar, @calculatedoldlineretgtax bDollar,
	@retainagerel bDollar, @retgtaxrel bDollar 

declare @dist_amt bDollar, @dist_amttax bDollar, 
	@invline_openretg bDollar, @oldinvline_openretg bDollar, @invline_openretgtax bDollar, @oldinvline_openretgtax bDollar,
  	@invline_relretg bDollar, @oldinvline_relretg bDollar, @invline_relretgtax bDollar,  @oldinvline_relretgtax bDollar

/* JBAR Header Variables used with JBAR Cursor */
declare  @jbcontract bContract, @jbcontractItem bContractItem,
	@batchtranstype char(1), @artrans bTrans, @custgroup bGroup, @customer bCustomer, @billmth bMonth,
	@billnumber int, @invoice char(10), @description bDesc, @RecType tinyint, @oldRecType tinyint,
	@transdate bDate, @discdate bDate, @DueDate bDate, @payterms bPayTerms, 
	@oldtransdate bDate, @oldduedate bDate, @olddiscdate bDate, @oldpayterms bPayTerms,	 
	@revrelretgYN bYN
   
/* JBAL Line Variables used with JBAL Cursor */
declare @ARLine smallint, @olddescription bDesc, @um bUM, 
   	@JCGLCo bCompany, @oldJCGLCo bCompany, @itemglrevacct bGLAcct,
   	@jb_retg bDollar, @RetgRel bDollar, @oldRetgRel bDollar, @oldRetainage bDollar,
	@LineRetgTax bDollar, @oldLineRetgTax bDollar, @LineRetgTaxRel bDollar, @oldLineRetgTaxRel bDollar,
   	@contractitemamt bDollar, @itemnotes varchar(8000)

/* Validation Variables */
declare  @ar_retg bDollar, @openretg bDollar, @ARtotalitemrelretg bDollar, @ARtotalitemRinvamt bDollar,
   	@thisretgtrans bTrans, @thisinvtrans bTrans, @R2applymth bMonth, 
   	@R2applytrans bTrans, @R2applyline smallint, @ARR2lineamt bDollar,
   	@Imth bMonth, @Iartrans bTrans, @Iarline smallint,
   	@R1mth bMonth, @R1artrans bTrans, @R1arline smallint	--ADDED D-04589/145852
   
/* GL Posting Variables */
declare @PostGLCo bCompany, @PostGLARAcct bGLAcct, @PostGLAcct bGLAcct,	@oldPostGLCo bCompany, @oldPostGLAcct bGLAcct,
   	@GLARAcct bGLAcct, @GLRetainAcct bGLAcct, @oldGLARAcct bGLAcct, @oldGLRetainAcct bGLAcct,
   	@ReleaseGLARAcct bGLAcct, @ReleaseGLRetainAcct bGLAcct, @oldReleaseGLARAcct bGLAcct, @oldReleaseGLRetainAcct bGLAcct,
   	@ReleasedGLARAcct bGLAcct, @ReleasedGLRetainAcct bGLAcct, @oldReleasedGLARAcct bGLAcct, @oldReleasedGLRetainAcct bGLAcct,	 
   	@PostAmount bDollar, @oldPostAmount bDollar, @errorAccount varchar(20),
   	@oldapplymth bMonth, @oldapplytrans bTrans, @oldapplyline smallint
   
select @tablename = 'bARTH', @opencursor_ARTL_I = 0, @opencursor_ARTL_R2 = 0, @opencursorARTL_V = 0, @oldglonly = 'N',
	@revoldglVonly = 'N', @revoldglonly = 'N'
   
/* Get required information */
select @arco = c.ARCo, @releasetocurrent = a.RelRetainOpt, @ARGLCo = a.GLCo,
	@HQCOtaxgroup = h.TaxGroup, @arcotaxretg = a.TaxRetg, @arcoseparateretgtax = a.SeparateRetgTax,
	@posttaxoninv = a.InvoiceTax
from bJCCO c with (nolock)
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where c.JCCo = @jbco

/* Declare cursor on JB Header Batch for validation */
declare bcJBAR cursor local fast_forward for
select BatchSeq, BillMonth, BillNumber, BatchTransType, Invoice, Contract, CustGroup, Customer,
	RecType, Description, ARTrans, TransDate, PayTerms, DueDate, DiscDate,
	oldRecType, oldTransDate, oldDueDate, oldDiscDate, oldPayTerms, RevRelRetgYN
from bJBAR with (nolock)
where Co = @jbco and Mth = @batchmth and BatchId = @batchid
   
/* Open cursor */
open bcJBAR
/* Set open cursor flag to true */
select @opencursorJBAR = 1
/* Get rows out of JBAR */
  
get_next_bcJBAR:
fetch next from bcJBAR into @seq, @billmth, @billnumber, @batchtranstype, @invoice, @jbcontract, @custgroup, @customer,
   	@RecType, @description, @artrans, @transdate, @payterms, @DueDate, @discdate,
   	@oldRecType, @oldtransdate, @oldduedate, @olddiscdate, @oldpayterms, @revrelretgYN
   
/*Loop through all rows */
while (@@fetch_status = 0)
  	BEGIN	/*Begin bJBAR loop */
  
  	/* BillMonth can only be different from BatchMth when the JBAR Seq/Header involved is related to 
  	   a Bill from a Closed Mth.  (Open Bills always have the same BillMonth as BatchMth).  Skip
  	   Release Retainage validation for this Bill. (Form prevents Release Retainage from being modified
  	   on a Closed Mth Bill) */
  	if @billmth <> @batchmth goto get_next_bcJBAR
  
  	select @errorstart = 'BillMonth ' + SubString(convert(varchar(10), @billmth, 1),0 ,3) + Right(convert(varchar(10), @billmth, 1), 3)
			 + ', BillNumber ' + convert(varchar(10), @billnumber) + ': '
   
	/* Look to see if there has already been a release retainage transaction for this bill
	   indicating that this bill has already been interfaced. */
	select @RelRetgTrans = n.ARRelRetgTran, @OrigInvTrans = n.ARRelRetgCrTran,
		@interfacetaxjc = c.TaxInterface, @custtaxcode = cm.TaxCode
	from bJBIN n with (nolock)
	join bJCCM c with (nolock) on c.JCCo = n.JBCo and c.Contract = n.Contract
	join bARCM cm with (nolock) on cm.CustGroup = n.CustGroup and cm.Customer = n.Customer
	where n.JBCo = @jbco and n.BillMonth = @batchmth and n.BillNumber = @billnumber
   
	/* Get GL Company and GLAcct based upon the RecType from this bills header.  This RecType and
	   GLAccts will apply to only the Credit Invoice transaction (Released - New Invoice) created by releasing
	   this retainage.  */
	select @GLARAcct = GLARAcct, @GLRetainAcct = GLRetainAcct
	from bARRT with (nolock)
	where ARCo = @arco and RecType = @RecType
   
   	/* The reality is that RecType and oldRecType will always be the same, therefore the GLAccts will also
   	   remain the same.  Reason:  If the RecType has changed on the current bill used to Release retainage,
   	   (which should not be allowed once interfaced), then the Lines for this bill must also be changed at 
   	   the same time.  Likewise, ALL FUTURE APPLYLINES need to be set to new RecType at that moment
   	   which cannot be allowed because GL would be affected adversely.  OLD AND NEW RECTYPE SHOULD BE THE SAME! */
   	if @oldRecType is not null
   		begin
   	  	select @oldGLARAcct = GLARAcct, @oldGLRetainAcct = GLRetainAcct
   	  	from bARRT with (nolock)
   	  	where ARCo = @arco and RecType = @oldRecType
   		end
   
   	/* bJBAR Validation */
	if @batchtranstype <> 'D'
       	begin	/* Begin Validate bJBAR */
     	/* Validate customer */
     	select @TmpCustomer = convert(varchar(15),@customer)
     	exec @rcode = bspARCustomerVal @custgroup, @TmpCustomer, NULL, @ReturnCustomer output, @errmsg output
  		if @rcode = 0
  			begin
  			/*get SortName*/
  			select @SortName = m.SortName, @custtaxcode = TaxCode
       		from bARCM m with (nolock)
       		where m.CustGroup = @custgroup and m.Customer = @customer
  			end
     	end		/* End Validate bJBAR */
   	
   	if @batchtranstype = 'D' and @OrigInvTrans is not null
       	begin
     	/* Do not allow the bill to be deleted if payments or reversing transactions have been applied against 
	      the original invoice previously created by releasing retainage. */
     	if exists(select top 1 1
               from bARTL with (nolock)
               where ARCo = @arco and ApplyMth = @batchmth and ApplyTrans = @OrigInvTrans and not
                     (Mth = @batchmth and ARTrans = @OrigInvTrans))
       		begin
  			select @errortext = @errorstart + '- Cannot delete bill.  ' +
           		'The Original Invoice that was created by interfacing released retainage on this bill ' +
              	'now has transactions applied against it in AR.'
  			exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
  			goto get_next_bcJBAR
       		end
     	end
 
	/*****************************************************************************************************
	*
	*										JBAL GENERAL VALIDATION
	*
	******************************************************************************************************/

	declare bcJBAL cursor local fast_forward for
	select l.Item, l.ARLine, l.GLCo, l.GLAcct, l.Description, l.UM, i.ContractAmt, 
		l.Retainage, l.oldRetainage, l.RetgTax, l.oldRetgTax, l.RetgRel, l.oldRetgRel, 
		l.RetgTaxRel, l.oldRetgTaxRel, l.GLCo, l.oldDescription, l.TaxGroup, l.TaxCode, l.Notes
	from bJBAL l with (nolock)
	join bJCCI i with (nolock) on i.JCCo = l.Co and i.Contract = @jbcontract and i.Item = l.Item 
	where l.Co = @jbco and l.Mth = @batchmth and l.BatchId=@batchid and l.BatchSeq=@seq and l.ARLine < 10000
		and ((l.RetgRel <> 0) or (l.oldRetgRel <> 0))	-- Must process if either is present, unlike posting procedure.
   
	/* Open cursor for line */
	open bcJBAL
	/* set appropiate cursor flag */
	select @opencursorJBAL = 1

/* Read cursor lines */
get_next_bcJBAL:
	fetch next from bcJBAL into @jbcontractItem, @ARLine, @JCGLCo, @itemglrevacct, @description, @um, @contractitemamt,
		@jb_retg, @oldRetainage, @LineRetgTax, @oldLineRetgTax, @RetgRel, @oldRetgRel, 
		@LineRetgTaxRel, @oldLineRetgTaxRel, @oldJCGLCo, @olddescription, @JBALtaxgroup, @JBALtaxcode, @itemnotes
   
	while (@@fetch_status = 0)
 		begin	/* Begin JBAL Loop */

		/* Reset temporary variables */
   		select @100_pct = 'N', @oldglonly = 'N', @revoldglVonly= 'N', @revoldglonly = 'N'
   		if @revrelretgYN = 'N'
   			begin
   			/* (Values from bJBAL:  Are Neg for Release, Are Pos for Reverse Release) */
   			select @RetgRel = -@RetgRel			--Convert to Pos for easier and more straight forward comparisons (Neg in JBAL for Rel)
			select @LineRetgTaxRel = -@LineRetgTaxRel
   			select @oldRetgRel = -@oldRetgRel	--Convert to Pos for easier and more straight forward comparisons (Neg in JBAL for Rel)
			select @oldLineRetgTaxRel = -@oldLineRetgTaxRel
   			end
   -------------- #20936 Begin here -------------
       	if @batchtranstype = 'C' and @OrigInvTrans is not null		
   	    	begin  /* Begin general evalulation of Previously interfaced Release transactions */
   	      	/* Do not allow the bill to be interfaced (changed) if payments or reversing applied entries have been applied 
   			   against the original invoice (Released) created by releasing retainage.  A user will not be allowed to change
   			   this Release amount if reversing entries have already been applied against the 'R' (Released) invoice created
   			   by this Release action in the first place.  Since all or some portion of this has been reversed, it
   			   is assumed that the reversal reflects the desired change and further change here is not allowed.
   			   1) Change allowed NO - If Normal Released Transaction contains a payment
   			   2) Change allowed NO - If Normal Released Transaction is involved in any Reverse Release
   			   3) Change allowed YES - On Reverse Released Transactions 
   
   			   Under this condition, consider this transaction final.  Further adjustments should be performed using
   			   a new bill as necessary. */
   	      	if exists(select top 1 1
   	                from bARTL with (nolock)
   	                where ARCo = @arco and ApplyMth = @batchmth and ApplyTrans = @OrigInvTrans and
   	                      JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractItem and
   	                      not (Mth = @batchmth and ARTrans = @OrigInvTrans))
   	        	begin
   
   	   			select @errortext = @errorstart + '- Item: ' + isnull(ltrim(@jbcontractItem),'') +
   	            	' cannot have its Release Retainage amount reinterfaced.  There are other lines applied against it in AR.'
   	   			exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
   	   			goto get_next_bcJBAL
   	        	end
   
   			/* Do not allow the bill to be interfaced (change) if original transaction is a normal Release
   			   transaction and now the user is attempting to change it to a Reverse Release transaction.
   			   4) Change allowed NO - If changing from Normal Released Transaction to Reverse Release Transaction */
   			if exists(select top 1 1
   					from bARTL with (nolock)
   	                where ARCo = @arco and ApplyMth = @batchmth and ApplyTrans = @OrigInvTrans and
   	                      JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractItem and
   	                      (Mth = @batchmth and ARTrans = @OrigInvTrans))
   						and @revrelretgYN = 'Y'
   	        	begin
   	   			select @errortext = @errorstart + '- Item: ' + isnull(ltrim(@jbcontractItem),'') +
   	            	' cannot change from Normal Released Retainage to Reverse Released Retainage on an Interfaced bill.'
   	   			exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
   	   			goto get_next_bcJBAL
   	        	end
   	      	end		/* End general evalulation of Previously interfaced Release transactions */
 
   	    /* Get next available transaction # for ARTH.  This is only for the purpose of comparisons.
   		   Actual values get set by the posting procedure. */
   		if @RelRetgTrans is null 
   			begin
   		    exec @thisretgtrans = bspHQTCNextTrans @tablename, @arco, @batchmth, @errmsg output
   		    if @thisretgtrans = 0 goto bspexit
   		
   		    exec @thisinvtrans = bspHQTCNextTrans @tablename, @arco, @batchmth, @errmsg output
   		    if @thisinvtrans = 0 goto bspexit
   			end
   		else
   			begin
   			select @thisretgtrans = @RelRetgTrans, @thisinvtrans = @OrigInvTrans
   			end
   
	/*****************************************************************************************************
	*
	*								RELEASE AND REVERSE RELEASE AMOUNT EVALUATION
	*
	******************************************************************************************************/

   		if @revrelretgYN = 'Y'
   			begin	/* Begin specific Reversing amount evaluation */
   			/* In the case of Reversing previously released retainage, we cannot allow the user to reverse
   			   more retainage than what was previously released AND/OR the amount reversed cannot exceed
   			   the amount due for ALL 'R' (Released) invoices that were created as a result of Releasing retainage.
   			   (ie. if cash was applied to one of these 'R' invoices, you may not reverse that amount.) 
   
   			   VALIDATION TESTS BELOW ARE BASED UPON TRANSACTIONS PRIOR THIS BILL!	If you are changing
   			   what you previously reversed, and if future reversals exist or payments on 'R'eleased invoices,
   			   (that this reversal will affect), have been made in the future, these will NOT be considered
   			   when making this Reversal change.  This is consistent with the entire Release Retainage
   			   process.  RELEASE RETG OR REVERSING RELEASE RETAINAGE SHOULD ALWAYS OCCUR ON A NEW BILL
   			   FOR BEST RESULTS. */
   
   			if @batchtranstype <> 'D'
   				begin	/* Begin not D */
   				/* Amount of Reverse Release retainage - Old values are not necessary here since the double 'R'
   				   transactions get completely removed and readded. */
   				--select @JBtotalitemrelretg = isnull(@RetgRel, 0)
   				--from bJBAL with (nolock)
   				--where Co = @jbco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @seq
   				--	and Item = @jbcontractItem and ARLine = @ARLine*/
   
   				/* 1st Test (Total Release Amount - 1st 'R'):  Determine the amount (in AR) of previously release retainage (1st 'R').  
   				   Users should not be interfacing this bill if prior bills exist in JB that have not been interfaced.  
   				   If this check passes then we must do a second test. */
   		    	select @ARtotalitemrelretg = isnull(sum(l.Retainage), 0)
   		    	from bARTH h with (nolock)
   		    	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
   		                    l.JCCo = @jbco and l.Contract = @jbcontract and l.Item = @jbcontractItem	-- This contract/Item only	
   		    	where h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
   					and (h.Mth < @batchmth or (h.Mth = @batchmth and h.ARTrans < @thisretgtrans)) 	-- Prior to this Release trans
   					and h.ARTransType = 'R'														-- Release values only
   					and (l.Mth <> l.ApplyMth or l.ARTrans <> l.ApplyTrans)						-- No original Released values
   
   				if @RetgRel <> 0 and abs(@RetgRel) > abs(@ARtotalitemrelretg)
   					begin
   					select @errortext = @errorstart + ', BillMth: ' + isnull(convert(varchar(8), @batchmth,1),'') + ', BillNumber: ' + isnull(convert(varchar(10),@billnumber),'')
   	   				select @errortext = @errortext + ' - May not reverse more than is released in AR for: ' 
   					select @errortext = @errortext + 'Customer: ' + isnull(Convert(varchar(10), @customer),'') + ', Contract: ' + isnull(@jbcontract,'')
   					select @errortext = @errortext + ', ContractItem: ' + isnull(@jbcontractItem,'')
   	   				exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
   	   				goto get_next_bcJBAL
   					end  
   
   				/* 2nd test (Total Released Amount - 2nd 'R').  Determine the amounts (in AR) for Released type invoices (2nd 'R') that were generated 
   				   as a result of releasing retainage to this point. This include payments and credits against these 'Released' (2nd 'R') invoices. */
   		    	declare bcARTL_R2 cursor local fast_forward for
   		    	select l.ApplyMth, l.ApplyTrans, l.ApplyLine
   		    	from bARTH h with (nolock)
   		    	join bARTL l with (nolock)on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
   		                    l.JCCo = @jbco and l.Contract = @jbcontract and l.Item = @jbcontractItem	-- This contract/Item only
   		    	where h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
   					and (h.Mth < @batchmth or (h.Mth = @batchmth and h.ARTrans < @thisinvtrans)) 		-- Prior to this Released trans
   					and h.ARTransType = 'R'															-- orig Released transactions only
   					and (l.Mth = l.ApplyMth and l.ARTrans = l.ApplyTrans)
   
   				open bcARTL_R2
   				select @opencursor_ARTL_R2 = 1, @ARtotalitemRinvamt = 0
   
       			fetch next from bcARTL_R2 into @R2applymth, @R2applytrans, @R2applyline
   				while @@fetch_status = 0
   					begin
   					/* For each Original 2nd 'R' (Released) transaction (relative to this contract item) we will
   					   get the sum of its Line Amounts and add it to the next 2nd 'R' transaction's sum
   					   for this item.  This will include any payments, credits or reversals relative
   					   to the new invoice transactions created when Retainage is released. 
   
   					   We have already restricted this cursor to the desired 2nd 'R' type transactions above.
   
   					   In case this Reversing Bill has already been posted once and is now in 'C'hange
   					   mode to be posted again, do not include the previously posted reversal amounts,
   					   for this bill, when considering how much is available to be Reversed. */
   		    		select @ARR2lineamt = isnull(sum(Amount), 0)
   		    		from bARTL with (nolock)
   		    		where ARCo = @arco and ApplyMth = @R2applymth and ApplyTrans = @R2applytrans
   						and ApplyLine = @R2applyline											--Sum all 'R'eleased applied lines this Item
   						and (Mth < @batchmth or (Mth = @batchmth and ARTrans < @thisinvtrans))	--Exclude this Prev Posted 'V' transaction
   	
   					/* Add this to the previous */
   					select @ARtotalitemRinvamt = @ARtotalitemRinvamt + @ARR2lineamt
   
   					fetch next from bcARTL_R2 into @R2applymth, @R2applytrans, @R2applyline
   					end
   
   				/* We have our total, close down cursor */
   				close bcARTL_R2
   				deallocate bcARTL_R2
   				select @opencursor_ARTL_R2 = 0
   
   				/* Make the comparison and inform user if the amount being reversed exceeds the amount
   				   relative to 2nd 'R'eleased transactions that we want to reverse in AR */
   				if @RetgRel <> 0 and abs(@RetgRel) > abs(@ARtotalitemRinvamt)
   					begin
   					select @errortext = @errorstart + ', BillMth: ' + isnull(convert(varchar(8), @batchmth,1),'') 
   						+ ', BillNumber: ' + isnull(convert(varchar(10),@billnumber),'') 
   	   				select @errortext = @errortext + ' - May not reverse this amount if a portion of the Credit transaction '
   						+ 'has been paid or credited in AR for Contract: ' 
   					select @errortext = @errortext + isnull(@jbcontract,'') + ', ContractItem: ' + isnull(convert(varchar(20),@jbcontractItem),'')
   	   				exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
   	   				goto get_next_bcJBAL
   					end  	
   				end		/* End not D */
  
  			--Re-instated "if @batchtranstype <> 'D' code below per issue #135562 
   			/* This Release Amount for this Item is OK to Reverse. */
   			/* Evaluate Total previously Release Retg for this Item.  If User is Reversing 100 percent of it then we will automatically
   			   Reverse the full amount of this Item on all Invoices.  There will be no evaluation and tracking of the distributed
   			   Reverse amounts for each Line in each invoice individually.  By doing this, any Negative Release Amounts for an 
   			   individual invoice will be dealt with correctly and ALL release amounts will be reversed entirely on all
   			   invoices.  This is a very important piece. */
   			if @batchtranstype <> 'D'
   				begin
				if isnull(@ARtotalitemrelretg,0) = -@RetgRel			--if Neg = -Pos
					begin
					select @100_pct = 'Y'
					end
   				end
   			else
   				begin
   				/* Typically this procedure is based upon evalulating New values to be posted.  Keeping track of distributing
   				   the new values is based upon this evaluation process.  Old values simply get posted, as things proceed, equal
   				   to what they were posted previously.  However, this evaluation process is void on 'D'eleted bills because
   				   there are no New values to post.  Therefore we simply process 'D'eletes as though they were 100 Percent.
   				   In this way, though updating new GL is skipped altogether, all previously posted lines will get processed
   				   and their old values will get removed from GL */
   				select @100_pct = 'Y'
   				end
   			end		/* End specific Reversing amount evaluation */
   		else
   			begin	/* Begin specific Releasing amount evaluation */
   			if @batchtranstype <> 'D'
   				begin
   	      		/* This entire check is only accurate on a newly added (not yet interfaced) bill.  There can be 
   				   absolutely no adjustments ('A' transactions in AR) for bills earlier than this one.  This is
   				   because an change to an earlier bill may very well create an Adjustment with a Date
   				   after this bill that you are working on.  Just go get later 'A' applied transactions you say!?
   				   Easier said than done.  There can be later applied transactions ('R' and 'V' and 'P' types)
   				   that have to be excluded after this date but need to be included prior than this date.  
   				   It can be daunting and this validation is best left simple.  (Some protection better than none)
   
   				   Begin by checking to make sure the released retainage is less than or equal to the open 
   				   retainage in AR. @ar_retg is all open retainage up to this point for this Co, contract, item. */
   	  	      	select @ar_retg = isnull(sum(l.Retainage),0)
   	  	      	from bARTH h with (nolock)
   	  	      	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
   	  	        	l.JCCo = @jbco and l.Contract = @jbcontract and l.Item = @jbcontractItem
   				join bARTH ha with (nolock) on ha.ARCo = l.ARCo and ha.Mth = l.ApplyMth and ha.ARTrans = l.ApplyTrans 	-- Added Issue# 25364
   	  	      	where h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
   	  				and (h.Mth < @batchmth or (h.Mth = @batchmth and h.ARTrans < @thisretgtrans))
   	  				and ((h.ARTransType <> 'R' 
   							and (ha.ARTransType <> 'R' or (ha.ARTransType = 'R' and (ha.AppliedMth is null and ha.AppliedTrans is null))))	--Issue# 25364
   						or (h.ARTransType = 'R' and (h.AppliedMth is null and h.AppliedTrans is null))) --Skip 'R'eleased (2nd R) Retg and Credits to it
   
   				/* Include the potential retainage to be created by this transaction in the calculation.  This bill
   				   may have previously been interfaced therefore we factor in @oldRetainage below.  It is not necessary
   				   to worry about RelRetg or oldRelRetg at this point since we are going to drop the old 'R', 'R' lines
   				   anyway and readd them fresh as though they never existed. */
   			 	select @openretg = 0
   				select @openretg = @ar_retg + (@jb_retg - isnull(@oldRetainage,0))  
  	
   	      		/* This check determines if the amount we expect to Release exceeds the amount available in AR for release.
   				   AR clerks may have already posted a payment or credit somewhere, therefore reducing the amount 
   				   available to release.  JB doesn't know about this.  We only make this check on new bills.  If user 
   				   wants to overrelease on previously interfaced bills, we let them.  Some protection is better than none.
   				   The abs() function is necessary because we may be dealing with a negative contract or contract item. */
   -- -- 	      		if @RetgRel <> 0 and (abs(@RetgRel) > abs(@openretg))		
   -- -- 	        		begin
   -- -- 	   				select @errortext = @errorstart + '- Not enough retainage exists in AR to release for: ' 
   -- -- 					select @errortext = @errortext + 'Customer: ' + isnull(Convert(varchar(10), @customer),'') + ', Contract: ' + isnull(@jbcontract,'')
   -- -- 					select @errortext = @errortext + ', ContractItem: ' + isnull(@jbcontractItem,'')
   -- -- 	   				exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
   -- -- 	   				goto get_next_bcJBAL
   -- -- 	        		end 
   				end		/* End not D */
   
			--Re-instated "if @batchtranstype <> 'D' code below per issue #135562
   			/* Evaluate Total Open Retainage for this Item.  If User is Releasing 100 percent of it then we will automatically
   			   Release the full amount of this Item on all Invoices.  There will be no evaluation and tracking of the distributed
   			   Release amounts for each Line in each invoice individually.  By doing this, any Negative Open Amounts for an 
   			   individual invoice will be dealt with correctly and ALL retainage amounts will be released entirely on all
   			   invoices.  This is a very important piece. */
   			if @batchtranstype <> 'D'
   				begin
				if isnull(@openretg,0) = @RetgRel
					begin
					select @100_pct = 'Y'
					end
   				end
   			else
   				begin
   				/* Typically this procedure is based upon evalulating New values to be posted.  Keeping track of distributing
   				   the new values is based upon this evaluation process.  Old values simply get posted, as things proceed, equal
   				   to what they were posted previously.  However, this evaluation process is void on 'D'eleted bills because
   				   there are no New values to post.  Therefore we simply process 'D'eletes as though they were 100 Percent.
   				   In this way, though updating new GL is skipped altogether, all previously posted lines will get processed
   				   and their old values will get removed from GL */
   				select @100_pct = 'Y'
   				end
   			end		/* End specific Releasing amount evaluation */
   -------------- #20936 End here -------------

   		/* Reset variables relative at the JBAL Line level prior to beginning GL distribution. */
   		select @oldapplymth = '01-01-1950', @oldapplytrans = 0	
   
   		/* GL distribution is different in JB.  You cannot add a transaction back into a batch for change.  Rather
   		   the Bill must be modified and Re-interfaced.  Therefore there are no Old values, on hand, for 
   		   redistributing in GL easily.  Instead, old values must be calculated on the fly.  There are two 
   		   different operations here:
   			1)  Normal Release Retainage
   			2)  Reverse Release Retainage
   
   		   They operate differently and the processes required to adjust GL entries are different.  In short, 
   		   validation must go throught the exact same process as the Release and Reverse Posting Procedures in
   		   order to determine values relative to the various and often multiple invoices involved. */

		if @revrelretgYN = 'N'
			begin	/* Begin Processing GL for Normal Release */
/*****************************************************************************************************
*
*									NORMAL RELEASE
*	BASED ON TOTAL AMOUNT TO BE RELEASED, CALCULATE RELEASE AMOUNTS FOR EACH INDIVIDUAL INVOICE
*
******************************************************************************************************/
			select @dist_amt = 0, @dist_amttax = 0, @currentbill = 'N', @distamtstilloppositeflag = 'N'
			/*****  Need GLAcct info from RecType of EACH 'Release' invoice that this release action will affect *****/
			/*	Cursor should limit / ignore the various adjustment transactions to begin with.  
				1) About:  (h.Mth < @batchmth or (h.Mth = @batchmth and h.ARTrans < @thisretgtrans))	
					Note #1: (The Current Bill only exists in this list if it has been previously interfaced.  If not,
						then the Current Bill will get processed at the end)
					Note #2: (Later bills never get considered.  Leftover amounts get placed on Last Line of Last Invoice during posting.) 
				2) About:  h.ARTransType not in ('F', 'R')  ('I' & 'R' invoices may both contain Retainage, 'F' will not.)
					Note #3: ('R' invoices will contain Retg if not Released to AR when created. This Retg not allowed to be 
						released now because JB Release Input form knows that it has already been released before.)
				3) About:  l.Mth = l.ApplyMth and l.ARTrans = h.ApplyTrans and l.ARLine = l.ApplyLine  (Only Original Lines) 
				4) About: Current Bill.  Current bill will be included in the cursor list in 'Change/Delete' modes only.
						When included in list, it is processed as any other earlier bill.  In 'Active' mode however,
						Current Bill will get processed at the very end. */
			declare bcARTL_I cursor local fast_forward for
			select l.Mth, l.ARTrans, l.ARLine, l.RecType, h.TransDate, l.TaxGroup, l.TaxCode
			from bARTH h with (nolock)
			join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
	    		and l.JCCo = h.JCCo and l.Contract = h.Contract 	--Not needed, lines restricted by Contract/Item below
			where h.ARCo = @arco 															
				and (h.Mth < @batchmth or (h.Mth = @batchmth and h.ARTrans < @thisretgtrans))		--See Note above
				and h.CustGroup = @custgroup and h.Customer = @customer 						--This Customer 
				and h.JCCo = @jbco and h.Contract = @jbcontract and l.Item = @jbcontractItem	--This Contract and ContractItem
				and h.ARTransType not in ('F', 'R') 											--See note above
				and l.Mth = l.ApplyMth and l.ARTrans = l.ApplyTrans and l.ARLine = l.ApplyLine	--Original lines only
			order by l.Mth, l.ARTrans, l.ARLine
						
			/* Open cursor for line */
			open bcARTL_I
			select @opencursor_ARTL_I = 1
	
			/**** Read cursor lines ****/
		get_next_bcARTL_I:

			fetch next from bcARTL_I into @Imth, @Iartrans, @Iarline, @OrigInvRecType, @originvtransdate,
				@invlinetaxgroup, @invlinetaxcode
			while (@@fetch_status = 0)
				begin  /* Begin ARTL process Release Invoice loop */
				select @invline_openretg = 0, @oldinvline_relretg = 0,	@invline_relretg = 0, @oppositeopenretgflag = 'N'
				select @invline_openretgtax = 0, @oldinvline_relretgtax = 0, @invline_relretgtax = 0

				/* Reset Line variables as needed here.  
				   Retrieved as each Lines TaxCode gets validated.  Reset to avoid leftover value when TaxCode is invalid */
				select @itemtaxgroup = null, @itemtaxcode = null, @newtaxgroup = null, @newtaxcode = null,
					@HQTXcrdGLAcct = null, @HQTXcrdRetgGLAcct = null, @HQTXcrdGLAcctPST = null, @HQTXcrdRetgGLAcctPST = null,
					@newHQTXcrdGLAcct = null, @newHQTXcrdRetgGLAcct = null, @newHQTXcrdGLAcctPST = null, @newHQTXcrdRetgGLAcctPST = null,
					@R2HQTXcrdGLAcct = null, @R2HQTXcrdRetgGLAcct = null, @R2HQTXcrdGLAcctPST = null, @R2HQTXcrdRetgGLAcctPST = null,
					@RetgTax = 0, @RetgTaxPST = 0, @oldRetgTax = 0, @oldRetgTaxPST = 0, @newTax = 0, @newTaxPST = 0, @oldTax = 0, @oldTaxPST = 0,
					@taxrate = 0, @gstrate = 0, @pstrate = 0, @newtaxrate = 0, @newgstrate = 0, @newpstrate = 0, 
					@R2taxrate = 0, @R2gstrate = 0, @R2pstrate = 0,
					@calculatednewlinetax = 0, @calculatedoldlinetax = 0, @calculatedoldlineretgtax = 0,
					@retainagerel = 0, @retgtaxrel = 0
	      		/* Get GL Company and GLAcct from line.  Each affected 'Release' invoice will be processed
				   separately in order to obtain this specific information that could be (though rarely is)
				   different for the same Bill, Contract/Item.

				   These are the GLAccts relative to the amounts being Credited to the Retainage Receivables
				   account.  Old and New should always be the same for reasons stated at beginning of this
				   procedure. */
	      		select @ReleaseGLARAcct = GLARAcct, @ReleaseGLRetainAcct = GLRetainAcct,
	        		@oldReleaseGLARAcct = GLARAcct, @oldReleaseGLRetainAcct = GLRetainAcct
	      		from bARRT with (nolock)
	      		where ARCo = @arco and RecType = @OrigInvRecType

				/* The calculation below gets the current Open Retainage amount for this Contract/Item on this Invoice. */
	  			select @invline_openretg = isnull(sum(Retainage),0),		-- Pos
					@invline_openretgtax = isnull(sum(RetgTax),0)
	  			from bARTL with (nolock)
	  			where ARCo = @arco and ApplyMth = @Imth and ApplyTrans = @Iartrans and ApplyLine = @Iarline
					and (Mth < @batchmth or (Mth = @batchmth and ARTrans < @thisretgtrans))	--exclude this release amount
																					 		--on 'C' bill and future amounts
				/* Get Old Release Retainage Amount for this Invoice transaction.  This is different (and should not be confused with) 
				   @oldrelretg that is retrieved from JBAL (Total old release retainage value against multiple invoices).  This
				   value is for a single invoice (one of) involved in the Release transaction being changed.  We are concerned
				   with this value because the RecType for this invoice transaction may be different from the other invoices
				   involved and we must report to GL accordingly. Note:  The 1st 'R' in AR has not yet been deleted and is available
				   here (Gets deleted and readded during posting.) */
				if @batchtranstype in ('C','D')
					begin	/* begin Get Old Loop */
	  				select @oldinvline_relretg = isnull(sum(Retainage),0),	-- Neg
						@oldinvline_relretgtax = isnull(sum(RetgTax),0)
		  			from bARTL with (nolock)
		  			where ARCo = @arco and ApplyMth = @Imth and ApplyTrans = @Iartrans and ApplyLine = @Iarline
						and Mth = @batchmth and ARTrans = @thisretgtrans	--(Based on 1st 'R' transaction)
					end		/* End Get Old Loop */

				/* Skip there is no Open Retg and no Change to retg being released prior. */
				if @invline_openretg = 0 and @oldinvline_relretg = 0 goto get_next_bcARTL_I

				/*  If here, we have either Open Retainage to be released on this invoice or there has been a
					change on the current bill that will effect GL entries.  Determine New Release amount to 
					be Debited and Credited to GL.  

					Based upon the Total Release amount, determining the new amount to release on each individual
					invoice is done here.  It is similar to the evaluation process that will later take place
					in the posting procedure.  (It needs to be this way because reporting to GL is done based
					upon each individual invoices RecType).  The Old release amount was retrieved above and will
					get reported to GL as well.  */
				
				/* Either of these conditions would be caused by the following.  
					a)  A Bill has been marked for Delete.
					b)  A Bill has been marked as Changed and the NEW release amount is less than the OLD release amount.
				   This protects from incorrectly analysing Invoices containing Negative (reverse polarity) lines.
				   For deleted bills, new values do not apply.  For changed bills, new values have already been processed and we 
				   have reach a point where we are simply backing out remaining old values from GL.  At this stage, GL is based strickly on OLD
				   previously posted values and there is no need to do line by line evaluation. */
				if @batchtranstype = 'D' or @oldglonly = 'Y' goto GSTTax_Loop
				
				/* More traditional processing when the above conditions do not yet exist */
				if @100_pct = 'Y'
					begin
					/* Evaluation not required, go directly to GL Routine */
					select @invline_relretg = @invline_openretg
					select @invline_relretgtax = @invline_openretgtax	
					goto GSTTax_Loop
					end
	 			else
					begin
					/* Some form of Evaluation and PostAmount determination required */
					if (@invline_openretg < 0 and @contractitemamt > 0) or (@invline_openretg > 0 and @contractitemamt < 0)
						begin
						/* Open Retainage has gone Negative on this invoice. Post full amount to compensate. */
						select @oppositeopenretgflag = 'Y'		--Distributed amount accumulates differently later
						select @invline_relretg = @invline_openretg
						select @invline_relretgtax = @invline_openretgtax
						end 
					else
						begin
						/* This is normal Postive (or normal Negative) open retainage.  Distribute accordingly */
						if @distamtstilloppositeflag = 'N'
							begin
		   					if abs(@dist_amt + @invline_openretg) <= abs(@RetgRel)		-- abs(Pos + Pos) <= abs(Pos), abs() required here for Negative Items
								begin
		   						select @invline_relretg = @invline_openretg				-- Pos = Pos		(or Neg = Neg)
								select @invline_relretgtax = @invline_openretgtax
								end
		 					else
								begin
		   						select @invline_relretg = @RetgRel - @dist_amt			-- Pos = Pos - Pos	(or Neg - (-Neg))
								select @invline_relretgtax = @LineRetgTaxRel - @dist_amttax
								end
							end
						else
							begin
							if ((@dist_amt + @invline_openretg) < 0 and @RetgRel > 0) or ((@dist_amt + @invline_openretg) > 0 and @RetgRel < 0)
								begin
								/* Because of Negative/Opposite polarity open retg values along the way the distributed amount has 
								   gone negative, leaving us with more to distribute than we originally began with.  When combined with
								   this invoice lines open retg for this item, we are still left with more than we began with.  Therefore
								   it is OK to release the full amount on this Line/Item and move on. There is no need for specific
								   evaluation since we are not in jeopardy of releasing more than we have. */
								select @invline_relretg = @invline_openretg
								select @invline_relretgtax = @invline_openretgtax
								end
							else
								begin
								/* Combined amounts swing in the correct direction, continue with normal evaluation process */
			   					if abs(@dist_amt + @invline_openretg) <= abs(@RetgRel)		-- abs(Pos + Pos) <= abs(Pos), abs() required here for Negative Items
									begin
			   						select @invline_relretg = @invline_openretg				-- Pos = Pos		(or Neg = Neg)
									select @invline_relretgtax = @invline_openretgtax
									end
			 					else
									begin
			   						select @invline_relretg = @RetgRel - @dist_amt			-- Pos = Pos - Pos	(or Neg - (-Neg))
									select @invline_relretgtax = @LineRetgTaxRel - @dist_amttax
									end
								end						
							end
	 					end
					end

			GSTTax_Loop:

/*****************************************************************************************************
*
*									NORMAL RELEASE
*						RETRIEVE TAX INFORMATION AND SETUP TAX VALUES
*								BASED ON AR Company SETUP
*
******************************************************************************************************/

				if @posttaxoninv = 'N' or (@posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N'))
					begin	/* Begin Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
					/* Not used but for consistency post TaxGroup, TaxCode on 2nd R transactions.  */
					select @newtaxgroup = isnull(TaxGroup, @invlinetaxgroup), @newtaxcode = isnull(TaxCode, @invlinetaxcode)
					from bJCCI with (nolock)
					where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractItem
					end		/* End Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
				if @posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'Y')
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
					/* Original invoice line TaxCode validation and info retrieval */
					if isnull(@invline_relretgtax, 0) <> 0 and @invlinetaxcode is null
						begin
						select @errortext = @errorstart + 'Line ' + isnull(convert(varchar(6),@ARLine),'') + 
							' must contain a TaxCode when tax amounts are not 0.00.'
						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
						if @rcode <> 0 goto bspexit
						end

					/*Validate original invoice line Tax Group if there is a tax code */
					if @invlinetaxcode is not null
						begin
						if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @invlinetaxgroup)
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @invlinetaxgroup),'')
							select @errortext = @errorstart + ' - is not valid!'
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end
						end

					/* Validate original invoice line TaxCode by getting the accounts for the tax code */
					if @invlinetaxcode is not null
						begin
						exec @rcode = bspHQTaxRateGetAll @invlinetaxgroup, @invlinetaxcode, @originvtransdate, null, @taxrate output, @gstrate output, @pstrate output, 
							@HQTXcrdGLAcct output, @HQTXcrdRetgGLAcct output, null, null, @HQTXcrdGLAcctPST output, 
							@HQTXcrdRetgGLAcctPST output, NULL, NULL, @errmsg output

						if @rcode <> 0
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@jbco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @invlinetaxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@invlinetaxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						if @pstrate = 0
							begin
							/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
							   In any case:
							   a)  @taxrate is the correct value.  
							   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
							   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
							select @RetgTax = isnull(@invline_relretgtax,0)
							end
						else
							begin
							/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
							if @taxrate <> 0
								begin
								select @RetgTax = (isnull(@invline_relretgtax,0) * @gstrate) / @taxrate		--GST RetgTax
								select @RetgTaxPST = isnull(@invline_relretgtax,0) - @RetgTax				--PST RetgTax
								end
							end
						end
					/* End original invoice line TaxCode validation and info retrieval */

					/* NEW TaxCode validation and info retrieval - TaxGroup, TaxCode validation will take place only when
					   the Contract Item TaxGroup/TaxCode is no longer the same as what was on the original invoice line. */
					if @jbcontract is not null and @jbcontractItem is not null
						begin
						/* Contract, ContractItem exists on this line.  Use Item TaxCode information.  Line and Customer TaxCode values are better
						   then nothing but not ideal.  */
						select @itemtaxgroup = isnull(TaxGroup, @invlinetaxgroup), @itemtaxcode = isnull(TaxCode, @invlinetaxcode)
						from bJCCI with (nolock)
						where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractItem

						--if @itemtaxgroup <> @invlinetaxgroup or @itemtaxcode <> @invlinetaxcode
						--	begin
						if isnull(@invline_relretgtax, 0) <> 0 and @itemtaxcode is null
							begin
							select @errortext = @errorstart + 'TaxCode must exist on contract item or original invoice line	to properly post NEW Released retainage tax amounts to GL. '
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						/*Validate Item Tax Group if there is a tax code */
						if @itemtaxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @itemtaxgroup)
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @itemtaxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end
							
						select @newtaxgroup = @itemtaxgroup, @newtaxcode = @itemtaxcode
						--	end
						end
					else
						begin
						/* When Contract is NULL, NEW TaxCode information must must come from another source.  
						   CONTRACT IS NEVER NULL in JB Release Retainage at this time.  Currently Retainage is released
						   only from JB Progress Billing where contracts are required. */
						select @newtaxgroup = isnull(@invlinetaxgroup,@HQCOtaxgroup), @newtaxcode = isnull(@invlinetaxcode,@custtaxcode)
						if isnull(@invline_relretgtax, 0) <> 0 and @newtaxcode is null
							begin
							select @errortext = @errorstart + 'TaxCode must exist on original invoice line or Customer to properly post NEW Released retainage tax amounts to GL. '
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end
		   
						/*Validate Item Tax Group if there is a tax code */
						if @newtaxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @newtaxgroup)
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @newtaxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end
						end

					/* Get NEW TaxCode information and rates */
					if @newtaxcode is not null
						begin
						exec @rcode = bspHQTaxRateGetAll @newtaxgroup, @newtaxcode, @transdate, null, @newtaxrate output, @newgstrate output, @newpstrate output, 
							@newHQTXcrdGLAcct output, @newHQTXcrdRetgGLAcct output, null, null, @newHQTXcrdGLAcctPST output, 
							@newHQTXcrdRetgGLAcctPST output, NULL,NULL, @errmsg output

						if @rcode <> 0
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @newtaxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@newtaxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						if @newtaxrate <> @taxrate
							begin
							/* Original invoice line Tax Rates vs New Tax Rates are different due to different Tax Code or new effective date.  We must
							   calculate new retainage tax values. */
							if @newpstrate = 0
								begin
								/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
								   In any case:
								   a)  @taxrate is the correct value.  
								   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
								   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
								select @newTax = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) * @newtaxrate
								end
							else
								begin
								/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
								if @newtaxrate <> 0
									begin
									select @calculatednewlinetax = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) * @newtaxrate
									select @newTax = (@calculatednewlinetax * @newgstrate) / @newtaxrate	-- New GST Tax
									select @newTaxPST = @calculatednewlinetax - @newTax						-- New PST Tax
									end
								end
							end
						else
							begin
							/* Original invoice line Tax Rate is same as New Tax Rate.  To avoid rounding errors simply use Retainage Tax values
							   directly from Line. */
							select @newTax = @RetgTax
							select @newTaxPST = @RetgTaxPST
							end
						end
					/* End Item (New) TaxCode validation and info retrieval */

					/* Begin 'C'hange or 'D'elete mode TaxCode validation and info retrieval */
					if @batchtranstype <> 'A'
						begin
						select @R2date = h.TransDate, @R2taxgroup = l.TaxGroup, @R2taxcode = l.TaxCode
						from bARTH h with (nolock)
						join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
						where l.ARCo = @arco and l.Mth = @billmth and l.ARTrans = @OrigInvTrans and l.Contract = @jbcontract
							and l.Item = @jbcontractItem

						/*Validate 'Released' Tax Group if there is a tax code */
						if @R2taxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @R2taxgroup)
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @R2taxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end

						/* Get Released TaxCode information and rates */
						if @R2taxcode is not null
							begin
							exec @rcode = bspHQTaxRateGetAll @R2taxgroup, @R2taxcode, @R2date, null, @R2taxrate output, @R2gstrate output, @R2pstrate output, 
								@R2HQTXcrdGLAcct output, @R2HQTXcrdRetgGLAcct output, null, null, @R2HQTXcrdGLAcctPST output, 
								@R2HQTXcrdRetgGLAcctPST output, NULL, NULL,@errmsg output

							if @rcode <> 0
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @R2taxgroup),'')
								select @errortext = @errortext + ' - TaxCode : ' + isnull(@R2taxcode,'') + ' - is not valid! - ' + @errmsg
								exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end

							/* Get OLD RetgTax values.  These are based upon R1 release amounts using the same TaxGroup/TaxCode 
							   as the Orig Invoice Line.  The only thing that varies is the amount being released. */
							if @pstrate = 0
								begin
								select @oldRetgTax = @oldinvline_relretgtax			--represents old retg tax released
								end
							else
								begin
								if @taxrate <> 0
									begin
									select @oldRetgTax = (@oldinvline_relretgtax * @gstrate) / @taxrate				-- old GST RetgTax
									select @oldRetgTaxPST = @oldinvline_relretgtax - @oldRetgTax					-- old PST RetgTax
									end
								end

							/* Get OLD (adjusted Tax value on new 'Released' invoice) */
							if @R2pstrate = 0
								begin
								/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
								   In any case:
								   a)  @taxrate is the correct value.  
								   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
								   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
								select @oldTax = (@oldinvline_relretg - @oldinvline_relretgtax) * @R2taxrate		--represents old tax (old - new retg tax value) prev posted as open tax payable
								end
							else
								begin
								/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
								if @R2taxrate <> 0
									begin
									select @calculatedoldlinetax = (@oldinvline_relretg - @oldinvline_relretgtax) * @R2taxrate
									select @oldTax = (@calculatedoldlinetax * @R2gstrate) / @R2taxrate	-- old GST Tax
									select @oldTaxPST = @calculatedoldlinetax - @oldTax								-- old PST Tax
									end
								end
							end
						end
						/* End 'C'hange or 'D'elete mode TaxCode validation and info retrieval */

					end	/* End International Release Retainage distribution.  Retainage already taxed, now report separately.  */

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'N' and @arcoseparateretgtax = 'N')
					begin	/* Begin International Release Retainage distribution.  Tax Retainage at this time. */
					/* NEW TaxCode validation and info retrieval */
					if @jbcontract is not null and @jbcontractItem is not null
						begin
						/* Contract, ContractItem exists on this line.  Use Item TaxCode information.  Line and Customer TaxCode values are better
						   then nothing but not ideal.  */
						select @itemtaxgroup = isnull(TaxGroup, @invlinetaxgroup), @itemtaxcode = isnull(TaxCode, @invlinetaxcode)
						from bJCCI with (nolock)
						where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractItem
						--if @itemtaxcode is null
						--	begin
						--	select @errortext = @errorstart + 'TaxCode must exist on contract item or original invoice line to properly post NEW Released retainage tax amounts to GL. '
						--	exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
						--	if @rcode <> 0 goto bspexit
						--	end

						/*Validate Item Tax Group if there is a tax code */
						if @itemtaxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @itemtaxgroup)
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @itemtaxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end
							
						select @newtaxgroup = @itemtaxgroup, @newtaxcode = @itemtaxcode
						end
					else
						begin
						/* When Contract is NULL, NEW TaxCode information must must come from another source.  
						   CONTRACT IS NEVER NULL in JB Release Retainage at this time.  Currently Retainage is released
						   only from JB Progress Billing where contracts are required. */
						select @newtaxgroup = isnull(@invlinetaxgroup,@HQCOtaxgroup), @newtaxcode = isnull(@invlinetaxcode,@custtaxcode)
						--if @newtaxcode is null
						--	begin
						--	select @errortext = @errorstart + 'TaxCode must exist on original invoice line to properly post NEW Released retainage tax amounts to GL. '
						--	exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
						--	if @rcode <> 0 goto bspexit
						--	end				

						/*Validate Item Tax Group if there is a tax code */
						if @newtaxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @newtaxgroup)
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @newtaxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end
						end

					/* Get NEW TaxCode information and rates */
					if @newtaxcode is not null
						begin 
						exec @rcode = bspHQTaxRateGetAll @newtaxgroup, @newtaxcode, @transdate, null, @newtaxrate output, @newgstrate output, @newpstrate output, 
							@newHQTXcrdGLAcct output, @newHQTXcrdRetgGLAcct output, null, null, @newHQTXcrdGLAcctPST output, 
							@newHQTXcrdRetgGLAcctPST output, NULL, NULL,@errmsg output

						if @rcode <> 0
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @newtaxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@newtaxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						if @newpstrate = 0
							begin
							/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
							   In any case:
							   a)  @taxrate is the correct value.  
							   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
							   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
							select @newTax = isnull(@invline_relretg,0) * @newtaxrate
							end
						else
							begin
							/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
							if @newtaxrate <> 0
								begin
								select @calculatednewlinetax = isnull(@invline_relretg,0) * @newtaxrate
								select @newTax = (@calculatednewlinetax * @newgstrate) / @newtaxrate	-- New GST Tax
								select @newTaxPST = @calculatednewlinetax - @newTax						-- New PST Tax
								end
							end
						end
					/* End Item (New) TaxCode validation and info retrieval */

					/* Begin 'C'hange or 'D'elete mode TaxCode validation and info retrieval */
					if @batchtranstype <> 'A'
						begin
						select @R2date = h.TransDate, @R2taxgroup = l.TaxGroup, @R2taxcode = l.TaxCode	--(Based on 2nd 'R')
						from bARTH h with (nolock)
						join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
						where l.ARCo = @arco and l.Mth = @billmth and l.ARTrans = @OrigInvTrans and l.Contract = @jbcontract
							and l.Item = @jbcontractItem			

						/*Validate Released Tax Group if there is a tax code */
						if @R2taxcode is not null
							begin
							if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @R2taxgroup)
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @R2taxgroup),'')
								select @errortext = @errorstart + ' - is not valid!'
								exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end
							end

						/* Get Released TaxCode information and rates */
						if @R2taxcode is not null
							begin
							exec @rcode = bspHQTaxRateGetAll @R2taxgroup, @R2taxcode, @R2date, null, @R2taxrate output, @R2gstrate output, @R2pstrate output, 
								@R2HQTXcrdGLAcct output, @R2HQTXcrdRetgGLAcct output, null, null, @R2HQTXcrdGLAcctPST output, 
								@R2HQTXcrdRetgGLAcctPST output, NULL, NULL, @errmsg output

							if @rcode <> 0
								begin
								select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @R2taxgroup),'')
								select @errortext = @errortext + ' - TaxCode : ' + isnull(@R2taxcode,'') + ' - is not valid! - ' + @errmsg
								exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
								if @rcode <> 0 goto bspexit
								end

							/* Get OLD (adjusted Tax value on new 'Released' invoice) */
							if @R2pstrate = 0
								begin
								/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
								   In any case:
								   a)  @taxrate is the correct value.  
								   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
								   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
								select @oldRetgTax = 0										--represents old retg tax released
								select @oldTax = @oldinvline_relretg * @R2taxrate		--represents old tax (old - new retg tax value) prev posted as open tax payable
								end
							else
								begin
								/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
								if @R2taxrate <> 0
									begin
									select @oldRetgTax = 0						-- old GST RetgTax
									select @oldRetgTaxPST = 0					-- old PST RetgTax

									select @calculatedoldlinetax = @oldinvline_relretg * @R2taxrate
									select @oldTax = (@calculatedoldlinetax * @R2gstrate) / @R2taxrate	-- old GST Tax
									select @oldTaxPST = @calculatedoldlinetax - @oldTax								-- old PST Tax
									end
								end
							end
						end
					/* End 'C'hange or 'D'elete mode TaxCode validation and info retrieval */

					end		/* End International Release Retainage distribution.  Tax Retainage at this time. */

/*****************************************************************************************************
*
*								NORMAL RELEASE GL DISTRIBUTIONS
*
******************************************************************************************************/			

			GL_Loop:
				if @posttaxoninv = 'N' or (@posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N'))
					begin	/* Begin Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */
						if isnull(@invline_relretg,0) <> 0 or isnull(@oldinvline_relretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
  							select @i=1 /* Set first account */
	  						while @i<=2
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0
	   
	        					/* AR Account */
	        					if @i=1
	          						begin
									/* GLAccts from JBAR.RecType and JBAR.oldRecType */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @GLARAcct, @PostAmount = isnull(@invline_relretg,0),
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldGLARAcct, @oldPostAmount = isnull(@oldinvline_relretg,0),
	                 					@errorAccount = 'AR Receivable Account'
	          						end
	   
	        					/* Retainage Account */
	        					if @i=2
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(-@invline_relretg,0),
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_relretg,0),
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.
	   
								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end
	   
							skip_GLUpdate:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
	   
							end  /* End Processing GL distribution loop */

						select @retgtaxrel = 0
						select @retainagerel = isnull(@invline_relretg,0)

						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					else
						begin	/* Begin Release to AR = 'N' */
						select @retgtaxrel = 0
						select @retainagerel = isnull(@invline_relretg,0)
							exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					end	/* End Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'Y')
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */
						if isnull(@invline_relretg,0) <> 0 or isnull(@oldinvline_relretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
	   	      
  							select @i=1 /* Set first account */
	  						while @i<=6
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0
	   
	        					/* AR Account */
	        					if @i=1
	          						begin
									/* GLAccts from JBAR.RecType and JBAR.oldRecType */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @GLARAcct, 
										@PostAmount = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) + (isnull(@newTax,0) + isnull(@newTaxPST,0)),	--debit w/new tax	
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldGLARAcct, 
										@oldPostAmount = (isnull(@oldinvline_relretg,0) - isnull(@oldinvline_relretgtax,0)) + (isnull(@oldTax,0) + isnull(@oldTaxPST,0)),				--credit w/new tax (old) on change
	                 					@errorAccount = 'AR Receivable Account'

	          						end

	        					/* Retainage Account */
	        					if @i=2
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(-@invline_relretg,0),		--credit w/orig tax
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_relretg,0),	--debit w/orig tax (old) on change
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Retainage Tax account.  Standard US or GST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcct, @PostAmount = isnull(@RetgTax,0),			--debit orig GST				
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @HQTXcrdRetgGLAcct, @oldPostAmount = isnull(@oldRetgTax,0),		--credit orig GST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								
								/* Tax account.  Standard US or GST */
								if @i=4 select @PostGLCo=@ARGLCo, @PostGLAcct=@newHQTXcrdGLAcct, @PostAmount = isnull(-@newTax,0),				--credit new GST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdGLAcct, @oldPostAmount = isnull(-@oldTax,0),				--debit new GST (old) on change
									@errorAccount = 'AR Tax Account'
								
								/* Retainage Tax account.  PST */
								if @i=5 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcctPST, @PostAmount = isnull(@RetgTaxPST,0),			--debit orig PST			
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @HQTXcrdRetgGLAcctPST, @oldPostAmount = isnull(@oldRetgTaxPST,0),	--credit orig PST (old) on change
									@errorAccount = 'AR Retg Tax Account PST'

								
								/* Tax account.  PST */
								if @i=6 select @PostGLCo=@ARGLCo, @PostGLAcct=@newHQTXcrdGLAcctPST, @PostAmount = isnull(-@newTaxPST,0),		--credit new PST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdGLAcctPST, @oldPostAmount = isnull(-@oldTaxPST,0),		--debit new PST (old) on change
									@errorAccount = 'AR Tax Account PST'

								
								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.
	   
								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end
	   
							skip_GLUpdate2:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
	   
							end  /* End Processing GL distribution loop */

						select @retgtaxrel = isnull(@newTax,0) + isnull(@newTaxPST,0)
						select @retainagerel = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) + isnull(@retgtaxrel,0)
						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					else
						begin	/* Begin Release to AR = 'N' */
						if isnull(@invline_relretg,0) <> 0 or isnull(@oldinvline_relretg,0)<> 0
	        				begin	/* Begin Processing GL distribution loop */
	   	      
  							select @i=1 /* Set first account */
	  						while @i<=6
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0
	   
	        					/* Retainage Account */
	        					if @i=1
	          						begin
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(-@invline_relretg,0),		--credit w/orig tax				
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_relretg,0),	--debit w/orig tax (old) on change
	                 					@errorAccount = 'AR Retainage Account'
	          						end

		        				/* Retainage Account */
	        					if @i=2
	          						begin
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, 
										@PostAmount = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) + (isnull(@newTax,0) + isnull(@newTaxPST,0)),	--debit w/new tax
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, 
										@oldPostAmount = (isnull(@oldinvline_relretg,0) - isnull(@oldinvline_relretgtax,0)) + (isnull(@oldTax,0) + isnull(@oldTaxPST,0)),				--credit w/new (old) tax on change
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Retainage Tax account.  Standard US or GST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcct, @PostAmount = isnull(@RetgTax,0),			--debit orig GST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @HQTXcrdRetgGLAcct, @oldPostAmount = isnull(@oldRetgTax,0),		--credit orig GST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Retainage Tax account.  Standard US or GST */
								if @i=4 select @PostGLCo=@ARGLCo, @PostGLAcct=@newHQTXcrdRetgGLAcct, @PostAmount = isnull(-@newTax,0),		--credit new GST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdRetgGLAcct, @oldPostAmount = isnull(-@oldTax,0),		--debit new GST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Retainage Tax account.  PST */
								if @i=5 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcctPST, @PostAmount = isnull(@RetgTaxPST,0),			--debit orig PST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @HQTXcrdRetgGLAcctPST, @oldPostAmount = isnull(@oldRetgTaxPST,0),	--credit orig PST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Retainage Tax account.  PST */
								if @i=6 select @PostGLCo=@ARGLCo, @PostGLAcct=@newHQTXcrdRetgGLAcctPST, @PostAmount = isnull(-@newTaxPST,0),		--credit new PST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdRetgGLAcctPST, @oldPostAmount = isnull(-@oldTaxPST,0),		--debit new PST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.
	   
								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end
	   
							skip_GLUpdate3:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
	   
							end  /* End Processing GL distribution loop */

						select @retgtaxrel = isnull(@newTax,0) + isnull(@newTaxPST,0)
						select @retainagerel = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) + isnull(@retgtaxrel,0)
						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					end		/* End International Release Retainage distribution.  Retainage already taxed, now report separately.  */

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'N' and @arcoseparateretgtax = 'N')
					begin	/* Begin International Release Retainage distribution.  Tax Retainage at this time. */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */
						if isnull(@invline_relretg,0) <> 0 or isnull(@oldinvline_relretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
	   	      
  							select @i=1 /* Set first account */
	  						while @i<=4
	        					begin	/* Begin GL */

	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0
	   
	        					/* AR Account */
	        					if @i=1
	          						begin
									/* GLAccts from JBAR.RecType and JBAR.oldRecType */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @GLARAcct, 
										@PostAmount = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) + (isnull(@newTax,0) + isnull(@newTaxPST,0)),	--debit w/new tax (@invline_relretgtax = 0)
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldGLARAcct, 
										@oldPostAmount = (isnull(@oldinvline_relretg,0) - isnull(@oldinvline_relretgtax,0)) + (isnull(@oldTax,0) + isnull(@oldTaxPST,0)),				--credit w/new tax (old) on change  (@invline_relretgtax = 0)
	                 					@errorAccount = 'AR Receivable Account'
	          						end

	        					/* Retainage Account */
	        					if @i=2
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(-@invline_relretg,0),		--credit w/orig tax  (Orig Tax = 0)
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_relretg,0),	--debit w/orig tax (old) on change  (Orig Tax = 0)
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Tax account.  Standard US or GST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@newHQTXcrdGLAcct, @PostAmount = isnull(-@newTax,0),		--credit new GST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdGLAcct, @oldPostAmount = isnull(-@oldTax,0),		--debit new GST (old) on change
									@errorAccount = 'AR Tax Account'

								/* Tax account.  PST */
								if @i=4 select @PostGLCo=@ARGLCo, @PostGLAcct=@newHQTXcrdGLAcctPST, @PostAmount = isnull(-@newTaxPST,0),		--credit new PST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdGLAcctPST, @oldPostAmount = isnull(-@oldTaxPST,0),		--debit new PST (old) on change
									@errorAccount = 'AR Tax Account PST'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.
								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end

							skip_GLUpdate4:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */

							end  /* End Processing GL distribution loop */

						select @retgtaxrel = isnull(@newTax,0) + isnull(@newTaxPST,0)
						select @retainagerel = isnull(@invline_relretg,0) + isnull(@retgtaxrel,0)
							exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					else
						begin	/* Begin Release to AR = 'N' */
						if isnull(@invline_relretg,0) <> 0 or isnull(@oldinvline_relretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
	   	      
  							select @i=1 /* Set first account */
	  						while @i<=4
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0
	   
	        					/* Retainage Account */
	        					if @i=1
	          						begin
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(-@invline_relretg,0),		--credit w/orig tax		(Orig Tax = 0)			
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_relretg,0),	--debit w/orig tax (old) on change  (Orig Tax = 0)
	                 					@errorAccount = 'AR Retainage Account'
	          						end

		        				/* Retainage Account */
	        					if @i=2
	          						begin
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, 
										@PostAmount = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) + (isnull(@newTax,0) + isnull(@newTaxPST,0)),	--debit w/new tax
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, 
										@oldPostAmount = (isnull(@oldinvline_relretg,0) - isnull(@oldinvline_relretgtax,0)) + (isnull(@oldTax,0) + isnull(@oldTaxPST,0)),				--credit w/new (old) tax on change
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Retainage Tax account.  Standard US or GST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@newHQTXcrdRetgGLAcct, @PostAmount = isnull(-@newTax,0),		--credit new GST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdRetgGLAcct, @oldPostAmount = isnull(-@oldTax,0),		--debit new GST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Retainage Tax account.  PST */
								if @i=4 select @PostGLCo=@ARGLCo, @PostGLAcct=@newHQTXcrdRetgGLAcctPST, @PostAmount = isnull(-@newTaxPST,0),		--credit new PST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdRetgGLAcctPST, @oldPostAmount = isnull(-@oldTaxPST,0),		--debit new PST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.
	   
								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end
	   
							skip_GLUpdate5:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
	   
							end  /* End Processing GL distribution loop */

						select @retgtaxrel = isnull(@newTax,0) +isnull(@newTaxPST,0)
						select @retainagerel = (isnull(@invline_relretg,0) - isnull(@invline_relretgtax,0)) + isnull(@retgtaxrel,0)
							exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					end		/* End International Release Retainage distribution.  Tax Retainage at this time. */

/*****************************************************************************************************
*
*			DETERMINE IF REMAINING AMOUNTS ARE TO BE RELEASED.  IF SO, GO TO NEXT INVOICE
*
******************************************************************************************************/	

				/* We have evaluated and process all NEW values at this point.  We are only dealing with remaining OLD values now.
				   OLD values come directly from the previously posted amounts and no further evaluation is necessary.  
				   Get next release invoice transaction. */
				if @batchtranstype = 'D' or @oldglonly = 'Y' goto get_next_bcARTL_I
				
				select @dist_amt = @dist_amt + isnull(@invline_relretg,0)
				select @dist_amttax = @dist_amttax + isnull(@invline_relretgtax,0)

				if (@dist_amt < 0 and @RetgRel > 0) or (@dist_amt > 0 and @RetgRel < 0)
					begin
					/* Our distribution amount has gone negative due to some Opposite Open Retainage values along the way.
					   Setting flag will help suspend some comparisons that require polarities between compared values
					   to be the same. */
					select @distamtstilloppositeflag = 'Y'
					end
				else
					begin
					select @distamtstilloppositeflag = 'N'
					end
		
				if @currentbill = 'N'
					begin
					/* Determine whether to move on to next Invoice or not. */
					if @100_pct = 'Y'
						begin
						/* We are releasing full amount for this Item/Line on all invoices in list. Just keep going. */
						goto get_next_bcARTL_I
						end
					else
						begin
						if @oppositeopenretgflag = 'Y'
							begin
							/* No evaluation necessary, we have more to Release than we began with */
							select @oppositeopenretgflag = 'N'
							goto get_next_bcARTL_I
							end
						else
							begin
							if @distamtstilloppositeflag = 'Y'
								begin
								/* We still have more money reserved to release than we originally began with.
								   No need for comparisons. Just get next Invoice for this Line/Item. */
								goto get_next_bcARTL_I
								end
							else
								begin
								/* Conditions are relatively normal at this point.  We are not (or no longer) dealing with 
								   negative/opposite OpenRetg on this invoice nor is our overall distribution amount
								   negative/opposite at this stage of the distribution process.  Therefore we must now continue
								   to compare values to assure that we distribute/release no more than was intended.   */
								if @currentbill = 'N'
									begin
									if (abs(@RetgRel) > abs(isnull(@oldRetgRel,0)))
										begin
										/* This is the Normal on New bills or those being changed where the New amount being
										   released is greater than the old release amount. */
			      						if abs(@dist_amt) < abs(@RetgRel) goto get_next_bcARTL_I else goto ARTL_loop_end	
										end
									else
										begin	
										/* This is a CHANGED bill and the New amount being released is less than the Old release amount. */
										if abs(@dist_amt) < abs(@RetgRel) 
											begin
											/* Normal processing until the New release amounts have been processed. */
											goto get_next_bcARTL_I
											end
										else
											begin
											/* If we have reduced the amount being released on a previously interfaced bill, although 
											   we have distributed all that we are going to at this point, we will continue
											   to cycle through the remaining Invoice transactions in order to back out of GL, the
											   remaining old values that have exceeded the new values. */
											select @oldglonly = 'Y'
											if abs(@dist_amt) < abs(@oldRetgRel) goto get_next_bcARTL_I	else goto ARTL_loop_end	
											end
										end
									end
								end
							end
						end
					end
				else
					begin
					/* We have just completed releasing retainage against the New Bill we are using to Release Retainage.
					   There are no other invoices to process at this point.  Return to where we left off. 
					   OR
					   We have just updated GL with an OverRelease amount.  Again we want to return to where we left off. */
					Goto NormalReleaseGL_End
					end
      			end /* End ARTL process Release Invoice loop */
	
		ARTL_loop_end:
			if @opencursor_ARTL_I = 1
				begin
				close bcARTL_I
				deallocate bcARTL_I
				select @opencursor_ARTL_I = 0
				end

/*****************************************************************************************************
*
*								RELEASE RETAINAGE ON CURRENT JB BILL
*
******************************************************************************************************/	

			/* Release Validation is generally a mirror of bspJBAR_PostRelRetg to assure equal evaluation
			   and application of dollar values.  This is the exception!  During Validation, the current
			   Bill potentially has never been posted (Active Bill) and so all of the previous GL processing,
			   to this point catches everything except for Releasing Retainage on this bill if there is
			   any to release.  Therefore we must make one final GL pass for this Contract Item if there
			   is any remaining retainage available to release. */
			if @batchtranstype = 'A' and (abs(@dist_amt) < abs(@RetgRel)) and @jb_retg <> 0
				and @currentbill = 'N'
				begin
				select @invline_openretg = 0, @oldinvline_relretg = 0,	@invline_relretg = 0,
					@invline_openretgtax = 0, @oldinvline_relretgtax = 0, @invline_relretgtax = 0,
					@invlinetaxgroup = @JBALtaxgroup, @invlinetaxcode = @JBALtaxcode, @originvtransdate = @transdate,
					@currentbill = 'Y'	--Keeps us from attempting to process more Invoice Lines when we return to update GL

				/* Open Retainage is this current bills Retainage for this Contract Item */		
				select @invline_openretg = @jb_retg
				select @invline_openretgtax = @LineRetgTax

				/* These are the GLAccts relative to the amounts being Credited to the Retainage Receivables
				   account.  Old and New should always be the same for reasons stated at beginning of this
				   procedure. */
	      		select @ReleaseGLARAcct = GLARAcct, @ReleaseGLRetainAcct = GLRetainAcct,
	        		@oldReleaseGLARAcct = GLARAcct, @oldReleaseGLRetainAcct = GLRetainAcct
	      		from bARRT with (nolock)
	      		where ARCo = @arco and RecType = @RecType					

				/* Set Release amounts */
				if @100_pct = 'Y'
					begin
					/* Evaluation not required, go directly to GL Routine */
					select @invline_relretg = @invline_openretg
					select @invline_relretgtax = @invline_openretgtax
					--
					--if @invline_relretgtax <> 0 goto GSTTax_Loop else goto GL_Loop CHS
					goto GSTTax_Loop
					end
	 			else
					begin
					/* Some form of Evaluation and PostAmount determination required */
					if (@invline_openretg < 0 and @contractitemamt > 0) or (@invline_openretg > 0 and @contractitemamt < 0)
						begin
						/* Open Retainage has gone Negative on this invoice. Post full amount to compensate. */
						select @oppositeopenretgflag = 'Y'		--Distributed amount accumulates differently later
						select @invline_relretg = @invline_openretg
						select @invline_relretgtax = @invline_openretgtax
						end 
					else
						begin
						/* This is normal Postive (or normal Negative) open retainage.  Distribute accordingly */
						if @distamtstilloppositeflag = 'N'
							begin
		   					if abs(@dist_amt + @invline_openretg) <= abs(@RetgRel)		-- abs(Pos + Pos) <= abs(Pos), abs() required here for Negative Items
								begin
		   						select @invline_relretg = @invline_openretg				-- Pos = Pos		(or Neg = Neg)
								select @invline_relretgtax = @invline_openretgtax
								end
		 					else
								begin
		   						select @invline_relretg = @RetgRel - @dist_amt			-- Pos = Pos - Pos	(or Neg - (-Neg))
								select @invline_relretgtax = @LineRetgTaxRel - @dist_amttax
								end
							end
						else
							begin
							if ((@dist_amt + @invline_openretg) < 0 and @RetgRel > 0) or ((@dist_amt + @invline_openretg) > 0 and @RetgRel < 0)
								begin
								/* Because of Negative/Opposite polarity open retg values along the way the distributed amount has 
								   gone negative, leaving us with more to distribute than we originally began with.  When combined with
								   this invoice lines open retg for this item, we are still left with more than we began with.  Therefore
								   it is OK to release the full amount on this Line/Item and move on. There is no need for specific
								   evaluation since we are not in jeopardy of releasing more than we have. */
								select @invline_relretg = @invline_openretg
								select @invline_relretgtax = @invline_openretgtax
								end
							else
								begin
								/* Combined amounts swing in the correct direction, continue with normal evaluation process */
			   					if abs(@dist_amt + @invline_openretg) <= abs(@RetgRel)		-- abs(Pos + Pos) <= abs(Pos), abs() required here for Negative Items
									begin
			   						select @invline_relretg = @invline_openretg				-- Pos = Pos		(or Neg = Neg)
									select @invline_relretgtax = @invline_openretgtax
									end
			 					else
									begin
			   						select @invline_relretg = @RetgRel - @dist_amt			-- Pos = Pos - Pos	(or Neg - (-Neg))
									select @invline_relretgtax = @LineRetgTaxRel - @dist_amttax
									end
								end						
							end
	 					end
					--if @invline_relretgtax <> 0 goto GSTTax_Loop else goto GL_Loop
					 goto GSTTax_Loop  --FIX FOR Issue #140708
					end	
				end

		NormalReleaseGL_End:
			if @batchtranstype in ('A', 'C')
				begin
				/* At this point after processing GL for all previous invoice Lines for this Item, if there is still a 
				   remaining Release amount unaccounted for, we will make one last pass to the GL process for this
				   amount.  (The posting routine is going to add it to the Last Invoice, Last Line for this item) */
				if @dist_amt <> @RetgRel
					begin
					/* Throughout this process, @dist_amt may have swung in value both Positive and Negative depending
					   on OpenRetg amounts for a given Invoice/Line Item.  However all invoices have been processed
					   and @dist_amount must be equal to @RetgRel or (There are some exceptions that have been identified) 
							1)  They are unequal because the user over released on a bill.
					   Therefore regardless of whether this is Negative ContractItem or Positive ContractItem,
					   we only care that there is a remaining amount not accounted for in GL */
					select @currentbill = 'Y'	--Keeps us from attempting to process more Invoice Lines when we return to update GL
					select @invline_relretg = @RetgRel - @dist_amt			-- Pos = Pos - Pos	(or Neg - (-Neg))
					select @invline_relretgtax = @LineRetgTaxRel - @dist_amttax
					select @oldinvline_relretg = 0, @oldinvline_relretgtax = 0

					/* AMOUNT TO RELEASE STILL REMAINS FOR THIS ITEM BUT WE HAVE RUN OUT OF LINES!  ALL INVOICES
					   INCLUDING THIS INVOICE BEING USED TO RELEASE RETAINAGE HAVE BEEN PROCESSED AND YET THERE
					   REMAINS AN AMOUNT NOT YET RELEASED.

					   In this condition we are over releasing retainage on this ITEM but it will be allowed.  In affect
					   we will over release retainage on the invoice that is being used to release retainage in the 
					   first place. */
      				select @ReleaseGLARAcct = GLARAcct, @ReleaseGLRetainAcct = GLRetainAcct,
        				@oldReleaseGLARAcct = GLARAcct, @oldReleaseGLRetainAcct = GLRetainAcct
      				from bARRT with (nolock)
      				where ARCo = @arco and RecType = @RecType		--Use the Releasing Bill's RecType for GL Accounts

					if @invline_relretgtax <> 0 goto GSTTax_Loop else goto GL_Loop
					end	
				end		
			end		/* End Processing GL for Normal Release */

/*****************************************************************************************************
*
*									REVERSE RELEASE
*	BASED ON TOTAL AMOUNT TO BE REVERSED, CALCULATE REVERSED AMOUNTS FOR EACH INDIVIDUAL INVOICE
*
******************************************************************************************************/


		/************************ Reverse Release Retainage GL distribution *************************/
		/* 																							*/
		/* READ BEFORE PROCEEDING!																	*/
		/*     This is very different.  It must be performed in 2 separate operations.  The first	*/
		/* operation will reverse amounts from the AR (Released) invoices that got generated as a 	*/
		/* result of releasing to AR.  This one Reversing action may apply to multiple AR (Released)*/
		/* invoices.  Each AR (Released) invoice has the potential to contain a different RecType	*/
		/* (also independent and possibly different than those invoices that we are releasing from) */
		/* then others involved in this same process and therefore must be reported to GL, one at 	*/
		/* a time, in case they are different.														*/
		/*    By the same token, the second operation which is the process of returning amounts		*/
		/* back to retainage on each of the individual invoices from which it was originally 		*/
		/* removed must also be done separately.  Again this reversing action may actually 			*/
		/* encompass multiple previous release actions each of which may have removed retainage		*/
		/* from multiple invoices.  Each invoice that previously had retainage released from may	*/
		/* very well contain different RecTypes and again we must return retainage to each and		*/
		/* report to the proper GL.  (Again the RecTypes for the invoices that we will be returning	*/
		/* retainage to has bearing on the RecType of the AR (Released) invoice that got created.	*/
		/* they can be different).																	*/
		/*    Therefore the GL reporting process must go through a similar process as that of the	*/
		/* actual posting routine. (NO SHORTCUTS).  **** Note **** The GL distribution report can	*/
		/* look strange as a result of these two very different processes when in 'C' mode.  They	*/
		/* are however, accurate.  It is different even from the Release Retainage process because	*/
		/* this process may actually be reversing multiple Release Retainage process.				*/
		/*																							*/
		/********************************************************************************************/  
		else
			begin	/* Begin Processing GL for Reverse Release */
			select @dist_amt = 0, @dist_amttax = 0, @distamtstilloppositeflag = 'N', @distamttaxstilloppositeflag = 'N'

/*****************************************************************************************************
*
*									REVERSE RELEASE
*					PROCESS THE 2ND 'R' TRANSACTIONS FOR REVERSAL
*
******************************************************************************************************/

			/* Reverse Release validation has to be a two step process because there may be multiple (Released)
			   invoices involved (possible different RecTypes on each) affecting possible different 
			   AR Receivable Accts and there likely is multiple (Release) invoices involved
			   (possible different RecTypes on each) affecting possible different AR Retainage Receivable
			   accts.  (This is different than normal Release Retainage validation because only one (Released)
			   invoice gets created during that process).

			   Begin by creating GL entries for the AR Receivable Accounts (displayed first in a 
			   GL Distribution list) to be consistent with GL distribution for normal Release Retainage action. */ 

				/******* Step #1 Reverse Release GL - AR Receivable *******/				   
			/* Need to create list of 'Released' invoices that may be reversed to some extent. */
    		declare bcARTL_V scroll cursor for
    		select l.ApplyMth, l.ApplyTrans, l.ApplyLine, l.RecType, h.TransDate, l.TaxGroup, l.TaxCode
    		from bARTH h with (nolock)
    		join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
						l.JCCo = @jbco and l.Contract = @jbcontract and l.Item = @jbcontractItem	-- This contract/Item only
    		where h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
				and (h.Mth < @batchmth or (h.Mth = @batchmth and h.ARTrans < @thisinvtrans))	-- Prior to this Released trans
				and h.ARTransType = 'R'														-- Released values only
				and (l.Mth = l.ApplyMth and l.ARTrans = l.ApplyTrans)	
			order by l.ApplyMth, l.ApplyTrans, l.ApplyLine	
	
    		/* open cursor for line */
    		open bcARTL_V
    		select @opencursorARTL_V = 1
	
    		/**** read cursor lines ****/
    		fetch last from bcARTL_V into @Imth, @Iartrans, @Iarline, @OrigInvRecType, @R2date,
				@R2taxgroup, @R2taxcode
    		while (@@fetch_status = 0)
    			begin	/* Begin V Rev Released Loop */
      			select @invline_openretg = 0, @oldinvline_openretg = 0, @invline_relretg = 0, 
					@oppositerelretgflag = 'N', @oppositerelretgtaxflag = 'N' 
				select @invline_openretgtax = 0, @oldinvline_openretgtax = 0, @invline_relretgtax = 0

				/* Reset Line variables as needed here.  
				   Retrieved as each Lines TaxCode gets validated.  Reset to avoid leftover value when TaxCode is invalid */
				select @itemtaxgroup = null, @itemtaxcode = null, @newtaxgroup = null, @newtaxcode = null,
					@HQTXcrdGLAcct = null, @HQTXcrdRetgGLAcct = null, @HQTXcrdGLAcctPST = null, @HQTXcrdRetgGLAcctPST = null,
					@newHQTXcrdGLAcct = null, @newHQTXcrdRetgGLAcct = null, @newHQTXcrdGLAcctPST = null, @newHQTXcrdRetgGLAcctPST = null,
					@R2HQTXcrdGLAcct = null, @R2HQTXcrdRetgGLAcct = null, @R2HQTXcrdGLAcctPST = null, @R2HQTXcrdRetgGLAcctPST = null,
					@RetgTax = 0, @RetgTaxPST = 0, @oldRetgTax = 0, @oldRetgTaxPST = 0, @newTax = 0, @newTaxPST = 0, @oldTax = 0, @oldTaxPST = 0,
					@taxrate = 0, @gstrate = 0, @pstrate = 0, @newtaxrate = 0, @newgstrate = 0, @newpstrate = 0, 
					@R2taxrate = 0, @R2gstrate = 0, @R2pstrate = 0,
					@calculatednewlinetax = 0, @calculatedoldlinetax = 0, @calculatedoldlineretgtax = 0,
					@retainagerel = 0, @retgtaxrel = 0

	      		/* Get GL Company and GLAcct from line.  Each affected 'Released' invoice will be processed
				   separately in order to obtain this specific information that could be (though rarely is)
				   different for the same Contract/Item.

				   These are the GLAccts relative to the amounts being Credited to the AR Receivables
				   account.  Old and New should always be the same for reasons stated at beginning of this
				   procedure. */
	      		select @ReleaseGLARAcct = GLARAcct, @ReleasedGLRetainAcct = GLRetainAcct,
	        		@oldReleaseGLARAcct = GLARAcct, @oldReleasedGLRetainAcct = GLRetainAcct
	      		from bARRT with (nolock)
	      		where ARCo = @arco and RecType = @OrigInvRecType

				/* For EACH Original 'R' (2nd R) transaction (relative to this contract item) we will
				   get the sum of its Line Amounts.  THIS WILL INCLUDE any payments, credits or reversals that apply
				   against this new AR (2nd R - Released) invoice transaction created when Retainage was released. 
	
				   We have already restricted this cursor to the desired 2nd 'R' (Released) type transactions
				   above. 
	
				   We only want to reverse an amount (on the 2nd R - By line)  that has not previously been reversed
				   by another means. (ie: by Payment, credit, writeoff or reversal). EARLIER VALIDATION WILL PREVENT us from
				   reversing too much overall (on all AR Released invoices) for this Item.  This prevents reversing too much 
				   on this invoice line relative to this item.  */
    			select @invline_relretg = isnull(sum(Amount), 0),	-- Pos, 2nd 'R' Released Invoice Amount remaining after credits for this Item
					@invline_relretgtax = case when @releasetocurrent = 'Y' then isnull(sum(TaxAmount), 0) else isnull(sum(RetgTax), 0) end
    			from bARTL with (nolock)
    			where ARCo = @arco and ApplyMth = @Imth and ApplyTrans = @Iartrans and ApplyLine = @Iarline	-- Sum this 2nd 'R' Released transaction
					and (Mth < @batchmth or (Mth = @batchmth and ARTrans < @thisinvtrans))	-- exclude 'Reversing Amounts' this bill
																							-- in 'C' mode or future bills
				/* Get OLD Reverse Released Retainage Amount from this 'V' transaction as it was posted earlier.  
				   It is possible that we are changing a previous reversal.  In which case it is necessary to report the 
				   old and new reversed values to GL.  */
				if @batchtranstype in ('C','D')
					begin	/* begin Get Old Loop */
    				select @oldinvline_openretg = isnull(sum(Amount), 0),	-- Neg, 2nd 'V' old Amount Reversed
						@oldinvline_openretgtax = case when @releasetocurrent = 'Y' then isnull(sum(TaxAmount), 0) else isnull(sum(RetgTax), 0) end
    				from bARTL with (nolock)
    				where ARCo = @arco and ApplyMth = @Imth and ApplyTrans = @Iartrans and ApplyLine = @Iarline	
					and Mth = @batchmth and ARTrans = @thisinvtrans	 
					end		/* End Get Old Loop */

				/* Skip if there is no Reverse Released Retg and no Change to prior Reversed Released Retg. */
      			if @invline_relretg = 0 and @oldinvline_openretg = 0 goto get_prior_bcARTL_V

				/*  If here, we have either 'Released' retg to be reversed on this 'Released' invoice or there 
					has been a change on the current bill for a previous reversal that will effect GL entries.  
					Determine New Released amount to be Credited and/or Debited to GL AR Receivable Acct.

					Note below that we use Released Retg value that excludes this current bill reversing amounts
					(in the event that this has previously been interfaced).  For all practical
					purposes, a bill being changed doesn't exist.  Validation has already confirmed that the
					change being made is acceptable.  This will be the New amount relative to GL. */
					
				/* Either of these conditions would be caused by the following.  
					a)  A Bill has been marked for Delete.
					b)  A Bill has been marked as Changed and the NEW reverse release amount is less than the OLD release amount.
				   This protects from incorrectly analysing Invoices containing Negative (reverse polarity) lines.
				   For deleted bills, new values do not apply.  For changed bills, new values have already been processed and we 
				   have reach a point where we are simply backing out remaining old values from GL.  At this stage, GL is based strickly on OLD
				   previously posted values and there is no need to do line by line evaluation. */
				if @batchtranstype = 'D' or @revoldglVonly = 'Y' goto GSTTax_LoopRev2	
					
				if @100_pct = 'Y'
					begin
					/* Evaluation not required, go directly to GL Tax Routine (Reversal Total of this Line) */
					select @invline_openretg = @invline_relretg
					select @invline_openretgtax = @invline_relretgtax
					select @dist_amt = @dist_amt + (@invline_relretg - @invline_relretgtax)		--Special! Must be at this location
					goto GSTTax_LoopRev2
					end
				else
					begin
					/* Some form of Evaluation and PostAmount determination required */
					if (@invline_relretg < 0 and @contractitemamt > 0) or (@invline_relretg > 0 and @contractitemamt < 0)
						begin
						/* Somehow the 2nd 'R'eleased invoice that got generated went abnormally negative. (I do not believe
						   this can happen but just in case ....) Reverse/Post full amount to compensate. */
						select @oppositerelretgflag = 'Y'
						select @invline_openretg = @invline_relretg
						select @invline_openretgtax = @invline_relretgtax
						select @dist_amt = @dist_amt + (@invline_relretg - @invline_relretgtax)		--Special! Must be at this location
						end
					else
						begin
						/* This is normal Postive (or normal Negative) release retainage to be reopened.  Distribute accordingly */
						if @distamtstilloppositeflag = 'N'
							begin
							if abs(@dist_amt + (@invline_relretg - @invline_relretgtax)) <= abs(@RetgRel - @LineRetgTaxRel)	--abs(Pos + Pos) <= abs(Pos)
								begin
								select @invline_openretg = @invline_relretg
								select @invline_openretgtax = @invline_relretgtax		-- Pos = Pos	(or Neg = Neg)
								select @dist_amt = @dist_amt + (@invline_relretg - @invline_relretgtax)		--Special! Must be at this location
								end
							else
								begin
								select @invline_openretg = (@RetgRel - @LineRetgTaxRel) - @dist_amt		-- Pos = Pos - Pos	(or Neg - Neg)
								select @dist_amt = @dist_amt + @invline_openretg		--Special! Must be at this location as shown
								end
							end
						else
							begin
							if ((@dist_amt + (@invline_relretg - @invline_relretgtax)) < 0 and (@RetgRel - @LineRetgTaxRel) > 0) 
								or ((@dist_amt + (@invline_relretg - @invline_relretgtax)) > 0 and (@RetgRel - @LineRetgTaxRel) < 0)
								begin
								/* Because of Negative/Opposite polarity release retg values along the way the distributed amount has 
								   gone negative, leaving us with more to distribute than we originally began with.  When combined with
								   this invoice lines release retg for this item, we are still left with more than we began with.  Therefore
								   it is OK to reverse the full amount on this Line/Item and move on. There is no need for specific
								   evaluation since we are not in jeopardy of reversing more than we have. */
								select @invline_openretg = @invline_relretg
								select @invline_openretgtax = @invline_relretgtax
								select @dist_amt = @dist_amt + (@invline_relretg - @invline_relretgtax)		--Special! Must be at this location
								end
							else
								begin
								/* Combined amounts swing in the correct direction, continue with normal evaluation process */
								if abs(@dist_amt + (@invline_relretg - @invline_relretgtax)) <= abs(@RetgRel - @LineRetgTaxRel)	--abs(Pos + Pos) <= abs(Pos)
									begin
									select @invline_openretg = @invline_relretg
									select @invline_openretgtax = @invline_relretgtax		-- Pos = Pos	(or Neg = Neg)
									select @dist_amt = @dist_amt + (@invline_relretg - @invline_relretgtax)		--Special! Must be at this location
									end
								else
									begin
									select @invline_openretg = (@RetgRel - @LineRetgTaxRel) - @dist_amt		-- Pos = Pos - Pos	(or Neg - Neg)
									select @dist_amt = @dist_amt + @invline_openretg		--Special! Must be at this location as shown
									end
								end
							end
						end
					end

			GSTTax_LoopRev2:

/*****************************************************************************************************
*
*						 REVERSE RELEASE - PART 1  (AR Recevables, Tax GL)
*						RETRIEVE TAX INFORMATION AND SETUP TAX VALUES
*								BASED ON AR Company SETUP
*
******************************************************************************************************/

				if @posttaxoninv = 'N' or (@posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N'))
					begin	/* Begin Normal US Reverse Release Retainage distribution.  Retainage Tax included in TaxAmount. */
					/* Not used but for consistency post TaxGroup, TaxCode on 2nd R transactions.  */
					select @newtaxgroup = isnull(TaxGroup, @invlinetaxgroup), @newtaxcode = isnull(TaxCode, @invlinetaxcode)
					from bJCCI with (nolock)
					where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractItem
					end		/* End Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
				if @posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'Y')
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */

					/*Validate R2 invoice line Tax Group if there is a tax code */
					if (@invline_openretg <> 0 or @oldinvline_openretg <> 0) and @R2taxcode is not null
						begin
						if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @R2taxgroup)
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @R2taxgroup),'')
							select @errortext = @errorstart + ' - is not valid!'
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end
						end

					/* Validate R2 invoice line TaxCode by getting the accounts for the tax code */
					if (@invline_openretg <> 0 or @oldinvline_openretg <> 0) and @R2taxcode is not null
						begin
						exec @rcode = bspHQTaxRateGetAll @R2taxgroup, @R2taxcode, @R2date, null, @R2taxrate output, @R2gstrate output, @R2pstrate output, 
							@R2HQTXcrdGLAcct output, @R2HQTXcrdRetgGLAcct output, null, null, @R2HQTXcrdGLAcctPST output, 
							@R2HQTXcrdRetgGLAcctPST output, NULL, NULL,@errmsg output

						if @rcode <> 0
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@jbco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @R2taxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@R2taxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						/* @invline_openretg could not be set previous because this is a partial line and the RetgTax
						   being reversed must be calculated at this point and combined with @invline_openretg tax basis. */
						if (@invline_openretg <> 0 or @oldinvline_openretg <> 0) and @R2taxcode is not null and @invline_openretgtax = 0
							begin
							select @invline_openretgtax = @invline_openretg * @R2taxrate
							select @invline_openretg = @invline_openretg + @invline_openretgtax
							--@dist_amt counter has already been adjusted earlier relative to this operation.  
							end

						if @R2pstrate = 0
							begin
							/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
							   In any case:
							   a)  @taxrate is the correct value.  
							   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
							   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
							select @newTax = isnull(@invline_openretgtax,0)
							end
						else
							begin
							/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
							if @R2taxrate <> 0
								begin
								select @newTax = (isnull(@invline_openretgtax,0) * @R2gstrate) / @R2taxrate		--GST Tax
								select @newTaxPST = isnull(@invline_openretgtax,0) - @newTax					--PST Tax
								end
							end
						end
					/* End R2 invoice line TaxCode validation and info retrieval */

					/* Begin 'C'hange or 'D'elete mode TaxCode validation and info retrieval */
					if @batchtranstype <> 'A'
						begin
						/* When changing an existing interfaced Reversing transaction, this old TaxCode information is still the
						   same as determined above because we are still dealing with the same R2 (2nd R) line.  The R2 line
						   values have not changed, only the amounts that we are reversing are changing. */

						/* Get OLD Tax values. */
						if @R2pstrate = 0
							begin
							select @oldTax = @oldinvline_openretgtax				--represents old tax released
							end
						else
							begin
							if @R2taxrate <> 0
								begin
								select @oldTax = (@oldinvline_openretgtax * @R2gstrate) / @R2taxrate	-- old GST Tax
								select @oldTaxPST = @oldinvline_openretgtax - @oldTax					-- old PST Tax
								end
							end
						end
					/* End 'C'hange or 'D'elete mode TaxCode validation and info retrieval */

					end	/* End International Release Retainage distribution.  Retainage already taxed, now report separately.  */

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'N' and @arcoseparateretgtax = 'N')	/* Hybrid same as International #1 setup for this cycle */
					begin	/* Begin International Release Retainage distribution.  Tax Retainage at this time. */

					/*Validate R2 invoice line Tax Group if there is a tax code */
					if (@invline_openretg <> 0 or @oldinvline_openretg <> 0) and @R2taxcode is not null
						begin
						if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @R2taxgroup)
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @R2taxgroup),'')
							select @errortext = @errorstart + ' - is not valid!'
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end
						end

					/* Validate R2 invoice line TaxCode by getting the accounts for the tax code */
					if (@invline_openretg <> 0 or @oldinvline_openretg <> 0) and @R2taxcode is not null	
						begin
						exec @rcode = bspHQTaxRateGetAll @R2taxgroup, @R2taxcode, @R2date, null, @R2taxrate output, @R2gstrate output, @R2pstrate output, 
							@R2HQTXcrdGLAcct output, @R2HQTXcrdRetgGLAcct output, null, null, @R2HQTXcrdGLAcctPST output, 
							@R2HQTXcrdRetgGLAcctPST output, NULL, NULL, @errmsg output

						if @rcode <> 0
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@jbco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @R2taxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@R2taxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						/* @invline_openretg could not be set previous because this is a partial line and the RetgTax
						   being reversed must be calculated at this point and combined with @invline_openretg tax basis. */
						if (@invline_openretg <> 0 or @oldinvline_openretg <> 0) and @R2taxcode is not null and @invline_openretgtax = 0
							begin
							select @invline_openretgtax = @invline_openretg * @R2taxrate
							select @invline_openretg = @invline_openretg + @invline_openretgtax
							--@dist_amt counter has already been adjusted earlier relative to this operation.  
							end

						if @R2pstrate = 0
							begin
							/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
							   In any case:
							   a)  @taxrate is the correct value.  
							   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
							   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
							select @newTax = isnull(@invline_openretgtax,0)
							end
						else
							begin
							/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
							if @R2taxrate <> 0
								begin
								select @newTax = (isnull(@invline_openretgtax,0) * @R2gstrate) / @R2taxrate		--GST Tax
								select @newTaxPST = isnull(@invline_openretgtax,0) - @newTax					--PST Tax
								end
							end
						end
					/* End R2 invoice line TaxCode validation and info retrieval */

					/* Begin 'C'hange or 'D'elete mode TaxCode validation and info retrieval */
					if @batchtranstype <> 'A'
						begin
						/* When changing an existing interfaced Reversing transaction, this old TaxCode information is still the
						   same as determined above because we are still dealing with the same R2 (2nd R) line.  The R2 line
						   values have not changed, only the amounts that we are reversing are changing. */

						/* Get OLD Tax values. */
						if @R2pstrate = 0
							begin
							select @oldTax = @oldinvline_openretgtax				--represents old tax released
							end
						else
							begin
							if @R2taxrate <> 0
								begin
								select @oldTax = (@oldinvline_openretgtax * @R2gstrate) / @R2taxrate	-- old GST Tax
								select @oldTaxPST = @oldinvline_openretgtax - @oldTax					-- old PST Tax
								end
							end
						end
					/* End 'C'hange or 'D'elete mode TaxCode validation and info retrieval */

					end		/* End International Release Retainage distribution.  Tax Retainage at this time. */

/*****************************************************************************************************
*
*								REVERSE RELEASE GL DISTRIBUTIONS - PART 1
*
******************************************************************************************************/	

			GL_LoopRev2:
				if @posttaxoninv = 'N' or (@posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N'))
					begin	/* Begin Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */	
      					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=1
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

	        					/* Released Retainage, (New Credit Invoice) */
	        					/* AR Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLARAcct, @PostAmount = isnull(-@invline_openretg,0),				--credit GLARAcct
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLARAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--debit
	                 					@errorAccount = 'AR Receivable Account'
	          						end

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end

							skip_GLUpdateRev:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */
	
						select @retgtaxrel = 0
						select @retainagerel = isnull(-@invline_openretg,0)
							exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end	
					else
						begin	/* Begin Release to AR = 'N' */
						select @retgtaxrel = 0
						select @retainagerel = isnull(-@invline_openretg,0)
							exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					end

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'Y')
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */	
      					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=3
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

	        					/* Released Retainage, (New Credit Invoice) */
	        					/* AR Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLARAcct, @PostAmount = isnull(-@invline_openretg,0),		--credit GLARAcct
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLARAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--debit
	                 					@errorAccount = 'AR Receivable Account'
	          						end

								/* Tax account.  Standard US or GST */
								if @i=2 select @PostGLCo=@ARGLCo, @PostGLAcct=@R2HQTXcrdGLAcct, @PostAmount = isnull(@newTax,0),				--debit new GST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdGLAcct, @oldPostAmount = isnull(@oldTax,0),			--credit new GST (old) on change
									@errorAccount = 'AR Tax Account'

								/* Tax account.  PST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@R2HQTXcrdGLAcctPST, @PostAmount = isnull(@newTaxPST,0),		--debit new PST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdGLAcctPST, @oldPostAmount = isnull(@oldTaxPST,0),		--credit new PST (old) on change
									@errorAccount = 'AR Tax Account PST'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end

							skip_GLUpdateRev2:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */
	
						select @retgtaxrel = -(isnull(@newTax,0) + isnull(@newTaxPST,0))
						select @retainagerel = isnull(-@invline_openretg,0)
							exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end	
					else
						begin	/* Begin Release to AR = 'N' */
     					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=3
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

	        					/* Released Retainage, (New Credit Invoice) */
	        					/* AR Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleasedGLRetainAcct, @PostAmount = isnull(-@invline_openretg,0),	--credit GLARAcct
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleasedGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--debit
	                 					@errorAccount = 'AR Receivable Account'
	          						end

								/* Retainage Tax account.  Standard US or GST */
								if @i=2 select @PostGLCo=@ARGLCo, @PostGLAcct = @R2HQTXcrdRetgGLAcct, @PostAmount = isnull(@newTax,0),		--debit new GST			
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdRetgGLAcct, @oldPostAmount = isnull(@oldTax,0),		--credit new GST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Retainage Tax account.  PST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct = @R2HQTXcrdRetgGLAcctPST, @PostAmount = isnull(@newTaxPST,0),	--debit new PST			
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdRetgGLAcctPST, @oldPostAmount = isnull(@oldTaxPST,0),	--credit new PST (old) on change
									@errorAccount = 'AR Retg Tax Account PST'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end

							skip_GLUpdateRev3:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */

						select @retgtaxrel = -(isnull(@newTax,0) + isnull(@newTaxPST,0))
						select @retainagerel = isnull(-@invline_openretg,0)
						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					end

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'N' and @arcoseparateretgtax = 'N')	/* Hybrid same as International #1 setup for this cycle */
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */
      					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=3
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

	        					/* Released Retainage, (New Credit Invoice) */
	        					/* AR Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLARAcct, @PostAmount = isnull(-@invline_openretg,0),		--credit GLARAcct
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLARAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--debit
	                 					@errorAccount = 'AR Receivable Account'
	          						end

								/* Tax account.  Standard US or GST */
								if @i=2 select @PostGLCo=@ARGLCo, @PostGLAcct=@R2HQTXcrdGLAcct, @PostAmount = isnull(@newTax,0),				--debit new GST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdGLAcct, @oldPostAmount = isnull(@oldTax,0),			--credit new GST (old) on change
									@errorAccount = 'AR Tax Account'

								/* Tax account.  PST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@R2HQTXcrdGLAcctPST, @PostAmount = isnull(@newTaxPST,0),		--debit new PST
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdGLAcctPST, @oldPostAmount = isnull(@oldTaxPST,0),		--credit new PST (old) on change
									@errorAccount = 'AR Tax Account PST'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end

							skip_GLUpdateRev4:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */
	
						select @retgtaxrel = -(isnull(@newTax,0) + isnull(@newTaxPST,0))
						select @retainagerel = isnull(-@invline_openretg,0)
							exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					else
						begin
     					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=3
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

	        					/* Released Retainage, (New Credit Invoice) */
	        					/* AR Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleasedGLRetainAcct, @PostAmount = isnull(-@invline_openretg,0),		--credit GLARAcct
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleasedGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--debit
	                 					@errorAccount = 'AR Receivable Account'
	          						end

								/* Retainage Tax account.  Standard US or GST */
								if @i=2 select @PostGLCo=@ARGLCo, @PostGLAcct = @R2HQTXcrdRetgGLAcct, @PostAmount = isnull(@newTax,0),		--debit new GST			
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdRetgGLAcct, @oldPostAmount = isnull(@oldTax,0),		--credit new GST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Retainage Tax account.  PST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct = @R2HQTXcrdRetgGLAcctPST, @PostAmount = isnull(@newTaxPST,0),	--debit new PST			
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @R2HQTXcrdRetgGLAcctPST, @oldPostAmount = isnull(@oldTaxPST,0),	--credit new PST (old) on change
									@errorAccount = 'AR Retg Tax Account PST'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									end

							skip_GLUpdateRev5:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */

						select @retgtaxrel = -(isnull(@newTax,0) + isnull(@newTaxPST,0))
						select @retainagerel = isnull(-@invline_openretg,0)
							exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
							@itemnotes, @errmsg output
						if @rcode <> 0
							begin
							select @errortext = @errorstart + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							goto bspexit
							end
						end
					end

/*****************************************************************************************************
*
*			DETERMINE IF REMAINING AMOUNTS ARE TO BE REVERSED.  IF SO, GO TO NEXT INVOICE
*
******************************************************************************************************/	

				--select @dist_amt = @dist_amt + @invline_openretg			--Special situation required this be done earlier
				if @batchtranstype = 'D' or @revoldglVonly = 'Y' goto get_prior_bcARTL_V
				
				if (@dist_amt < 0 and @RetgRel > 0) or (@dist_amt > 0 and @RetgRel < 0)
					begin
					/* Our distribution amount has gone negative due to some Opposite Release Retainage values along the way.
					   Setting flag will help suspend some comparisons that require polarities between compared values
					   to be the same. */
					select @distamtstilloppositeflag = 'Y'
					end
				else
					begin
					select @distamtstilloppositeflag = 'N'
					end

				/* Note:  Current bill or the bill associatated with this release action does not need to be dealt
				   with separately as we do with Releasing retg.  We would not be reversing retg on a bill that has
				   never been interfaced and if it has previously been interfaced and we are changing Reversing amts
				   then the current bill or associated bill is already included in the cursor list. */
				if @100_pct = 'Y'
					begin
					/* We are reversing full amount for this Item/Line on all invoices in list. Just keep going. */
					goto get_prior_bcARTL_V
					end
				else
					begin
					if @oppositerelretgflag = 'Y'
						begin
						/* No evaluation necessary, we have more to Reverse than we began with */
						select @oppositerelretgflag = 'N'
						goto get_prior_bcARTL_V
						end
					else
						begin
						if @distamtstilloppositeflag = 'Y'
							begin
							/* We still have more money reserved to reverse than we originally began with.
							   No need for comparisons. Just get next Invoice for this Line/Item. */
							goto get_prior_bcARTL_V
							end
						else
							begin
							/* Conditions are relatively normal at this point.  We are not (or no longer) dealing with 
							   negative/opposite RelRetg on this invoice nor is our overall distribution amount
							   negative/opposite at this stage of the distribution process.  Therefore we must now continue
							   to compare values to assure that we distribute/reverse no more than was intended.   */
							if abs(@RetgRel) > abs(isnull(@oldRetgRel,0))
								begin
								/* This is the Normal on New bills or those being changed where the New amount being
								   reversed is greater than the old reverse amount. */
	      						if abs(@dist_amt) < abs(@RetgRel)
									begin 
									goto get_prior_bcARTL_V 
									end
								else 
									begin
									goto ARTL_V_loop_end 
									end
								end
							else
								begin	
								/* This is a CHANGED bill and the New amount being reverse released is less than the Old reverse released amount. */
								if abs(@dist_amt) < abs(@RetgRel) 
									begin
									/* Normal processing until the New reverse release amounts have been processed. */
									goto get_prior_bcARTL_V
									end
								else
									begin
									/* If we have reduced the amount being reverse released on a previously interfaced bill, although 
									   we have distributed all that we are going to at this point, we will continue
									   to cycle through the remaining Invoice transactions in order to back out of GL, the
									   remaining old values that have exceeded the new values. */
									select @revoldglVonly = 'Y'
									if abs(@dist_amt) < abs(@oldRetgRel) goto get_prior_bcARTL_V else goto ARTL_V_loop_end	
									end
								end
							end
						end
					end
					
			get_prior_bcARTL_V:
				fetch prior from bcARTL_V into @Imth, @Iartrans, @Iarline, @OrigInvRecType, @R2date,
				@R2taxgroup, @R2taxcode
				end		/* End V Rev Released Loop */

		ARTL_V_loop_end:	
			close bcARTL_V
			deallocate bcARTL_V
			select @opencursorARTL_V = 0

/*****************************************************************************************************
*
*									REVERSE RELEASE
*					PROCESS THE 1ST 'R' TRANSACTIONS FOR REVERSAL
*
******************************************************************************************************/

			/*   Next create GL entries for the AR Retainage Receivable Accounts (displayed last in a 
			   GL Distribution list) to be consistent with GL distribution for normal Release Retainage action. */ 

				/******* Step #2 Reverse Release GL - AR Retainage Receivable *******/				   
			/* Need to create list of 'Release' invoices that may be reversed to some extent. */
			select @dist_amt = 0, @dist_amttax = 0, @distamtstilloppositeflag = 'N', @distamttaxstilloppositeflag = 'N'

			/* This cursor list starts over for each Item.

			   Create GL for Reversing Release Retainage on each transaction for this item, starting with the latest
			   transaction that release will occurred on.  We are reversing the first 'R' in the ('I', 'R', 'R')
			   sequence.  Depending on the amount to be reversed, there may be more than one 'R' set of 
			   ARTL lines drawn in by the cursor (If the Item was billed multiple times and released multiple times
			   then there will be multiple 'R'elease transactions containing different ApplyMth, ApplyTrans values
			   for this Item). 

			   It is also possible that two lines within this cursor actually effect the same ApplyMth, ApplyTrans. 
			   (This might occur when the amount being released for a given item is such that only a portion of
			   amount for the item/Line gets released on a particular invoice the first time.  Then when retg is 
			   released the next time for this item, This same invoice (ApplyMth, ApplyTrans) and same invoice line
			   (ApplyLine) gets generated under a separate 'R'elease transaction)(It can also occur because of 
			   previous Reverse Release action against this ApplyMth, ApplyTrans, ApplyLine).  In this case, 
			   the cursor below will return the same ApplyMth, ApplyTrans, ApplyLine values twice or more.

			   It is possible that the invoice line being released upon for this Item is not the same for all invoices
			   relative to this Item.  Each invoice will contain only a single Line per Item.  Evaluation is done per
			   each invoice (ApplyMth, ApplyTrans) separately.  Therefore the code below may use Item or Line 
			   interchangeably.

			   For each ContractItem, this cursor below brings in a list of all 1st 'R' Release transactions (both normal
			   release and reverse release).  This gives us (though multiple times) all possible invoices that have been
			   Released upon (or Reversed) relative to this ContractItem. */
    		declare bcARTL_I scroll cursor for
    		select l.ApplyMth, l.ApplyTrans, l.ApplyLine, l.RecType, h.TransDate, l.TaxGroup, l.TaxCode,
    			l.Retainage, l.RetgTax				--ADDED D-04589/145852
    		from bARTH h with (nolock)
    		join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
				l.JCCo = @jbco and l.Contract = @jbcontract and l.Item = @jbcontractItem	-- This contract/Item only
    		where h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
				and (h.Mth < @batchmth or (h.Mth = @batchmth and h.ARTrans < @thisretgtrans)) -- Prior to this Release trans
				and h.ARTransType = 'R'												-- Release values only
				and (l.Mth <> l.ApplyMth or l.ARTrans <> l.ApplyTrans)				-- No (2nd R) Released values
				--and ((l.Retainage < 0 and @RetgRel > 0)  				-- Neg item, Pos release trans only, ignore prev reversals
				--	or (l.Retainage > 0 and @RetgRel < 0))				-- Pos item, Neg release trans only, ignore prev reversals
			order by l.ApplyMth, l.ApplyTrans, l.ApplyLine				-- To assure correct reversing order.
	
    		/* open cursor for line */
    		open bcARTL_I
    		select @opencursor_ARTL_I = 1
	
    		/**** read cursor lines ****/
    		fetch last from bcARTL_I into @Imth, @Iartrans, @Iarline, @OrigInvRecType, @originvtransdate,
				@invlinetaxgroup, @invlinetaxcode, 
				@invline_relretg, @invline_relretgtax	--ADDED D-04589/145852
    		while (@@fetch_status = 0)
    			begin	/* Begin I Rev Release Loop */
      			select @invline_openretg = 0, @oldinvline_openretg = 0,		--REMOVED D-04589/145852: @invline_relretg = 0, 
					@oppositerelretgflag = 'N', @oppositerelretgtaxflag = 'N'
				select @invline_openretgtax = 0, @oldinvline_openretgtax = 0	--REMOVED D-04589/145852:, @invline_relretgtax = 0

				/* Reset Line variables as needed here.  
				   Retrieved as each Lines TaxCode gets validated.  Reset to avoid leftover value when TaxCode is invalid */
				select @itemtaxgroup = null, @itemtaxcode = null, @newtaxgroup = null, @newtaxcode = null,
					@HQTXcrdGLAcct = null, @HQTXcrdRetgGLAcct = null, @HQTXcrdGLAcctPST = null, @HQTXcrdRetgGLAcctPST = null,
					@newHQTXcrdGLAcct = null, @newHQTXcrdRetgGLAcct = null, @newHQTXcrdGLAcctPST = null, @newHQTXcrdRetgGLAcctPST = null,
					@R2HQTXcrdGLAcct = null, @R2HQTXcrdRetgGLAcct = null, @R2HQTXcrdGLAcctPST = null, @R2HQTXcrdRetgGLAcctPST = null,
					@RetgTax = 0, @RetgTaxPST = 0, @oldRetgTax = 0, @oldRetgTaxPST = 0, 
					@taxrate = 0, @gstrate = 0, @pstrate = 0, @newtaxrate = 0, @newgstrate = 0, @newpstrate = 0, 
					@R2taxrate = 0, @R2gstrate = 0, @R2pstrate = 0,
					@calculatednewlinetax = 0, @calculatedoldlinetax = 0, @calculatedoldlineretgtax = 0,
					@retainagerel = 0, @retgtaxrel = 0

				-- CHS	10/14/2011	- D-02573 
				-- TJL	06/07/2012 - D-04589/145852  
				--NOTE:
				--	We are no longer summing records by applymth and applytrans exclusively, therefore there is no need to 
				--  skip duplicate records as we are now evaluating each line individually.
				--    /* If already dealt with, move on. */
				--    if isnull(@oldapplymth, '01-01-1950') = @Imth and isnull(@oldapplytrans, 0) = @Iartrans goto get_prior_bcARTL_I

	      		/* Get GL Company and GLAcct from line.  Each affected 'Release' invoice will be processed
				   separately in order to obtain this specific information that could be (though rarely is)
				   different for the same Contract/Item.

				   These are the GLAccts relative to the amounts being Debited to the AR Retainage Receivables
				   account.  Old and New should always be the same for reasons stated at beginning of this
				   procedure. */
				   
	      		select @ReleaseGLARAcct = GLARAcct, @ReleaseGLRetainAcct = GLRetainAcct,
	        		@oldReleaseGLARAcct = GLARAcct, @oldReleaseGLRetainAcct = GLRetainAcct
	      		from bARRT with (nolock)
	      		where ARCo = @arco and RecType = @OrigInvRecType

				----REMOVED D-04589/145852
				----NOTE: 1st R values being reversed (Debit to AR Retainage GL) are now being processed, on at a time,
				----	  based upon the exact transaction derived in the cursor.  There is no longer the need to get
				----	  a SUM of the retention values being reversed for the purpose of GL Distributions.  We will 
				----	  pull the necessary amount directly from the cursor itself.  (Less prone to error)
				
				--/* Get amounts that have previously been released (All previous 1st R's) for this contact/Item.
				--   (This combines/includes all previous Release amts (1st R) and previous reversal amts (1st R) 
				--   and when combined represent the total still	available to be reversed.) 
				--   This is the amount that can be reversed.  This value DOES NOT INCLUDE A REVERSING AMOUNT
				--   ON THIS CURRENT BILL IF IT HAS PREVIOUSLY BEEN INTERFACED. */
	   -- 		select @invline_relretg = isnull(sum(l.Retainage), 0),	-- Neg	
				--	@invline_relretgtax = isnull(sum(l.RetgTax), 0)				
	   -- 		from bARTH h with (nolock)
	   -- 		join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
				--			l.JCCo = @jbco and l.Contract = @jbcontract and l.Item = @jbcontractItem	-- This contract/Item only 
	   -- 		where h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
				--	and (h.Mth < @batchmth or (h.Mth = @batchmth and h.ARTrans < @thisretgtrans))	-- Prior to this Release trans
				--	and h.ARTransType = 'R'												-- Release values only, including reversals
				--	and (l.Mth <> l.ApplyMth or l.ARTrans <> l.ApplyTrans)				-- No Released Values
				--	and l.ApplyMth = @Imth and l.ApplyTrans = @Iartrans					-- starting with Latest Month and Trans		
				--	and l.ApplyLine = @Iarline
				--	and l.RecType = @OrigInvRecType
				--	and h.TransDate = @originvtransdate
				--	and ISNULL(l.TaxGroup,'') = ISNULL(@invlinetaxgroup,'')  -- D-04589 Isnull wrap TaxGroup and TaxCode
				--	and ISNULL(l.TaxCode,'') = ISNULL(@invlinetaxcode,'')																			
				--	-- CHS	10/14/2011	- D-02573 	
				

				/* Get Old Reverse Release Retainage Amount (This is the 1st R of THIS transaction ONLY.  It is possible that we 
				   are changing a previous reversal amount on this billing. (Because we increased or reduced the overall Reverse amt on this billing).
				   In which case it is necessary to report the old and new reversed values to GL.  */
				if @batchtranstype in ('C','D')
					begin	/* Begin Get Old Loop */
				
					set @oldinvline_openretg = 0
					
					-- CHS	10/14/2011	- D-02573   NOTE:
					-- TJL	06/07/2012 - The idea of SUMMING and SKIPPING below seems contrary to changes made above as a result of D-04589/145852.
					--					 This code is so complex and convoluted that changes are made only AS REQUIRED. There is too much risk in 
					--					 in making changes that have not been reported as failing.
					/* If already dealt with, move on. */
					if isnull(@oldapplymth, '01-01-1950') = @Imth 
						and isnull(@oldapplytrans, 0) = @Iartrans 
						and isnull(@oldapplyline, 0) = @Iarline 
						BEGIN
						goto Continue_with_reverse
						END

				
    				select @oldinvline_openretg = isnull(sum(Retainage), 0),		-- Pos
						@oldinvline_openretgtax = isnull(sum(RetgTax), 0)
    				from bARTL with (nolock)
    				where ARCo = @arco 
    					and ApplyMth = @Imth 
    					and ApplyTrans = @Iartrans 
    					and ApplyLine = @Iarline	
						and Mth = @batchmth 
						and ARTrans = @thisretgtrans
		
					--set old variables
					select @oldapplymth = @Imth, @oldapplytrans = @Iartrans, @oldapplyline = @Iarline -- add arline too
					
					end	/* End Get Old Loop */


Continue_with_reverse:


				/* Skip if there is no Reverse Release Retg and no Change to prior Reversed Release Retg. */
      			if @invline_relretg = 0 and @oldinvline_openretg = 0 
					begin
					-- CHS	10/14/2011	- D-02573
					-- select @oldapplymth = @Imth, @oldapplytrans = @Iartrans
					goto get_prior_bcARTL_I
					end

				/*  If here, we have either 'Release' retg to be reversed on this 'Release' invoice or there 
					has been a change on the current bill that will effect GL entries.  Determine New Release
					amount to be Credited and/or Debited to GL AR Retainage Receivable Acct.

					Note below that we use Release Retg value that excludes this current bill reversing amounts
					(in the event that this has previously been interfaced).  For all practical
					purposes, a bill being changed doesn't exist.  Validation has already confirmed that the
					change being made is acceptable.  This will be the New amount relative to GL. */
					
				/* Either of these conditions would be caused by the following.  
					a)  A Bill has been marked for Delete.
					b)  A Bill has been marked as Changed and the NEW reverse release amount is less than the OLD reverse release amount.
				   This protects from incorrectly analysing Invoices containing Negative (reverse polarity) lines.
				   For deleted bills, new values do not apply.  For changed bills, new values have already been processed and we 
				   have reach a point where we are simply backing out remaining old values from GL.  At this stage, GL is based strickly on OLD
				   previously posted values and there is no need to do line by line evaluation. */
				if @batchtranstype = 'D' or @revoldglonly = 'Y' goto GSTTax_LoopRev3	
					
				if @100_pct = 'Y'
					begin
					/* Evaluation not required, go directly to GL Routine */
					select @invline_openretg = -@invline_relretg
					select @invline_openretgtax = -@invline_relretgtax		-- Pos = -Neg
					goto GSTTax_LoopRev3
					end
				else
					begin
					/* Some form of Evaluation and PostAmount determination required */
					if (-@invline_relretg < 0 and @contractitemamt > 0) or (-@invline_relretg > 0 and @contractitemamt < 0)
						begin
						/* Somehow the 1st 'R'elease transaction went abnormally negative/opposite relative to the invoice
						   that it applies against. (Perhaps because the original retainage value went negative/opposite due
						   to excessive credits or just negative retainage.  This would cause a Release Retg transaction
						   to be negative/opposite as well.) Post full amount to compensate. */
						select @oppositerelretgflag = 'Y'
						select @invline_openretg = -@invline_relretg
						select @invline_openretgtax = -@invline_relretgtax
						end
					else
						begin
						/* This is normal Postive (or normal Negative) release retainage to be reopened.  Distribute accordingly */
						if @distamtstilloppositeflag = 'N'
							begin
			      			if abs(@dist_amt + (-@invline_relretg)) <= abs(@RetgRel)	-- abs(Pos + (-Neg)) <= abs(Pos)
								begin
			        			select @invline_openretg = -@invline_relretg			-- Pos = -Neg
								select @invline_openretgtax = -@invline_relretgtax
								end
			       			else
								begin
			            		select @invline_openretg = @RetgRel - @dist_amt			-- Pos = Pos - Pos
								select @invline_openretgtax = @LineRetgTaxRel - @dist_amttax
								end
							end		
						else
							begin
							if ((@dist_amt + (-@invline_relretg)) < 0 and @RetgRel > 0) or ((@dist_amt + (-@invline_relretg)) > 0 and @RetgRel < 0)
								begin
								/* Because of Negative/Opposite polarity release retg values along the way the distributed amount has 
								   gone negative, leaving us with more to distribute than we originally began with.  When combined with
								   this invoice lines release retg for this item, we are still left with more than we began with.  Therefore
								   it is OK to reverse the full amount on this Line/Item and move on. There is no need for specific
								   evaluation since we are not in jeopardy of reversing more than we have. */
								select @invline_openretg = -@invline_relretg
								select @invline_openretgtax = -@invline_relretgtax
								end
							else
								begin
								/* Combined amounts swing in the correct direction, continue with normal evaluation process */
				      			if abs(@dist_amt + (-@invline_relretg)) <= abs(@RetgRel)	-- abs(Pos + (-Neg)) <= abs(Pos)
									begin
				        			select @invline_openretg = -@invline_relretg			-- Pos = -Neg
									select @invline_openretgtax = -@invline_relretgtax
									end
				       			else
									begin
				            		select @invline_openretg = @RetgRel - @dist_amt			-- Pos = Pos - Pos
									select @invline_openretgtax = @LineRetgTaxRel - @dist_amttax
									end
								end
							end
						end
					end

			GSTTax_LoopRev3:

/*****************************************************************************************************
*
*									REVERSE RELEASE - PART 2	(AR Retainage, RetgTax GL)
*						RETRIEVE TAX INFORMATION AND SETUP TAX VALUES
*								BASED ON AR Company SETUP
*
******************************************************************************************************/

				if @posttaxoninv = 'N' or (@posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N'))
					begin	/* Begin Normal US Reverse Release Retainage distribution.  Retainage Tax included in TaxAmount. */
					/* Not used but for consistency post TaxGroup, TaxCode on 2nd R transactions.  */
					select @newtaxgroup = isnull(TaxGroup, @invlinetaxgroup), @newtaxcode = isnull(TaxCode, @invlinetaxcode)
					from bJCCI with (nolock)
					where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractItem
					end		/* End Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
				if @posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'Y')
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
					/* Original invoice line TaxCode validation and info retrieval */

					/*Validate original invoice line Tax Group if there is a tax code */
					if @invlinetaxcode is not null
						begin
						if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @arco  and TaxGroup = @invlinetaxgroup)
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@arco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @invlinetaxgroup),'')
							select @errortext = @errorstart + ' - is not valid!'
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end
						end

					/* Validate original invoice line TaxCode by getting the accounts for the tax code */
					if @invlinetaxcode is not null
						begin
						exec @rcode = bspHQTaxRateGetAll @invlinetaxgroup, @invlinetaxcode, @originvtransdate, null, @taxrate output, @gstrate output, @pstrate output, 
							@HQTXcrdGLAcct output, @HQTXcrdRetgGLAcct output, null, null, @HQTXcrdGLAcctPST output, 
							@HQTXcrdRetgGLAcctPST output, NULL, NULL, @errmsg output

						if @rcode <> 0
							begin
							select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@jbco),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @invlinetaxgroup),'')
							select @errortext = @errortext + ' - TaxCode : ' + isnull(@invlinetaxcode,'') + ' - is not valid! - ' + @errmsg
							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							end

						if @pstrate = 0
							begin
							/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
							   In any case:
							   a)  @taxrate is the correct value.  
							   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
							   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
							select @RetgTax = isnull(@invline_openretgtax,0)
							end
						else
							begin
							/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
							if @taxrate <> 0
								begin
								select @RetgTax = (isnull(@invline_openretgtax,0) * @gstrate) / @taxrate	--GST RetgTax
								select @RetgTaxPST = isnull(@invline_openretgtax,0) - @RetgTax				--PST RetgTax
								end
							end
						end
					/* End original invoice line TaxCode validation and info retrieval */

					/* Begin 'C'hange or 'D'elete mode TaxCode validation and info retrieval */
					if @batchtranstype <> 'A'
						begin
						/* When changing an existing interfaced Reversing transaction, this old TaxCode information is still the
						   same as determined above because we are still dealing with the same R1 (1st R) line.  The R1 line
						   values have not changed, only the amounts that we are reversing are changing. */

						/* Get OLD RetgTax values. */
						if @pstrate = 0
							begin
							select @oldRetgTax = @oldinvline_openretgtax			--represents old retg tax released
							end
						else
							begin
							if @taxrate <> 0
								begin
								select @oldRetgTax = (@oldinvline_openretgtax * @gstrate) / @taxrate		-- old GST RetgTax
								select @oldRetgTaxPST = @oldinvline_openretgtax - @oldRetgTax				-- old PST RetgTax
								end
							end
						end
					/* End 'C'hange or 'D'elete mode TaxCode validation and info retrieval */

					end	/* End International Release Retainage distribution.  Retainage already taxed, now report separately.  */

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'N' and @arcoseparateretgtax = 'N')	/* Hybrid same as US Standard setup for this cycle */
					begin	/* Begin International Release Retainage distribution.  Tax Retainage at this time. */
					/* No special setup required. During Reverse Release PART #2, this cycle refers to reversing the
					   amounts released from the original invoices.  In an Intl Setup #2, there are no Retainage Tax 
					   values on the original invoices and therefore no RetgTax was originally released. */
					select @newtaxgroup = @invlinetaxgroup
					end		/* End International Release Retainage distribution.  Tax Retainage at this time. */

/*****************************************************************************************************
*
*								REVERSE RELEASE GL DISTRIBUTIONS - PART 2
*
******************************************************************************************************/	

			GL_LoopRev3:
				if @posttaxoninv = 'N' or (@posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N'))
					begin	/* Begin Normal US Release Retainage distribution.  Retainage Tax included in TaxAmount. */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */	
      					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=1
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

								/* Release Retainage, (Possible Multiple Invoice values affected by release) */
	        					/* Retainage Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(@invline_openretg,0),				--debit Retainage
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--credit
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
 									end		/* End insert Changed or Deleted values */

							skip_GLUpdateRev6:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */

--						select @retgtaxrel = 0
--						select @retainagerel = isnull(@invline_openretg,0)
--
--						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
--							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
--							@itemnotes, @errmsg output
--						if @rcode <> 0
--							begin
--							select @errortext = @errorstart + @errmsg
--							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
--							goto bspexit
--							end
						end	
					else
						begin	/* Begin Release to AR = 'N' */
						select @retgtaxrel = 0
--						select @retainagerel = isnull(@invline_openretg,0)
--
--						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
--							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
--							@itemnotes, @errmsg output
--						if @rcode <> 0
--							begin
--							select @errortext = @errorstart + @errmsg
--							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
--							goto bspexit
--							end
						end
					end

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'Y')
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */
      					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=3
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

								/* Release Retainage, (Possible Multiple Invoice values affected by release) */
	        					/* Retainage Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(@invline_openretg,0),				--debit Retainage
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--credit
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Retainage Tax account.  Standard US or GST */
								if @i=2 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcct, @PostAmount = isnull(-@RetgTax,0),			--credit orig GST				
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @HQTXcrdRetgGLAcct, @oldPostAmount = isnull(@oldRetgTax,0),		--debit orig GST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Retainage Tax account.  PST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct = @HQTXcrdRetgGLAcctPST, @PostAmount = isnull(-@RetgTaxPST,0),		--credit orig PST			
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @HQTXcrdRetgGLAcctPST, @oldPostAmount = isnull(@oldRetgTaxPST,0),	--debit orig PST (old) on change
									@errorAccount = 'AR Retg Tax Account PST'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
 									end		/* End insert Changed or Deleted values */

							skip_GLUpdateRev7:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */

--						select @retgtaxrel = isnull(@RetgTax,0) + isnull(@RetgTaxPST,0)
--						select @retainagerel = isnull(@invline_openretg,0)
--
--						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
--							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
--							@itemnotes, @errmsg output
--						if @rcode <> 0
--							begin
--							select @errortext = @errorstart + @errmsg
--							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
--							goto bspexit
--							end
						end
					else
						begin	/* Begin Release to AR = N */
     					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=3
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

								/* Release Retainage, (Possible Multiple Invoice values affected by release) */
	        					/* Retainage Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(@invline_openretg,0),				--debit Retainage
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--credit
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Retainage Tax account.  Standard US or GST */
								if @i=2 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcct, @PostAmount = isnull(-@RetgTax,0),			--credit orig GST				
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @HQTXcrdRetgGLAcct, @oldPostAmount = isnull(@oldRetgTax,0),		--debit orig GST (old) on change
									@errorAccount = 'AR Retg Tax Account'

								/* Retainage Tax account.  PST */
								if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcctPST, @PostAmount = isnull(-@RetgTaxPST,0),		--credit orig PST			
									@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @HQTXcrdRetgGLAcctPST, @oldPostAmount = isnull(@oldRetgTaxPST,0),	--debit orig PST (old) on change
									@errorAccount = 'AR Retg Tax Account PST'

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
 									end		/* End insert Changed or Deleted values */

							skip_GLUpdateRev8:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */

--						select @retgtaxrel = isnull(@RetgTax,0) + isnull(@RetgTaxPST,0)
--						select @retainagerel = isnull(@invline_openretg,0)
--
--						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
--							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
--							@itemnotes, @errmsg output
--						if @rcode <> 0
--							begin
--							select @errortext = @errorstart + @errmsg
--							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
--							goto bspexit
--							end
						end
					end

				if @posttaxoninv = 'Y' and (@arcotaxretg = 'N' and @arcoseparateretgtax = 'N')		/* Hybrid same as US Standard setup for this cycle */
					begin	/* Begin International Release Retainage distribution.  Retainage already taxed, now report separately.  */
       				if @releasetocurrent = 'Y'
						begin	/* Begin Release to AR = Y */
     					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=1
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

								/* Release Retainage, (Possible Multiple Invoice values affected by release) */
	        					/* Retainage Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(@invline_openretg,0),				--debit Retainage
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--credit
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
 									end		/* End insert Changed or Deleted values */

							skip_GLUpdateRev9:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */

--						select @retgtaxrel = 0
--						select @retainagerel = isnull(@invline_openretg,0)
--
--						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
--							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
--							@itemnotes, @errmsg output
--						if @rcode <> 0
--							begin
--							select @errortext = @errorstart + @errmsg
--							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
--							goto bspexit
--							end
						end	
					else
						begin	/* Begin Release to AR = 'N' */
     					if isnull(@invline_openretg,0) <> 0 or isnull(@oldinvline_openretg,0) <> 0
	        				begin	/* Begin Processing GL distribution loop */
		 	      
  							select @i=1 /* Set first account */
	  						while @i<=1
	        					begin	/* Begin GL */
	        					/* Validate GL Accounts */
	      						/* Spin through each type of GL account, check it and write GL Amount */
	  							select @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0

								/* Release Retainage, (Possible Multiple Invoice values affected by release) */
	        					/* Retainage Account */
	        					if @i=1
	          						begin
									/* GLAccts from Each affected Invoice ARTL.Line RecType value.  May vary */
	          						select @PostGLCo = @ARGLCo, @PostGLAcct = @ReleaseGLRetainAcct, @PostAmount = isnull(@invline_openretg,0),				--debit Retainage
	                 					@oldPostGLCo = @ARGLCo, @oldPostGLAcct = @oldReleaseGLRetainAcct, @oldPostAmount = isnull(-@oldinvline_openretg,0),	--credit
	                 					@errorAccount = 'AR Retainage Account'
	          						end

								/* Check for a change */
								--Do not do in this procedure.  Have had GL reporting problems.  Difficult to explain but has to do with
								--having to release against multiple invoices.  Multiple invoices get evaluated/distributed for each JBAL line and
								--a single invoice value does not represent a Change/No Change at the JBAL line level.

								exec @rcode = vspJBGLSetDistributions @jbco, @batchmth, @batchid, @seq, @batchtranstype, @PostAmount, @oldPostAmount,
									@PostGLCo, @PostGLAcct, @oldPostGLCo, @oldPostGLAcct, @RelRetgTrans, @ARLine, @custgroup, @customer, 
									@SortName, @invoice, @jbcontract, @jbcontractItem, @transdate, @oldtransdate, @errmsg output
								if @rcode <> 0
									begin
            						if @rcode = 1
              							begin
              							select @errmsg = @errmsg + @errortext
              							goto bspexit
          								end
									if @rcode = 7
										begin
	             						select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct,'') + ': ' + isnull(@errmsg,'')
	             						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
									if @rcode = 8
										begin
      									select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') +  '- GL Account -: ' + isnull(@oldPostGLAcct,'') +': '+ isnull(@errmsg,'')
      									exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
	             						if @rcode <> 0 goto get_next_bcJBAL
										end
 									end		/* End insert Changed or Deleted values */

							skip_GLUpdateRev10:
								/* get next GL record */
								select @i=@i+1, @errmsg=''
								end		/* End GL */
							end  /* End Processing GL distribution loop */

--						select @retgtaxrel = 0
--						select @retainagerel = isnull(@invline_openretg,0)
--
--						exec @rcode = vspJBALSetReleased @jbco, @batchmth, @batchid, @seq, @jbcontractItem, @batchtranstype,
--							@JCGLCo, @itemglrevacct, @newtaxgroup, @newtaxcode, @um, @releasetocurrent, @retainagerel, @retgtaxrel,
--							@itemnotes, @errmsg output
--						if @rcode <> 0
--							begin
--							select @errortext = @errorstart + @errmsg
--							exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
--							goto bspexit
--							end
						end
					end

/*****************************************************************************************************
*
*			DETERMINE IF REMAINING AMOUNTS ARE TO BE REVERSED.  IF SO, GO TO NEXT INVOICE
*
******************************************************************************************************/	
				if @batchtranstype = 'D' or @revoldglonly = 'Y' goto get_prior_bcARTL_I
				
				select @dist_amt = @dist_amt + @invline_openretg
				select @dist_amttax = @dist_amttax + @invline_openretgtax

				if (@dist_amt < 0 and @RetgRel > 0) or (@dist_amt > 0 and @RetgRel < 0)
					begin
					/* Our distribution amount has gone negative due to some Opposite Release Retainage values along the way.
					   Setting flag will help suspend some comparisons that require polarities between compared values
					   to be the same. */
					select @distamtstilloppositeflag = 'Y'
					end
				else
					begin
					select @distamtstilloppositeflag = 'N'
					end

				/* Note:  Current bill or the bill associated with this release action does not need to be dealt
				   with separately as we do with Releasing retg.  We would not be reversing retg on a bill that has
				   never been interfaced and if it has previously been interfaced and we are changing Reversing amts
				   then the current bill or associated bill is already included in the cursor list. */
				if @100_pct = 'Y'
					begin
					/* We are reversing full amount for this Item/Line on all invoices in list. Just keep going. */
					goto get_prior_bcARTL_I 
					end
				else
					begin
					if @oppositerelretgflag = 'Y'
						begin
						/* No evaluation necessary, we have more to Reverse than we began with */
						select @oppositerelretgflag = 'N'
						goto get_prior_bcARTL_I
						end
					else
						begin
						if @distamtstilloppositeflag = 'Y'
							begin
							/* We still have more money reserved to reverse than we originally began with.
							   No need for comparisons. Just get next Invoice for this Line/Item. */
							goto get_prior_bcARTL_I
							end
						else
							begin
							/* Conditions are relatively normal at this point.  We are not (or no longer) dealing with 
							   negative/opposite RelRetg on this invoice nor is our overall distribution amount
							   negative/opposite at this stage of the distribution process.  Therefore we must now continue
							   to compare values to assure that we distribute/reverse no more than was intended.   */
							if abs(@RetgRel) > abs(isnull(@oldRetgRel,0)) --and abs(@LineRetgTaxRel) >= abs(isnull(@oldLineRetgTaxRel,0))
								begin
								/* This is the Normal on New bills or those being changed where the New amount being
								   reversed is greater than the old reverse amount. */
								if abs(@dist_amt) < abs(@RetgRel)
									begin
									-- CHS	10/14/2011	- D-02573
									-- select @oldapplymth = @Imth, @oldapplytrans = @Iartrans 
									goto get_prior_bcARTL_I 
									end
								else 
									begin									
									goto ARTL_I_loop_end				 
									end									
								end
							else
								begin
								/* This is a CHANGED bill and the New amount being reverse released is less than the Old reverse release amount. */
								if abs(@dist_amt) < abs(@RetgRel) 
									begin
									/* Normal processing until the New reverse release amounts have been processed. */
									-- CHS	10/14/2011	- D-02573
									-- select @oldapplymth = @Imth, @oldapplytrans = @Iartrans 
									goto get_prior_bcARTL_I 
									end
								else
									begin
									/* If we have reduced the amount being reverse released on a previously interfaced bill, although 
									   we have distributed all that we are going to at this point, we will continue
									   to cycle through the remaining Invoice transactions in order to back out of GL, the
									   remaining old values that have exceeded the new values. */
									select @revoldglonly = 'Y'
									if abs(@dist_amt) < abs(@oldRetgRel) 
										begin
										-- CHS	10/14/2011	- D-02573
										--select @oldapplymth = @Imth, @oldapplytrans = @Iartrans 
										goto get_prior_bcARTL_I 
										end
									else
										begin

										goto ARTL_I_loop_end
										end
									end
								end
							end
						end
					end

				-- CHS	10/14/2011	- D-02573
				-- select @oldapplymth = @Imth, @oldapplytrans = @Iartrans
				

			get_prior_bcARTL_I:	
			
			
				fetch prior from bcARTL_I into @Imth, @Iartrans, @Iarline, @OrigInvRecType, @originvtransdate,
				@invlinetaxgroup, @invlinetaxcode,
				@invline_relretg, @invline_relretgtax	--ADDED D-04589/145852
				end 	/* End I Rev Release Loop */

		ARTL_I_loop_end:	
			close bcARTL_I
			deallocate bcARTL_I
			select @opencursor_ARTL_I = 0	

			end		/* End Processing GL for Reverse Release */

   		/* Job Cost Update */
		if @releasetocurrent = 'Y' 
			begin
   			select @changed = 'N'

   			if @batchtranstype = 'C' and
				(isnull(@description,'') <> isnull(@olddescription,'') or
       			isnull(@transdate,'') <> isnull(@oldtransdate,'') or
        		isnull(@RetgRel,0) <> isnull(@oldRetgRel,0)) select @changed = 'Y'
	   
 	  		/* JC Update = insert into bARBI */
  	  		if @RetgRel=0 goto JCUpdate_Old

  			/*If the line type is delete then do not update the new line - go update the old line */
 	  		if (@batchtranstype = 'A' or @changed = 'Y') and @jbcontract is not null
      			begin
        		insert into bJBJC(JBCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, JBTransType, Description,
           			ActDate, ARTrans, Invoice, BilledUnits, BilledTax, BilledAmt, Retainage)
        		values (@jbco, @batchmth, @batchid, @jbco, @jbcontract, @jbcontractItem, @seq, @ARLine, 1, 'R', @description,
           			@transdate, @RelRetgTrans, @invoice,  0, 0, 0, 
					case when @revrelretgYN = 'N' then 
						case when @interfacetaxjc = 'Y' then -@RetgRel else -(@RetgRel - @LineRetgTaxRel) end
					else case when @interfacetaxjc = 'Y' then @RetgRel else (@RetgRel - @LineRetgTaxRel)end end)
	     		if @@rowcount = 0
     	   			begin
         			select @errmsg = 'Unable to add JB Contract audit - ' + isnull(@errmsg,''), @rcode = 1
          			GoTo bspexit
     	   			end
        		end

   		JCUpdate_Old:
      		/* update old amounts to JC */
			if (@batchtranstype = 'D' or @changed = 'Y') and @jbcontract is not null
         		begin
      			if @oldRetgRel = 0 goto JCUpdate_End

         		insert into bJBJC(JBCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, JBTransType, ARTrans, Description,
           			ActDate, Invoice, BilledUnits,BilledTax, BilledAmt, Retainage)
  	      		values(@jbco, @batchmth, @batchid, @jbco, @jbcontract, @jbcontractItem, @seq, @ARLine, 0, 'R', @RelRetgTrans, @olddescription,
          			@transdate, @invoice, 0, 0, 0, 
				case when @revrelretgYN = 'N' then 
					case when @interfacetaxjc = 'Y' then @oldRetgRel else (@oldRetgRel - @oldLineRetgTaxRel) end
				else case when @interfacetaxjc = 'Y' then -@oldRetgRel else -(@oldRetgRel - @oldLineRetgTaxRel) end end)
  	      		if @@rowcount = 0
      	    		begin
  	        		select @errmsg = 'Unable to add JB Contract audit - ' + isnull(@errmsg,''), @rcode = 1
  	        		GoTo bspexit
      	    		end
				end
			end
		else
			begin
			/* TaxCode rate may have changed and a new RetgTax might have been recalculated.  The difference in RetgTax amount, as a result of
			   the tax rate change, may need to be reported to Job Cost.  */
  			select @changed = 'N'

			/*
			This is a bug with no solution.  Under a specific setup condition (as described below) it is a possibility that when  
			retainage gets released, the difference in the OLD tax amount when posted to JCID.CurrentRetainAmt on the original bill
			and the NEW tax amount calculated as the retainage is released will not be reflected in JCID.  The setup condition is:
			1)	AR Company is NOT set to Release to Current AR  (Therefore released retainage remains as retainage on new invoice) (5% of users)
			2)	Contract IS set to Interface Tax to JC	(Not a common practice)
			3a)  AR Company is setup Intl #2 (Calculate Tax on Retainage = 'N') OR
			3b)  AR Company is setup Intl #1 (Calculate Tax on Retainage = 'Y', Dist Tax to Retg = 'Y') and TaxRate has changed
			
			The problems resolving this are many:
			1)  At this point in the procedure, what is the difference from the Total Tax released and the New Total Tax
				for each Line/Item?  We cycle through multiple invoice lines per each JBAL record.
			2)	If a user changes the Release amount on an interfaced bill under these conditions, how do we retrieve OLD values
				representing the difference from the Total Tax released and the New Total Tax as well as the NEW for same?
			3)  We must handle not only "Release" but the "Reverse Release" as well.

			At the very least it would take a pretty extensive procedure called from a strategic position (or two) within this one.
			This will be addressed if/when problem is found by user and requested for fix.
			*/
			end

	JCUpdate_End:
   
 	     /*** next line **/
        goto get_next_bcJBAL
        end /* End JBAL Loop */
   
   	close bcJBAL
   	deallocate bcJBAL
   	select @opencursorJBAL = 0
   
   	goto get_next_bcJBAR
   	end 	/* End JBAR LOOP*/
   
close bcJBAR
deallocate bcJBAR
select @opencursorJBAR=0
   
bspexit:

terminate:
if @opencursorJBAR = 1
   	begin
  	close bcJBAR
  	deallocate bcJBAR
  	end
   
if @opencursorJBAL = 1
  	begin
  	close bcJBAL
  	deallocate bcJBAL
  	end
   
if @opencursor_ARTL_R2 = 1
   	begin
   	close bcARTL_R2
   	deallocate bcARTL_R2
   	end
   
if @opencursor_ARTL_I = 1
   	begin
   	close bcARTL_I
   	deallocate bcARTL_I
   	select @opencursor_ARTL_I = 0
   	end
   
if @opencursorARTL_V = 1
   	begin
   	close bcARTL_V
   	deallocate bcARTL_V
   	select @opencursorARTL_V = 0
   	end
   
return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspJBARReleaseVal] TO [public]
GO
