SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspARFCAmtDueLineForInvoice]
   (@ARCo bCompany, @CustGroup bGroup, @Customer bCustomer, @applymth bMonth, @ARTrans bTrans, 
   	@ARLine int, @duedatecutoff bDate = null, @paiddatecutoff bDate = null, @display bYN = null,
   	@amtdueline bDollar output, @linedesc varchar(30) output)
   
   /*******************************************************************************************
   * CREATED BY: 	TJL 05/30/01
   * Modified By:	TJL 07/17/01  Corrected calculation not to include negative @DiscTaken in @AmtDue calculations
   *						and not to include payments made on finance charges if ARCO flag set to 'N'
   *		TJL 03/05/02 - Issue #14171, Performance modifications.
   *		TJL 02/17/03 - Issue #20107, Use FinanceChg column to determine @amtdue rather than 'F' LineType
   *		TJL 02/04/04 - Issue #23642, During review of this issue, added "with (nolock)" thru-out
   *
   *
   * USAGE:
   * 	This procedure calculates the amount due for each line of an invoice in manual calculate
   *	or calculates all amount dues for each line of a batch of invoices by customer in automatic calculate
   *
   * INPUT PARAMETERS:
   * 	@ARCo, @ApplyMth, @ARTrans, @ARLine
   *	@duedatecutoff is current date only when used for totalling the amount due for the line for display only
   *	@duedatecutoff is generally null here during line processing
   *	@paiddatecutoff is used to remove payments made after cutoff date from total of each line
   *
   * OUTPUT PARAMETERS:
   *	@amtdueline after filters have been applied
   *	Error message
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   ********************************************************************************************/
   as
   set nocount on
   
   /* declare working variables */
   declare	@hARTransType char(1), @hTransDate bDate, @FCCalcOnFC char(1), @rcode int
   
   select @rcode = 0
   
   /* Dont bother calculating without transaction information */
   If @applymth is null or @ARTrans is null or @ARLine is null goto bspexit
   
   If @duedatecutoff is null
   	begin
   	select @duedatecutoff = getdate()
   	end
   If @paiddatecutoff is null
   	begin
   	select @paiddatecutoff = getdate()
   	end
   
   /* Do we want to include Finance Charges in the Finance Charge calculations? */
   select @FCCalcOnFC=FCCalcOnFC from bARCO with (nolock) where ARCo=@ARCo
   
   /* Calculate AmtDue for a each Line */
   select @amtdueline = isnull(((sum(l.Amount) - sum(l.Retainage)) - 
   					(case when @FCCalcOnFC = 'N' then sum(l.FinanceChg) else 0 end)), 0)
   			--isnull((sum(l.Amount) - sum(l.Retainage)), 0)			--#20107 TJL
   from bARTL l with (nolock)
   join bARTH h with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
   where l.ARCo = @ARCo 
   	and l.ApplyMth = @applymth and l.ApplyTrans = @ARTrans and l.ApplyLine = @ARLine
   	--and l.LineType <> (case when @FCCalcOnFC = 'N' then 'F' else '1' end)		--#20107 TJL
   	and (h.ARTransType <> 'P' or (h.ARTransType = 'P' and h.TransDate <= @paiddatecutoff))
   
   /* Only run when VB users cycles through Lines to redisplay Line description. 
      Retrieve description from original line.*/
   if @display = 'Y'
   	begin
   	select @linedesc = Description
   	from bARTL with (nolock)
   	where ARCo = @ARCo and ApplyMth = @applymth and ApplyTrans = @ARTrans and ApplyLine = @ARLine
   		and Mth = ApplyMth and ARTrans = ApplyTrans and ARLine = ApplyLine
   	end
   
   bspexit:
   /* amtdueline and linedesc are passed back to bspARFinanceChgCalc or
      directly to VB for further consideration and processing. */

GO
GRANT EXECUTE ON  [dbo].[bspARFCAmtDueLineForInvoice] TO [public]
GO
