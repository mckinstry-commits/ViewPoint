SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARFCAmtDue    Script Date: 8/28/99 9:34:11 AM ******/
   CREATE  proc [dbo].[bspARFCAmtDue]
   /*************************************************************************************************************
   * CREATED BY: 	TJL 5/30/01
   * MODIFIED BY: 	TJL 07/17/01  Corrected calculation not to include negative @DiscTaken in @AmtDue calculations
   *								and not to include payments made on finance charges if ARCO flag set to 'N'
   *		TJL 07/18/01  Corrected On Account calcs to include On Account Payments not yet applied to invoice
   *		TJL 03/15/02 - Issue #14171, Add BY RECTYPE option, Exclude by Contract and by
   *					Invoice option, and performance mods.
   *		GG 09/20/02 - #18522 ANSI nulls
   *		TJL 02/17/03 - Issue #20107, Use FinanceChg column to determine @amtdue rather than 'F' LineType 
   *		TJL 10/29/03 - Issue #22877, Zero Balance Invoice - Incorrect FinanceChg column issue
   *		TJL 02/04/04 - Issue #23642, During review of this issue, added "with (nolock)" thru-out
   *
   *
   * USAGE:
   * 	This procedure calculates the amount due for either an customer account or an Invoice/ ARTransaction
   *	If the ARTrans is not null then the amount due is for the Invoice/transaction else
   *          the amount due is for the customer account.
   * INPUT PARAMETERS:
   * 	@ARCo, @Mth, @ARTrans, @CustGroup, @Customer, @applymth
   *	@duedatecutoff  determines which transactions shall be totaled for the purpose of a Finance Charge
   *	@paiddatecutoff determines which payments shall be allowed before determining Invoice AmtDue
   *
   * OUTPUT PARAMETERS:
   *	@originvamt  used by VB to display Original Invoice Amt
   *	@amtdue  used to calculate Finance Charges and to be display in VB form
   *	@currinvamt used by VB to display Current Invoice Amt
   *	Error message
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   **************************************************************************************************************/
   (@ARCo bCompany, @Mth bMonth, @ARTrans bTrans = null, @CustGroup bGroup, @Customer bCustomer,
     	@duedatecutoff bDate = null, @paiddatecutoff bDate = null, @applymth bDate, @FCType char(1),
   	@originvamt bDollar output,	@amtdue bDollar output, @currinvamt bDollar output)
   
   as
   set nocount on
   
   /* Declare working variables */
   declare	@hARTransType char(1), @hTransDate bDate, @FCCalcOnFC char(1), @invamount bDollar,
   	@excludecontract char(1), @rcode int
   
   select @rcode = 0, @amtdue = 0
   
   if @duedatecutoff is null	-- #18522
   	begin
   	select @duedatecutoff = getdate()
   	end
   if @paiddatecutoff is null	-- #18522
   	begin
   	select @paiddatecutoff = getdate()
   	end
   
   /* Do we want to include Finance Charges in the Finance Charge calculations? */
   select @FCCalcOnFC = FCCalcOnFC from bARCO with (nolock) where ARCo=@ARCo
   
   /* Do we want to exclude Contract invoices from Finance Charge calculations? */
   select @excludecontract = ExclContFromFC 
   from bARCM with (nolock)
   where CustGroup = @CustGroup and Customer = @Customer
   
   /****************************************************************************************************/
   /*		BY INVOICE - EITHER AUTOMATIC FOR MULTIPLE INVOICES OR MANUALLY	FOR SINGLE INVOICES			*/
   /*																									*/
   /*	When calculating Automatically for a batch of invoices, 										*/
   /*	bspARFCFinanceChgCalc has already established the record set by DueDateCutOff.					*/
   /*	Each transaction is passed in, the amount due is calculated and returned.						*/
   /*																									*/
   /*	When calculating Manually for a single invoice, 												*/
   /*	bspARFCFinanceChgCalcManual passes in the single transaction selected by the user.				*/
   /*	DueDateCutOff is not a factor and therefore not considered.  The amount due is					*/
   /*	calculated and returned.																		*/
   /*																									*/
   /*	When calculating Automatically or Manually BY RECTYPE, invoices for each RecType				*/
   /*	are processed and evaluated, one at a time.  A record set by DueDateCutOff has 					*/
   /*	already been established, by this time, if appropriate.	The amount due for each invoice 		*/
   /*	is passed back, compared and if a FC is calculated, it will be added to the previous			*/
   /*	Finance Charge amounts calculated for this one RecType.											*/
   /*																									*/
   /****************************************************************************************************/
   
   /* @ARTrans will NOT be null if processing 'BY INVOICE' either automatically or manually */
   if @FCType in ('I', 'R')
   	/* An ARTrans has been passed in via an Invoice number in Manual mode or in Automatic calculate */
   	begin
   	if @FCType = 'I'
   		begin
   		/* First get Original Invoice Amount and Current Invoice Amount for this invoice.  
   	   	   For display only, used only by VB event 'GetBalance' - Not valid when processing
   		   invoices for the BY RECTYPE option. */
   		select @originvamt = sum(case when
         			(bARTL.ApplyMth = bARTL.Mth and bARTL.ApplyTrans = bARTL.ARTrans and bARTL.ApplyLine = bARTL.ARLine)
          			then bARTL.Amount else 0 end),
   	   			@currinvamt = sum(case when bARTH.ARTransType <> 'P' then bARTL.Amount else 0 end)
    		from bARTH with (nolock)
   		join bARTL with (nolock) on bARTH.ARCo = bARTL.ARCo and bARTH.Mth = bARTL.Mth and bARTH.ARTrans = bARTL.ARTrans
    		where bARTL.ARCo = @ARCo and bARTL.ApplyMth = @applymth and bARTL.ApplyTrans = @ARTrans
   		end
   
   	/* Next Calculate AmtDue for a single invoice. 
   	   Generally this AmtDue is for determining if FC should be applied to a particular invoice.
    	   If so, then bspAmtDueLineForInvoice will follow and actually calculate amounts, by line,
   	   to apply the FC percentage against. */
   
   	/* BY INVOICE:
   	Sum Amount column and subtract sum of Retainage Column because Retg is not
      	included in Finance Charges.
   	a)	For this Company, Custgroup, and Customer's original transactions 
   	b)  	**** DONE IN bspARFinanceChgCalc and bspARFinanceChgCalcManual ****
   			The Transaction DueDate has been pre-determined to be <= the DueDateCutOff.
   	c)		Include amounts for all applied transactions of the originals.
   	d)		Do not include payment transactions unless the payment TransDate
   				is <= the PaidDateCutoff. 
   	e)		Exclude or include amounts of applied FinanceChg lines as determined 
   				by the ARCO.FCCalcOnFC setting.
   	f)		**** DONE IN bspARFinanceChgCalc and bspARFinanceChgCalcManual **** 
   			Exclude or include invoices containing contracts as determined by
   				the ARCM.ExclContFromFC setting.
   	g)		**** DONE IN bspARFinanceChgCalc and bspARFinanceChgCalcManual **** 
   			Exclude invoice if ARTH.ExcludeFC is set to 'Y' */
   	select @amtdue = isnull(((sum(l.Amount) - sum(l.Retainage)) - 
   					(case when @FCCalcOnFC = 'N' then sum(l.FinanceChg) else 0 end)), 0),
   		@invamount = isnull(sum(l.Amount), 0)
   					--isnull(sum(l.Amount) - sum(l.Retainage), 0) --#20107 TJL
   	from bARTL l with (nolock)
   	join bARTH h with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
   	where l.ARCo = @ARCo and l.ApplyMth = @applymth and l.ApplyTrans = @ARTrans
   		and (h.ARTransType <> 'P' or (h.ARTransType = 'P' and h.TransDate <= @paiddatecutoff))
   		-- and l.LineType <> (case when @FCCalcOnFC = 'N' then 'F' else '1' end)  --#20107 TJL
   		-- and isnull(l.Contract, '') = isnull((case when @excludecontract = 'N' then l.Contract else Null end), '')
   		-- and ha.ExcludeFC <> 'Y')
   
   	/* Needed for Bad Data in FinanceChg column (sum negative on 0.00 balance invoices), usually leftover
   	   from old Invoice finance charges (0.00 in column) incorrectly written off (Reversed) using the 
   	   Finance Charge module (negative in column) */
   	if @invamount = 0 select @amtdue = @invamount
   	goto bspexit
   	end 
   
   /****************************************************************************************************/
   /*				ON ACCOUNT - EITHER AUTOMATIC CALCULATIONS OR MANUAL CALCULATIONS					*/
   /*																									*/
   /*	Whether calculating manually ON ACCOUNT or Automatically ON ACCOUNT,							*/
   /*	bspARFCFinanceChgCalc AND bspARFCFinanceChgCalcManual has NOT established 						*/
   /*  the record set by DueDateCutOff, therefore, DueDateCutOff is part of the where clause.			*/
   /*																									*/
   /*																									*/
   /****************************************************************************************************/
   
   if @FCType = 'A'
   	/* If doing Automatic Calc ON ACCOUNT then this routine totals all transactions for a particular customer.
   	   There is no need to return Original Invoice Amount or Current Invoice Amount ON ACCOUNT calculations. */
   	begin
   	/* ON-ACCOUNT:
   	Sum Amount column and subtract sum of Retainage Column because Retg is not
      	included in Finance Charges.
   	a)	For this Company, Custgroup, and Customer's original transactions 
   	b)  	The Transaction DueDate must be <= the DueDateCutOff.
   	c)		Include amounts for all applied transactions of the originals.
   	d)		Do not include payment transactions unless the payment TransDate
   				is <= the PaidDateCutoff. 
   	e)		Exclude or include amounts of applied FinanceChg lines as determined 
   				by the ARCO.FCCalcOnFC setting.
   	f)		Exclude or include invoices containing contracts as determined by
   				the ARCM.ExclContFromFC setting.
   	g)		Exclude invoice if ARTH.ExcludeFC is set to 'Y'
   	Also sum the Amount column for independent Payments on Account.
   	h)		Do not include On-Account payment transactions unless the payment TransDate
   				is <= the PaidDateCutoff. */
   	select @amtdue = isnull(((sum(l.Amount) - sum(l.Retainage)) - 
   					(case when @FCCalcOnFC = 'N' then sum(l.FinanceChg) else 0 end)), 0)
   			-- isnull((sum(l.Amount) - sum(l.Retainage)), 0)			--#20107 TJL
   	from bARTL l with (nolock)
   	join bARTH ha with (nolock) on l.ARCo=ha.ARCo and l.ApplyMth=ha.Mth and l.ApplyTrans=ha.ARTrans
   	join bARTH h with (nolock) on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans
   	where ha.ARCo = @ARCo and ha.CustGroup = @CustGroup and ha.Customer = @Customer and
   	((ha.DueDate <= @duedatecutoff and ha.Mth = ha.AppliedMth and ha.ARTrans = ha.AppliedTrans
   		and (h.ARTransType <> 'P' or (h.ARTransType = 'P' and h.TransDate <= @paiddatecutoff))
   		--and l.LineType <> (case when @FCCalcOnFC = 'N' then 'F' else '1' end)		--#20107 TJL
   		and isnull(l.Contract, '') = isnull((case when @excludecontract = 'N' then l.Contract else Null end), '')
   		and ha.ExcludeFC <> 'Y') or
   		(ha.ARTransType = 'P' and l.LineType = 'A' and ha.TransDate <= @paiddatecutoff))
   
   	goto bspexit
   	end
   
   /****************************************************************************************************/
   /*																									*/
   /*		*************** NOT IN USE! - POTENTIAL PARSONS FUTURE *********************				*/
   /*																									*/
   /*		BY RECTYPE, SINGLE LINE - EITHER AUTOMATIC CALCULATIONS OR MANUAL CALCULATIONS				*/
   /*																									*/
   /*	Whether calculating manually BY RECTYPE or Automatically BY RECTYPE,							*/
   /*	bspARFCFinanceChgCalc AND bspARFCFinanceChgCalcManual has NOT established 						*/
   /*  the record set by DueDateCutOff, therefore, DueDateCutOff is part of the where clause.			*/
   /*																									*/
   /*																									*/
   /****************************************************************************************************/
   
   --if @FCType = 'T'
   	/* If doing Automatic Calc BY RECTYPE, SINGLE LINE then this routine totals all transactions
   	   for a particular customer, one RECTYPE at a time.  There is no need to return
   	   Original Invoice Amount or Current Invoice Amount when doing BY RECTYPE, SINGLE LINE calculations. */
   --	begin
   	/* BY RECTYPE, SINGLE LINE:
   	Sum Amount column and subtract sum of Retainage Column because Retg is not
      	included in Finance Charges.
   	a)	For this Company, Custgroup, and Customer's original transactions 
   	b)  	The Transaction DueDate must be <= the DueDateCutOff.
   	c)		Include amounts for all applied transactions of the originals.
   	d)		Do not include payment transactions unless the payment TransDate
   				is <= the PaidDateCutoff. 
   	e)		Exclude or include amounts of applied FinanceChg lines as determined 
   				by the ARCO.FCCalcOnFC setting.
   	f)		Exclude or include invoices containing contracts as determined by
   				the ARCM.ExclContFromFC setting.
   	g)		Exclude invoice if ARTH.ExcludeFC is set to 'Y'
   	h)		For this RECTYPE */
   --	select @amtdue = isnull(((sum(l.Amount) - sum(l.Retainage)) - 
   --					(case when @FCCalcOnFC = 'N' then sum(l.FinanceChg) else 0 end)), 0)
   --				--isnull((sum(l.Amount) - sum(l.Retainage)), 0)			--#20107 TJL
   --	from bARTL l with (nolock)
   --	join bARTH ha with (nolock) on l.ARCo=ha.ARCo and l.ApplyMth=ha.Mth and l.ApplyTrans=ha.ARTrans
   --	join bARTH h with (nolock) on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans
   --	where ha.ARCo = @ARCo and ha.CustGroup = @CustGroup and ha.Customer = @Customer and
   --	((ha.DueDate <= @duedatecutoff and ha.Mth = ha.AppliedMth and ha.ARTrans = ha.AppliedTrans
   --		and (h.ARTransType <> 'P' or (h.ARTransType = 'P' and h.TransDate <= @paiddatecutoff))
   --		--and l.LineType <> (case when @FCCalcOnFC = 'N' then 'F' else '1' end)		--#20107 TJL
   --		and isnull(l.Contract, '') = isnull((case when @excludecontract = 'N' then l.Contract else Null end), '')
   --		and ha.ExcludeFC <> 'Y' and ha.RecType = @rectype)
   --	goto bspexit
   --	end
   
   bspexit:
   
   /* AmtDue, OrigInvAmt, CurrInvAmt are passed back to bspARFinanceChgCalc or
      directly to VB for further consideration and processing. */

GO
GRANT EXECUTE ON  [dbo].[bspARFCAmtDue] TO [public]
GO
