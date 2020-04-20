SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARPmtDetailUpdate    Script Date: 8/28/99 9:34:13 AM ******/
CREATE procedure [dbo].[bspARPmtDetailUpdate]
/***********************************************************
* CREATED BY: JRE  07/11/97
* MODIFIED By : JRE 07/28/97  - insert TransType was missing
*     	bc  08/18/99  - rewrote the insert section and changed the ARLine input to allow null values
*    	GG  04/26/00 - mods for MS
*		TJL 03/28/02 - Issue #16734:  Add Finance Chg UnpaidFC column and ApplyFC Column to grid.
*		TJL 05/13/02 - Issue #17421:  Add Unpaid Tax and Apply Tax Column to grid.
*		TJL 06/05/02 - Issue #17574:  Correct 'INSERT bARBL' section. 
*		TJL 07/30/02 - Issue #11219:  Add Avail TaxDisc and Apply TaxDisc to grid.
*		TJL 03/08/05 - Issue #27335:  Corrected to avoid multiple inserts to bARBL for same Transaction Line 
*		TJL 06/05/08 - Issue #128457:  ARCashReceipts International Sales Tax
*
* USAGE:
*     Only used to update a payment detail line from AR Payment Detail.  Not used by any
*	  other form or procedure.
*
* INPUT PARAMETERS
*     @Co AR Company
*     @Mth Batch Month
*     @BatchId Batch ID
*     @BatchSeq Batch SEQ #
*     @ARLine Line # of the transaction
*     @Amount total amount being applied
*     @Retainage how much of the amount is being applied
*     @DiscTaken how much of the total amount is discount
*     @ApplyMth for about the original invoice
*     @ApplyTrans for about the original invoice
*     @ApplyLine for about the original invoice
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@Co bCompany,@Mth bMonth,@BatchId bBatchID,@BatchSeq int,@ARLine smallint = null,
	@Amount bDollar, @TaxAmount bDollar, @Retainage bDollar, @FinanceChg bDollar, @DiscTaken bDollar, 
	@TaxDisc bDollar, @ApplyMth bMonth, @ApplyTrans bTrans, @ApplyLine smallint, 
	@RetgTax bDollar, @errmsg varchar(255) output)
as
set nocount on
declare @rcode int, @errortext varchar(255), @source bSource, @tablename char(20), 
	@artranstype char(1)

select @rcode = 0

/* UPDATE the transaction - This is what occurs 90% of the time.  Typically a user has
  input a value at the CashReceipts Grid, which runs ARAutoApplyLine, which places values
  in bARBL before the ARPmtDetailForm opens.  Therefore by the time any adjustments are
  made, the line already exists and this UPDATE Occurs. Likewise, any transaction added
  back into the batch for change or delete will result in this UPDATE */
if exists(select 1 from bARBL with (nolock) where Co = @Co and Mth = @Mth and BatchId = @BatchId and BatchSeq = @BatchSeq
   	and ApplyMth = @ApplyMth and ApplyTrans = @ApplyTrans and ApplyLine = @ApplyLine)
   	begin
  	update bARBL
  	set Amount=@Amount, TaxAmount=@TaxAmount, Retainage=@Retainage, RetgTax = @RetgTax,
		DiscTaken=@DiscTaken, FinanceChg=@FinanceChg, TaxDisc=@TaxDisc
  	where Co = @Co and Mth = @Mth and BatchId = @BatchId and BatchSeq = @BatchSeq 
		and ApplyMth = @ApplyMth and ApplyTrans = @ApplyTrans and ApplyLine = @ApplyLine
  	if @@rowcount=0
    	begin
    	select @errmsg='Cash Line could not be updated', @rcode=1
    	goto bspexit
    	end
   	end
else
/* INSERT the transaction - Until Issue #17574, this never occurred.  The form would not allow a
   user to enter the ARPmtDetail form without an applied amount on the grid, triggering the above
   set of events.  As of Issue #17574, user may enter the ARPmtDetail form when TotalApplied is 0.00
   and so no bARBL lines will exist and a new line will be inserted.  */
 	begin 
 	select @ARLine = isnull(max(ARLine),0) + 1
 	from bARBL
 	where Co=@Co and Mth=@Mth and BatchId=@BatchId and BatchSeq=@BatchSeq

 	insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, RecType, LineType,
	Description, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, 
		FinanceChg,	DiscOffered, TaxDisc, DiscTaken, ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, ContractUnits,
		Job, PhaseGroup, Phase, CostType, UM, JobUnits, JobHours, ActDate, INCo, Loc, MatlGroup, Material,
		UnitPrice, ECM, MatlUnits, CustJob, CustPO, EMCo, Equipment, EMGroup, CostCode, EMCType)
	select ARCo, @Mth, @BatchId, @BatchSeq, @ARLine, 'A', RecType, LineType, Description,
		GLCo, GLAcct, TaxGroup, TaxCode, @Amount, 0, @TaxAmount, 0, @Retainage, @RetgTax,
		@FinanceChg, 0, @TaxDisc, @DiscTaken, @ApplyMth, @ApplyTrans, @ApplyLine, JCCo, Contract, 
		Item, null,	Job, PhaseGroup, Phase, CostType, UM, null, null, ActDate, INCo, Loc, 
		MatlGroup, Material, UnitPrice, ECM, null, CustJob, CustPO, EMCo, Equipment, EMGroup,
		CostCode, EMCType
 	from ARTL
 	where ARCo=@Co and Mth=@ApplyMth and ARTrans=@ApplyTrans and ARLine=@ApplyLine

 	if @@rowcount=0
   		begin
   		select @errmsg='Cash Line could not be inserted', @rcode=1
   		goto bspexit
   		end
 	end

bspexit:
if @rcode<>0 select @errmsg=@errmsg	--+ char(13) + char(10) + '[bspARPmtDetailUpdate]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARPmtDetailUpdate] TO [public]
GO
