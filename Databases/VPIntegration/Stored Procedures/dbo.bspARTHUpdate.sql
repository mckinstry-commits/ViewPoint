SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARTHUpdate    Script Date: 8/28/99 9:34:15 AM ******/
CREATE proc [dbo].[bspARTHUpdate] 
/*--------------------------------------------------------------
*  Created By: 	JRE  5/15/97
*  Modified By:	bc 8/12/98 for Misc Cash purposes
* 		GH 03/12/99 -  Added isnull to PayDaysDueDate, and PayDaysTrDate as a customer
*               		was having problems inserting value NULL into PayDaysDueDt in ARMT.
*		GG 10/17/01 - #14186 - removed holdlock on ARTH to prevent deadlocks
*		TJL 02/27/02 - Issue #14171, Update new column bARTH.FinanceChg with line amounts
*		TJL 05/01/03 - Issue #20936, Reverse Release Retainage
*		gf 07/15/2003 - issue #21828 - performance improvements with nolocks
*		TJL 07/28/04 - Issue #25123, Do not NULL out PayFullDate on invoice from which retg is released
*		
*
*  USAGE:
*	Called by the ARTL triggers to update amounts in ARTH
*
*  INPUTS:
*	@ARCo			AR Company
*	@Mth			Month
*	@CustGroup		Customer Group
*	@Customer		Customer #
*	@Amount			Line total amount
*	@Retainage		Line retainage amount
*	@FinanceChg		Line finance charge amount
*	@DiscTaken		Line discount taken amount
*	@ARTransType	Transaction type
*	@TransDate		Transaction date
*	@ApplyMth		Apply month
*	@ApplyTrans		Apply transaction #
*
*  OUTPUT:
*	@errmsg			Error message
*
*  RETURN CODES:
*	0				Success
*	1				Failure
*--------------------------------------------------------------*/
(@ARCo bCompany, @Mth bMonth, @CustGroup bGroup, @Customer bCustomer,
    @Amount bDollar, @Retainage bDollar, @FinanceChg bDollar, @DiscTaken bDollar,
    @ARTransType char(1), @TransDate bDate, @ApplyMth bMonth, @ApplyTrans bTrans, 
    @errmsg varchar(255) output)
as
set nocount on

declare @numrows int, @validcnt int, @validcnt2 int, @rcode int,
	@HighestCredit bDollar,@LastInvDate bDate,@LastPayDate bDate,
	@Invoiced bDollar,@Paid bDollar,@ApplyDiscTaken bDollar,
	@AmountDue bDollar,@PrevAmtDue bDollar,@PayFullDate bDate,@ApplyARTransType char(1),
	@PrevPayFullDate bDate, @NumInvPaid int,@ApplyTransDate bDate,@ApplyDueDate bDate,
	@PayDaysTrDate int, @PayDaysDueDate int
   
select @rcode=0

IF @ARCo IS NULL BEGIN select @errmsg='Company may not be null',@rcode=1 GOTO bspexit END
IF @Mth IS NULL BEGIN select @errmsg='Mth may not be null',@rcode=1 GOTO bspexit END
IF @CustGroup IS NULL BEGIN select @errmsg='CustGroup may not be null',@rcode=1 GOTO bspexit END
IF @ARTransType <> 'M' AND @Customer IS NULL BEGIN select @errmsg='Customer may not be null',@rcode=1 GOTO bspexit END
IF @Amount IS NULL BEGIN select @errmsg='Invoiced may not be null',@rcode=1 GOTO bspexit END
IF @Retainage IS NULL BEGIN select @errmsg='Retainage may not be null',@rcode=1 GOTO bspexit END
IF @FinanceChg IS NULL BEGIN select @errmsg='Finance Charge may not be null',@rcode=1 GOTO bspexit END
IF @DiscTaken IS NULL BEGIN select @errmsg='DiscTaken may not be null',@rcode=1 GOTO bspexit END
IF @ARTransType IS NULL BEGIN select @errmsg='ARTransType may not be null',@rcode=1 GOTO bspexit END
IF @TransDate IS NULL BEGIN select @errmsg='TransDate may not be null',@rcode=1 GOTO bspexit END
IF @ApplyMth IS NULL BEGIN select @errmsg='ApplyMth may not be null',@rcode=1 GOTO bspexit END
IF @ApplyTrans IS NULL BEGIN select @errmsg='ApplyTrans may not be null',@rcode=1 GOTO bspexit END
   
/* Set initial values */
select @LastInvDate=null, @LastPayDate=null
   
if @ARTransType in ('P','M')
   	select @Invoiced=0, @Paid=-@Amount, @DiscTaken=-@DiscTaken, @LastPayDate=@TransDate
else
   	select @Invoiced=@Amount, @Paid=0, @DiscTaken=@DiscTaken, @LastInvDate=case @ARTransType when 'I' then @TransDate else null end
   
/* get the previous amount due so we can compare to the current amount due
  if the invoice is now fully paid we can then add to ARMT NumInvPaid */
select @AmountDue=AmountDue+@Invoiced-@Retainage-@Paid,
   @PrevAmtDue=AmountDue,
   @ApplyARTransType=ARTransType,
   @PrevPayFullDate=PayFullDate,
   @ApplyTransDate=TransDate,
   @ApplyDueDate=DueDate
from bARTH with (nolock)
where ARCo=@ARCo and Mth=@ApplyMth and ARTrans=@ApplyTrans
   
if @ARTransType not in ('V') and @PrevAmtDue<>0 and @AmountDue=0
   	begin
   	/* This is final payment or Adjustment/Credit and invoice is now paid in full, set PayFullDate */
   	select @PayFullDate=Max(bARTH.TransDate) 
   	from bARTL with (nolock)
   	join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
   	where bARTL.ARCo=@ARCo and bARTL.ApplyMth=@ApplyMth and bARTL.ApplyTrans=@ApplyTrans
   	end
Else
   /* At this point 
   	1) We have a new @PayFullDate value if the Invoice just went from AmtDue <> 0 to AmtDue = 0 (Just got paid)
       2) We will later have a NULL @PayFullDate if the Invoice still has an AmtDue <> 0 (Still has a balance)
   
      However, if this invoice was previously paid in full, then at this point, @PayFullDate is currently
      NULL (not set) but needs to be equal to @PrevPayfullDate so that the following update statement doesn't reset
      this PaidFull invoice PaidFullDate back to NULL */
	begin
   	/* This was previously Paid and is still Paid so keep PrevPayFullDate during next update statement */ 
   	if @PrevPayFullDate is not NULL and @PrevAmtDue = 0 and @AmountDue = 0	
   		begin
   		select @PayFullDate = @PrevPayFullDate
   		end
   	end
   
/* If this invoice is not Paid Full at this point, then @PayFullDate must be NULL */
if @AmountDue <> 0 select @PayFullDate=null
   
update bARTH
set Invoiced=Invoiced+@Invoiced,
	Paid=Paid+@Paid,
	Retainage=Retainage+@Retainage,
	FinanceChg=FinanceChg+@FinanceChg,
	DiscTaken=DiscTaken+@DiscTaken,
	AmountDue=AmountDue+@Invoiced-@Retainage-@Paid,
	PayFullDate=@PayFullDate
from bARTH with (ROWLOCK)
where ARCo=@ARCo and Mth=@ApplyMth and ARTrans=@ApplyTrans
   
/* ARMT Calculations */
IF @ARTransType <> 'M'  -- Misc Cash Receipts has no customer
   	Begin
   	select @NumInvPaid=0, @PayDaysTrDate=0,@PayDaysDueDate=0
   	if @ApplyARTransType in ('I','R','F')
   		begin
   		if @PrevPayFullDate is not null and @PayFullDate is null
   		select @NumInvPaid=-1,
   			@PayDaysTrDate=isnull(DATEDIFF(day,  @PrevPayFullDate,@ApplyTransDate),0),
   			@PayDaysDueDate=isnull(DATEDIFF(day, @PrevPayFullDate,@ApplyDueDate),0)
   
   		if @PrevPayFullDate is null and @PayFullDate is not null
   		select @NumInvPaid=1,
   			@PayDaysTrDate=isnull(DATEDIFF(day,@ApplyTransDate, @PayFullDate),0),
   			@PayDaysDueDate=isnull(DATEDIFF(day,@ApplyDueDate, @PayFullDate),0)
   		end
   
   	/* insert new ARMT record IF it does not exist */
   	if not exists(select top 1 1 from bARMT with (nolock) where ARCo=@ARCo AND Mth=@Mth 
   			AND CustGroup=@CustGroup AND Customer=@Customer)
   		begin
   		insert into bARMT(ARCo, Mth, CustGroup, Customer,Invoiced, Retainage, FinanceChg,
   				Paid, DiscountTaken, NumInvPaid, PayDaysTrDt, PayDaysDueDt, LastInvDate, LastPayDate)
   		select @ARCo, @Mth, @CustGroup, @Customer, @Invoiced, @Retainage, @FinanceChg,
   				@Paid, @DiscTaken, @NumInvPaid, @PayDaysTrDate, @PayDaysDueDate, @LastInvDate, @LastPayDate
       	end
   	else
   		begin
   		/* UPDATE it */
   		update bARMT
   		set Invoiced=Invoiced+@Invoiced,
   			Retainage=Retainage+@Retainage,
   			FinanceChg=FinanceChg+@FinanceChg,
   			Paid=Paid+@Paid,
   			DiscountTaken=DiscountTaken+@DiscTaken,
   			LastInvDate= case when @LastInvDate IS NULL then LastInvDate
   				when LastInvDate IS NULL then @LastInvDate
   				when LastInvDate<@LastInvDate then @LastInvDate
   				else LastInvDate end,
   			LastPayDate= case when @LastPayDate IS NULL then LastPayDate
   				when LastPayDate IS NULL then @LastPayDate
   				when LastPayDate<@LastPayDate then @LastPayDate
   				else LastPayDate end,
   			PayDaysTrDt=PayDaysTrDt+@PayDaysTrDate,
   			PayDaysDueDt=PayDaysDueDt+@PayDaysDueDate,
   			NumInvPaid=NumInvPaid+@NumInvPaid
   		from bARMT with (ROWLOCK)
   		where ARCo=@ARCo AND Mth=@Mth AND CustGroup=@CustGroup AND Customer=@Customer
   		end
   
/* now update hi credit */
select @HighestCredit=sum(bARMT.Invoiced-bARMT.Retainage-bARMT.Paid)
from bARMT with (nolock)
where ARCo=@ARCo AND Mth<=@Mth AND CustGroup=@CustGroup AND Customer=@Customer
   
update bARMT
set HighestCredit=@HighestCredit
where ARCo=@ARCo AND Mth=@Mth AND CustGroup=@CustGroup AND Customer=@Customer AND HighestCredit<@HighestCredit
   
End -- when not type 'M'
   
bspexit:
if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARTHUpdate]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARTHUpdate] TO [public]
GO
