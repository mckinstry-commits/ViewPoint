SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBMaxRetgCheck]

/****************************************************************************
* CREATED BY:     TJL 12/16/09 - Issue #129894, Maximum Retainage Enhancement
* MODIFIED By :   
*
*
* USAGE:
*	This routine might be called from:
*		A.  Automated Progress Bill Initialize routine bspJBProgressBillItemsInit when Max Retainage is setup on Bill's Contract
*		B.  JB Progress Bill form.  Either from File_Menu option "Max Retainage Update" or Automatically when Max Retainage is setup on Bill's Contract
*		C.  JB Retainage Totals form when Max Retainage is setup on Bill's Contract. 
*
*	The routine will calculate and warn users/calling procedures:
*		A.	When the Bill's Maximum Retainage amounts that can be applied have exceeded the Contract's maximum retg limit.
*
*
*  INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg			error message if error occurs
*	@maxretgamt		Will be passed into 'vspJBMaxRetgUpdate' update procedure to avoid a second recalculation of same value
*	@prebillmaxretglimitmet		Used by the 'bspProgressBillItemsInit' proc to determine JBIT retainage percent defaults
*
* RETURN VALUE
*   0         Success - Maximum Retg has not been exceeded.  No Maximum Retainage Adjustments required.
*   1         Failure
*	7		  Conditional Success - Maximum Retg limits have been exceeded, Maximum Retainage Adjustments are required.
****************************************************************************/
(@co bCompany, @billmth bMonth = null, @billnum int = null, @contract bContract = null, 
	@wcretgin bDollar = 0, @smretgin bDollar = 0, @source varchar(20) = null, 
	@maxretgamt bDollar output, @prebillmaxretglimitmet bYN output,	@errmsg varchar(255) output)

--@custgroup bGroup, @customer bCustomer

as

set nocount on

/*generic declares */
declare @rcode int, @maxretgopt char(1), @maxretgpct bPct, @jccmmaxretgamt bDollar,	@inclacoinmax bYN,
	@totalwcretg bDollar, @totalsmretg bDollar, @billwcretg bDollar, @billsmretg bDollar

select @rcode=0, @maxretgamt = 0, @prebillmaxretglimitmet = 'N'

if @co is null
	begin
	select @errmsg = 'Missing JB Company.', @rcode = 1
	goto vspexit
	end
if @billmth is null
	begin
	select @errmsg = 'Missing JB Bill Month.', @rcode = 1
	goto vspexit
	end
if @billnum is null
	begin
	select @errmsg = 'Missing JB Bill Number.', @rcode = 1
	goto vspexit
	end
if @contract is null
	begin
	select @errmsg = 'Missing Contract value.', @rcode = 1
	goto vspexit
	end
		
select @maxretgopt = MaxRetgOpt, @maxretgpct = MaxRetgPct, @jccmmaxretgamt = MaxRetgAmt, @inclacoinmax = InclACOinMaxYN
from bJCCM with (nolock)
where JCCo = @co and Contract = @contract

if @maxretgopt in ('P', 'A')
	begin
	select @maxretgamt = @jccmmaxretgamt
	
	if @maxretgopt = 'P'
		begin
		/* May or may not exclude change order values but regardless, will always exclude any
		   contract items with a JCCI.RetainPCT set to 0.0%. */
		select @maxretgamt = case when @inclacoinmax = 'Y' then (@maxretgpct * isnull(sum(ContractAmt), 0)) 
			else (@maxretgpct * isnull(sum(OrigContractAmt), 0)) end
		from bJCCI with (nolock)
		where JCCo = @co and Contract = @contract and RetainPCT <> 0
		end

	if @source = 'JBRetainTotals'
		begin
		/* When from Retainage Totals form, must factor in the amounts being passed in from this form.
		   These amounts have not yet been applied to the existing billing and this bills current values
		   do not apply.  Current values will be overwritten.  */
		select @totalwcretg = isnull(sum(t.WCRetg), 0) + @wcretgin		--, @totalsmretg = isnull(sum(t.SMRetg), 0) + @smretgin
		from bJBIT t with (nolock)
		join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
		--join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item		--Holds SMRetgPct value
		where t.JBCo = @co and t.Contract = @contract							--and n.CustGroup = @custgroup and n.Customer = @customer
			and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber < @billnum))
			and t.WCRetPct <> 0					--ONLY WC Retainage considered in Max Retg calcs.  To include SMRetg add "or tg.SMRetgPct <> 0" here		
		end
	else
		begin
		/* We are here either from the JB Progress Bill Header form or from the JBProgressBillItemsInit procedure.
		   Total will include this current bill amounts. */			
		select @totalwcretg = isnull(sum(t.WCRetg), 0)			--, @totalsmretg = isnull(sum(t.SMRetg), 0)
		from bJBIT t with (nolock)
		join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
		--join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item		--Holds SMRetgPct value
		where t.JBCo = @co and t.Contract = @contract							--and n.CustGroup = @custgroup and n.Customer = @customer
			and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
			and t.WCRetPct <> 0					--ONLY WC Retainage considered in Max Retg calcs.  To include SMRetg add "or tg.SMRetgPct <> 0" here
		end
		
	----select @totalwcretg = (isnull(sum(t.PrevWCRetg), 0) + isnull(sum(t.WCRetg), 0)), @totalsmretg = (isnull(sum(t.PrevSMRetg), 0) + isnull(sum(t.SMRetg), 0))
	----from bJBIT t with (nolock)
	----join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
	----where t.JBCo = @co --and t.Contract = @contract --and n.CustGroup = @custgroup and n.Customer = @customer
	----	and t.BillMonth = @billmth and t.BillNumber = @billnum 

	if (@totalwcretg > 0 and @maxretgamt < 0) or (@totalwcretg < 0 and @maxretgamt > 0)	
		begin
		select @errmsg = 'Cannot determine if Maximum Retainage has been exceeded.  '
		select @errmsg = @errmsg + 'There might be a bad Maximum Retainage setting in JC Contract Master.'
		select @rcode = 1
		goto vspexit
		end
	else
		begin
		select @billwcretg = isnull(sum(t.WCRetg), 0)		--, @billsmretg = isnull(sum(t.SMRetg), 0)
		from bJBIT t with (nolock)
		where t.JBCo = @co and t.BillMonth = @billmth and t.BillNumber = @billnum 
			and t.WCRetPct <> 0		
			
		if abs(@totalwcretg) >= abs(@maxretgamt)	--ONLY WC Retainage considered in Max Retg calcs.  To include SMRetg add "+ @totalsmretg" here
			begin		
			if @billwcretg = 0
				begin
				/* We are likely here because the JBIN bill header record has just been created, the trigger has fired
				   and bill items have NOT yet been created.  This flag will be used (and is only used) early in the 
				   bspJBProgressBillItemsInit procedure to control the bill items retainage percent default and later
				   in the procedure to control if Max Retainage needs to be checked and updated after the bill 
				   items have been intialized. It is NOT used by any form code calling this procedure. */
				select @prebillmaxretglimitmet = 'Y'
				end
			end
				
		if abs(@totalwcretg) > abs(@maxretgamt)	--ONLY WC Retainage considered in Max Retg calcs.  To include SMRetg add "+ @totalsmretg" here
			begin
			/* Maximum Retainage Limits have been exceeded. */
			if @source = 'JBRetainTotals' or (@source <> 'JBRetainTotals' and @billwcretg <> 0)
				begin
				/* @rcode will be used by 'bspJBProgressBillItemsInit' as well as in form code to determine when User messages
				   should be raised and when bill items need to be adjusted/updated. */
				select @errmsg = 'Bill: (' + convert(varchar(5), Month(@billmth)) + '/' + right(convert(varchar(5), Year(@billmth)),2) + ', #' + convert(varchar(10), @billnum) + ') ' 
				select @errmsg = @errmsg + 'now exceeds the maximum retention allowed for Contract: ' + @contract + '.'
				select @errmsg = @errmsg + char(13) + char(10) + char(13) + char(10)
				select @errmsg = @errmsg + 'Do you wish to automatically set Maximum retention on the billing now?'
				select @rcode = 7
				end
			end
		end
	end		/* End Max Retainage Evaluation */
	  					
vspexit:

return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJBMaxRetgCheck] TO [public]
GO
