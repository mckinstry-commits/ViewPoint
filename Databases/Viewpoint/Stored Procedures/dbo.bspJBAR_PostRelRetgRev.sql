SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBAR_PostRelRetgRev]
/***********************************************************
* CREATED BY  : TJL  04/17/03 Issue #20936, Reverse previous release retainage.
* MODIFIED By : TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 02/03/04 - Issue #23642, Insert Original TaxGroup, TaxCode from original invoice on 'R' and 'V' transactions
*		TJL  02/11/04 Issue #23750, Corrected @oldapplymth, @oldapplytrans not clear on new JBAL
*		TJL 02/24/04 - Issue #18917, Use orig invoice RecType for 'Release' transaction not new bills JBIN RecType
*		TJL 02/25/05 - Issue #27111, Remove TaxCode from Reversed 'Release' transaction and Reversed 'Released' Transaction
*		TJL 03/11/05 - Issue #27370, Improve on Negative Open Retainage, Release Retainage processing
*		TJL 09/11/08 - Issue #128370, JB Release International Sales Tax
*
*
* USAGE:  Called from bspJBAR_Post for every sequence in JBAR.
*         This bsp creates, updates or deletes ARTH records and associated lines in ARTL based on JBAR and JBAL
*		  and is intended to reverse the effects of previous release retainage.
*
*         If new retainage was created on this bill, then it has already been added to AR by bspJBAR_Post and will
*		  be ignored during this reversing action.
*
*
* INPUT PARAMETERS
*   JBCo        JB Co
*   Month       Bill Month
*   BatchId     Batch ID to validate
*   BatchSeq    Batch Sequence
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@jbco bCompany, @Mth bMonth, @BatchId bBatchID, @seq int, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @tablename char(20),  @item bContractItem, @arline int, @dist_amt bDollar, 
	@ARCurrentFlag bYN, @arco bCompany, @PostLine int, @PostLine2 int, @post_RelRetg bDollar,
	@totalrel_retg bDollar, @100_pct bYN, @oldapplymth bMonth, @oldapplytrans bTrans,
	@opencursorJBAL int, @opencursorJBAL10k int, @opencursorARTL_R1 int, @opencursorARTL_V int, @oppositeopenretgflag bYN,
   	@distamtstilloppositeflag bYN, @oppositerelretgflag bYN 
/* International Sales Tax */
declare @arcotaxretg bYN, @arcoseparateretgtax bYN, @posttaxoninv bYN, @relretgtax_amt bDollar, --@open_retgtax bDollar,
	@post_RelRetgTax bDollar, @dist_amttax bDollar, @line_relretgtax bDollar,  
	@newtaxgroup bGroup, @newtaxcode bTaxCode, @originvtaxgroup bGroup, @originvtaxcode bTaxCode,
	@Vtaxgroup bGroup, @Vtaxcode bTaxCode, @Vdate bDate, @line_reltaxamt bDollar, @Vtaxrate bRate

--declare @taxgroup bGroup, @taxcode bTaxCode 
    
/* Declarations to both JBAR and ARTH */
declare  @billnumber varchar(10), @retgtrans bTrans, @crTrans bTrans, @custgrp bGroup, @customer bCustomer, 
	@Source bSource, @contract bContract, @rectype int, @batchtranstype char(1), @revrelretgYN bYN

/* Declarations relative to both JBAL and ARTL */
declare @jbal_arline int, @retgline int, @crLine int, @relretg_amt bDollar, @glco bCompany,
	@applymth bMonth, @applytrans bTrans, @applyline int, @line_relretg bDollar, @line_relamt bDollar,
	@originvrectype tinyint, @contractitemamt bDollar
    
select @rcode=0, @Source = 'JB', @retgtrans = null, @crTrans = null, @tablename = 'bARTH',
	@opencursorJBAL = 0, @opencursorJBAL10k = 0, @opencursorARTL_R1 = 0, @opencursorARTL_V = 0

/* get the arco based on the jc company */
select @arco = c.ARCo, @ARCurrentFlag = a.RelRetainOpt, @posttaxoninv = a.InvoiceTax,
	@arcotaxretg = a.TaxRetg, @arcoseparateretgtax = a.SeparateRetgTax
from bJCCO c with (nolock)
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where c.JCCo = @jbco

/* retrieve values needed for further posting from JBAR & JBIN */
select @billnumber = r.BillNumber, @contract = r.Contract, @custgrp = r.CustGroup, @customer = r.Customer,
	@rectype = r.RecType, @batchtranstype = r.BatchTransType, @revrelretgYN = r.RevRelRetgYN,
	@retgtrans = n.ARRelRetgTran, @crTrans = n.ARRelRetgCrTran
from bJBAR r with (nolock)
join bJBIN n with (nolock) on n.JBCo = r.Co and n.BillMonth = r.Mth and n.BillNumber = r.BillNumber
where r.Co = @jbco and r.Mth = @Mth and r.BatchId = @BatchId and r.BatchSeq = @seq
    
/* clear out existing AR Retainage transaction lines for existing AR retainage transactions */
if @retgtrans is not null
	begin
	delete bARTL where ARCo = @arco and Mth = @Mth and ARTrans = @retgtrans
	delete bARTL where ARCo = @arco and Mth = @Mth and ARTrans = @crTrans
	end
    
/* if the bill is being deleted, clear out the ARTH records, if any exists, for release retainage. */
if @batchtranstype = 'D' goto program_end
    
/* add new retainage transactions into ARTH */
if @retgtrans is null and
	(select isnull(sum(RetgRel),0) from bJBAL with (nolock) where Co=@jbco and Mth=@Mth and BatchId=@BatchId and BatchSeq=@seq and ARLine < 10000) <> 0
	begin
   	select @retgtrans = 0, @crTrans = 0
    
   	/* get next available transaction # for ARTH */
   	exec @retgtrans = bspHQTCNextTrans @tablename, @arco, @Mth, @errmsg output
   	if @retgtrans = 0 goto bspexit
    
   	exec @crTrans = bspHQTCNextTrans @tablename, @arco, @Mth, @errmsg output
   	if @crTrans = 0 goto bspexit
    
   	/* insert ARTH record - First 'R', applied to many earlier transactions */
   	insert into bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, JCCo, Contract, Invoice, Description, Source, TransDate, DueDate,
   		CreditAmt, Invoiced, Paid, Retainage, DiscTaken, AmountDue, AppliedMth, AppliedTrans, PurgeFlag, EditTrans, BatchId)
   	select @arco, Mth, @retgtrans, 'R', CustGroup, Customer, NULL, Co, Contract, NULL, 'Reverse Release Retainage', @Source, TransDate, NULL,
   		0, 0, 0, 0, 0, 0, NULL, NULL, 'N','N', BatchId
   	from bJBAR with (nolock)
   	where Co = @jbco and Mth = @Mth and BatchId = @BatchId and BatchSeq=@seq
   	if @@rowcount = 0 goto bspexit
    
   	/* insert the ARTH record - Second 'V', applied to many earlier 'Released' transactions only */
   	insert into bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, JCCo, Contract, Invoice, Description, Source, TransDate, DueDate,
   		CreditAmt, Invoiced, Paid, Retainage, DiscTaken, AmountDue, AppliedMth, AppliedTrans, PurgeFlag, EditTrans, BatchId)
   	select @arco, @Mth, @crTrans, 'V', CustGroup, Customer, NULL, Co, Contract, NULL, 'Reverse Released Retainage', @Source, TransDate, NULL,
   		0, 0, 0, 0, 0, 0, NULL, NULL, 'N','N', BatchId
   	from bJBAR with (nolock)
   	where Co = @jbco and Mth = @Mth and BatchId = @BatchId and BatchSeq=@seq
   	if @@rowcount = 0 goto bspexit
    
   	/* set the JBIN columns to the new transaction values */
   	update bJBIN
   	set ARRelRetgTran = @retgtrans, ARRelRetgCrTran = @crTrans
   	where JBCo = @jbco and BillMonth = @Mth and BillNumber = @billnumber
   	end  -- end of ARTH insert section
    
/* JBAL <10000 posting loop */
/* RetgRel is stored as a negative number in JBAL under normal release conditions. */
declare bcJBAL cursor local fast_forward for
select l.Item, l.ARLine, l.RetgRel, l.RetgTaxRel, l.GLCo, i.ContractAmt
from bJBAL l with (nolock)
join bJCCI i with (nolock) on i.JCCo = l.Co and i.Contract = @contract and i.Item = l.Item
where l.Co = @jbco and l.Mth = @Mth and l.BatchId=@BatchId and l.BatchSeq=@seq and l.ARLine < 10000 
	and (l.RetgRel <> 0)	--Do not care about oldRetgRel during posting. Old info was deleted above and we are starting over
    
/* open cursor for line */
open bcJBAL
select @opencursorJBAL = 1
    
/**** read JBAL records ****/
get_next_bcJBAL:
fetch next from bcJBAL into @item, @jbal_arline, @relretg_amt, @relretgtax_amt, @glco, @contractitemamt
while (@@fetch_status = 0)
   	begin	/* Begin JBAL <10000 Item Loop */
   	/* Reset temporary variables */
   	select @100_pct = 'N', @dist_amt = 0, @dist_amttax = 0, @distamtstilloppositeflag = 'N'
	select @oldapplymth = '01-01-1950', @oldapplytrans = 0	
    
   	/* Calculate the total Release retainage for this Item in AR that has 
   	   been previously released. */
   	select @totalrel_retg = isnull(sum(l.Retainage),0)			-- Typically (but not always) we want the neg values
   	from bARTH h with (nolock)
   	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
   		and l.JCCo = @jbco and l.Contract = @contract and l.Item = @item	-- for this contract/item
   	where h.ARCo = @arco and h.CustGroup = @custgrp and h.Customer = @customer	
   		and (h.Mth < @Mth or (h.Mth = @Mth and h.ARTrans < @retgtrans))		-- Prior to this Release trans
   		and h.ARTransType = 'R'												-- Release values only (typically -)
   		and (l.Mth <> l.ApplyMth or l.ARTrans <> l.ApplyTrans)				-- No Released values (typically +)
    
   	if @totalrel_retg = -@relretg_amt	--if Neg = -Pos
   		begin
   		select @100_pct = 'Y'			-- By Item
   		end
    
	/* Process a reversal for this item but only if there is actually some
	   release retainage to reverse for this item. */
	if @totalrel_retg <> 0
		begin	/* Begin Reversing Loop */
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
		   The 'Group by' clause will combine these into one cursor record for less redundancy.  However (though
		   unlikely) if somehow a redundant ApplyMth, ApplyTrans, ApplyLine slips by, it will be processed only
		   once.  The second occurance will be ignored.
	   	
		   It is possible that the invoice line being released upon for this Item is not the same for all invoices
		   relative to this Item.  Each invoice will contain only a single Line per Item.  Evaluation is done per
		   each invoice (ApplyMth, ApplyTrans) separately.  Therefore the code below may use Item or Line 
		   interchangeably.
   	
   		   For each ContractItem, this cursor below brings in a list of all 1st 'R' Release transactions (both normal
   		   release and reverse release).  This gives us (though multiple times) all possible invoices that have been
   		   Released upon (or Reversed) relative to this ContractItem.  We use the ApplyMth, ApplyTrans values to get
   		   a Total of the Retainage having been released (Retg released + Retg released reversed = Actual Retg released
   		   that can still be reversed).  Because we are bringing back multiple values for the same ApplyMth, ApplyTrans,
   		   ApplyLine, we attempt to minimize this by the 'Group By' clause.  */
    	declare bcARTL_R1 scroll cursor for
    	select l.ApplyMth, l.ApplyTrans, l.ApplyLine, l.TaxGroup, l.TaxCode
    	from bARTH h with (nolock)
    	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
                    l.JCCo = @jbco and l.Contract = @contract and l.Item = @item	-- This contract/Item only
    	where h.ARCo = @arco and h.CustGroup = @custgrp and h.Customer = @customer
			and (h.Mth < @Mth or (h.Mth = @Mth and h.ARTrans < @retgtrans)) 	-- Prior to this Release trans
			and h.ARTransType = 'R'												-- Release values only
			and (l.Mth <> l.ApplyMth or l.ARTrans <> l.ApplyTrans)				-- No Released values
			--and ((l.Retainage < 0 and @relretg_amt > 0)  		-- Neg item, Pos release trans only, ignore prev reversals
			--	or (l.Retainage > 0 and @relretg_amt < 0))		-- Pos item, Neg release trans only, ignore prev reversals
																-- Prev reversals get considered next.
   		group by l.ApplyMth, l.ApplyTrans, l.ApplyLine, l.TaxGroup, l.TaxCode			-- Minimize redundant cursor records.
		order by l.ApplyMth, l.ApplyTrans, l.ApplyLine			-- To assure correct reversing order.
    
    	/* open cursor for line */
    	open bcARTL_R1
    	select @opencursorARTL_R1 = 1
    
    	/**** read cursor lines ****/
    	fetch last from bcARTL_R1 into @applymth, @applytrans, @applyline, @originvtaxgroup, @originvtaxcode
    	while (@@fetch_status = 0)
    		begin	/* Begin R1 Loop */
      		select @post_RelRetg = 0, @post_RelRetgTax = 0, @line_relretg = 0, @line_relretgtax = 0, @oppositerelretgflag = 'N'
    			
			/* If already dealt with, move on. */
			if isnull(@oldapplymth, '01-01-1950') = @applymth and isnull(@oldapplytrans, 0) = @applytrans goto get_prior_bcARTL_R1
    
   			/* Get amount that has previously been released on this 'Release' bill for this contact/Item.
   			   (This combines/includes all previous Release amts and previous reversal amts for a total still
   			    available to be reversed.) 
   			   This is the amount that will be reversed.  This value DOES NOT INCLUDE A REVERSING AMOUNT
   			   ON THIS CURRENT BILL IF IT HAS PREVIOUSLY BEEN INTERFACED. */
	    	select @line_relretg = sum(l.Retainage), @line_relretgtax = sum(l.RetgTax)		-- Neg
	    	from bARTH h with (nolock)
	    	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
				l.JCCo = @jbco and l.Contract = @contract and l.Item = @item	-- This contract/Item only 
	    	where h.ARCo = @arco and h.CustGroup = @custgrp and h.Customer = @customer
				and (h.Mth < @Mth or (h.Mth = @Mth and h.ARTrans < @retgtrans)) 	-- Prior to this Release trans
				and h.ARTransType = 'R'												-- Release values only, including reversals
				and (l.Mth <> l.ApplyMth or l.ARTrans <> l.ApplyTrans)				-- No Released Values
				and l.ApplyMth = @applymth and l.ApplyTrans = @applytrans			-- starting with Latest Month and Trans		
																					-- @applyline not needed due to @item above
			/* If there is nothing to reverse, move to previous. */
      		if @line_relretg = 0 
				begin
				select @oldapplymth = @applymth, @oldapplytrans = @applytrans
				goto get_prior_bcARTL_R1
				end
    
			/* Get some info from original transaction line to be inserted with this applyline.
		   These are not part of the cursor (probably could be) because, quite frankly, at this point 
		   in time I have so much going on in my head that getting this info separately helps me keep
		   things straight.
			    In this case:
				1) If TaxCode is changed on an interfaced bill for the Contract/Item then TaxGroup
				   must be present on all related applied transactions.  TaxCode is optional. 
			   These values have no effect on GL and are inserted to avoid problems during
			       another operation. (This cannot be done during validation.)
			2) RecType must represent the RecType of the original transaction that the release
			   is occuring against. GL is affected and has been dealt with in validation. */
			select @originvrectype = RecType					--, @taxgroup = TaxGroup, @taxcode = TaxCode
			from bARTL with (nolock)
			where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans and ARLine = @applyline
    		
    			/* We now have Release transactions applied against an invoice that have not already
    			   been completely reversed.  Proceed. */
   			if @100_pct = 'Y'
   				begin
   				/* Evaluation not required, go directly to Post Routine */
   				select @post_RelRetg = -@line_relretg				-- Pos = -Neg
				select @post_RelRetgTax = -@line_relretgtax			
   				goto Post_R1
   				end
   			else
   				begin
   				/* Some form of Evaluation and PostAmount determination required */
   				if (-@line_relretg < 0 and @contractitemamt > 0) or (-@line_relretg > 0 and @contractitemamt < 0)
   					begin
   					/* Somehow the 1st 'R'elease transaction went abnormally negative/opposite relative to the invoice
   					   that it applies against. (Perhaps because the original retainage value went negative/opposite due
   					   to excessive credits or just negative retainage.  This would cause a Release Retg transaction
   					   to be negative/opposite as well.) Post full amount to compensate. */
   					select @oppositerelretgflag = 'Y'
   					select @post_RelRetg = -@line_relretg
					select @post_RelRetgTax = -@line_relretgtax
   					--goto Post_R1
   					end
   				else
   					begin
   					/* This is normal Postive (or normal Negative) release retainage to be reopened.  Distribute accordingly */
   					if @distamtstilloppositeflag = 'N'
   						begin
   			       		if abs(@dist_amt + (-@line_relretg)) <= abs(@relretg_amt)	-- abs(Pos + (-Neg)) <= abs(Pos)
   							begin
   			         		select @post_RelRetg = -@line_relretg					-- Pos = -Neg
							select @post_RelRetgTax = -@line_relretgtax
   							end
   			        	else
   							begin
   			             	select @post_RelRetg = @relretg_amt - @dist_amt			-- Pos = Pos - Pos
							select @post_RelRetgTax = @relretgtax_amt - @dist_amttax
   							end
   						end
   					else
   						begin
   						if ((@dist_amt + (-@line_relretg)) < 0 and @relretg_amt > 0) or ((@dist_amt + (-@line_relretg)) > 0 and @relretg_amt < 0)
   							begin
   							/* Because of Negative/Opposite polarity release retg values along the way the distributed amount has 
   							   gone negative, leaving us with more to distribute than we originally began with.  When combined with
   							   this invoice lines release retg for this item, we are still left with more than we began with.  Therefore
   							   it is OK to reverse the full amount on this Line/Item and move on. There is no need for specific
   							   evaluation since we are not in jeopardy of reversing more than we have. */
   							select @post_RelRetg = -@line_relretg
							select @post_RelRetgTax = -@line_relretgtax
   							end
   						else
   							begin
   							/* Combined amounts swing in the correct direction, continue with normal evaluation process */
   				       		if abs(@dist_amt + (-@line_relretg)) <= abs(@relretg_amt)	-- abs(Pos + (-Neg)) <= abs(Pos)
   								begin
   				         		select @post_RelRetg = -@line_relretg					-- Pos = -Neg
								select @post_RelRetgTax = -@line_relretgtax
   								end
   				        	else
   								begin
   				             	select @post_RelRetg = @relretg_amt - @dist_amt			-- Pos = Pos - Pos
								select @post_RelRetgTax = @relretgtax_amt - @dist_amttax
   								end
   							end
   						end
   					--goto Post_R1
   					end
   				end
    
   		Post_R1:
      		if @post_RelRetg <> 0
        		begin	/* Begin ARTL insert loop for R1 */
    
    			/* get next available line number for this transaction */
        		select @PostLine = isnull(max(ARLine),0) + 1
        		from bARTL with (nolock)
        		where ARCo = @arco and Mth = @Mth and ARTrans = @retgtrans
    
        		/* apply released retainage line against the line where the retainage resides */
        		insert into bARTL(ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
          			TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct,
  	     			Retainage, RetgTax, DiscOffered, DiscTaken, JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
        		values(@arco, @Mth, @retgtrans, @PostLine, @originvrectype, 'R', 'Reverse Release Retainage', @glco, null,
            		@originvtaxgroup, @originvtaxcode, @post_RelRetg, 0, 0, 0,
  	           		@post_RelRetg, @post_RelRetgTax, 0, 0, @jbco, @contract, @item, @applymth, @applytrans, @applyline)
 
    			select @dist_amt = @dist_amt + @post_RelRetg
				select @dist_amttax = @dist_amttax + @post_RelRetgTax
   
   				if (@dist_amt < 0 and @relretg_amt > 0) or (@dist_amt > 0 and @relretg_amt < 0)
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

   				if @100_pct = 'Y'
   					begin
   					/* We are reversing full amount for this Item/Line on all invoices in list. Just keep going. */
   					goto get_prior_bcARTL_R1
   					end
   				else
   					begin
   					if @oppositerelretgflag = 'Y'
   						begin
   						/* No evaluation necessary, we have more to Reverse than we began with */
   						select @oppositerelretgflag = 'N'
   						goto get_prior_bcARTL_R1
   						end
   					else
   						begin
   						if @distamtstilloppositeflag = 'Y'
   							begin
   							/* We still have more money reserved to reverse than we originally began with.
   							   No need for comparisons. Just get next Invoice for this Line/Item. */
   							goto get_prior_bcARTL_R1
   							end
   						else
   							begin
   							/* Conditions are relatively normal at this point.  We are not (or no longer) dealing with 
   							   negative/opposite RelRetg on this invoice nor is our overall distribution amount
   							   negative/opposite at this stage of the distribution process.  Therefore we must now continue
   							   to compare values to assure that we distribute/reverse no more than was intended.   */
   			 				if abs(@dist_amt) < abs(@relretg_amt) 
   			 					begin
   			 					select @oldapplymth = @applymth, @oldapplytrans = @applytrans
   			 					goto get_prior_bcARTL_R1 
   			 					end
   			 				else 
   			 					begin
   			 					close bcARTL_R1
   			 					deallocate bcARTL_R1
   			 					select @opencursorARTL_R1 = 0, @dist_amt = 0, @distamtstilloppositeflag = 'N' 
   			 					goto get_next_bcJBAL
   			 					end
   							end
   						end
   					end
     			end		/* End ARTL insert loop for R1 */
    
			select @oldapplymth = @applymth, @oldapplytrans = @applytrans
		get_prior_bcARTL_R1:
			fetch prior	from bcARTL_R1 into @applymth, @applytrans, @applyline, @originvtaxgroup, @originvtaxcode
        	end  /* End R1 Loop */

	ARTL_R1loop_end:
		if @opencursorARTL_R1 = 1
			begin
			close bcARTL_R1
			deallocate bcARTL_R1
			select @opencursorARTL_R1 = 0
			end
		end

 	goto get_next_bcJBAL
	end /* End JBAL <10000 Item Loop */
    
close bcJBAL
deallocate bcJBAL
select @opencursorJBAL = 0

/* JBAL =10000 posting loop */
/* RetgRel is stored as a negative number in JBAL under normal release conditions. */
declare bcJBAL10k cursor local fast_forward for
select l.Item, l.ARLine, l.RetgRel, l.RetgTaxRel, l.GLCo, i.ContractAmt
from bJBAL l with (nolock)
join bJCCI i with (nolock) on i.JCCo = l.Co and i.Contract = @contract and i.Item = l.Item
where l.Co = @jbco and l.Mth = @Mth and l.BatchId=@BatchId and l.BatchSeq=@seq and l.ARLine = 10000 
	and (l.RetgRel <> 0)	--Do not care about oldRetgRel during posting. Old info was deleted above and we are starting over
    
/* open cursor for line */
open bcJBAL10k
select @opencursorJBAL10k = 1
    
/**** read JBAL records ****/
get_next_bcJBAL10k:
fetch next from bcJBAL10k into @item, @jbal_arline, @relretg_amt, @relretgtax_amt, @glco, @contractitemamt
while (@@fetch_status = 0)
   	begin	/* Begin JBAL <10000 Item Loop */
   	select @100_pct = 'N', @dist_amt = 0, @dist_amttax = 0, @distamtstilloppositeflag = 'N'

   	/* Calculate the total Release retainage for this Item in AR that has 
   	   been previously released. */
   	select @totalrel_retg = isnull(sum(l.Amount),0)					-- Max reversable for this Item.
   	from bARTH h with (nolock)
   	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
   		and l.JCCo = @jbco and l.Contract = @contract and l.Item = @item	-- for this contract/item
   	where h.ARCo = @arco and h.CustGroup = @custgrp and h.Customer = @customer	
   		and (h.Mth < @Mth or (h.Mth = @Mth and h.ARTrans < @crTrans))		-- Prior to this Released trans
   		and h.ARTransType in ('R', 'V')										-- Released (2nd R) values only (typically + (R), - (V))
   		and (l.Mth = l.ApplyMth and l.ARTrans = l.ApplyTrans)				-- No Release (1st R) values (typically -)
    
   	if @totalrel_retg = -@relretg_amt	--if Pos = -Neg
   		begin
   		select @100_pct = 'Y'			-- By Item
   		end

	if @totalrel_retg <> 0
		begin	/* Begin Reversing Loop */
	V_Loop:
		declare bcARTL_V scroll cursor for
		select l.ApplyMth, l.ApplyTrans, l.ApplyLine, l.RecType, l.TaxGroup, l.TaxCode, h.TransDate
		from bARTH h with (nolock)
		join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
					l.JCCo = @jbco and l.Contract = @contract and l.Item = @item	-- This contract/Item only
		where h.ARCo = @arco and h.CustGroup = @custgrp and h.Customer = @customer
			and (h.Mth < @Mth or (h.Mth = @Mth and h.ARTrans < @crTrans)) 		-- Prior to this Release trans
			and h.ARTransType = 'R'												-- Released values only
			and (l.Mth = l.ApplyMth and l.ARTrans = l.ApplyTrans)				-- These are original 'R' type invoices
		order by l.ApplyMth, l.ApplyTrans, l.ApplyLine
	    
		/* open cursor for line */
		open bcARTL_V
		select @opencursorARTL_V = 1

		/**** read cursor lines ****/
		fetch last from bcARTL_V into @applymth, @applytrans, @applyline, @originvrectype, @Vtaxgroup, @Vtaxcode, @Vdate
		while (@@fetch_status = 0)
			begin	/* Begin V Loop */
  			select @post_RelRetg = 0, @post_RelRetgTax = 0, @line_relamt = 0, @line_reltaxamt = 0, @oppositerelretgflag = 'N'

			/* For each Original 'R' transaction (relative to this contract item) we will
			   get the sum of its Line Amounts.  THIS WILL INCLUDE any payments, credits or reversals
			   relative to this new AR (Released) invoice transaction created when Retainage was released. 

			   We have already restricted this cursor to the desired 2nd 'R' (Released) type transactions
			   above. 

			   We only want to reverse an amount for the line that has not previously been reversed
			   by another means. (ie: by Payment, credit, writeoff or reversal). EARLIER VALIDATION HAS PREVENTED us from
			   reversing too much overall (on all AR Released invoices) for this Item.  This prevents reversing too much 
			   on this invoice line relative to this item.  */
			select @line_relamt = isnull(sum(Amount), 0),	-- Pos, 2nd 'R' Released Invoice Amount remaining after credits for this Item
				@line_reltaxamt = case when @ARCurrentFlag = 'Y' then isnull(sum(TaxAmount), 0) else isnull(sum(RetgTax), 0) end
			from bARTL with (nolock)
			where ARCo = @arco and ApplyMth = @applymth and ApplyTrans = @applytrans
				and ApplyLine = @applyline									-- Sum this 2nd 'R' Released transaction
				and (Mth < @Mth or (Mth = @Mth and ARTrans < @crTrans))		-- exclude 'Reversing Amounts' this bill
																				-- in 'C' mode or future bills
			/* Skip if there is no Released Retg to be Reversed. */ 
  			if @line_relamt = 0 goto get_prior_bcARTL_V
	 
				/* Begin processing Reverse amounts against the Released transactions. */
			if @100_pct = 'Y'
				begin
				/* Evaluation not required, go directly to Post Routine */
				select @post_RelRetg = @line_relamt				--Pos = Pos
				select @post_RelRetgTax = @line_reltaxamt
				goto Post_V
				end
			else
				begin
				/* Some form of Evaluation and PostAmount determination required */
				if (@line_relamt < 0 and @contractitemamt > 0) or (@line_relamt > 0 and @contractitemamt < 0)
					begin
					/* Somehow the 2nd 'R'eleased invoice that got generated went abnormally negative. (I do not believe
					   this can happen but just in case ....) Post full amount to compensate. */
					select @oppositerelretgflag = 'Y'
					select @post_RelRetg = @line_relamt			--Pos = Pos
					select @post_RelRetgTax = @line_reltaxamt
					--goto Post_V
					end
				else
					begin
					/* This is normal Postive (or normal Negative) release retainage to be reopened.  Distribute accordingly */
					if @distamtstilloppositeflag = 'N'
						begin
		       			if abs(@dist_amt + @line_relamt) <= abs(@relretg_amt)	-- abs(Pos + Pos) <= abs(Neg)
							begin
		         			select @post_RelRetg = @line_relamt					-- Pos = Pos	
							select @post_RelRetgTax = @line_reltaxamt
							end
		        		else
							begin
		             		select @post_RelRetg = -@relretg_amt - @dist_amt		-- Pos = -Neg - Pos		
							select @post_RelRetgTax = -@relretgtax_amt - @dist_amttax	
							end				
						end
					else
						begin
						if ((@dist_amt + @line_relamt) < 0 and -@relretg_amt > 0) or ((@dist_amt + @line_relamt) > 0 and -@relretg_amt < 0)
							begin
							/* Because of Negative/Opposite polarity release retg values along the way the distributed amount has 
							   gone negative, leaving us with more to distribute than we originally began with.  When combined with
							   this invoice lines release retg for this item, we are still left with more than we began with.  Therefore
							   it is OK to reverse the full amount on this Line/Item and move on. There is no need for specific
							   evaluation since we are not in jeopardy of reversing more than we have. */
		         			select @post_RelRetg = @line_relamt					-- Pos = Pos	
							select @post_RelRetgTax = @line_reltaxamt
							end
						else
							begin
							/* Combined amounts swing in the correct direction, continue with normal evaluation process */
			       			if abs(@dist_amt + @line_relamt) <= abs(@relretg_amt)	-- abs(Pos + Pos) <= abs(Neg)
								begin
		         				select @post_RelRetg = @line_relamt				-- Pos = Pos	
								select @post_RelRetgTax = @line_reltaxamt	
								end
			        		else
								begin
		             			select @post_RelRetg = -@relretg_amt - @dist_amt		-- Pos = -Neg - Pos		
								select @post_RelRetgTax = -@relretgtax_amt - @dist_amttax	
								end
							end
						end
					--goto Post_V
					end
				end

		Post_V:
  			if @post_RelRetg <> 0
    			begin	/* Begin ARTL insert loop for V */
				/* Depending on the Amount reversed, it is possible that the cursor contains multiple 
				   ARTL records with the same ApplyMth, ApplyTrans and ApplyLine.  Therefore update
				   if the record already exists.  Otherwise do an insert. */
				update bARTL
				set Amount = Amount + (-@post_RelRetg), 
					TaxBasis = case when @posttaxoninv = 'N' or (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N') then 0 
						else case when @ARCurrentFlag = 'Y'  and @post_RelRetgTax <> 0 then TaxBasis + (-(@post_RelRetg - @post_RelRetgTax)) else TaxBasis + 0 end end,
					TaxAmount = case @ARCurrentFlag when 'Y' then TaxAmount + (-@post_RelRetgTax) else 0 end, 
					Retainage = case @ARCurrentFlag when 'Y' then 0 else Retainage + (-@post_RelRetg) end,
					RetgTax = case @ARCurrentFlag when 'Y' then 0 else RetgTax + (-@post_RelRetgTax) end
				where ARCo = @arco and Mth = @Mth and ARTrans = @crTrans
					and ApplyMth = @applymth and ApplyTrans = @applytrans and ApplyLine = @applyline
				if @@rowcount = 0
					begin
    				/* get next available line number for this transaction */
        			select @PostLine2 = isnull(max(ARLine),0) + 1
        			from bARTL with (nolock)
        			where ARCo = @arco and Mth = @Mth and ARTrans = @crTrans

        			/* apply released retainage line against the line where the retainage resides */
        			insert into bARTL(ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
          				TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct,
  	     				Retainage, RetgTax,
						DiscOffered, DiscTaken, JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
        			values(@arco, @Mth, @crTrans, @PostLine2, @originvrectype, 'V', 'Reverse Released Retainage', @glco, null,
            			@Vtaxgroup, @Vtaxcode, -@post_RelRetg, 
						case when @posttaxoninv = 'N' or (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N') then 0 
							else case when @ARCurrentFlag = 'Y' and @post_RelRetgTax <> 0 then -(@post_RelRetg - @post_RelRetgTax) else 0 end end, 
						case @ARCurrentFlag when 'Y' then -@post_RelRetgTax else 0 end, 
						0,
  	           			case @ARCurrentFlag when 'Y' then 0 else -@post_RelRetg end, 
						case @ARCurrentFlag when 'Y' then 0 else -@post_RelRetgTax end,
						0, 0, @jbco, @contract, @item, @applymth, @applytrans, @applyline)
					end
			
				select @dist_amt = @dist_amt + @post_RelRetg
				select @dist_amttax = @dist_amttax + @post_RelRetgTax
	    
				if (@dist_amt < 0 and -@relretg_amt > 0) or (@dist_amt > 0 and -@relretg_amt < 0)
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
		 					if abs(@dist_amt) < abs(@relretg_amt)		-- abs(Pos) < abs(Neg)
		 						begin
		 						goto get_prior_bcARTL_V 
		 						end
		 					else 
		 						begin
		 						close bcARTL_V
		 						deallocate bcARTL_V
		 						select @opencursorARTL_V = 0, @dist_amt = 0, @distamtstilloppositeflag = 'N'
		 						goto get_next_bcJBAL10k
		 						end
							end
						end
					end
				end		/* End ARTL insert loop for V */
	    
		get_prior_bcARTL_V:
			fetch prior from bcARTL_V into @applymth, @applytrans, @applyline, @originvrectype, @Vtaxgroup, @Vtaxcode, @Vdate
			end		/* End V Loop */
	    
	ARTL_loop_end:
		if @opencursorARTL_V = 1
			begin
			close bcARTL_V
			deallocate bcARTL_V
			select @opencursorARTL_V = 0
			end
		end

	goto get_next_bcJBAL10k
	end /* End JBAL Item Loop */
    
close bcJBAL10k
deallocate bcJBAL10k
select @opencursorJBAL10k = 0

/*we need to update transaction number to other batch tables that need it*/
/*GL*/
update bJBGL
set ARTrans = @retgtrans
where JBCo = @jbco and Mth = @Mth and BatchId = @BatchId and BatchSeq = @seq and
	Item = @item and JBTransType = 'R'

/*Job*/
update bJBJC
set ARTrans = @retgtrans
where JBCo = @jbco and Mth = @Mth and BatchId = @BatchId and BatchSeq = @seq and
	Item = @item and JBTransType = 'R'
    
program_end:
if not exists (select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @Mth and ARTrans = @retgtrans)
   	begin
	delete bARTH where ARCo = @arco and Mth = @Mth and ARTrans = @retgtrans
	update bJBIN
	set ARRelRetgTran = null
	where JBCo = @jbco and BillMonth = @Mth and BillNumber = @billnumber

	delete bARTH where ARCo = @arco and Mth = @Mth and ARTrans = @crTrans
	update bJBIN
	set ARRelRetgCrTran = null
	where JBCo = @jbco and BillMonth = @Mth and BillNumber = @billnumber
	end
    
bspexit:
    
if @opencursorJBAL = 1
	begin
	close bcJBAL
	deallocate bcJBAL
	end

if @opencursorARTL_R1 = 1
	begin
	close bcARTL_R1
	deallocate bcARTL_R1
	end

if @opencursorARTL_V = 1
	begin
	close bcARTL_V
	deallocate bcARTL_V
	end

if @opencursorJBAL10k = 1
	begin
	close bcJBAL10k
	deallocate bcJBAL10k
	end
    
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBAR_PostRelRetgRev] TO [public]
GO
