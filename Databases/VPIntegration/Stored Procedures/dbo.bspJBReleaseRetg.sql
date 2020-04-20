SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBReleaseRetg]

/****************************************************************************
* CREATED BY: bc 02/16/00
* MODIFIED By : bc 04/18/00 - added rounding option
* 		bc 03/08/01 - corrected update to AmountDue and threw difference into last item with released retainage
*		TJL 04/18/03 - Issue #20936, Reverse Release Retainage	
*		TJL 03/19/04 - Issue #24100, Distribute Rounding Excess amount starting with first ContractItem
*		TJL 03/21/05 - Issue #27440, Improve distribution process when Negative Items exist
*		TJL 08/14/08 - Issue #128370, JB International Sales Tax
*
* USAGE:  When releasing by Contract, releases retainage on the passed in bill for every item that has 
* 		  open retainage.  It is based upon a Percentage value that has been passed in however the 
*		  total amount being released must also equal the (Pct * Total Contract OpenAmt) value.
*	
*
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************/
(@jbco bCompany, @billmth bMonth, @billnum int, @relpct bPct, @released_amt bDollar output, @msg varchar(355) output)
as
   
set nocount on
   
/*generic declares */
declare @rcode int, @item bContractItem, @amt bDollar, @contract bContract,
   	@roundopt char(1), @amt2 bDollar, @relamtleft bDollar, @release_diff bDollar,
   	@revrelretgYN bYN, @xamt bDollar, @distamt bDollar, @contractitemamt bDollar,
   	@openitemcursor int,
	--International Sales Tax
	@retgtaxamt bDollar, @retgtaxamt2 bDollar

select @rcode = 0, @amt = 0, @amt2 = 0, @xamt = 0, @relamtleft = 0, @retgtaxamt = 0,
	@retgtaxamt2 = 0, @openitemcursor = 0 

/********************************************************************************************************/
/*																										*/
/* READ BEFORE CONTINUEING!																				*/
/*   Due to Rounding effect, this process is not as straight forward as you might expect.  50% is not 	*/
/* necessarily exactly 50%. (ie: 50% of 72.33 = 36.165 rounded to 36.17).  If you simply apply 50%		*/
/* to all items and allow this rounding effect to go unchecked, you could very well end up applying		*/
/* more or less then the Total 50% dollar value intended.  Therefore each item is processed in order	*/
/* and a running total of the amount distributed is kept track of.  If rounding has left you with an	*/
/* amount leftover after applying to all items, it is added to the first item and the total 50% amount	*/
/* released for entire contract is correct.  (Likewise you could end up with less on your first item)	*/
/*   This process assures that 50% Released of the Total Amount is correct.  (It was decided that this	*/
/* is more important than 50% of each item which cannot be maintained anyway as the example above		*/
/* shows)																								*/
/*																										*/
/********************************************************************************************************/
   
select @contract = Contract, @revrelretgYN = RevRelRetgYN
from bJBIN with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
select @roundopt = RoundOpt
from bJCCM with (nolock)
where JCCo = @jbco and Contract = @contract
   
/* Set the starting Distribution amount for countdown.  Even though distribution is based upon the 
   Input PCT value we still do not want to allow distributing more than the user input 
   dollar value.  This will counter the effect of a rounded UP or DOWN PCT value input. 
   ...
   Since there is no RetgTax input when Releasing by Contract, there is no need for a retgtaxleft
   variable.  Simply release RetgTax using the percent released value. */
select @relamtleft = case when @roundopt = 'R' then round(@released_amt,0) else @released_amt end
   
/* Zero @release_amt input must be processed incase user is zeroing out a previous entry. */
declare bcItem cursor local fast_forward for
select Item
from bJBIT with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
open bcItem
select @openitemcursor = 1

fetch next from bcItem into @item
while @@fetch_status = 0
   	begin	/* Begin initial Item Loop */
	select @amt = 0, @amt2 = 0, @retgtaxamt = 0, @retgtaxamt2 = 0

	/* Get Item Open Retainage amount (Release) or the Item amount already released when reversing (Reverse Release). */
	select @amt = case when @revrelretgYN = 'N' then (PrevRetg + RetgBilled - PrevRetgReleased) * @relpct
			else -(PrevRetgReleased * @relpct) end,
		@retgtaxamt = case when @revrelretgYN = 'N' then (PrevRetgTax + RetgTax - PrevRetgTaxRel) * @relpct
			else -(PrevRetgTaxRel * @relpct) end
	from bJBIT with (nolock)
	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Item = @item 
	--and (PrevRetg + RetgBilled - PrevRetgReleased) <> 0
   
   	/* Round Opt 'R' drops the cents */
	if @roundopt = 'R' select @amt2 = round(@amt,0) else select @amt2 = @amt
	if @roundopt = 'R' select @retgtaxamt2 = round(@retgtaxamt,0) else select @retgtaxamt2 = @retgtaxamt
   
   	/* Set value for this item based upon Pct input by user. */
 	update bJBIT
 	set RetgRel = @amt2, RetgTaxRel = @retgtaxamt2,
		AmountDue = AmtBilled - (RetgBilled - RetgTax) + TaxAmount + @amt2
 	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   
   	/* Keep running total of amount having been distributed amongst the items.  We will adjust for 
   	   rounding error later. */
   	select @relamtleft = @relamtleft - @amt2

   	/* Get next Item.  We want to process ALL Items at this Pct rate. */
   	fetch next from bcItem into @item
    end		/* End initial Item Loop */
   
if @openitemcursor = 1
   	begin
   	close bcItem
   	deallocate bcItem
   	select @openitemcursor = 0
   	end
   
/* If there is a difference between the Retainage Release Amount (or Reverse Amount) and the running total,
   then update the first item with the remaining amount not to exceed 100% released on the item.  Move on 
   to the next item if necessary.

   Begin 2nd pass through items as required and distribute leftover amounts caused by
   rounding issues beginning with the first item.  Typically, you will never get passed the
   very first item on the 2nd pass. 

   If there are some items on this bill whose amounts are opposite in polarity to the
   overall bill amounts (Negative items on a positive bill) then leftover amounts
   caused by rounding issues will be distributed only to the normal positive items. (skip odd negative items)
   Typically we are talking relatively small amounts leftover and the full leftover positive
   amount will be distributed.  

   Again, there is NO leftover amounts relative to RetgTax because user does not enter a RetgTax amount
   to be released when releasing by Contract.  Therefore RetgTax is released strictly on a percent basis.
   The following does not apply to RetgTax. */
   
if @released_amt <> 0 and @relamtleft <> 0
	begin	/* Begin 2nd Pass to apply excess amounts. */
   	declare bcItem cursor local fast_forward for
   	select t.Item, i.ContractAmt
   	from bJBIT t with (nolock)
   	join bJCCI i with (nolock) on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item
   	where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnum and t.RetgRel <> 0
   
   	open bcItem
   	select @openitemcursor = 1
   
   	fetch next from bcItem into @item, @contractitemamt
   	while @@fetch_status = 0
   		begin	/* Begin excess amount Item Loop */
   		/* Get Item Open Retainage amount (Release) or the Item amount already released when reversing (Reverse Release). */
   	    select @amt = case when @revrelretgYN = 'N' then ((PrevRetg + RetgBilled) - (PrevRetgReleased + RetgRel))
   				else -(PrevRetgReleased + RetgRel) end
   	    from bJBIT with (nolock)
   	    where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Item = @item 
   
   		/* Do not attempt to apply minor rounding leftover amounts to Reverse polarity 
   		   items (Neg items on Positive Bill or visa versa).  This only further increases the leftover
   		   amount needing to be distributed.  Skip these items. */
   		if (@revrelretgYN = 'N' and ((@contractitemamt < 0 and @released_amt > 0) or (@contractitemamt > 0 and @released_amt < 0))) or 	--Pos, Pos
   			(@revrelretgYN = 'Y' and ((@contractitemamt < 0 and -@released_amt > 0) or (@contractitemamt > 0 and -@released_amt < 0)))	--Pos, -Neg
   			begin
   			goto NextItem
   			end
   		else
   		/* At this point we are applying leftover amounts to the correct polarity item (Normally positive) */
   			begin
   			if (@relamtleft < 0 and @released_amt > 0) or (@relamtleft > 0 and @released_amt < 0)	-- Typically Pos, Pos (Rel) or Neg, Neg (Rev Rel)
   				begin
   				/* Due to rounding, too much has been applied overall (Amount Left has gone Negative).  
   				   Take some back on the first item. */
   				select @xamt = @relamtleft
   				end
   			else
   				begin
   				/* Due to rounding, not enough has yet been applied.  Place more on the first item, then 
   				   second if necessary. */
   				select @xamt = case when abs(@amt) <= abs(@relamtleft) then @amt else @relamtleft end
   				end
   	
       		update bJBIT
       		set RetgRel = RetgRel + @xamt, AmountDue = AmountDue + @xamt
       		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   
   			/* If additional amount still remains, get next item being released on */
   			select @relamtleft = @relamtleft - @xamt
   
   			end
   
   		/* Get next Item if an amount still remains, else exit loop to save time.  */
   	NextItem:
   		if @relamtleft = 0 goto SecondLoopExit
   
   		fetch next from bcItem into @item, @contractitemamt
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
   	   Dollar Amount that does not calculate out to an even Percentage value (ie: 1750 released / 3000 open = .5833333)).  
   	   
   	   The Pct value gets rounded down to 58.33% overall so the amount distributed comes up short initially.
   	   If the item values are just right, I believe its possible to apply the remaining amount to all items
   	   on the second pass and still have an amount left undistributed.  (It came up in testing or I would not have
   	   been aware of this) */
   	if @relamtleft <> 0
   		begin
   		if @revrelretgYN = 'N' 
   			begin		
   			select @msg = 'The actual PCT value resulting from (Release Retg Input divided by Net Retg) may be different than the displayed' + char(13)
   			select @msg = @msg + '(Pct Released) value because of rounding.  This can result in a leftover amount not distributed!'
   			--select @msg = @msg + 'A lesser input value may be due to the effect of Negative item values on this process.'
   			select @rcode = 1
   			end
   		else
   			begin		
   			select @msg = 'The actual PCT value resulting from (Reverse Rel Retg Input divided by Amount Released) may be different than' + char(13)
   			select @msg = @msg + 'the displayed (Pct Released) value because of rounding.  This can result in a leftover amount not distributed!'
   			--select @msg = @msg + 'A lesser input value may be due to the effect of Negative item values on this process.'
   			select @rcode = 1
   			end
   		end
	end		/* End 2nd Pass to apply excess amounts. */
   
bspexit:
if @rcode <> 0 
   	begin
   	select @released_amt = @released_amt - @relamtleft
   	select @msg = @msg		--+ char(13) + char(10) + '[bspJBReleaseRetg]'
   	end
   
if @openitemcursor = 1
   	begin
   	close bcItem
   	deallocate bcItem
   	select @openitemcursor = 0
   	end
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBReleaseRetg] TO [public]
GO
