SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBAR_PostRelRetg]
/***********************************************************
* CREATED BY  : bc 02/22/00
* MODIFIED By : bc 10/19/00 - take care of negative retainage
*   		TJL 09/27/01 - Issue #13104, Post GLCo to ARTL
*                		Remove Invoice for Release Trans, since there may be multiple
*                   		Remove AppliedMth, AppliedTrans for Release Trans, since there may be multiple
*    	TJL 10/02/01 - Issue #14776, related to Issue #13931, Set bARTH.PurgeFlag = 'N' rather than 'Y'
*		TJL 05/01/03 - Issue #20936, Reverse Release Retg,  Set DueDate NULL in ARTH for Release 'R' only
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 02/02/04 - Issue #23611, Insert correct GLCo and GLRevAccount on the Released Retainage Invoice.
*		TJL 02/03/04 - Issue #23642, Insert Original TaxGroup, TaxCode from original invoice on 'R'elease transactions
*		TJL 02/24/04 - Issue #18917, Use orig invoice RecType for 'Release' transaction not new bills JBIN RecType
*		TJL 09/14/04 - Issue #25518, Loosen 'Not enough Retainage in AR' validation
*		TJL 02/25/05 - Issue #27111, Remove TaxCode from 'Release' transaction
*		TJL 03/11/05 - Issue #27370, Improve on Negative Open Retainage, Release Retainage processing
*		TJL 06/21/05 - Issue #29041, Fix/Allow over releasing retg on Item when 0.00 Item open retg exists.
*		TJL 01/07/08 - Issue #120443, Post JBIN Notes and JBIT Notes to Released (2nd R or Credit Invoice) in ARTH, ARTL
*		TJL 09/11/08 - Issue #128370, JB Release International Sales Tax
*
*
* USAGE:  called from bspJBAR_Post for every sequence in JBAR,
*         this bsp creates, updates or deletes ARTH records and associated lines in ARTL based on JBAR and JBAL.
*
*         if new retainage was created on this bill, then it has already been added to AR by bspJBAR_Post and can
*         potentially be released immediately.
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
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@jbco bCompany, @Mth bMonth, @BatchId bBatchID, @seq int, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @tablename char(20), @billnumber varchar(10), @item bContractItem, @arline int

declare @artrans bTrans, @retgtrans bTrans, @crTrans bTrans, @jbal_arline int, @retgline int, @crLine int,
   	@ARCurrentFlag bYN, @arco bCompany, @armth bMonth, @custgrp bGroup, @customer bCustomer, @opencursorJBAL int,
   	@Source bSource, @contract bContract, @rectype int, @batchtranstype char(1), @relretg_amt bDollar,
   	@PostLine int, @PostLine2 int, @inserted bYN, @totalaropen_retg bDollar, @100_pct bYN,
   	@originvtaxgroup bGroup, @originvtaxcode bTaxCode, @originvrectype tinyint, @postlastline int, @contractitemamt bDollar,
   	@oppositeopenretgflag bYN, @distamtstilloppositeflag bYN, @armthsave bMonth, @artranssave bTrans, @arlinesave int	
/* International Sales Tax */
declare @arcotaxretg bYN, @arcoseparateretgtax bYN, @posttaxoninv bYN, @relretgtax_amt bDollar, @open_retgtax bDollar,
	@post_RelRetgTax bDollar, @dist_amttax bDollar

declare @opencursorARTL int, @open_retg bDollar, @dist_amt bDollar, @post_RelRetg bDollar

select @rcode=0, @Source = 'JB', @retgtrans = null, @crTrans = null, @tablename = 'bARTH'

/* get the arco based on the jc company */
select @arco = c.ARCo, @ARCurrentFlag = a.RelRetainOpt, @posttaxoninv = a.InvoiceTax,
	@arcotaxretg = a.TaxRetg, @arcoseparateretgtax = a.SeparateRetgTax
from bJCCO c with (nolock)
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where c.JCCo = @jbco

/* retrieve values needed for further posting from JBAR & JBIN */
select @billnumber = r.BillNumber, @contract = r.Contract, @custgrp = r.CustGroup, @customer = r.Customer,
	@rectype = r.RecType, @batchtranstype = r.BatchTransType,
	@retgtrans = n.ARRelRetgTran, @crTrans = n.ARRelRetgCrTran
from bJBAR r with (nolock)
join bJBIN n with (nolock) on n.JBCo = r.Co and n.BillMonth = r.Mth and n.BillNumber = r.BillNumber
where r.Co = @jbco and r.Mth = @Mth and r.BatchId = @BatchId and r.BatchSeq = @seq
   
/* Clear out existing AR Retainage transaction lines for existing AR retainage transactions */
if @retgtrans is not null
   	begin
   	delete bARTL where ARCo = @arco and Mth = @Mth and ARTrans = @retgtrans
   	delete bARTL where ARCo = @arco and Mth = @Mth and ARTrans = @crTrans
   	end
    
if @batchtranstype = 'D' goto program_end
    
/* Add new retainage transactions into ARTH */
if @retgtrans is null and
	(select isnull(sum(RetgRel),0) from bJBAL with (nolock) where Co=@jbco and Mth=@Mth and BatchId=@BatchId and BatchSeq=@seq and ARLine < 10000) <> 0
   	begin
   	select @retgtrans = 0, @crTrans = 0
   	
   	/* Get next available transaction # for ARTH */
   	exec @retgtrans = bspHQTCNextTrans @tablename, @arco, @Mth, @errmsg output
   	if @retgtrans = 0 goto bspexit
   	
   	exec @crTrans = bspHQTCNextTrans @tablename, @arco, @Mth, @errmsg output
   	if @crTrans = 0 goto bspexit
   	
   	/* Insert ARTH 'Release' record (First 'R') which contains lines applied to many earlier transactions */
   	insert into bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, JCCo, Contract, Invoice, Description, Source, TransDate, DueDate,
   		CreditAmt, Invoiced, Paid, Retainage, DiscTaken, AmountDue, AppliedMth, AppliedTrans, PurgeFlag, EditTrans, BatchId)
   	select @arco, Mth, @retgtrans, 'R', CustGroup, Customer, NULL, Co, Contract, NULL, 'Release Retainage', @Source, TransDate, NULL,
   		0, 0, 0, 0, 0, 0, NULL, NULL, 'N','N', BatchId
   	from bJBAR with (nolock)
   	where Co = @jbco and Mth = @Mth and BatchId = @BatchId and BatchSeq=@seq
   	if @@rowcount = 0 goto bspexit
   	
   	/* Insert the ARTH 'Released' record (Second 'R') that has retainage applied to itself */
   	insert into bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, JCCo, Contract, Invoice, Description, Source, TransDate, DueDate,
   		CreditAmt, Invoiced, Paid, Retainage, DiscTaken, AmountDue, AppliedMth, AppliedTrans, PurgeFlag, EditTrans, BatchId, Notes)
   	select @arco, @Mth, @crTrans, 'R', CustGroup, Customer, RecType, Co, Contract, Invoice, 'Released Retainage', @Source, TransDate, DueDate,
   		0, 0, 0, 0, 0, 0, @Mth, @crTrans, 'N','N', BatchId, Notes
   	from bJBAR with (nolock)
   	where Co = @jbco and Mth = @Mth and BatchId = @BatchId and BatchSeq=@seq
   	if @@rowcount = 0 goto bspexit
   	
   	/* Set the JBIN columns to the new transaction values */
   	update bJBIN
   	set ARRelRetgTran = @retgtrans, ARRelRetgCrTran = @crTrans
   	where JBCo = @jbco and BillMonth = @Mth and BillNumber = @billnumber
   	end  -- end of ARTH insert section
     
/* JBAL retainage posting loop */
/* RetgRel is stored as a negative number in JBAL under normal release conditions. Keep this in mind. */
declare bcJBAL cursor local fast_forward for
select l.Item, l.ARLine, l.RetgRel, l.RetgTaxRel, i.ContractAmt
from bJBAL l with (nolock)
join bJCCI i with (nolock) on i.JCCo = l.Co and i.Contract = @contract and i.Item = l.Item
where l.Co = @jbco and l.Mth = @Mth and l.BatchId=@BatchId and l.BatchSeq=@seq and l.ARLine < 10000
	and (l.RetgRel <> 0)	--Do not care about oldRetgRel during posting. Old info was deleted above and we are starting over
    
/* open cursor for line */
open bcJBAL
select @opencursorJBAL = 1
    
/**** read JBAL records ****/
get_next_bcJBAL:
fetch next from bcJBAL into @item, @jbal_arline, @relretg_amt, @relretgtax_amt, @contractitemamt
while (@@fetch_status = 0)
   	BEGIN	/* Begin Item Loop */
   	/* Reset temporary variables */
   	select @100_pct = 'N', @inserted = 'N', @dist_amt = 0, @dist_amttax = 0, @postlastline = null, @distamtstilloppositeflag = 'N'
   	select @relretg_amt = -@relretg_amt, @relretgtax_amt = -@relretgtax_amt		--Convert to Positive for easier and more straight forward comparisons (Neg in JBAL)
    
   	/* Evaluate Total Open Retainage for this Item.  If User is Releasing 100 percent of it then we will automatically
   	   Release the full amount of this Item on all Invoices.  There will be no evaluation and tracking of the distributed
   	   Release amounts for each Line in each invoice individually.  By doing this, any Negative Open Amounts for an 
   	   individual invoice will be dealt with correctly and ALL retainage amounts will be released entirely on all
   	   invoices.  This is a very important piece. */
   	select @totalaropen_retg = isnull(sum(l.Retainage),0)
   	from bARTH h with (nolock)
   	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
   		l.JCCo = @jbco and l.Contract = @contract and l.Item = @item
   	join bARTH ha with (nolock) on ha.ARCo = l.ARCo and ha.Mth = l.ApplyMth and ha.ARTrans = l.ApplyTrans 	-- Added Issue# 25364
   	where h.ARCo = @arco and h.CustGroup = @custgrp and h.Customer = @customer
   		and (h.Mth < @Mth or (h.Mth = @Mth and h.ARTrans < @retgtrans))
   		and ((h.ARTransType <> 'R' 
   			and (ha.ARTransType <> 'R' or (ha.ARTransType = 'R' and (ha.AppliedMth is null and ha.AppliedTrans is null))))	--Issue# 25364
   				or (h.ARTransType = 'R' and (h.AppliedMth is null and h.AppliedTrans is null))) --Skip 'R'eleased (2nd R) Retg and Credits to it
   
   	If @totalaropen_retg = @relretg_amt
   		begin
   		select @100_pct = 'Y'
   		end
   
   	/************************** BEGIN INDIVIDUAL INVOICE PROCESSING FOR THIS ITEM - POSTING ALGORITHIM *****************************/	
   
   	/* Spin through every record in ARTH/ARTL assigned to this arco/custgrp/customer/jcco/contract/item.
   	   We will be releasing retg possibly across multiple invoice transaction lines for the same
   	   Customer, Contract and Item. */
   	
   	/* Issue #23642, This cursor needed work!  It was bringing back just about every original,
   	   credit, adjustment, writeoff, and FC transaction for a given contract. It would then cycles thru each,
   	   sum the retainage, and then skip those whose retainage value is 0.00, which happened to be 
   	   the credits, adjustments, writeoffs and FC transactions.  It ultimately processed only the 
   	   original transactions with retainage, which is why it worked, but it was very inefficient.
    
    	   Cursor should limit / ignore the various adjustment transactions to begin with.  
    		1) About:  (h.Mth < @Mth or (h.Mth = @Mth and h.ARTrans < @retgtrans))
    			Note #1: (By now, this releasing invoice has been posted. The new or changed Retg value will be included.
    			Note #2: (Later bills never get considered.  Leftover amounts get placed on Last Line of Last Invoice.) 
    		2) About:  h.ARTransType not in ('F', 'R')  ('I' & 'R' invoices may both contain Retainage, 'F' will not.)
    			Note #3: ('R' invoices will contain Retg if not Released to AR when created. This Retg not allowed to be 
    				released now because JB Release Input form knows that it has already been released before.)
    		3) About:  l.Mth = l.ApplyMth and l.ARTrans = h.ApplyTrans and l.ARLine = l.ApplyLine  (Only Original Lines) */
   
   	/* This is our list of Original Invoices (By Mth, Transaction) upon which we will be releasing retainage 
   	   for this item, one at a time. */
   	declare bcARTL cursor local fast_forward for
   	select l.Mth, l.ARTrans, l.ARLine, l.RecType, TaxGroup, TaxCode
   	from bARTH h with (nolock)
   	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
   		and l.JCCo = h.JCCo and l.Contract = h.Contract 	--Not needed, lines restricted by Contract/Item below
   	where h.ARCo = @arco	
   		and (h.Mth < @Mth or (h.Mth = @Mth and h.ARTrans < @retgtrans))		--See not above
   		and h.CustGroup = @custgrp and h.Customer = @customer 				--This Customer 
   		and h.JCCo = @jbco and h.Contract = @contract and l.Item = @item	--This Contract and ContractItem
   		and h.ARTransType not in ('F', 'R') 								--See note above
   		and l.Mth = l.ApplyMth and l.ARTrans = l.ApplyTrans and l.ARLine = l.ApplyLine	--Original lines only
   	order by l.Mth, l.ARTrans, l.ARLine
    		
   	/* open cursor for line */
   	open bcARTL
   	select @opencursorARTL = 1
    
   	/**** read cursor lines ****/
   	get_next_bcARTL:
   	fetch next from bcARTL into @armth, @artrans, @arline, @originvrectype, @originvtaxgroup, @originvtaxcode
   	while (@@fetch_status = 0)
   		begin	/* Begin Line loop for this Item */
		select @post_RelRetg = 0, @post_RelRetgTax = 0, @oppositeopenretgflag = 'N', @postlastline = 0
   		select @armthsave = @armth, @artranssave = @artrans, @arlinesave = @arline
   
  		/* If this is a new bill, the arline should have been added just prior to released retainage posting. */
  		select @open_retg = isnull(sum(Retainage),0), @open_retgtax = isnull(sum(RetgTax),0)	-- Pos
  		from bARTL with (nolock)
  		where ARCo = @arco and ApplyMth = @armth and ApplyTrans = @artrans and ApplyLine = @arline
			and (Mth < @Mth or (Mth = @Mth and ARTrans < @retgtrans))
    
   		/* Multiple invoices may be involved for this one Item.  On the earlier invoices, the retg amount for
   		   this item may have already been released.  If so, just skip and move on. */
		if @open_retg = 0 goto get_next_bcARTL
   
   		if @100_pct = 'Y'
   			begin
   			/* Evaluation not required, go directly to Post Routine */
   			select @post_RelRetg = @open_retg
			select @post_RelRetgTax = @open_retgtax		
   			goto Post_Routine
   			end
		else
   			begin
   			/* Some form of Evaluation and PostAmount determination required */
   			if (@open_retg < 0 and @contractitemamt > 0) or (@open_retg > 0 and @contractitemamt < 0)
   				begin
   				/* Open Retainage has gone Negative on this invoice. Post full amount to compensate. */
   				select @oppositeopenretgflag = 'Y'		--Distributed amount accumulates differently later
   				select @post_RelRetg = @open_retg
				select @post_RelRetgTax = @open_retgtax	
   				end 
   			else
   				begin
   				/* This is normal Postive (or normal Negative) open retainage.  Distribute accordingly */
   				if @distamtstilloppositeflag = 'N'
   					begin
   	   				if abs(@dist_amt + @open_retg) <= abs(@relretg_amt)			-- abs(Pos + Pos) <= abs(Pos), abs() required here for Negative Items
   						begin
   	   					select @post_RelRetg = @open_retg						-- Pos = Pos		(or Neg = Neg)
						select @post_RelRetgTax = @open_retgtax	
   						end
   	 				else
   						begin
   	   					select @post_RelRetg = @relretg_amt - @dist_amt			-- Pos = Pos - Pos	(or Neg - (-Neg))
						select @post_RelRetgTax = @relretgtax_amt - @dist_amttax	
   						end
   					end
   				else
   					begin
   					if ((@dist_amt + @open_retg) < 0 and @relretg_amt > 0) or ((@dist_amt + @open_retg) > 0 and @relretg_amt < 0)
   						begin
   						/* Because of Negative/Opposite polarity open retg values along the way the distributed amount has 
   						   gone negative, leaving us with more to distribute than we originally began with.  When combined with
   						   this invoice lines open retg for this item, we are still left with more than we began with.  Therefore
   						   it is OK to release the full amount on this Line/Item and move on. There is no need for specific
   						   evaluation since we are not in jeopardy of releasing more than we have. */
   						select @post_RelRetg = @open_retg
						select @post_RelRetgTax = @open_retgtax	
   						end
   					else
   						begin
   						/* Combined amounts swing in the correct direction, continue with normal evaluation process */
   		   				if abs(@dist_amt + @open_retg) <= abs(@relretg_amt)			-- abs(Pos + Pos) <= abs(Pos), abs() required here for Negative Items
   							begin
   		   					select @post_RelRetg = @open_retg						-- Pos = Pos		(or Neg = Neg)
							select @post_RelRetgTax = @open_retgtax	
   							end
   		 				else
   							begin
   		   					select @post_RelRetg = @relretg_amt - @dist_amt			-- Pos = Pos - Pos	(or Neg - (-Neg))
							select @post_RelRetgTax = @relretgtax_amt - @dist_amttax	
   							end
   						end						
   					end
    			end
			end

   	Post_Routine:
      	if @post_RelRetg <> 0
        	begin
        	/* Get next available line number for this transaction */
        	select @PostLine = isnull(max(ARLine),0) + 1
        	from bARTL with (nolock)
        	where ARCo = @arco and Mth = @Mth and ARTrans = @retgtrans
   			
   			select @postlastline = @PostLine
   
	        /* Insert ARTL applied line against original invoice transaction, thus reducing retg */
	        insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
	        	TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct,
	  	    	Retainage, RetgTax, DiscOffered, DiscTaken, JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
	        select @arco, Mth, @retgtrans, @PostLine, @originvrectype, 'R', 'Release Retainage', GLCo, null,
	        	@originvtaxgroup, @originvtaxcode, -(@post_RelRetg), 0, 0, 0,
	  	    	-(@post_RelRetg), -(@post_RelRetgTax), 0, 0, @jbco, @contract, Item, @armth, @artrans, @arline
	        from bJBAL with (nolock)
	        where Co=@jbco and Mth=@Mth and BatchId=@BatchId and BatchSeq=@seq and Item = @item and ARLine = @jbal_arline
    
	        /* Insert ARTL line on new Released retg invoice (applied to itself) - represented by ARLine = 10000 
	           If the ARCurrentFlag is set to 'Y' then this Retg amount is NOT inserted as a Retainage value on
			   the new Released Retainage invoice  (Therefore Released to AR).
	           Only insert one of these lines per item with the full retainage amount released for that item */
	        if @inserted = 'N'
	        	begin
	          	/* Get next available line number for this transaction */
	          	select @PostLine2 = isnull(max(ARLine),0) + 1
	          	from bARTL with (nolock)
	          	where ARCo = @arco and Mth = @Mth and ARTrans = @crTrans
	
	          	insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, 
	            	TaxGroup, TaxCode, Amount, 
					TaxBasis, TaxAmount, RetgPct,
	  		     	Retainage, RetgTax, DiscOffered, DiscTaken,
	             	JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine, Notes)
	          	select @arco, Mth, @crTrans, @PostLine2, @rectype, 'R', 'Released Retainage', GLCo, GLAcct, 
	            	TaxGroup, TaxCode, isnull(RetgRel,0),
					case when @posttaxoninv = 'N' or (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N') then 0 
						else case when @ARCurrentFlag = 'Y' and isnull(RetgTaxRel,0) <> 0 then isnull(RetgRel,0) - isnull(RetgTaxRel,0) else 0 end end, 
					case @ARCurrentFlag when 'Y' then isnull(RetgTaxRel,0) else 0 end, 
					isnull(RetgPct,0),
	  		    	case @ARCurrentFlag when 'Y' then 0 else isnull(RetgRel,0) end, 
					case @ARCurrentFlag when 'Y' then 0 else isnull(RetgTaxRel,0) end,
					0, 0,
	            	@jbco, @contract, Item, Mth, @crTrans, @PostLine2, Notes
	          	from bJBAL with (nolock)
	          	where Co=@jbco and Mth=@Mth and BatchId=@BatchId and BatchSeq=@seq and Item = @item and ARLine = 10000

          		select @inserted = 'Y'
          		end
			end  --  end of artl insert section
    
		select @dist_amt = @dist_amt + @post_RelRetg
		select @dist_amttax = @dist_amttax + @post_RelRetgTax
   
   		if (@dist_amt < 0 and @relretg_amt > 0) or (@dist_amt > 0 and @relretg_amt < 0)
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
   
   		/* Determine whether to move on to next Invoice or not */
   		if @100_pct = 'Y'
   			begin
   			/* We are releasing full amount for this Item/Line on all invoices in list. Just keep going. */
   			goto get_next_bcARTL
   			end
   		else
   			begin
   			if @oppositeopenretgflag = 'Y'
   				begin
   				/* No evaluation necessary, we have more to Release than we began with */
   				select @oppositeopenretgflag = 'N'
   				goto get_next_bcARTL
   				end
   			else
   				begin
   				if @distamtstilloppositeflag = 'Y'
   					begin
   					/* We still have more money reserved to release than we originally began with.
   					   No need for comparisons. Just get next Invoice for this Line/Item. */
   					goto get_next_bcARTL
   					end
   				else
   					begin
   					/* If All has been distributed then we are done. */
   					if abs(@dist_amt) < abs(@relretg_amt) goto get_next_bcARTL else goto ARTL_loop_end 
   					end
   				end
   			end
		end /* End Line loop for this Item */
   
   	/* On a previously interfaced bill we allow the user to Release more retainage than is Open in AR.
   	   (We don't allow this on a new bill in an attempt to keep JB in sync with AR however if user
   	   must Release an amount despite AR, then they can do so by first Interfacing an 'A'ctive bill 
   	   within the limits, then changing the same 'I'nterfaced bill to any Release amount desired
   	   and re-interfacing.  Most of the time they are working with a previously interfaced bill anyway.) 
   	   At this point after releasing to all previous invoice Lines for this Item, if there is still a remaining
   	   Amount to be released, we will place this amount on the Last Invoice in AR for this Line/Item. 
   
	   AMOUNT TO RELEASE STILL REMAINS FOR THIS ITEM BUT WE HAVE RUN OUT OF LINES! */
	if @dist_amt <> @relretg_amt
		begin
		select @post_RelRetg = @relretg_amt - @dist_amt			-- Pos = Pos - Pos		(or Neg - (-Neg))
		select @post_RelRetgTax = @relretgtax_amt - @dist_amttax
    
   		/* @postlastline gets reset for each new invoice processed containing this Contract Item.
   		   It may or may not have a value at this point depending on whether or not the last invoice
   		   processed had open retainage for this item to release against.  */
   		if isnull(@postlastline, 0) > 0
   			begin
   			/* Some retg on the last invoice processed had retg released for this item.  We can update
   			   the existing FIRST 'R' (Release) transaction in ARTL with any remaining amounts.  
   			   There is no need to update the SECOND 'R' (Released) transaction because the full
   			   amount has already been posted above.  */
   	      	update bARTL 
   	 		set Amount = Amount + -(@post_RelRetg), Retainage = Retainage + -(@post_RelRetg), RetgTax = RetgTax + -(@post_RelRetgTax)
   	    	where ARCo = @arco and Mth = @Mth and ARTrans = @retgtrans and ARLine = @postlastline
   			end
   		else
   			begin
   			/* To this point for this Item there was no open retainage to release on the Last Invoice 
   			   containing this Contract Item.  Therefore we need to insert this item into the existing 
   			   FIRST 'R' (Release) transaction in ARTL relative to the ApplyMth and ApplyTrans of the
   			   Last Invoice containing this Contract Item using this remaining amount.  */
   
         	/* Get next available line number for this FIRST 'R' (Release) transaction */
         	select @postlastline = isnull(max(ARLine),0) + 1
         	from bARTL with (nolock)
         	where ARCo = @arco and Mth = @Mth and ARTrans = @retgtrans
     
 	        /* Insert ARTL applied line against original invoice transaction, thus reducing retg */
	        insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
	        	TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct,
	  	    	Retainage, RetgTax, DiscOffered, DiscTaken, JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
	        select @arco, Mth, @retgtrans, @postlastline, @originvrectype, 'R', 'Release Retainage', GLCo, null,
	        	@originvtaxgroup, @originvtaxcode, -(@post_RelRetg), 0, 0, 0,
	  	    	-(@post_RelRetg), -(@post_RelRetgTax), 0, 0, @jbco, @contract, Item, @armthsave, @artranssave, @arlinesave
	        from bJBAL with (nolock)
	        where Co=@jbco and Mth=@Mth and BatchId=@BatchId and BatchSeq=@seq and Item = @item and ARLine = @jbal_arline
   	  
 	        /* If a partial amount for this item has already been released against an earlier 
			   invoice then the SECOND 'R' (Released) transaction has already been established.  Otherwise
			   insert ARTL line on new Released retg invoice (applied to itself) - represented by ARLine = 10000 
 	           If the ARCurrentFlag is set to 'Y' then this Retg amount is NOT inserted as a Retainage value on
 			   the new Released Retainage invoice  (Therefore Released to AR). */
   
   			/* @inserted gets reset for each new Contract Item processed.  If retainage has already been
   			   released against an earlier invoice for this Item, then the SECOND 'R' (Released) transaction
   			   has already been established for the Full Release Amount and should not be added a 2nd time. */
 	        if @inserted = 'N'
 	        	begin
   	          	/* Get next available line number for this transaction */
   	          	select @PostLine2 = isnull(max(ARLine),0) + 1
   	          	from bARTL with (nolock)
   	          	where ARCo = @arco and Mth = @Mth and ARTrans = @crTrans
   	  	
	          	insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, 
	            	TaxGroup, TaxCode, Amount, 
					TaxBasis, TaxAmount, RetgPct,
	  		     	Retainage, RetgTax, DiscOffered, DiscTaken,
	             	JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
	          	select @arco, Mth, @crTrans, @PostLine2, @rectype, 'R', 'Released Retainage', GLCo, GLAcct, 
	            	TaxGroup, TaxCode, isnull(RetgRel,0), 
					case when @posttaxoninv = 'N' or (@arcotaxretg = 'Y' and @arcoseparateretgtax = 'N') then 0 
						else case when @ARCurrentFlag = 'Y' and isnull(RetgTaxRel,0) <> 0 then isnull(RetgRel,0) - isnull(RetgTaxRel,0) else 0 end end, 
					case @ARCurrentFlag when 'Y' then isnull(RetgTaxRel,0) else 0 end, 
					isnull(RetgPct,0),
	  		    	case @ARCurrentFlag when 'Y' then 0 else isnull(RetgRel,0) end, 
					case @ARCurrentFlag when 'Y' then 0 else isnull(RetgTaxRel,0) end,
					0, 0,
	            	@jbco, @contract, Item, Mth, @crTrans, @PostLine2
	          	from bJBAL with (nolock)
	          	where Co=@jbco and Mth=@Mth and BatchId=@BatchId and BatchSeq=@seq and Item = @item and ARLine = 10000

   				select @inserted = 'Y'
   				end
     		end
		end
   
ARTL_loop_end:
	close bcARTL
	deallocate bcARTL
	select @opencursorARTL = 0
    
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
   	
   	goto get_next_bcJBAL
   	END /* End Item Loop */
    
close bcJBAL
deallocate bcJBAL
select @opencursorJBAL = 0
    
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

if @opencursorARTL = 1
	begin
	close bcARTL
	deallocate bcARTL
	end
    
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBAR_PostRelRetg] TO [public]
GO
