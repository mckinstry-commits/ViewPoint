SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBRetgTotalsUpdate    Script Date: 8/28/99 9:34:29 AM ******/
CREATE procedure [dbo].[bspJBRetgTotalsUpdate]
/*************************************
*
* Created:  bc 10/13/99
* Modified: kb 3/12/00 - was updating RetgBilled with WCRetg and SMRetg
*		bc 04/18/00 - added rounding option
*    	bc 02/22/01 - need to update AmountDue after updating RetgBilled at the end of the procedure
*    	bc 09/17/02 - do not update JBIT unless new retg <> old retg
*		TJL 12/23/03 - Issue #23248, (Correct select @newsmretg = case @roundopt.... below)
*		TJL 08/06/04 - Issue #25287, Distribute Rounding Excess amount starting with first ContractItem
*		TJL 03/21/05 - Issue #27440, Improve distribution process when Negative Items exist
*		TJL 07/24/08 - Issue #128287, JB International Sales Tax
*		TJL 12/16/09 - Issue #129894/137089, Max Retainage Enhancement
*
* Called from JBProgBillRetgTot form.  When JBIN WCRetg and SMRetg totals have been
* overridden, for a bill, using this form, this procedure gets called to properly distribute
* the new amounts correctly across all of the bill items. (Updates wc and/or sm retainange
* totals for all items in JBIT for a specified bill)
*
* Pass:
*	JBCo, Bill Number, Contract, WCUpdate, SMUpdate, WC percent, This Bill's total Retainage,
*   SM Percent, This Bill's total SM Retainage
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
(@jbco bCompany, @billmth bMonth, @billnumber int, @jbcontract bContract, @wcupdate bYN, @smupdate bYN,
    @wcpct bPct, @billedretg bDollar, @smpct bPct, @billedsmretg bDollar, @enforcemaxretg bYN,
    @source varchar(20) = null, @msg varchar(255) output)
     
as
set nocount on

declare @rcode int
   
declare @jbitem bContractItem, @wcitemamt bDollar, @smitemamt bDollar,
   	@roundopt char(1), @wcretg bDollar, @smretg bDollar, 
   	@oldwcretg bDollar, @oldsmretg bDollar, @wcretgleft bDollar, @smretgleft bDollar,
   	@xwcretg bDollar, @xsmretg bDollar, @contractitemamt bDollar, @openitemcursor int,
   	@billitemwcpct bPct, @billitemsmpct bPct, @diststyle char(1),
	--International Sales Tax
	@arco bCompany, @arcoinvoicetaxyn bYN, @arcotaxretgyn bYN, @arcosepretgtaxyn bYN,
	@amtbilled bDollar, @taxbasis bDollar, @taxamount bDollar, @retgbilled bDollar, @retgtax bDollar, 
	@amountdue bDollar, @retgrel bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxrate bRate, @invdate bDate
   
select @rcode = 0, @openitemcursor = 0, @wcretgleft = 0, @smretgleft = 0

/********************************************************************************************************/
/*																										*/
/* READ BEFORE CONTINUEING!																				*/
/*   Due to Rounding effect, this process is not as straight forward as you might expect.  50% is not 	*/
/* necessarily exactly 50%. (ie: 50% of 72.33 = 36.165 rounded to 36.17).  If you simply apply 50%		*/
/* to all items and allow this rounding effect to go unchecked, you could very well end up applying		*/
/* more or less then the Total 50% dollar value intended.  Therefore each item is processed in order	*/
/* and a running total of the amount distributed is kept track of.  If rounding has left you with an	*/
/* amount leftover after applying to all items, it is added to the first item and the total 50% amount	*/
/* retainage for entire bill is correct.  (Likewise you could end up with less on your first item)		*/
/*   This process assures that 50% Retainage of the Total Amount is correct.  (It was decided that this	*/
/* is more important than 50% of each item which cannot be maintained anyway as the example above		*/
/* shows)																								*/
/*																										*/
/********************************************************************************************************/
 
if @jbco is null
   	begin
   	select @msg = 'Missing JB Company', @rcode = 1
   	goto bspexit
   	end
     
if @billnumber is null
   	begin
   	select @msg = 'Missing bill number', @rcode = 1
   	goto bspexit
   	end
     
if @jbcontract is null
   	begin
   	select @msg = 'Missing bill contract', @rcode = 1
   	goto bspexit
   	end
     
if @wcupdate is null or @smupdate is null
   	begin
   	select @msg = 'Missing update parameter', @rcode = 1
   	goto bspexit
   	end
     
/* Percentages, passed in, cannot be greater than 100% */
if @wcpct > 1 or @smpct > 1
   	  begin
   	  select @msg = 'Cannot create retainage greater than 100% of the items amount.', @rcode = 1
   	  goto bspexit
   	  end

/* Get additional information */
select @roundopt = RoundOpt, @diststyle = MaxRetgDistStyle
from bJCCM with (nolock)
where JCCo = @jbco and Contract = @jbcontract

select @arco = c.ARCo, @arcoinvoicetaxyn = a.InvoiceTax, @arcotaxretgyn = a.TaxRetg, 
	@arcosepretgtaxyn = a.SeparateRetgTax
from bJCCO c with (nolock)
join bARCO a with (nolock) on a.ARCo = c.ARCo
where c.JCCo = @jbco

select @invdate = InvDate
from bJBIN with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber

/* Set the starting Distribution amount for countdown.  Even though distribution is based upon the 
   Input PCT value we still do not want to allow distributing more than the user input 
   dollar value.  This will counter the effect of a rounded UP or DOWN PCT value input. */
if @wcupdate = 'Y' select @wcretgleft = case when @roundopt = 'R' then round(@billedretg,0) else @billedretg end
if @smupdate = 'Y' select @smretgleft = case when @roundopt = 'R' then round(@billedsmretg,0) else @billedsmretg end

/* Zero @billedretg input must be processed incase user is zeroing out a previous entry */
declare bcItem cursor local fast_forward for
select t.Item, isnull(t.WC,0), isnull(t.WCRetg,0), isnull(t.SM,0), isnull(t.SMRetg,0), isnull(t.RetgRel,0),
	t.TaxGroup, t.TaxCode, t.WCRetPct, tg.SMRetgPct
from bJBIT t with (nolock)
join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item
where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber
   
open bcItem
select @openitemcursor = 1

fetch next from bcItem into @jbitem, @wcitemamt, @oldwcretg, @smitemamt, @oldsmretg, @retgrel, 
	@taxgroup, @taxcode, @billitemwcpct, @billitemsmpct
while @@fetch_status = 0
   	begin	/* Begin Item Loop. */

	select @wcretg = @oldwcretg, @smretg = @oldsmretg, @xwcretg = 0, @xsmretg = 0, @amtbilled = 0, 
		@taxbasis = 0, @taxamount = 0, @retgbilled = 0, @retgtax = 0, @amountdue = 0

	if @taxcode is not null
		begin
		exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output, null, null, @msg output
		if @rcode <> 0
			begin
			if @openitemcursor = 1
				begin
				close bcItem
				deallocate bcItem
				select @openitemcursor = 0
				end 
			goto bspexit
			end
		end

	if @wcupdate = 'Y' and @billitemwcpct <> 0
   		begin
		/******************* Update the JBIT work complete retainage. **********************/
   		/* The WCPct input from the JBProgBillRetgTot form is now used to recalculated WCRetg for
   		   each item.  (Basically we are taking the new override bill amount/Pct, as a whole, and
   		   recalculating WCRetg values for each item) */
   		if @source <> 'JBRetainTotals' and @diststyle = 'I'
   			begin
   			if (@wcretgleft < 0 and (case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end) > 0) 
   				or (@wcretgleft > 0 and (case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end) < 0)
   				begin
   				/* Negative Item being processed. Will ultimately increase @wcretgleft. */
   				select @wcpct = @billitemwcpct
   				select @wcretg = (case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end)
   				end
   			else
   				begin
   				/* Set Retainage % */
   				if @wcretgleft = 0 or @wcitemamt = 0
   					begin
   					select @wcpct = 0
   					end
   				else
   					begin
   					select @wcpct = case when abs(@wcretgleft) <= abs(case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end)
   						then @wcretgleft / @wcitemamt else @billitemwcpct end
   	   				end
   	   			
   	   			/* Set WC Retainage */
   				if abs(@wcretgleft) <= abs((case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end))
   					begin
   					select @wcretg = @wcretgleft
   					end
   				else
   					begin
   					select @wcretg = case @roundopt when 'R' then round(@wcitemamt * @wcpct, 0) else @wcitemamt * @wcpct end
   					end
   				end
   			end
   		Else
   			begin
   			/* Retainage % will be a composite value and has already been passed into this procedure.  No need to recalculate.
   			   Set WC Retainage only. */
			select @wcretg = case @roundopt when 'R' then round(@wcitemamt * @wcpct, 0) else @wcitemamt * @wcpct end
			end

		/* Update the item with the new calculated WC retainage amount based upon WCPct input. */
		/* Those bill items with a Retainage % value set to 0.00% have been SKIPPED entirely. */
		update t
		set t.WCRetg = @wcretg,
   			t.WCRetPct = case when @enforcemaxretg = 'Y' 
   				/* Max Retainage limit is about to be enforced here.  @wcpct & @wcretg are correct for each other as determined above */
   				then case when t.WC = 0 then 0 else @wcpct end else 
   				/* Normal Retainage Totals from Retainage Totals form.  @wcpct comes directly from the user input. */
   				-- There is retainage to be distributed.  Those Bill Items w/out a billedamt will keep the Retainage % currently on bill item.
   				case when @wcpct <> 0 and t.WC = 0 then @billitemwcpct
   				-- Normal:  @wcretg is calculated from the @wcpct passed in therefore use the WC Percent value passed in.
   				when (@wcpct <> 0 and t.WC <> 0 and @wcretgleft <> 0 and ((@wcretgleft - @wcretg) <> 0)) then @wcpct
   				-- Normal:  @wcretg is calculated from the @wcpct passed in therefore use the WC Percent value passed in.
   				when (@wcpct <> 0 and t.WC <> 0 and @wcretgleft <> 0 and ((@wcretgleft - @wcretg) = 0)) then @wcpct	
   				-- Retainage is being Zero'd out.  Reset WC Percent to Contract Item default for startover.  There is no other logical reset value
   				when (@wcpct = 0 and @wcretgleft = 0 and @wcretg = 0) then i.RetainPCT
   				-- If @wcpct <> 0 and @wcretgleft = 0 then this might occur because of a Negative Item. Using @wcpct might be the best choice 
   			else @wcpct end end,
   			AuditYN = 'N'
   		from bJBIT t with (nolock)
   		join bJCCI i with (nolock) on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item
		where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber and t.Item = @jbitem 
   		--	and @wcretg <> @oldWCRetg

   		/* Keep running total of amount having been distributed amongst the items.  We will adjust for 
   		   rounding error later. */
   		select @wcretgleft = @wcretgleft - @wcretg
		end

	if @smupdate = 'Y' and @billitemsmpct <> 0
   		begin
		/******************* Update the JBIT Stored Material retainage. **********************/
   		/* The SMPct input from the JBProgBillRetgTot form is now used to recalculated SMRetg for
   		   each item.  (Basically we are taking the new override bill amount/Pct, as a whole, and
   		   recalculating SMRetg values for each item) */  
		select @smretg = case @roundopt when 'R' then round(@smitemamt * @smpct,0) else @smitemamt * @smpct end
   
		/* Update the item with the new calculated SM retainage amount based upon SMPct. */
		update bJBIT
		set SMRetg = @smretg, AuditYN = 'N'
		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem 
   		--	and @smretg <> @oldSMRetg
   
   		/* Keep running total of amount having been distributed amongst the items.  We will adjust for
   		   rounding error later. */
   		select @smretgleft = @smretgleft - @smretg
		end

	/* Begin Tax calculations */
	if @taxcode is null or @arcoinvoicetaxyn = 'N' 
		begin
		/* Either No TaxCode on this Item or AR Company is set to No Tax on Invoice/Bills */
		select @taxbasis = 0
		select @taxamount = 0
		select @retgtax = 0
		select @retgbilled = @wcretg + @smretg
		end
	else
		begin
		/* TaxCode does exist and AR Company is set for Tax on Invoice/Bills */
		if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
			begin
			/* Standard US */
			select @taxbasis = @wcitemamt + @smitemamt		--BilledAmt			
			select @taxamount = @taxbasis * @taxrate	
			select @retgtax = 0
			select @retgbilled = @wcretg + @smretg			--Retainage
			end
		if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
			begin
			/* International with RetgTax */
			select @taxbasis = (@wcitemamt + @smitemamt) - (@wcretg + @smretg)	
			select @taxamount = @taxbasis * @taxrate
			select @retgtax = (@wcretg + @smretg) * @taxrate
			select @retgbilled = (@wcretg + @smretg) + @retgtax
			end
		if @arcotaxretgyn = 'N'
			begin
			/* International no RetgTax */
			select @taxbasis = (@wcitemamt + @smitemamt) - (@wcretg + @smretg)
			select @taxamount = @taxbasis * @taxrate
			select @retgtax = 0
			select @retgbilled = (@wcretg + @smretg)
			end			
		end

	update t
	set t.TaxBasis = @taxbasis, t.TaxAmount = @taxamount, t.RetgBilled = @retgbilled, t.RetgTax = @retgtax,
		t.AmountDue = ((@wcitemamt + @smitemamt) - (@wcretg + @smretg)) + @taxamount + @retgrel,
		t.AuditYN = 'N',
		t.WCRetPct = case when (@enforcemaxretg = 'N' and @source = 'JBRetainTotals' and @billitemwcpct = 0 and @wcpct = 0 and @wcretgleft = 0 and @wcretg = 0) then i.RetainPCT
			else t.WCRetPct end			-- Special for when JB Retainage Totals is used to Zero out the bills Retainage.
	from bJBIT t
	join bJCCI i with (nolock) on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item
	where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber and t.Item = @jbitem 

	update bJBIT
	set AuditYN = 'Y'
	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem
		
	/* Get next item. We want to process ALL items at the WCPct rate. */
	fetch next from bcItem into @jbitem, @wcitemamt, @oldwcretg, @smitemamt, @oldsmretg, @retgrel, 
		@taxgroup, @taxcode, @billitemwcpct, @billitemsmpct
	end		/* End Item Loop. */
   
if @openitemcursor = 1
	begin
	close bcItem
	deallocate bcItem
	select @openitemcursor = 0
	end
   
/* If there is a difference between the Retainage Amount and the running total,
   update the first item with the remaining amount not to exceed 100% of the Billed Amt
   on the item.  Move on to the next item if necessary. 

   Begin 2nd pass through items as required and distribute leftover amounts caused by
   rounding issues beginning with the first item.  Typically, you will never get passed the
   very first item on the 2nd pass. 

   If there are some items on this bill whose amounts are opposite in polarity to the
   overall bill amounts  (Negative items on a positive bill) then leftover amounts
   caused by rounding issues will be distributed only to the normal positive items. (skip odd negative items)
   Typically we are talking relatively small amounts leftover and the full leftover positive
   amount will be distributed. */
   
if @billedretg <> 0 and (@wcretgleft <> 0 or @smretgleft <> 0)
    begin	/* Begin excess amount remains */
	declare bcItem cursor local fast_forward for
	select t.Item, i.ContractAmt, isnull(t.WC,0), isnull(t.WCRetg,0), isnull(t.SM,0), isnull(t.SMRetg,0), isnull(t.RetgRel,0),
		t.TaxGroup, t.TaxCode, t.WCRetPct, tg.SMRetgPct
	from bJBIT t with (nolock)
	join bJCCI i with (nolock) on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item
	join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item
	where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber
   
	open bcItem
	select @openitemcursor = 1
   
	fetch next from bcItem into @jbitem, @contractitemamt, @wcitemamt, @oldwcretg, @smitemamt, @oldsmretg, @retgrel, 
		@taxgroup, @taxcode, @billitemwcpct, @billitemsmpct
	while @@fetch_status = 0
   		begin	/* Begin excess amount Item Loop */
		select @wcretg = 0, @smretg = 0, @xwcretg = 0, @xsmretg = 0, @amtbilled = 0, 
			@taxbasis = 0, @taxamount = 0, @retgbilled = 0, @retgtax = 0, @amountdue = 0

		if @taxcode is not null
			begin
			exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output, null, null, @msg output
			if @rcode <> 0
				begin
				if @openitemcursor = 1
					begin
					close bcItem
					deallocate bcItem
					select @openitemcursor = 0
					end 
				goto bspexit
				end
			end

		/* Do not attempt to apply minor rounding leftover amounts to Reverse polarity 
		   items (Neg items on Positive Bill or visa versa).  This only further increases the leftover
		   amount needing to be distributed.  Skip these items. */
		if (@contractitemamt < 0 and @billedretg > 0) or (@contractitemamt > 0 and @billedretg < 0)		--Typically Pos, Pos
			begin
			goto NextItem
			end
		else
   			/* At this point we are applying leftover amounts to the correct polarity item (Normally positive) */
   			begin 
			if @wcupdate = 'Y' and @wcretgleft <> 0 and @billitemwcpct <> 0
   				begin
   				if (@wcretgleft < 0 and @billedretg > 0) or (@wcretgleft > 0 and @billedretg < 0)	--Typically Pos, Pos
   					begin
   					/* Due to rounding, too much has been applied overall (Amount Left has gone Negative).  
   					   Take some back on the first item. */
   					select @xwcretg = @wcretgleft
   					end
   				else
   					begin
   					/* Due to rounding, not enough has yet been applied.  Place more on the first item, then 
   				       second if necessary. */				
   					select @xwcretg = case when abs(@wcitemamt) >= (abs(@wcretgleft) + abs(@oldwcretg)) 
   							then @wcretgleft else (@wcitemamt - @oldwcretg) end
   					end
		
   		    	update bJBIT
   				set WCRetg = (WCRetg + @xwcretg), 
   					WCRetPct = case when WC = 0 then 0 else (WCRetg + @xwcretg)/WC end,
   					AuditYN = 'N'
   		    	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem
   		
   				/* If additional amount still remains, get next item. */
   				select @wcretgleft = @wcretgleft - @xwcretg
				end

			if @smupdate = 'Y' and @smretgleft <> 0 and @billitemsmpct <> 0
				begin
   				if (@smretgleft < 0 and @billedsmretg > 0) or (@smretgleft > 0 and @billedsmretg < 0)	--Typically Pos, Pos
   					begin
   					/* Due to rounding, too much has been applied overall (Amount Left has gone Negative).  
   					   Take some back on the first item. */
   					select @xsmretg = @smretgleft
   					end
   				else
   					begin					
   					/* Due to rounding, not enough has yet been applied.  Place more on the first item, then 
   				       second if necessary. */	
   					select @xsmretg = case when abs(@smitemamt) >= (abs(@smretgleft) + abs(@oldsmretg)) 
   						then @smretgleft else (@smitemamt - @oldsmretg) end
   					end
   		
   	    		update bJBIT
   				set SMRetg = (SMRetg + @xsmretg), AuditYN = 'N'
   	    		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem
   	
   				/* If additional amount still remains, get next item. */
   				select @smretgleft = @smretgleft - @xsmretg
				end

			/* Begin Tax calculations */
			if @taxcode is null or @arcoinvoicetaxyn = 'N' 
				begin
				/* Either No TaxCode on this Item or AR Company is set to No Tax on Invoice/Bills */
				select @taxbasis = 0
				select @taxamount = 0
				select @retgtax = 0
				select @retgbilled = (@oldwcretg + @xwcretg) + (@oldsmretg + @xsmretg)
				end
			else
				begin
				/* TaxCode does exist and AR Company is set for Tax on Invoice/Bills */
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
					begin
					/* Standard US */
					select @taxbasis = @wcitemamt + @smitemamt		--BilledAmt			
					select @taxamount = @taxbasis * @taxrate	
					select @retgtax = 0
					select @retgbilled = (@oldwcretg + @xwcretg) + (@oldsmretg + @xsmretg)		--Retainage
					end
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
					begin
					/* International with RetgTax */
					select @taxbasis = (@wcitemamt + @smitemamt) - ((@oldwcretg + @xwcretg) + (@oldsmretg + @xsmretg))	
					select @taxamount = @taxbasis * @taxrate
					select @retgtax = ((@oldwcretg + @xwcretg) + (@oldsmretg + @xsmretg)) * @taxrate
					select @retgbilled = ((@oldwcretg + @xwcretg) + (@oldsmretg + @xsmretg)) + @retgtax
					end
				if @arcotaxretgyn = 'N'
					begin
					/* International no RetgTax */
					select @taxbasis = (@wcitemamt + @smitemamt) - ((@oldwcretg + @xwcretg) + (@oldsmretg + @xsmretg))
					select @taxamount = @taxbasis * @taxrate
					select @retgtax = 0
					select @retgbilled = (@oldwcretg + @xwcretg) + (@oldsmretg + @xsmretg)
					end			
				end
	
			update bJBIT
			set TaxBasis = @taxbasis, TaxAmount = @taxamount, RetgBilled = @retgbilled, RetgTax = @retgtax,
				AmountDue = ((@wcitemamt + @smitemamt) - ((@oldwcretg + @xwcretg) + (@oldsmretg + @xsmretg))) + @taxamount + @retgrel,
				AuditYN = 'N'
			where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem 
   			end
   
		/* Get next Item if an amount still remains, else exit loop to save time.  */
	NextItem:
		if (@wcretgleft = 0 and @smretgleft = 0) goto SecondLoopExit

		update bJBIT
		set AuditYN = 'Y'
		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem
	
		fetch next from bcItem into @jbitem, @contractitemamt, @wcitemamt, @oldwcretg, @smitemamt, @oldsmretg, @retgrel, 
			@taxgroup, @taxcode, @billitemwcpct, @billitemsmpct
		end		/* End excess amount Item Loop */
   
SecondLoopExit:
	if @openitemcursor = 1
		begin
		close bcItem
		deallocate bcItem
		select @openitemcursor = 0
		end

	/* If Excess amount is still not 0.00 then users must be warned and input value must be adjusted. 
	   This is very unlikely to happen.  (I think it occurs as a result of the user inputting an overall
	   Dollar Amount that does not calculate out to an even Percentage value (ie: 1750 retg / 3000 itemamt = .5833333)).  
	   
	   The Pct value gets rounded down to 58.33% overall so the amount distributed comes up short initially.
	   If the item values are just right (too few items, too small in value), I believe its possible to apply 
	   the remaining amount to all items on the second pass and still have an amount left undistributed.  
	   (It came up in testing or I would not have been aware of this) */
	if @wcretgleft <> 0
		begin
		select @msg = 'The full WC Retainage was not distributed due to special circumstances and rounding.  '
		select @msg = @msg + 'To correct, apply an additional ' + convert(varchar, @wcretgleft) + ' amount to WC Retainage on an item on the bill.'
		select @msg = @msg + char(13) + char(10) + char(13) + char(10)
		--select @msg = @msg + 'A lesser input value may be due to the effect of Negative item values on this process.'
		select @rcode = 1
		end
	if @smretgleft <> 0
		begin
		select @msg = 'The full SM Retainage was not distributed due to special circumstances and rounding.  '
		select @msg = @msg + 'To correct, apply an additional ' + convert(varchar, @smretgleft) + ' amount to SM Retainage on an item on the bill.'
		--select @msg = @msg + 'A lesser input value may be due to the effect of Negative item values on this process.'
		select @rcode = 1
		end
	end		/* End excess amount remains */
 
bspexit:
if @openitemcursor = 1
   	begin
   	close bcItem
   	deallocate bcItem
   	select @openitemcursor = 0
   	end

if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[bspJBRetgTotalsUpdate]'
return @rcode








GO
GRANT EXECUTE ON  [dbo].[bspJBRetgTotalsUpdate] TO [public]
GO
