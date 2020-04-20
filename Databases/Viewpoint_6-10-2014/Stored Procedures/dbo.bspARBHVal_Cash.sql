SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBHVal_Cash    Script Date: 8/28/99 9:36:42 AM ******/
CREATE  procedure [dbo].[bspARBHVal_Cash]
/***********************************************************
* CREATED BY:  JRE 8/17/97
* MODIFIED By: JRE 5/16/98 - cursor picked up last record only,
*		bc 8/20/98 - Applied amount included Deleted transactions within Check validation.
*		JM 8/21/98 - Added statement to clear EM Cost Distributions Audit in bEMBF
*		bc 12/29/98
*		JM 2/26/99 - Added check that there are lines in bARBL for the header.
*		GH 3/10/99 - Problem with NULL causing error 'Check Amt does not equal apply
* 		             Amount' when the amounts did equal.  Added IsNull to CreditAmt,
*		             Applied, and AppliedDisc.
*		bc 05/20/99 check to see if the cmref has already been cleared
*    	GR 02/29/00 Added check to see whether misc dist - if exists are marked for deletion
*                 	on mark of header deletion
*    	GR 06/16/00 corrected the validation on CMRef as per issue# 4532
*     	bc 01/11/01 - added check at end of procedure to throw an error if GL doesn't balance
*    	GH 1/12/01 'CM Reference invalid, statement has already been cleared' when it hadn't looking at check instead of deposit.  Issue #11135
*		TJL 08/13/01 - Add call to EM distribution validation procedure bspARBH1_ValMiscCashEM
*		TJL 09/14/01 - Issue #13106, Added validation checking for ALL $0.00 lines (Invalid Seq) in a sequence before allowing posting.
*		TJL 04/18/02 - Issue #16097, Correct debit/credit check. Must be 0.00 within GLCo as well as overall.
*						Also Check that if posting cash to an InterCompany, that InterCompany SubLedger is open.
*		TJL 04/29/02 - Issue #16669, Correct update ARTrans in ARBM from ARBH for 'C' type Transactions when 'A'dding a MiscDist
*		TJL 07/31/02 - Issue #11219, Add 'Apply TaxDisc' to grid for user input.
*		TJL 08/08/03 - Issue #22087, Performance Mods, Add NoLocks
*		TJL 09/30/03 - Issue #22549, Catch Payments applied to On Account Payments in validation
*		TJL 01/12/04 - Issue #23346, Allow AR Change to TransDate, ChkDate, ChkNo when Statement Closed
*		TJL 11/05/08 - Issue #123056, Validate GL Fiscal Yr for Intercompany CM GLCo
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*		TJL 07/22/09 - Issue #130964, Auto generate Misc Distributions base on AR Customer setup.
*
* USAGE:
* Validates each entry in bARBH and bARBL for a selected batch - must be called
* prior to posting the batch.
*
* After initial Batch and AR checks, bHQBC Status set to 1 (validation in progress)
* bHQBE (Batch Errors), (JC Detail Audit), and (CM)
* entries are deleted.
*
* Creates a cursor on bARBH to validate each entry individually, then a cursor on bARBL for
* each item for the header record.
*
* Errors in batch added to bHQBE using bspHQBEInsert
* Job distributions added to
* CM distributions added to
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
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource, @errmsg varchar(255) output
as
set nocount on
declare @rcode int, @errortext varchar(255), @tablename char(20), @seq int,
   	@inuseby bVPUserName, @status tinyint,@ReturnCustomer bCustomer,
   	@lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint, @accttype char(1),
   	@itemcount int, @deletecount int, @errorstart varchar(50),@CMSTStatus tinyint,
   	@isContractFlag bYN, @SortName varchar(15), @actdate bDate, @offsettingaccount bGLAcct,
   	@paymentjrnl bJrnl, @glpaylvl int, @misccashjrnl bJrnl, @glmisccashlvl int,
	@AR_glco int, @fy bMonth, @RecTypeGLCo int, @TotalApplied bDollar, @Applied bDollar, @AppliedDisc bDollar,
   	@AppliedTaxDisc bDollar, @CMGLCo bCompany, @oldCMGLCo bCompany, @CMsubclosed bMonth, 
   	@oldCMsubclosed bMonth, @MiscDistOnPayYN bYN 

/*Declare AR Header variables*/
declare @transtype char(1), @artrans bTrans, @artranstype char(1), @custgroup bGroup,
   	@customer bCustomer, @jcco bCompany, @contract bContract, @custref varchar(10), @invoice char(10),
   	@checkno char(10), @description bDesc, @transdate bDate, @duedate bDate, @discdate bDate,
   	@checkdate bDate, @appliedmth bMonth, @appliedtrans bTrans, @cmco bCompany, @cmacct bCMAcct,
   	@cmdeposit varchar(10), @creditamt bDollar, @payterms bPayTerms,
   	@oldcustref char(20), @oldinvoice char(10), @oldcheckno char(10), @olddescription bDesc,
   	@oldtransdate bDate, @oldduedate bDate, @olddiscdate bDate, @oldcheckdate bDate, @oldcmco bCompany,
   	@oldcmacct bCMAcct, @oldcmdeposit varchar(10), @oldcreditamt bDollar, @oldpayterms bPayTerms
   
declare	@numrows int, @stmtdate bDate, @skipCMDT bYN

select @skipCMDT = 'N'

--validate HQ Batch
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AR Receipt', 'ARBH', @errmsg output, @status output

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
   
--check for a payment batch
if exists (select 1 from bARBH with (nolock)
          where Co=@co and Mth = @mth and BatchId = @batchid and ARTransType not in ('P','M'))
   	begin
   	select @errmsg = 'Unable to continue, non payment transactions exist in batch', @rcode = 1
   	goto bspexit
   	end
   
--set HQ Batch status to 1 (validation in progress)
update bHQBC
set Status = 1
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status', @rcode = 1
   	goto bspexit
   	end
   
--clear HQ Batch Errors
delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
--clear JC Revenue Distributions Audit
delete bARBI where ARCo = @co and Mth = @mth and BatchId = @batchid
--clear JC Costs Distributions Audit - Misc Cash
delete bARBJ where ARCo = @co and Mth = @mth and BatchId = @batchid
--clear EM Cost Distributions Audit - Misc Cash
delete bARBE where ARCo = @co and Mth = @mth and BatchId = @batchid
--clear CM Distributions Audit
delete bARBC where ARCo = @co and Mth = @mth and BatchId = @batchid
--clear GL Distribution list
delete bARBA where Co = @co and Mth = @mth and BatchId = @batchid
   
--get some company specific variables and do some validation
--need to validate GLFY and GLJR if gl is going to be updated
select @paymentjrnl = PaymentJrnl, @glpaylvl = GLPayLev, @glmisccashlvl = GLMiscCashLev, @AR_glco = GLCo,
@misccashjrnl = MiscCashJrnl
from ARCO with (nolock)
where ARCo = @co
   
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
   
	if @glmisccashlvl > 1
      	begin
   		exec @rcode = bspGLJrnlVal @AR_glco, @misccashjrnl, @errmsg output
   		if @rcode <> 0
      		begin
        	select @errortext = 'Misc Cash Journal (' + isnull(RTrim(@misccashjrnl),'') +
                          		') is invalid. A valid journal must be setup in AR Company.'
        	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	 		if @rcode <> 0 goto bspexit
        	end
		end
   
	if @glmisccashlvl > 1 or @glpaylvl > 1
		begin
     	--validate Fiscal Year
     	select @fy = FYEMO 
   		from bGLFY with (nolock)
   		where GLCo = @AR_glco and @mth >= BeginMth and @mth <= FYEMO
     	if @@rowcount = 0
       		begin
   	  		select @errortext = 'Must first add Fiscal Year in GL Company ' + isnull(convert(varchar(3),@AR_glco),'')
   	 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  		if @rcode <> 0 goto bspexit
   	  		end
      	end
   
	--**************************************
	-- AR Header Batch loop for validation
	--**************************************
	select @seq=Min(BatchSeq) 
	from bARBH with (nolock)
	where Co=@co and Mth=@mth and BatchId=@batchid
	while @seq is not null
		BEGIN
		/* Reset some variables */
   		select @skipCMDT = 'N'	
   
      	--read batch header
      	select @transtype=TransType, @artrans=ARTrans, @invoice=Invoice,
   	   		@source=Source, @artranstype=ARTransType, @custgroup=CustGroup, @customer=Customer,
   	 		@jcco=JCCo, @contract=Contract, @transdate=TransDate, @creditamt=Isnull(CreditAmt,0),
         	@cmco=CMCo, @cmacct=CMAcct, @cmdeposit=CMDeposit, @checkno=CheckNo,
        	@oldcustref=oldCustRef, @oldinvoice=oldInvoice, @oldcheckno=oldCheckNo, @olddescription=oldDescription,
   	   		@oldtransdate=oldTransDate, @oldduedate=oldDueDate, @olddiscdate=oldDiscDate,
   	  		@oldcheckdate=oldCheckDate, @oldcmco=oldCMCo, @oldcmacct=oldCMAcct, @oldcmdeposit=oldCMDeposit,
   	  		@oldcreditamt=oldCreditAmt, @oldpayterms=oldPayTerms, @oldcheckno = oldCheckNo
      	from bARBH with (nolock)
      	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
     	select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
    	select @isContractFlag = case when @jcco is null then 'N' else 'Y' end
     	if @transtype<>'A' and @transtype<>'C' and @transtype <>'D'
   			begin
   	  		select @errortext = @errorstart + ' - invalid transaction type, must be A, C, or D'
   	  		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  		if @rcode <> 0 goto bspexit
   			end
   
   		--validation specific to ADD type AR header
   		if @transtype = 'A'
   			begin
   			--all old values must be null if a new transaction
   			if @oldcustref is not null or @oldinvoice is not null or @oldcheckno is not null or
   	   			@olddescription is not null or @oldtransdate is not null or @oldduedate is not null or
           		@olddiscdate is not null or @oldcheckdate is not null or @oldcmco is not null or
				@oldcmacct is not null or @oldcmdeposit is not null or @oldcreditamt is not null
             		or @oldpayterms is not null
   				begin
   		   		select @errortext =@errorstart + ' - Old entries in batch must be -null- for -Add- type entries.'
   		   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		   		if @rcode<>0 goto bspexit
   				end
   			end
   
     	--validation specific to ADD or CHANGE type AR header
     	if @transtype = 'C' or @transtype = 'A'
   	  		begin
       		if @artranstype<>'M'
          		begin
   	    		--validate customer
           		exec @rcode = bspARCustomerVal @custgroup, @customer, NULL, @ReturnCustomer output, @errmsg output
				if @rcode = 0
  	       			begin
					/*get Customer information */
  					select @MiscDistOnPayYN = MiscOnPay	
  	 				from bARCM m with (nolock)
  	 				where m.CustGroup = @custgroup and m.Customer = @customer
  	       			end
  	       		else
   	      			begin
   	      			select @errortext = @errorstart + ' - Customer ' + isnull(convert(varchar(10),@customer),'') + ' is not valid!'
   	  	  			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		  			if @rcode <> 0 goto bspexit
   	      			end
   	    		end
   
   			--Check that there are lines in bARBL for the header
   			select @numrows = count(*)
    		from bARBL with (nolock)
   			where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   	  		if @numrows = 0
   				begin
   				select @errortext = @errorstart + ' - No lines exist for Receipt.'
   				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
   				end
   
   			/* Check this sequence for valid lines.  If none exist then this Seq is invalid and must be removed! */
   			select @numrows = count(*)
   			from bARBL with (nolock)
   			where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and
       				(isnull(Amount, 0) <> 0 or isnull(TaxAmount, 0)<> 0 or isnull(Retainage,0)<> 0 or
       				 isnull(DiscOffered,0)<> 0 or isnull(DiscTaken,0) <> 0 or isnull(FinanceChg,0) <> 0 or
   					 isnull(TaxDisc,0) <> 0)
   			if @numrows = 0
       			begin
       			select @errortext = @errorstart + ' - Invalid SEQ.  ALL batch lines contain only $0.00 amounts.  Delete Seq '
   					+ convert (varchar(6),@seq) + ' before proceeding.'
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 goto bspexit
       			end
   
      		--Check if Check is fully applied
        	select @Applied=Sum(Amount), @AppliedDisc=Sum(DiscTaken), @AppliedTaxDisc=Sum(TaxDisc)
       		from bARBL with (nolock)
        	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and TransType <> 'D'
   
       		select @TotalApplied=IsNull(@Applied,0) - IsNull(@AppliedDisc,0) - IsNull(@AppliedTaxDisc,0)
   
        	if @TotalApplied<>@creditamt
           		begin
          		select @errortext = @errorstart + ' - Check Amt '+ convert(varchar(14),@creditamt) +
            			' does not equal apply amount' + convert(varchar(14),@TotalApplied)
           		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
          		if @rcode <> 0 goto bspexit
           		end
   
   /* Per Issue #11219: It would be OK (but rare) to apply Discounts greater than the Apply Amount
      for the Invoice.  In affect, the invoice would still get paid and the Cash Acct would be
      adjusted accordingly for the amount of the Discount taken after the fact. */
   /*    	if Abs(@Applied)<Abs(@AppliedDisc) + Abs(@AppliedTaxDisc)							
           	begin
           	select @errortext = @errorstart + ' - Total Applied Discounts: '+ convert(varchar(14),@AppliedDisc)  + ' + '
   								+ convert(varchar(14),@AppliedTaxDisc) +									
                                 	' may not be more than the apply amount ' + convert(varchar(14),@Applied)
           	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
           	if @rcode <> 0 goto bspexit
           	end
   */
   
    	  	/* Validate CM Reference */
			-- deposit validation
    	  	select @stmtdate = StmtDate
    	  	from bCMDT with (nolock)
     	  	where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmdeposit and StmtDate is not null and CMTransType=2
    	  	if @@rowcount <> 0
   				/* CM statement has been Cleared, further evaluation is required. */
    	   		begin
   				if	(@cmco <> isnull(@oldcmco,0) or @cmacct <> isnull(@oldcmacct,'') or
            		@cmdeposit <> isnull(@oldcmdeposit,'') or @creditamt <> isnull(@oldcreditamt,0))
   					begin
   					/* Error and exit when Change involves critical CMDT values and CM Statement is already cleared. */
     	   			select @errortext = @errorstart + ' - CM Reference ' + isnull(@cmdeposit,'') + ' has already been cleared on statement '
                            	+ isnull(convert(varchar(20),@stmtdate),'') + ' .'
     	 			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   					end
   				else
   					begin
   					/* Skip CMDT update when Statement is cleared but TransDate, CheckDate, CheckNo is changed for AR */
   					select @skipCMDT = 'Y'
   					end
    	   		end
   
   			/* If InterCompany CM, Validate CMCo Last SubLedger ClosedDate */
			select @CMGLCo = GLCo
			from bCMCO with (nolock)
			where CMCo = @cmco
   			
			select @CMsubclosed = LastMthSubClsd, @maxopen = MaxOpen 
			from bGLCO with (nolock)
			where GLCo = @CMGLCo
   
			if @mth <= @CMsubclosed or @mth > dateadd(month, @maxopen, @CMsubclosed)
				begin
 	   			select @errortext = @errorstart + ' - CM GLCo ' + isnull(convert(varchar(3),@CMGLCo),'') + ' subledger has been closed'
				select @errortext = @errortext + ' through month ' + isnull(convert(varchar(8), @CMsubclosed, 1),'') + '!'
 	 			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 				if @rcode <> 0 goto bspexit 
				end

			/* validate Fiscal Year of CMCo */
			select @fy = FYEMO 
			from bGLFY with (nolock)
			where GLCo = @CMGLCo and @mth >= BeginMth and @mth <= FYEMO
			if @@rowcount = 0
				begin
				select @errortext = @errorstart + 'Must first add Fiscal Year for CM GLCo ' + isnull(convert(varchar(3),@CMGLCo),'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   		
   			if @transtype = 'C' and isnull(@oldcmco,0) <> @cmco	
   				begin
   				select @oldCMGLCo = GLCo
   				from bCMCO with (nolock)
   				where CMCo = @oldcmco
	   			
   				select @oldCMsubclosed = LastMthSubClsd, @maxopen = MaxOpen
   				from bGLCO with (nolock)
   				where GLCo = @oldCMGLCo
	   
   				if @mth <= @oldCMsubclosed or @mth > dateadd(month, @maxopen, @oldCMsubclosed)
   					begin
     	   			select @errortext = @errorstart + ' -  Old CM GLCo ' + isnull(convert(varchar(3),@oldCMGLCo),'') + ' subledger has been closed'
   					select @errortext = @errortext + ' through month ' + isnull(convert(varchar(8), @oldCMsubclosed, 1),'') + '!'
     	 			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit 
   					end

				/* validate Fiscal Year of oldCMCo */
				select @fy = FYEMO 
				from bGLFY with (nolock)
				where GLCo = @oldCMGLCo and @mth >= BeginMth and @mth <= FYEMO
				if @@rowcount = 0
					begin
					select @errortext = @errorstart + 'Must first add Fiscal Year for CM GLCo ' + isnull(convert(varchar(3),@oldCMGLCo),'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
   				end
			end --Add or Change Val
   
       --validation specific to DELETE type AR header
       if @transtype = 'D'
   			begin
			/* Need to check to see if there are any transactions applied to the one we are trying to delete.
			You may only delete 'P' applied transactions using the ARCashReceipts program! (Others not displayed
			in "Add Transactions" lookup and cannot be added to ARCashReceipts batch.) Only the original 
			Invoice transaction will have both Mth = ApplyMth and ARTrans = ApplyTrans at this point. 
			***** NOTE, all transactions contain a ARTransType 'P' in this module, not a good filter! */
     	   	if (exists (select top 1 1 from bARTH h with (nolock)
   					join bARTL l with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
   					where l.ARCo = @co and l.ApplyMth = @mth and l.ApplyTrans = @artrans 
   						and (l.Mth <> l.ApplyMth or l.ARTrans <> l.ApplyTrans))
   				or exists (select top 1 1 from bARBH bh with (nolock)
   					join bARBL bl with (nolock) on bh.Co = bl.Co and bh.Mth = bl.Mth 
   						and bh.BatchId = bl.BatchId and bh.BatchSeq = bl.BatchSeq
   					where bl.Co = @co and bl.ApplyMth = @mth and bl.ApplyTrans = @artrans 
   						and (bl.Mth <> bl.ApplyMth or isnull(bl.ARTrans, 0) <> bl.ApplyTrans)))
          		begin
				select @errortext = @errorstart + ' - Transaction - ' + isnull(convert(varchar(40),@artrans),'') + 
   					' - has other transactions applied to it that must first be removed. Cannot delete! '
     	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	        if @rcode <> 0 goto bspexit
     	        end
   
         	select @itemcount = count(*)
        	from bARTL with (nolock)
         	where ARCo=@co and Mth=@mth and ARTrans=@artrans
   
        	select @deletecount= count(*)
         	from bARBL with (nolock)
         	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and TransType='D'
   
         	if @itemcount <> @deletecount
   	    		begin
   	     		select @errortext = @errorstart + ' - In order to delete a AR Header, all lines must be in the current batch and marked for delete! '
   	     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	     		if @rcode <> 0 goto bspexit
   	    		end
   
    	  	/* Validate CM Reference */
        	-- deposit validation
    		select @itemcount = count(*)
    	  	from bCMDT with (nolock)
         	where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmdeposit and StmtDate is not null and CMTransType = 2
    	  	if @itemcount <> 0
    	  		begin
     	    	select @errortext = @errorstart + ' - CM Reference ' + isnull(@cmdeposit,'') + ' is invalid, That statement has already been cleared.'
     	    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	    	if @rcode <> 0 goto bspexit
    	    	end
   
   			/* If InterCompany CM, Validate CMCo Last SubLedger ClosedDate */
			select @oldCMGLCo = GLCo
			from bCMCO with (nolock)
			where CMCo = @oldcmco
   			
			select @oldCMsubclosed = LastMthSubClsd, @maxopen = MaxOpen
			from bGLCO with (nolock)
			where GLCo = @oldCMGLCo
   
			if @mth <= @oldCMsubclosed or @mth > dateadd(month, @maxopen, @oldCMsubclosed)	
				begin
 	   			select @errortext = @errorstart + ' - CM GLCo ' + isnull(convert(varchar(3),@oldCMGLCo),'') + ' subledger has been closed'
				select @errortext = @errortext + ' through month ' + isnull(convert(varchar(8), @oldCMsubclosed, 1),'') + '!'
 	 			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 				if @rcode <> 0 goto bspexit 
				end

			/* validate Fiscal Year of oldCMCo */
			select @fy = FYEMO 
			from bGLFY with (nolock)
			where GLCo = @oldCMGLCo and @mth >= BeginMth and @mth <= FYEMO
			if @@rowcount = 0
				begin
				select @errortext = @errorstart + 'Must first add Fiscal Year for CM GLCo ' + isnull(convert(varchar(3),@oldCMGLCo),'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
	   
    		/* Check whether misc dist are marked for deletion, if exists */
     		if exists(select top 1 1 from bARBM with (nolock)
       		where Co = @co and Mth = @mth and ARTrans = @artrans and TransType <> 'D')
      			begin
       			select @errortext= @errorstart + 'Misc Distributions exist - not marked for deletion'
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 	    		if @rcode <> 0 goto bspexit
       			end
   			end --Delete validation
   
		--ARBL Payment Line Check
      	if @artranstype='P'
   			begin
   			exec @rcode = bspARBH1_ValCashLines @co,@mth,@batchid, @seq, @errmsg output
   			if @rcode <> 0 goto bspexit  /* could not add to error batch */
         	end
   
      	--ARBL Misc Cash Check
      	if @artranstype='M'
   			begin
   			--GL Misc Cash Check
   			exec @rcode = bspARBH1_ValMiscCashGL @co,@mth,@batchid, @seq, @errmsg output
   
   			if @rcode <> 0 goto bspexit  /* could not add to error batch */
   			--JC Misc Cash Check
   			exec @rcode = bspARBH1_ValMiscCashJC @co,@mth,@batchid, @seq, @errmsg output
   			if @rcode <> 0 goto bspexit   /* could not add to error batch */
   			--EM Misc Cash Check
   			exec @rcode = bspARBH1_ValMiscCashEM @co,@mth,@batchid, @seq, @errmsg output
   			if @rcode <> 0 goto bspexit
      		end
   
      	--CM Validate
   		if @skipCMDT = 'N'
   			begin
      		exec @rcode=bspARBH1_ValCMDist @co, @mth, @batchid,@transtype,@cmco, @cmacct, @cmdeposit,
           		@transdate, @creditamt,@oldcmco , @oldcmacct, @oldcmdeposit, @oldtransdate, @oldcreditamt,
           		@errorstart,@errmsg  output
   			end
   
		/* Create Misc Distributions automatically.
		   Create only on New Receipts based on AR Customer Setup option. */
		if @transtype = 'A' and @MiscDistOnPayYN = 'Y'
			begin
			/* User has opted to automatically generate Misc Distributions.  To avoid a mix of manually entered values
			   and auto-generated values we clear the table at the start.  The auto-generation process cannot 
			   possibly tell the difference from manually entered values to those values already entered as part
			   of the automatic process.  It's cleanest to clear and begin again. */
			Delete bARBM where bARBM.Co = @co and bARBM.Mth = @mth and bARBM.BatchId = @batchid and bARBM.BatchSeq = @seq 
			
			/* Update existing Misc Distribution record first.
				a.  This is record set process (rather than using a cursor)
				b.  We update bARBM using a Derived table (SQL Statement, aliased as MiscDist)
				c.  Derived Table (MiscDist) returns the following:
					1) Joins original Invoice's (ARTH) Customer and Contract to (ARCM and JCCM)
					2) Returns ARCM.MiscDistCode and JCCM.MiscDistCode for all paid invoices and uses either Contract code 1st, else uses Customer code
					3) All paid invoices in a single Seq are considered and then grouped by common Misc Dist Codes
					4) Paid Invoice amounts are grouped by and totaled by common Misc Dist Codes  
					5) No records are returned for update when all Customer and Contract source MiscDistCodes are null
				d.  The update to bARBM occurs relative to a single batch sequence (ARBH header record) */
			update bARBM
			set bARBM.Amount = MiscDist.MiscDistAmt, bARBM.Description = MiscDist.Description
			from bARBM
			join (select sum(IsNull(l.Amount,0))- (sum(IsNull(l.TaxAmount,0)) + sum(IsNull(l.RetgTax,0))) as MiscDistAmt,
					isnull(c.MiscDistCode, m.MiscDistCode) as MiscDistCodeDflt,
					mc.Description
				from bARBL l with (nolock)
				join bARTH th with (nolock) on th.ARCo = l.Co and th.Mth = l.ApplyMth and th.ARTrans = l.ApplyTrans
				left outer join bJCCM c with (nolock) on c.JCCo = th.JCCo and c.Contract = th.Contract
				join bARCM m with (nolock) on m.CustGroup = th.CustGroup and m.Customer = th.Customer
				join bARMC mc with (nolock) on mc.CustGroup = th.CustGroup and mc.MiscDistCode = isnull(c.MiscDistCode, m.MiscDistCode)
				left outer join bARBM bm with (nolock) on bm.Co = l.Co and bm.Mth = l.Mth and bm.BatchId = l.BatchId and bm.BatchSeq = l.BatchSeq and bm.MiscDistCode = isnull(c.MiscDistCode, m.MiscDistCode) --
				where l.Co = @co and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @seq
					and bm.MiscDistCode is not null and bm.Co is not null and isnull(c.MiscDistCode, m.MiscDistCode) is not null
				group by isnull(c.MiscDistCode, m.MiscDistCode), mc.Description) MiscDist on MiscDist.MiscDistCodeDflt = bARBM.MiscDistCode
			where bARBM.Co = @co and bARBM.Mth = @mth and bARBM.BatchId = @batchid and bARBM.BatchSeq = @seq 
			if @@error <> 0
				begin
				select @errortext = @errorstart + '- Auto-create MiscDist has failed. Turn off AR Customer option, enter manually.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit				
				end;
			
			/* Insert remaining Misc Distribution records that did not already exist. 
				a.  This is record set process (rather than using a cursor)
				b.  We first generate a Common Table Expression (MiscDistTemp) from which to insert into bARBM
					This is very similar to the Derived table above only a slightly different syntax
				c.  Common Table Expression (MiscDistTemp) returns the following:
					1) Joins original Invoice's (ARTH) Customer and Contract to (ARCM and JCCM)
					2) Returns ARCM.MiscDistCode and JCCM.MiscDistCode for all paid invoices and uses either Contract code 1st, else uses Customer code
					3) All paid invoices in a single Seq are considered and then grouped by common Misc Dist Codes
					4) Paid Invoice amounts are grouped by and totaled by common Misc Dist Codes 
					5) No records are returned for insert when all Customer and Contract source MiscDistCodes are null
					6) Will ONLY include those MiscDistCodes that DO NOT already exist in bARBM	*/
			with MiscDistTemp (MiscDistCode, Amount, Description)
			as (select MiscDist.MiscDistCodeDflt, MiscDist.MiscDistAmt, MiscDist.Description
				from (select sum(IsNull(l.Amount,0))- (sum(IsNull(l.TaxAmount,0)) + sum(IsNull(l.RetgTax,0))) as MiscDistAmt,
						isnull(c.MiscDistCode, m.MiscDistCode) as MiscDistCodeDflt,
						mc.Description
					from bARBL l with (nolock)
					join bARTH th with (nolock) on th.ARCo = l.Co and th.Mth = l.ApplyMth and th.ARTrans = l.ApplyTrans
					left outer join bJCCM c with (nolock) on c.JCCo = th.JCCo and c.Contract = th.Contract
					join bARCM m with (nolock) on m.CustGroup = th.CustGroup and m.Customer = th.Customer
					join bARMC mc with (nolock) on mc.CustGroup = th.CustGroup and mc.MiscDistCode = isnull(c.MiscDistCode, m.MiscDistCode)
					left outer join bARBM bm with (nolock) on bm.Co = l.Co and bm.Mth = l.Mth and bm.BatchId = l.BatchId and bm.BatchSeq = l.BatchSeq and bm.MiscDistCode = isnull(c.MiscDistCode, m.MiscDistCode)
					where l.Co = @co and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @seq 
						and bm.MiscDistCode is null and bm.Co is null and isnull(c.MiscDistCode, m.MiscDistCode) is not null
					group by isnull(c.MiscDistCode, m.MiscDistCode), mc.Description) MiscDist
			)

			/*  The insert to bARBM will use only those records established by the Common Table Expression above */
			insert into bARBM(Co, Mth, BatchId, CustGroup, MiscDistCode, BatchSeq, TransType, DistDate, Description, Amount)
			select @co, @mth, @batchid, @custgroup, MiscDistCode, @seq, 'A', @transdate, Description, Amount
			from MiscDistTemp
			if @@error <> 0
				begin
				select @errortext = @errorstart + '- Auto-create MiscDist has failed. Turn off AR Customer option, enter manually.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit				
				end
			end		/* End Auto-generate Misc Distributions loop */
   			
      	--next header
      	select @seq=Min(BatchSeq) from bARBH with (nolock)
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq>@seq
   
   		END --ARBH LOOP
   
/* Check Misc Distributions - Updating bARBM with Transaction number and Dist Code
  validation are both accomplished for an entire batch and therefore should occur
  after looping through each header/Seq */
/* Need to update the misc dist. transaction number if the header was a 'change' type
  and the misc distribution is a add type.  Posting program will not update transaction
  number, so we will do it here. */
update bARBM
set ARTrans = h.ARTrans
from bARBH h with (nolock)
join bARBM m with (nolock) on m.Co = h.Co and m.Mth = h.Mth and m.BatchId = h.BatchId and m.BatchSeq = h.BatchSeq
where m.Co = @co and m.Mth = @mth and m.BatchId = @batchid
	and m.TransType = 'A' and h.TransType ='C'

exec @rcode = bspARBH1_ValMiscDist @co, @mth, @batchid, @errmsg output
if @rcode <> 0 goto bspexit

-- make sure debits and credits balance
select GLCo
from bARBA with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
group by GLCo
having isnull(sum(Amount),0) <> 0
if @@rowcount <> 0
	begin
	select @errortext =  'GL Company ' + isnull(convert(varchar(3), @AR_glco),'') + ' entries do not balance!'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end
   
bspexit:
   
/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3	/* valid - ok to post */
if exists(select top 1 1 from bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @status = 2	/* validation errors */
	end
   
update bHQBC
set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	end
   			  
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBHVal_Cash]'
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspARBHVal_Cash] TO [public]
GO
