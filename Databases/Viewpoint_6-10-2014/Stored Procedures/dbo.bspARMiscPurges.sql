SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARMiscPurges    Script Date: 8/28/99 9:34:13 AM ******/
   CREATE  proc [dbo].[bspARMiscPurges]
   /*****************************************************************************************************************
    * CREATED: CJW 09/10/97
    * MODIFIED: CJW 09/10/97
    *			TJL  08/30/01 - Issue #13942, Removed the option to remove Temporary Customers here, ARPURGEMISC. Now done in ARPURGEPAIDINV
    *						Corrected Purge Customer Monthly Totals.  Added RollBack feature in event of error.
    *			TJL  02/27/02 - Issue #14171, Modify to properly sum and total the ARMT.FinanceChg column when rolling
    *						up all values during Monthly Totals purge. 
    *			GG 02/22/08 - #120107 - separate sub ledger close - use AR close month			
    *
    * USAGE:
    *
    *  User may rollup detailed monthly total transactions into a single entry representing
    *  totals for the period to be rolled up, thereby reducing disc usage.
    *  User may remove Misc Cash Receipt or Misc Distributions for a given company
    *  for a given period of time.  These transactions are not summarized.
    *
    * INPUT PARAMETERS
    *  @arco							ARCo
    *  @BeginningCustomer and @EndingCustomer			Not Currently in Use
    *  @CustomerTotals, @CashReceipts and @Distributions Flags	To indicate an action to take
    *  @CustThroughMth, @CashThroughMth, @DistThroughMth	Through month to purge
    *
    * OUTPUT PARAMETERS
    *   @errmsg
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *
    ****************************************************************************************************************/
   
   (@arco bCompany=null,
    @BeginningCustomer bCustomer = null, @EndingCustomer bCustomer = null,
    @CustomerTotals bYN = 'N', @CustThroughMth bMonth = null,
    @CashReceipts bYN = 'N', @CashThroughMth bMonth = null,
    @Distributions bYN = 'N', @DistThroughMth bMonth = null,
    @errmsg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @CustGroup bGroup, @Customer bCustomer, @LastClosedMth bMonth,
   		@SumInvoiced bDollar, @SumRetainage bDollar, @SumDiscTaken bDollar, @SumPaid bDollar,
   		@MaxHighestCredit bDollar, @SumNumInvPaid smallint, @MaxLastInvDate bDate, @MaxLastPayDate bDate,
   		@SumPayDaysTrDt int, @SumPayDaysDueDt int, @topurge int, @topurge2 int, @deleted int, @deleted2 int,
   		@inserted tinyint, @SumFinanceChg bDollar
   
   select @rcode = 0, @topurge = 0, @topurge2 = 0, @deleted = 0, @deleted2 = 0, @inserted = 0
   IF @arco is null
   	begin
   	select @rcode=1,@errmsg='AR Company is missing'
   	goto error
   	end
   
   if @CustomerTotals = 'Y' and @CustThroughMth is null
   	begin
   	select @rcode = 1, @errmsg = 'Customer through month is missing.'
   	goto error
   	end
   
   if @CashReceipts = 'Y' and @CashThroughMth is null
   	begin
   	select @rcode =1, @errmsg = 'Cash receipts through month is missing.'
   	goto error
   	end
   
   if @Distributions = 'Y' and @DistThroughMth is null
   	begin
   	select @rcode = 1, @errmsg = 'Distribution through month is missing.'
   	goto error
   	end
   
   /* Get last closed mth from GLCo */
   select @LastClosedMth = g.LastMthARClsd	-- #120107 - use AR close month 
   from bARCO a
   join bGLCO g on g.GLCo = a.GLCo
   where a.ARCo = @arco
   
   /* Delete Monthly Customer Totals */
   if @CustomerTotals = 'Y'
   BEGIN
   select @CustGroup = null, @Customer = null
   
   if @CustThroughMth > @LastClosedMth
   	begin
   	select @rcode = 1, @errmsg = 'Customer Totals Through Month may not be greater than AR Closed Month.'
   	goto error
   	end
   
   /* Spin through groups*/
   select @CustGroup = min(bARCM.CustGroup) from bARCM
   while @CustGroup is not null
      	begin
   	/* Spin through customers*/
   	select @Customer = min(bARCM.Customer)
   	from bARCM
   	join bARMT on bARMT.CustGroup = bARCM.CustGroup and bARMT.Customer = bARCM.Customer
   	where  bARCM.CustGroup = @CustGroup and bARMT.ARCo = @arco
   	while @Customer is not null
   		begin
   		select @topurge = 0, @deleted = 0, @inserted = 0
     		/*Need to get amount that we are going to delete so that we can add a summary line to bARMT*/
         	select @topurge = count(*), @SumInvoiced =isnull(sum(Invoiced),0),
         			@SumRetainage= isnull(sum(Retainage),0), @SumPaid = isnull(sum(Paid),0),
         		   	@SumDiscTaken = isnull(sum(DiscountTaken),0), @MaxHighestCredit = isnull(max(HighestCredit),0),
         		   	@SumNumInvPaid = isnull(sum(NumInvPaid),0), @SumPayDaysTrDt = isnull(sum(PayDaysTrDt),0),
         		   	@SumPayDaysDueDt = isnull(sum(PayDaysDueDt),0), @MaxLastInvDate = max(LastInvDate),
         		   	@MaxLastPayDate = max(LastPayDate), @SumFinanceChg= isnull(sum(FinanceChg),0)
         	from bARMT
         	where ARCo = @arco and CustGroup = @CustGroup and Customer = @Customer and Mth <= @CustThroughMth
   		if @topurge > 0
   			begin
   	   		begin transaction
      			delete bARMT
      			where ARCo = @arco and CustGroup = @CustGroup and Customer = @Customer and Mth <= @CustThroughMth
   			select @deleted = @@rowcount
   
   			/* Insert the summary line for amounts calculated above */
   			insert into bARMT(ARCo, Mth, CustGroup, Customer, Invoiced, Retainage, Paid, DiscountTaken,
   				HighestCredit, NumInvPaid, PayDaysTrDt, PayDaysDueDt, LastInvDate, LastPayDate, FinanceChg)
     			values(@arco, @CustThroughMth, @CustGroup, @Customer, isnull(@SumInvoiced,0),isnull(@SumRetainage,0),
   				isnull(@SumPaid,0),isnull(@SumDiscTaken,0), isnull(@MaxHighestCredit,0), isnull(@SumNumInvPaid,0),
   				@SumPayDaysTrDt, @SumPayDaysDueDt, @MaxLastInvDate, @MaxLastPayDate, isnull(@SumFinanceChg,0))
   			select @inserted = @@rowcount
   
   			if @topurge <> @deleted or @inserted <> 1
   				begin
   				rollback transaction
   				select @rcode = 1, @errmsg = 'An error has occurred! Customer #'
   				select @errmsg = @errmsg + convert(varchar(10),@Customer) + ' not purged! Begin with next customer.'
   				goto error
   				end
   
   			commit transaction
   		    end
   
   		NextCustomer:
   		select @Customer = min(bARCM.Customer)
   		from bARCM
   		join bARMT on bARMT.CustGroup = bARCM.CustGroup and bARMT.Customer = bARCM.Customer
   		where  bARCM.CustGroup = @CustGroup and bARMT.ARCo = @arco and bARCM.Customer > @Customer
   
     		if @@rowcount = 0 select @Customer = null
           end	/* END CUSTOMER LOOP */
   
   	NextGroup:
   	select @CustGroup = min(bARCM.CustGroup) from bARCM where bARCM.CustGroup > @CustGroup
   	if @@rowcount = 0 select @CustGroup = null
   	end	/* END CUSTGROUP LOOP */
   END	/* END CUSTOMER MONTHLY TOTALS PURGE */
   
   /* Delete the Miscellaneous cash receipts */
   if @CashReceipts = 'Y'
   BEGIN
   
   if @CashThroughMth > @LastClosedMth
   	begin
   	select @rcode = 1, @errmsg = 'Misc Cash Receipt Through Month may not be greater than Subledger Closed Month.'
   	goto error
   	end
   
   	begin transaction
   	select @topurge = 0, @topurge2 = 0, @deleted = 0, @deleted2 = 0
   
   	select @topurge = count(*)
   	from bARTL l
   	join bARTH h on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
   	where l.ARCo = @arco and l.Mth <= @CashThroughMth and h.ARTransType in ('M')
   
   	delete bARTL
   	from bARTL l
   	join bARTH h on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
   	where l.ARCo = @arco and l.Mth <= @CashThroughMth and h.ARTransType in ('M')
   	select @deleted = @@rowcount
   
   	select @topurge2 = count(*)
   	from bARTH
   	where ARCo = @arco and Mth <= @CashThroughMth and ARTransType in ('M')
   
   	delete bARTH where ARCo = @arco and Mth <= @CashThroughMth and ARTransType in ('M')
   	select @deleted2 = @@rowcount
   
   	if @topurge <> @deleted or @topurge2 <> @deleted2
   		begin
   		rollback transaction
   		select @rcode = 1, @errmsg = 'An error has occurred. Misc Cash Receipts not purged! Begin again.'
   		goto error
   		end
   
   	commit transaction
   END
   
   /* Delete Misc Distributions */
   if @Distributions = 'Y'
   BEGIN
   
   if @DistThroughMth > @LastClosedMth
   	begin
   	select @rcode = 1, @errmsg = 'Misc Distributions Through Month may not be greater than Subledger Closed Month.'
   	goto error
   	end
   
   	begin transaction
   	select @topurge = 0, @deleted = 0
   
   	select @topurge = count(*)
   	from bARMD
   	where ARCo = @arco and Mth <= @DistThroughMth
   
   	delete bARMD
   	where ARCo = @arco and Mth <= @DistThroughMth
   	select @deleted = @@rowcount
   
   	if @topurge <> @deleted
   		begin
   		rollback transaction
   		select @rcode = 1, @errmsg = 'An error has occurred. Misc Distributions not purged! Begin again.'
   		goto error
   		end
   
   	commit transaction
   END
   
   error:
   if @rcode<>0 select @errmsg=@errmsg	--+ char(13) + char(10) + '[bspARMiscPurges]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARMiscPurges] TO [public]
GO
