SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBMaxRetgUpdate]

/****************************************************************************
* CREATED BY:     TJL 12/16/09 - Issue #129894, Maximum Retainage Enhancement
* MODIFIED By :   
*
*
* USAGE:
*	This routine might be called from:
*		A.  Automated Progress Bill Initialize routine bspJBProgressBillItemsInit when bspJBMaxRetgCheck returns "rcode = 7"
*		B.  JB Progress Bill form.  Either from File_Menu option (when bspJBMaxRetgCheck returns "rcode = 7") or Automatically (when user says 'Y' to Update)
*		C.  JB Retainage Totals form when user says 'Y' to Update.
*
*	The routine will calculate:
*		A.	The Bill's Maximum Retainage amounts that can be applied without exceeding the Contract's maximum retg limit.
*		B.	The Bill's adjusted Retainage Pct based upon the maximum retainage amount allowed for the bill.
*		C.  The calculated WC Retg amount and SM Retg amount to be passed into the Retainage Totals procedure (bspJBRetgTotalsUpdate)
*
*
*  INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************/
(@co bCompany, @billmth bMonth = null, @billnum int = null, @contract bContract = null, @maxretgamt bDollar = 0, 
	@wcupdate bYN = 'N', @smupdate bYN = 'N', @wcpct bPct = 0, @wcretg bDollar = 0, @smpct bPct = 0, @smretg bDollar = 0,
	@godirecttoretgupdate bYN = 'N', @source varchar(20) = null, @errmsg varchar(255) output)

as

set nocount on

/*generic declares */
declare @rcode int, @maxretgopt char(1), @maxretgpct bPct, @jccmmaxretgamt bDollar,	@inclacoinmax bYN,
	@totalwcretg bDollar, @totalsmretg bDollar, @billedamt bDollar, @maxbillretg bDollar, @billretgpct bPct,
	@sm bDollar, @wc bDollar, @enforcemaxretg bYN   

select @rcode=0, @maxretgamt = isnull(@maxretgamt, 0), @enforcemaxretg = 'N'

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

if @godirecttoretgupdate = 'N'
	begin	/* Begin calculate Max Retainage values */	
	select @wcupdate = 'N' --@smupdate = 'N', 
	select @wcpct = 0, @wcretg = 0, @enforcemaxretg = 'Y'
	
	select @maxretgopt = MaxRetgOpt, @maxretgpct = MaxRetgPct, @jccmmaxretgamt = MaxRetgAmt, @inclacoinmax = InclACOinMaxYN
	from bJCCM with (nolock)
	where JCCo = @co and Contract = @contract

	if @maxretgopt not in ('P', 'A')
		begin
		select @errmsg = 'The contract on this billing is not set to use Maximum Retainage limits.  Bill retension has not been updated.', @rcode = 1
		goto vspexit
		end

	/* If Maximum Retainage amount is not already pre-calculated (passed in), get it now. */
	if @maxretgamt = 0
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
		end	
		
	/* Determine Maximum Retainage Amount and Average Retg% allowed for this bill being updated. */
	select @totalwcretg = isnull(sum(t.WCRetg), 0)		--, @totalsmretg = isnull(sum(t.SMRetg), 0)
	from bJBIT t with (nolock)
	join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
	--join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item		--Holds SMRetgPct value
	where t.JBCo = @co and t.Contract = @contract 
		and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber < @billnum)) 
		and t.WCRetPct <> 0					--ONLY WC Retainage considered in Max Retg calcs.  To include SMRetg add "or tg.SMRetgPct <> 0" here

	select @wc = isnull(sum(t.WC), 0)		--, @sm = isnull(sum(t.SM), 0), @billedamt = (@wc + @sm)
	from bJBIT t with (nolock)
	join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
	--join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item		--Holds SMRetgPct value
	where t.JBCo = @co and t.BillMonth = @billmth and t.BillNumber = @billnum 
		and t.WCRetPct <> 0					--ONLY WC Retainage considered in Max Retg calcs.  To include SMRetg add "or tg.SMRetgPct <> 0" here
		  	
	select @maxbillretg = @maxretgamt - (@totalwcretg)		--ONLY WC Retainage considered in Max Retg calcs.  To include SMRetg add "+ @totalsmretg" here
	if @wc = 0 or (@maxbillretg < 0 and @maxretgamt > 0) or (@maxbillretg > 0 and @maxretgamt < 0)
		begin
		select @maxbillretg = 0, @billretgpct = 0
		end
	else
		begin
		select @billretgpct = @maxbillretg/@wc
		--select @billretgpct =  @maxbillretg/@billedamt	--USE if you want include SM in calculations
		end

	/* Determine WCRetg and SMRetg based upon maximum retainage amounts allowed for this billing. */
	select @wcpct = @billretgpct			--, @smpct = @billretgpct
	select @wcretg = @maxbillretg, @wcupdate = 'Y'
	--select @wcretg = @wcpct * @wc, @wcupdate = 'Y'		--MUST parse into @wcretg & @smretg when including SM
	--select @smretg = @maxbillretg - @wcretg, @smupdate = 'Y'
	end  /* End calculate Max Retainage values */

/* Pass calculated values into Retainage Totals procedure for distribution against each Bill Item. */
exec @rcode = bspJBRetgTotalsUpdate @co, @billmth, @billnum, @contract, @wcupdate, @smupdate, 
	@wcpct, @wcretg, @smpct, @smretg, @enforcemaxretg, @source, @errmsg output

vspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJBMaxRetgUpdate] TO [public]
GO
