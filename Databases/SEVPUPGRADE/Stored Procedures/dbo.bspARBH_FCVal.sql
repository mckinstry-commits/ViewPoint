SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH_FCVal    Script Date: 8/28/99 9:36:06 AM ******/

CREATE  procedure [dbo].[bspARBH_FCVal]
/***********************************************************
* CREATED BY: 	CJW 10/29/97
* MODIFIED By : CJW 10/29/97
*		JM 6/2/98 Added @deptdead bDept, @custdead bCustomer, @retgdead bPct
*		  		declares, and added these as params to bspJCContractVal call to
*				make params match bsp call
*    	GR 11/23/99 corrected the where clause to get the item count from ARTL
*   	GR 11/24/99 corrected ARBH cursor loop and some clean up
*	  	GG 07/07/00 fixed call to bspHQBEInsert, change validation of Finance Charge Account to AR GL Account
*		TJL  07/30/01 fixed Cross-Company code.
*		TJL  11/28/01 - Issue #14449, Validate the existence of DueDate and TransDate on original (On Account) FC Invoice.
*		TJL  02/28/02 - Issue #14171, Did a complete review, modified extensively
*		TJL 04/22/02 - Issue #17070, Catch improper GLAcct SubTypes during GLAcct validation.
*		TJL 11/05/02 - Issue #19161, Related to #19492: Within SubTypes some GLAccts may be the same.	
*		TJL 02/19/03 - Issue #20369, If Form GLAcct is NULL, send error to HQBE
*		TJL 03/27/03 - Issue #20644, Validate Payment Terms, NULL Payment Terms is OK
*		TJL 09/18/03 - Issue #22394, Performance Enhancements, Add NoLocks
*		TJL 02/26/07 - Issue #120561, Made adjustment pertaining to bHQCC Close Control entry handling
*		TJL 10/02/07 - Issue #124262, Catch in validation before trigger when 'F' trans being deleted has applied trans against it
*		TJL 03/24/09 - Issue #132807, Trigger error when validating AR Finance Charge batch
*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
*
* USAGE:
* Validates each entry in bARBH and bARBL for a selected batch - must be called from finance charges form and
* prior to posting the batch.
*
* After initial Batch and AR checks, bHQBC Status set to 1 (validation in progress)
* bHQBE (Batch Errors), (JC Detail Audit), and (Inventory dist)
* entries are deleted.
*
* Creates a cursor on bARBH to validate each entry individually, then a cursor on bARBL for
* each item for the header record.
*
* Errors in batch added to bHQBE using bspHQBEInsert
* GL debit and credit totals must balance.
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
* INPUT PARAMETERS
*   CMCo        CM Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
    
   @co bCompany, @mth bMonth, @batchid bBatchID, @source char(10), @errmsg varchar(255) output
   as
   
   set nocount on
    
	DECLARE @rcode int,
			@errortext varchar(255),
			@seq int,
			@UpdateJC int,
			@status tinyint,
			@opencursorARBL tinyint,
			@opencursorARBH tinyint,
			@opencursorARBM tinyint,
			@itemcount int,
			@deletecount int,
			@errorstart varchar(50),
			@isContractFlag bYN,
			@invjrnl bJrnl,
			@glinvoicelvl int,
			@AR_glco int,
			@fy bMonth,
			@RecTypeGLCo int,
			@errorAccount varchar(30),
			@oldRecTypeGLCo bCompany,
			@SortName varchar(15),
			@GLARAcct bGLAcct,
			@oldGLARAcct bGLAcct,
			@GLARFCRecvAcct bGLAcct,
			@oldGLARFCRecvAcct bGLAcct,
			@chksubtype char(1)
    
   /* Declare AR Header variables */
	DECLARE @transtype char(1),
			@ARTransHD bTrans,
			@ARTransTypeHD char(1),
			@custgroup bGroup,
			@customer bCustomer,
			@JCCoHD bCompany,
			@ContractHD bContract,
			@invoice char(10),
			@DescriptionHD bDesc,
			@transdate bDate,
			@duedate bDate,
			@appliedmth bMonth,
			@appliedtrans bTrans,
			@oldInvoice char(10),
			@oldDescription bDesc,
			@oldTransDate bDate,
			@oldDueDate bDate,
			@payterms bPayTerms
    
	/* Declare AR Line variables */
	DECLARE @ARLine smallint,
			@TransTypeLine char,
			@ARTrans bTrans,
			@RecType tinyint,
			@LineType char,
			@Description bDesc,
			@Line_GLCo bCompany,
			@RevAcct bGLAcct,
			@Amount bDollar,
			@ApplyMth bMonth,
			@ApplyTrans bTrans,
			@ApplyLine smallint,
			@JCCo bCompany,
			@Contract bContract,
			@ContractItem bContractItem,
			@FinanceChg bDollar,
			@rptApplyMth bMonth,
			@rptApplyTrans bTrans,
			@oldLineType char(1),
			@oldRecType tinyint,
			@oldAmount bDollar,
			@oldApplyMth bMonth,
			@oldApplyTrans bTrans,
			@oldApplyLine smallint,
			@oldJCCo bCompany,
			@oldContract bContract,
			@oldItem bContractItem,
			@PostGLCo bCompany,
			@PostGLAcct bGLAcct,
			@PostAmount bDollar,
			@oldPostGLCo bCompany,
			@oldPostGLAcct bGLAcct,
			@oldPostAmount bDollar,
			@i int,
			@oldLine_GLCo bCompany,
			@oldRevAcct bGLAcct,
			@oldFinanceChg bDollar,
			@oldrptApplyMth bMonth,
			@oldrptApplyTrans bTrans
    
   /* Declare Misc Dist Variables */
	DECLARE @TmpCustomer varchar(15),
			@ReturnCustomer bCustomer,
			@ContractStatus int,
			@deptdead bDept,
			@custdead bCustomer,
			@retgdead bPct,
			@startmthdead bMonth
    
   /* set open cursor flags to false */
   select @opencursorARBH = 0, @opencursorARBL = 0, @opencursorARBM = 0
    
   /* validate source */
   if @source not in ('ARFinanceC')
    	begin
    	select @errmsg = @source + ' is invalid', @rcode = 1
    	goto bspexit
    	end
    
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'ARBH', @errmsg output, @status output
   if @rcode <> 0
    	begin
    	select @errmsg = @errmsg, @rcode = 1
    	goto bspexit
    	end
    
   if @status < 0 or @status > 3
    	begin
    	select @errmsg = 'Invalid Batch status!', @rcode = 1
    	goto bspexit
    	end
    
   /* set HQ Batch status to 1 (validation in progress) */
   update bHQBC
   set Status = 1
   where Co = @co and Mth = @mth and BatchId = @batchid
    
   if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    	goto bspexit
    	end
    
   /* clear HQ Batch Errors */
   delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* clear JC Distributions Audit */
   delete bARBI where ARCo = @co and Mth = @mth and BatchId = @batchid
   
   /* clear GL Distribution list */
   delete bARBA where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* get some company specific variables and do some validation */
    
   /* need to validate GLFY and GLJR if gl is going to be updated */
   select @invjrnl = InvoiceJrnl, @glinvoicelvl = GLInvLev, @AR_glco = GLCo, @UpdateJC = FCLevel 
   from ARCO with (nolock)
   where ARCo = @co
    
   if @glinvoicelvl > 1
    	begin
    	exec @rcode = bspGLJrnlVal @AR_glco, @invjrnl, @errmsg output
    	if @rcode <> 0
    		begin
        	select @errortext = 'Invalid Journal - A valid journal must be setup in AR Company.'
    		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        	if @rcode <> 0 goto bspexit
      		end
    
    	/* validate Fiscal Year */
      	select @fy = FYEMO 
   	from bGLFY with (nolock)
      	where GLCo = @AR_glco and @mth >= BeginMth and @mth <= FYEMO
      	if @@rowcount = 0
          	begin
          	select @errortext = 'Must first add Fiscal Year'
          	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
         	if @rcode <> 0 goto bspexit
          	end
      	end
    
   /* declare cursor on AR Header Batch for validation */
   declare bcARBH cursor for select BatchSeq, TransType, ARTrans, Invoice, Source, 
   	ARTransType, CustGroup, Customer, JCCo, Contract, TransDate, DueDate, RecType,
   	AppliedMth, AppliedTrans, PayTerms, oldInvoice, oldDescription, oldTransDate, oldDueDate
   from bARBH with (nolock)
   where Co = @co and Mth = @mth and BatchId = @batchid
    
   /* open cursor */
   open bcARBH
   select @opencursorARBH = 1
    
   /* get rows out of ARBH */
   get_next_bcARBH:
   fetch next from bcARBH into @seq, @transtype, @ARTransHD, @invoice, @source,
    	@ARTransTypeHD, @custgroup, @customer, @JCCoHD, @ContractHD, @transdate, @duedate, @RecType,
    	@appliedmth, @appliedtrans, @payterms, @oldInvoice, @oldDescription, @oldTransDate, @oldDueDate
    
   /* Loop through all rows */
   while (@@fetch_status = 0)
    	begin  /* Begin Header Loop */
    	select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
        select @isContractFlag = case when @ContractHD is null then 'N' else 'Y' end

    	if @ARTransTypeHD <>'F'
     		begin
          	select @errortext = @errorstart + ' - invalid AR transaction type, ' + @ARTransTypeHD + ' must be F.'
        	exec  @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        	if @rcode <> 0 goto bspexit
          	end
    
      	if @transtype<>'A' and @transtype<>'C' and @transtype <>'D'
        	begin
        	select @errortext = @errorstart + ' - invalid transaction type, must be A, C, or D.'
        	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
          	if @rcode <> 0 goto bspexit
          	end
    
   	/* validation specific to ADD type AR header */
    
      	/* validation specific to ADD or CHANGE type AR header */
      	if @transtype = 'C' or @transtype = 'A'
    		begin
        	/* validate customer */
        	select @TmpCustomer = convert(varchar(15),@customer)
        	exec @rcode = bspARCustomerVal @custgroup, @TmpCustomer, NULL, @ReturnCustomer output, @errmsg output
        	if @rcode <> 0
        		begin
        	 	select @errortext = @errorstart + '- Customer ' + isnull(convert(varchar(10),@customer),'') + ' is not a valid customer!'
        	   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        	   	if @rcode <> 0 goto bspexit
        	   	end
    
        	/* Validate Receivable Type */
        	exec @rcode = bspRecTypeVal @co, @RecType, @errmsg output
        	if @rcode <> 0
        		begin
        	 	select @errortext = @errorstart + '- Receivable Type:' + isnull(convert(varchar(3),@RecType),'') +': '+ isnull(@errmsg,'')
        	 	print @errortext
        	 	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        	  	if @rcode <> 0 goto bspexit
        	  	end
   
   		/* Validate Payment Terms */
   		if @payterms is not null
   			begin
   			select 1 from bHQPT with (nolock) where PayTerms = @payterms
   			if @@rowcount = 0
   				begin
   				select @errortext = @errorstart + '- Payment Term: ' + isnull(@payterms,'') + ', is not valid!'
   				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
   				end
   			end
    
    		/* Validate Contract Related values */
        	if @isContractFlag='Y'   
        		begin
        	   	/* validate JCCo */
        	  	exec @rcode = bspJCCompanyVal @JCCoHD, @errmsg output
        	  	if @rcode <> 0
        			begin
        			select @errortext = @errorstart + '- JCCo:' + isnull(convert (varchar(3),@JCCoHD),'') +': ' + isnull(@errmsg,'')
        			exec @rcode = bspHQBEInsert @JCCoHD, @mth, @batchid, @errortext, @errmsg output
        			if @rcode <> 0 goto bspexit
        			end
        		select @errmsg = NULL
    
        		/* validate Contract */
              	exec @rcode = bspJCContractVal @JCCoHD, @ContractHD, @ContractStatus output, @deptdead output, @custdead output,
    				 @retgdead output, @startmthdead output, @msg=@errmsg output
        		if @rcode <> 0
        			begin
        		  	select @errortext = @errorstart + '- Contract:' + isnull(@ContractHD,'') + ': ' + isnull(@errmsg,'')
        		   	exec @rcode = bspHQBEInsert @JCCoHD, @mth, @batchid, @errortext, @errmsg output
        		   	if @rcode <> 0 goto bspexit
        	       	end
        		select @errmsg = NULL
        	    end  /* End Contract Related validation */
    
    		/* Validate TransDate and DueDate. */
    		/* In the Batch table AppliedMth and AppliedTrans are null only for an
    		   original 'On Account' or 'RecType' FC Invoice. (These have values if applied to another)
    		   TransDate and DueDate may not be NULL for original FC invoices. */
    		if @appliedmth is null and @appliedtrans is null	-- Then this is original
    	     	begin
    	     	if isnull(@transdate, '') = '' or isnull(@duedate, '') = ''
    				begin
    				select @errortext = @errorstart + '- Inv/Trans Date and Due Date may not be NULL on an original invoice! ' + isnull(@errmsg,'')
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 goto bspexit
       	   		end
    	     	end
    	 	else		-- This is an Applied Finance Charge .  TransDate may not be NULL for Applied Finance Charge.
    	     	begin
    	     	if isnull(@transdate, '') = ''
    				begin
    				select @errortext = @errorstart + '- Inv/Trans Date may not be NULL! ' + isnull(@errmsg,'')
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 goto bspexit
       	      	end
    	     	end
     		end    -- End Add or Change Val
   
      	/* validation specific to CHANGE or DELETE type AR header */
      	if @transtype = 'C' or @transtype = 'D'
    		begin
    		/* On change and delete, Customer and Invoice fields may NOT be changed. */
    		if not exists (select 1
    					  from bARTH with (nolock)
    					  where ARCo = @co and Mth = @mth and ARTrans = @ARTransHD
    						and CustGroup = @custgroup and Customer = @customer
    					    and Invoice = @invoice)
    			begin
    			select @errortext = @errorstart + '- Customer or Invoice number may not be changed! ' + isnull(@errmsg,'')
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 goto bspexit
    			end
    		end		-- End Change or Delete Val
    
      	/* validation specific to DELETE type AR header */
      	if @transtype = 'D'
    		begin
          	select @itemcount = count(*) from bARTL with (nolock) where ARCo=@co and ARTrans=@ARTransHD and Mth=@mth
          	select @deletecount= count(*) from bARBL with (nolock) where Co=@co and Mth=@mth 
    							and BatchId=@batchid and BatchSeq=@seq and TransType='D'
    
          	if @itemcount <> @deletecount
    	     	begin
        	  	select @errortext = @errorstart + ' - In order to delete a AR Header, all lines must be in the current batch and marked for delete! '
        	  	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        	 	if @rcode <> 0 goto bspexit
        	  	end
      		end   -- Delete validation
    
    	/* Validation for all lines associated to this AR Transaction */
    	declare bcARBL cursor for select
        	ARLine, TransType, ARTrans, LineType, Description, GLCo, GLAcct, RecType,
        	Amount, FinanceChg, ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item,
    		rptApplyMth, rptApplyTrans, 
    		oldLineType, oldDescription, oldGLCo, oldGLAcct,oldRecType, oldAmount, 
    		oldFinanceChg, oldApplyMth, oldApplyTrans, oldApplyLine, oldJCCo,
        	oldContract, oldItem
    	from bARBL with (nolock)
    	where Co = @co and Mth = @mth and BatchId=@batchid and BatchSeq=@seq
    
    	/* open cursor for line */
    	open bcARBL
    	select @opencursorARBL = 1
    
    	/* get first row (line) */
    	get_next_bcARBL:
    	fetch next from bcARBL into
        	  	@ARLine, @TransTypeLine, @ARTrans, @LineType, @Description, @Line_GLCo, @RevAcct, @RecType,
        	  	@Amount, @FinanceChg, @ApplyMth, @ApplyTrans, @ApplyLine, @JCCo, @Contract, @ContractItem, 
    			@rptApplyMth, @rptApplyTrans,
    			@oldLineType,  @oldDescription, @oldLine_GLCo, @oldRevAcct, @oldRecType, @oldAmount, 
    			@oldFinanceChg, @oldApplyMth, @oldApplyTrans, @oldApplyLine, @oldJCCo,
        	  	@oldContract, @oldItem
    
    	while (@@fetch_status = 0)
          	begin	/* Begin ARBL Line Loop */
          	select @errorstart = 'Seq' + convert (varchar(6),@seq) + ' Item ' + convert(varchar(6),@ARLine)+ ' '
    
          	/* validate transactions action */
          	if @TransTypeLine<>'A' and @TransTypeLine <>'C' and @TransTypeLine <>'D'
    			begin
    			select @errortext = @errorstart + ' - Invalid transaction type, must be A, C, or D.'
    			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		if @rcode <> 0 goto bspexit
        		end
    
    	   	/*Validate Receivable Type*/
        	exec @rcode = bspRecTypeVal @co, @RecType, @errmsg output
    	   	if isnull(@RecType,0) = 0 select @rcode = 1
    	   	if @rcode <> 0
                begin
                select @errortext = @errorstart + ' - Receivable Type:' + isnull(convert(varchar(3),@RecType),'') + isnull(@errmsg,'')
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                end
    
    		/* validation specific to Add type transaction */
    		-- none
    
          	/* validation specific to Add type transactions, or Change type transactions */
          	if @TransTypeLine = 'A' or @TransTypeLine = 'C'
        		begin
        	  	/* Validate Contract types */
        	    if @isContractFlag = 'Y'
        	   		begin
        		   	/* Validate Contract Item */
   
        		  	exec @rcode = bspJCCIVal @JCCo, @Contract, @ContractItem, @errmsg output
        			if @rcode <> 0
        		 		begin
        				select @errortext = @errorstart + '- Contract :' + isnull(@ContractHD,'') + ', ' + 'Item :' + isnull(@ContractItem,'') +': ' + isnull(@errmsg,'')
        	   	  		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		       	if @rcode <> 0 goto bspexit
        		       	end
        	      	end  -- contract types
    
        		/* get offsetting Receivables GLAcct - GLAR FinanceChg Receivables Account */
        		select @RecTypeGLCo = t.GLCo, @GLARFCRecvAcct = t.GLARFCRecvAcct
           		from bARRT t with (nolock)
        		where ARCo = @co and RecType = @RecType
    
    			/* Validate rptApplyMth and rptApplyTrans.  If both have values,
    			   then they must be valid to be useful.  Validate to assure this. */
    			if isnull(@rptApplyMth, '') <> '' and isnull(@rptApplyTrans, 0) <> 0
    				begin
    				select ARCo, Mth, ARTrans
    				from bARTH with (nolock)
    				where ARCo = @co and Mth = @rptApplyMth and ARTrans = @rptApplyTrans
    						and Mth = AppliedMth and ARTrans = AppliedTrans
    				if @@rowcount = 0
    					begin
    					select @errortext = @errorstart + 'The original Mth: ' + isnull(convert(varchar(8), @rptApplyMth, 1),'')
    					select @errortext = @errortext + ' and Transaction: ' + isnull(convert(varchar(10), @rptApplyTrans),'')
    					select @errortext = @errortext + ' have been purged or is invalid: ' + isnull(@errmsg,'')
        		 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		  		if @rcode <> 0 goto bspexit
        		  		end 
    				end
    
    			/* Make sure that Finance Charge amount is the same value as Amount. */
    			if @Amount <> @FinanceChg
    				begin
    				update bARBL
    				set FinanceChg = @Amount
    				where Co = @co and Mth = @mth and BatchId=@batchid and BatchSeq=@seq
    					and ARLine = @ARLine
    				end
    
      			end  /* End trans type A or C */
    
          	if @TransTypeLine = 'C' or @TransTypeLine = 'D'
      			begin
    	   		/*Validate old Receivable Type*/
        		exec @rcode = bspRecTypeVal @co, @oldRecType, @errmsg output
    	   		if isnull(@oldRecType,0) = 0 select @rcode = 1
    	   		if @rcode <> 0
                	begin
                	select @errortext = @errorstart + '- old Receivable Type:' + isnull(convert(varchar(3),@oldRecType),'') + isnull(@errmsg,'')
                	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                	if @rcode <>0 goto bspexit
                	end
    
        		/* get the old offsetting Receivables GLAcct - GLAR FinanceChg Receivables Account */	
        		select @oldRecTypeGLCo = GLCo, @oldGLARFCRecvAcct= GLARFCRecvAcct
             	from bARRT with (nolock)
    			where ARCo = @co and RecType = @oldRecType
    
    	    	end	/* End trans type C or D */
    
			/*validation specific for deletes*/
			if @TransTypeLine = 'D'
				begin
				/*need to check to see if there are any transaction lines applied to the line we are trying to delete*/
				if exists (select top 1 1 from bARTH h with (nolock)
					join bARTL l with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
					where l.ARCo = @co and l.ApplyMth = @mth and l.ApplyTrans = @ARTrans 
						and (l.Mth <> l.ApplyMth or l.ARTrans <> l.ApplyTrans))
					begin
					select @errortext = @errorstart + ' - Transaction - ' + isnull(convert(varchar(40),@ARTrans),'') + 
						' - has other transactions applied to it that must first be removed. Cannot delete! '
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
				end

    		/* Begin GL update */
          	update_audit:  
          	select @i=1  --set first account
          	while @i<=2	 --4 Intercompany posting not required for Finance Charges
    			begin
        		select @i
            	/* spin through each type of GL account, check it and write GL Amount */
        		select @PostGLAcct = NULL
        		select @PostAmount= 0
        		select @oldPostGLAcct = NULL
        		select @oldPostAmount = 0
    			select @chksubtype = 'N'
    
        		/* AR FinanceChg Revenue/Income Acct (RecType - GLFinchgAcct) */ -- or JCDM - Open GL Acct if contract) */
        		if @i=1 select @PostGLCo= @Line_GLCo, @PostGLAcct=@RevAcct, 
    							@PostAmount = -(isnull(@Amount,0)),
        						@oldPostGLCo=@oldLine_GLCo, @oldPostGLAcct = @oldRevAcct, 
    							@oldPostAmount= (isnull(@oldAmount,0)), @errorAccount = 'AR FC Revenue Account'
    
                /* AR FinanceChg Receivables Account (RecType - GLARFCRecvAcct) */
            	if @i=2 
    				begin
    				select @PostGLCo=@RecTypeGLCo, @PostGLAcct=@GLARFCRecvAcct, 
    							@PostAmount=(isnull(@Amount,0)),
        						@oldPostGLCo= @oldRecTypeGLCo, @oldPostGLAcct=@oldGLARFCRecvAcct, 
    							@oldPostAmount=-(isnull(@oldAmount,0)), @errorAccount = 'AR FC Receivables Account'
    
    				/* Need to declare proper GLAcct SubType */
    				select @chksubtype = 'R'
    				end
    
   
    			/* As of 02/28/02, it has been determined that a customer should never interface
    			   Finance charges to JC.  Finance Charge Revenue is a collections issue and 
    			   should remain with the AR Company.  If it is determined otherwise, AR Invoice
   			   Entry should be reviewed and the CrossCompany code here should be similar. */
    
           	/* dont create GL if old and new are the same */
           	if @TransTypeLine='C' and @PostAmount=-@oldPostAmount and @PostGLCo=@oldPostGLCo 
    				and isnull(@PostGLAcct,'') = isnull(@oldPostGLAcct ,'')
        	  	goto skip_GLUpdate
   
        		/*********  This 1st Update/Insert relates to OLD values during Change and Delete Modes *********/
   
   			/* Issue #19161:  Update a record if GLAccts are the same.  Revenue and Receivable 
   			   would offset one another which may not be what the user wants but at least 
   			   it would be evident on the AR GL Distribution list and would not generate a 
   			   Posting duplicate key error. */
   		    if isnull(@oldPostAmount,0) <> 0 /* and @i < @InterCompany */ and @TransTypeLine <> 'A'
   		        begin
   		        update bARBA
   		        set Amount = Amount + @oldPostAmount
   		        where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and GLCo=@oldPostGLCo 
   					and GLAcct=@oldPostGLAcct and ARLine=@ARLine and OldNew = 0
   		        if @@rowcount=1 select @oldPostAmount=0 	/* set Amount to zero so we don't re-add the record*/
   		        end
    
    			/* For posting OLD values to all Accounts i=1 thru i=2 */			
        		if isnull(@oldPostAmount,0) <> 0 and @TransTypeLine <> 'A'
        			begin
           			exec @rcode = bspGLACfPostable @oldPostGLCo, @oldPostGLAcct,@chksubtype, @errmsg output
     	            if @rcode <> 0
    					begin
               	   	select @errortext = @errorstart + 'GLCo -: ' + convert(varchar(10),@oldPostGLCo) 
   							+ '- GL Account - ( '+ @errorAccount + '): ' + isnull(@oldPostGLAcct, '') + ': ' + @errmsg
                   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   	if @rcode <> 0 goto bspexit
                   	end
    				else
      		           	begin
         		       	insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine, ARTransType, Customer, SortName,
        				   		CustGroup, Invoice, Contract, ContractItem, ActDate, Description, Amount)
        		      	values(@co, @mth, @batchid, @oldPostGLCo, @oldPostGLAcct, @seq, 0, @ARTransHD, @ARLine, @ARTransTypeHD, @customer, @SortName,
        				   		@custgroup, @invoice, @Contract, @ContractItem, @transdate, @DescriptionHD, @oldPostAmount)
                	  	if @@rowcount = 0
                        	begin
                    	 	select @errmsg = 'Unable to add AR Detail audit - ' + isnull(@errmsg,''), @rcode = 1
                    	  	GoTo bspexit
                    	   	end

						/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
						if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @oldPostGLCo)
   							begin
   							insert bHQCC (Co, Mth, BatchId, GLCo)
   							values (@co, @mth, @batchid, @oldPostGLCo)
   							end
                    	end
                 	end
    
    			/*********  This 2nd Update/Insert relates to NEW values during Add and Change Modes *********/
    
   			/* Issue #19161:  Update a record if GLAccts are the same.  Revenue and Receivable 
   			   would offset one another which may not be what the user wants but at least 
   			   it would be evident on the AR GL Distribution list and would not generate a 
   			   Posting duplicate key error. */
   		    if isnull(@PostAmount,0) <> 0 /* and @i < @InterCompany */ and @TransTypeLine <> 'D'
   		        begin
   		        update bARBA
   		        set Amount=Amount + @PostAmount
   		        where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and GLCo=@PostGLCo 
   					and GLAcct=@PostGLAcct and ARLine=@ARLine and OldNew = 1
   		        if @@rowcount=1 select @PostAmount=0 	/* set Amount to zero so we don't re-add the record*/
   		        end
   
    			/* For posting NEW values to all Accounts i=1 thru i=2 */
        		if isnull(@PostAmount,0) <> 0 and @TransTypeLine <> 'D'
   
        			begin
              	   	exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, @chksubtype, @errmsg output
           	   	if @rcode <> 0
               		begin
               	   	select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') 
   									+ '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct, '') + ': ' + isnull(@errmsg,'')
                   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   	if @rcode <> 0 goto bspexit
                   	end
    				else
               			begin
        		       	insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine, ARTransType, Customer, SortName,
        						CustGroup, Invoice, Contract, ContractItem, ActDate, Description, Amount)
        		   	 	values(@co, @mth, @batchid, @PostGLCo, @PostGLAcct, @seq, 1, @ARTransHD, @ARLine, @ARTransTypeHD, @customer, @SortName,
        						@custgroup, @invoice, @Contract, @ContractItem, @transdate, @DescriptionHD, @PostAmount)
                	    if @@rowcount = 0
         	            	begin
                         	select @errmsg = 'Unable to add AR Detail audit 1 - ' + @errortext , @rcode = 1
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
     
            skip_GLUpdate:
    			/* get next GL record */
      			select @i=@i+1, @errmsg=''
    			END	 /* End Audit Update */
    
    		/* As of 02/28/02, it has been determined that a customer should never interface
    		   Finance charges to JC.  Finance Charge Revenue is a collections issue and 
    		   should remain with the AR Company.  If it is determined otherwise, the following
    		   code would need to be rewritten to comply more with what is happening in 
    		   AR Invoice Entry.  As is, it is flawed. */
    
          	/* JC Update = insert into bARBI */
          	--if @Amount=0 or @TransTypeLine = 'D' goto JCUpdate_Old
    
          	--if @JCCo is null and @Contract is null and @ContractItem is null goto JCUpdate_Old
          	--if @isContractFlag = 'Y' and @UpdateJC = 3
        	--	Begin
   			/* check JCCO */
   		-- 	if not exists(select 1 from bJCCO with (nolock) where JCCo=@JCCo)
   		-- 		begin
   		--  	select @errortext = @errorstart + '- JC Company -: ' + convert(char(3),@JCCo) +': is invalid'
   		--     	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		--     	if @rcode <> 0 goto bspexit
   		--  	end
    
   			/* check if Contract or Item is null */
        	--	if @Contract is null
   		--     	begin
   		--     	select @errortext = @errorstart + '- Contract -: may not be null'
   		--   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		--    	if @rcode <> 0 goto bspexit
   		--    	end
    
   		-- 	insert into bARBI(ARCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, ARTrans, Description, ActualDate,
        	--		Invoice, BilledAmt)
   		-- 	values (@co, @mth, @batchid, @JCCo, @Contract, @ContractItem, @seq, @ARLine, 1, @ARTransHD, @DescriptionHD, @transdate,
        	--		@invoice, @Amount)
    
        	--	if @@rowcount = 0
       	--		begin
       	--		select @errmsg = 'Unable to add AR Contract audit - ' + @errmsg, @rcode = 1
       	--		GoTo bspexit
       	--   	end
    
    		--JCUpdate_Old:
        		/* update old amounts to JC */
        	--	if @oldAmount=0  goto JCUpdate_End
          	--	if @oldJCCo is null and @oldContract is null and @oldItem is null goto JCUpdate_End
    
          		/* check JCCO */
        	--	if not exists(select 1 from bJCCO with (nolock) where JCCo=@oldJCCo)
        	--		begin
         	--     	select @errortext = @errorstart + '- JC Company -: ' + convert(char(3),@oldJCCo) +': is invalid'
        	--  	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   
        	--   	if @rcode <> 0 goto bspexit
         	--   	end
    
        		/* check if Contract or Item is null */
        	--	if @oldContract is null
         	--   	begin
        	--   	select @errortext = @errorstart + '- old Contract -: may not be null'
        	--    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        	--    	if @rcode <> 0 goto bspexit
        	--    	end
    
        	--	if @oldItem is null
   		--		begin
   		-- 	   	select @errortext = @errorstart + '- old Contract Item -: may not be null'
   		-- 	   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		--	   	if @rcode <> 0 goto bspexit
   		--	   	end
    
        	--	insert into bARBI(ARCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, ARTrans, BilledAmt,ActualDate)
        	--	values (@co, @mth, @batchid, @oldJCCo, @oldContract, @oldItem, @seq, @ARLine, 0, @ARTransHD, -@oldAmount,@transdate)
    
        	--	if @@rowcount = 0
   		--	  	begin
        	--  	select @errmsg = 'Unable to add AR Contract audit - ' + @errmsg, @rcode = 1
        	--   	GoTo bspexit
   		--	   	end
    
        	--JCUpdate_End:
    
        	--	End  --isContract loop
    
    		goto get_next_bcARBL
    		end   /* End ARBL Line Loop */
    
    		close bcARBL
    		deallocate bcARBL
    		select @opencursorARBL = 0
    
    	goto get_next_bcARBH
    	end   /* End ARBH Loop */
    
    	close bcARBH
    	deallocate bcARBH
    	select @opencursorARBH=0
    
   --check HQ Batch Errors and update HQ Batch Control status
   select @status = 3	--valid - ok to post
   if exists(select 1 from bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @status = 2	  --validation errors
    	end
    
   update bHQBC
   set Status = @status
   where Co = @co and Mth = @mth and BatchId = @batchid
    
   if @@rowcount <> 1
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    	goto bspexit
    	end
    
   bspexit:
    
   if @opencursorARBH = 1
    	begin
    	close bcARBH
    	deallocate bcARBH
    	end
    
   if @opencursorARBL = 1
   	begin
   	close bcARBL
   	deallocate bcARBL
   	end
    
   if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBH_FCVal]'
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspARBH_FCVal] TO [public]
GO
