SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARPurgeBalanceForward    Script Date: 8/28/99 9:36:08 AM ******/
 CREATE  proc [dbo].[bspARPurgeBalanceForward]
 /******************************************************
  * CREATED BY	: CJW 10/31/97
  * MODIFIED By	: CJW 10/31/97
  *				  DANF 10/12/06 # 122740 Correct Insert statement into ARTL
  *
  * USAGE:
  *
  *
  * INPUT PARAMETERS
  *   ARCo
  * OUTPUT PARAMETERS
  *   @errmsg
  *
  * RETURN VALUE
  *   returns - not sure yet
  *
  *****************************************************/
 (@arco bCompany=null, @ThroughMth bMonth=null, @InvDate bMonth, @DueDate bMonth,
  @BeginningCustomer bCustomer = null, @EndingCustomer bCustomer = null,
  @OnlyPaidAccounts bYN, @errmsg varchar(255) output)
 as
 set nocount on
 declare @rcode int, @CustGroup bGroup, @Customer bCustomer, @ARLine smallint, @ApplyMth bMonth, @ARTrans bTrans,
 		@CustContFlag int, @sum int, @MaxMth bMonth, @LastClosedMth bMonth, @tmpCo bCompany, @balance bDollar, @CustCount int,
 		@SumInvoiced bDollar, @SumRetainage bDollar, @SumDiscTaken bDollar, @SumPaid bDollar, @Mth bDate, @NewTrans bTrans,
 		@MaxHighestCredit bDollar, @SumNumInvPaid smallint, @MaxLastInvDate bDate, @MaxLastPayDate bDate,
 		@SumPayDaysTrDt int, @SumPayDaysDueDt int, @TempYN bYN, @SelPurge bYN, @NetRetg bDollar, @NetInv bDollar, @NetDiscTaken bDollar,
 		@errortext bDesc, @NewInvoice varchar(10)
 select @rcode = 0
 IF @arco is null
 	begin
 	select @rcode=1,@errmsg='AR Company is missing'
 	goto bspexit
 	end
 IF @ThroughMth is null
 	begin
 	select @rcode=1,@errmsg='AR Month is missing'
 	goto bspexit
 	end
 /* Get last closed mth from GLCo */
 select @LastClosedMth = g.LastMthGLClsd from bARCO a join bGLCO g on g.GLCo = a.GLCo where a.ARCo = @arco
 /* Spin through groups*/
 select @CustGroup = min(bARCM.CustGroup) from bARCM
 while @CustGroup is not null
    begin
 	/* Spin through customers*/
 	select @Customer = min(m.Customer) from bARCM m where m.Customer >= @BeginningCustomer and m.Customer <= @EndingCustomer
 					 and m.CustGroup = @CustGroup and m.StmtType = 'B' and m.SelPurge = 'N'
 	while @Customer is not null
 	   begin
 	      begin transaction
 	      /* Need to check balance if necessary */
 	      /* If Yes, then only pruge transactions where the customer's total nets to zero. */
 	      if @OnlyPaidAccounts = 'Y'
 	      begin
 	         select @balance = isnull(sum(Invoiced),0) - isnull(sum (Retainage),0) - isnull(sum(Paid),0) - isnull(sum(DiscountTaken),0)
 				from bARMT
 				where ARCo = @tmpCo and CustGroup = @CustGroup and Customer = @Customer
 				group by ARCo, CustGroup, Customer
 		if @balance <> 0 goto GetNextCustomer
 	      end
 		/*Spin through Months*/
 		select @Mth = min(h.Mth) from bARTH h where h.ARCo = @arco
 		while @Mth is not null
 		    begin
 			/*Spin through Transactions */
 			select @ARTrans = min(h.ARTrans) from bARTH h where h.ARCo = @arco and h.Mth = @Mth
 			while @ARTrans is not null
 			begin
 			   /* Check apply to transactions to see if apply to transaction > purge mth */
 		           if (select count(*) from bARTH
 			      join bARTL on bARTH.ARCo = bARTL.ARCo and bARTH.Mth = bARTL.Mth and bARTH.ARTrans = bARTL.ARTrans
 			      where bARTL.ApplyMth > @ThroughMth and bARTL.ApplyTrans = @ARTrans ) <> 0 goto GetNextTransaction
 			   /* Need to total Retainage and Invoice amount for balance forward entry */
 			   Select @NetRetg = isnull(sum(l.Retainage),0), @NetInv = isnull(sum(l.Amount),0)
 				 from bARTL l where l.ARCo = @arco and l.Mth = @Mth and l.ARTrans = @ARTrans
 			   /* START DELETION PROCESS if all conditions are met */
 			   delete bARTL where bARTL.ARCo = @arco and bARTL.Mth = @Mth and bARTL.ARTrans = @ARTrans
 			   delete bARTH where bARTH.ARCo = @arco and bARTH.Mth = @Mth and bARTH.ARTrans = @ARTrans
 			GetNextTransaction:
 			select @ARTrans = min(h.ARTrans) from bARTH h where h.ARCo = @arco and h.Mth = @Mth and h.ARTrans > @ARTrans
 			end
 		    GetNextMth:
 		    select @Mth = min(h.Mth) from bARTH h where h.ARCo = @arco and h.Mth > @Mth
 		    end
 		    /* Need to add balance forward transaction */
 	            if isnull(@NetRetg,0) <> 0 and isnull(@NetInv,0) <> 0
 	               begin
 			  /*Get a transaction number */
 		          exec @NewTrans = bspHQTCNextTrans bARTH, @arco, @InvDate, @errmsg output
   			  if @NewTrans = 0
 	      		  begin
 	         	     select @errortext = 'Unable to retreive AR Transaction number!'
 	         	     exec @rcode = bspHQBEInsert @arco, @InvDate, @errortext, @errmsg output
 			     goto bspexit
 	       		  end
 			  /* Get a invoice number */
 			  select @NewInvoice = convert(varchar(10),InvLastNum+1) from bARCO where ARCo = @arco
 			  insert into bARTH(ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer,
 				Invoice, Source, TransDate, DueDate, Description, Retainage, PurgeFlag,
 				EditTrans, DiscTaken, AmountDue)
 			  values (@arco, @InvDate, @NewTrans, 'I', @CustGroup, @Customer,
 				@NewInvoice, 'AR', @InvDate, @DueDate, 'Balance Forward', @NetRetg, 'Y',
 				'Y', @NetDiscTaken, @balance)
 			  /* Insert a line that applies to itselef */
 			  insert into bARTL(ARCo, Mth, ARTrans, ARLine, LineType, Description,
 				Amount, TaxBasis, TaxAmount, Retainage, DiscTaken, ApplyMth, ApplyTrans, ApplyLine)
 			  values (@arco, @InvDate, @NewTrans, 1, 'I', 'Balance Forward',
 				@balance, 0, 0, @NetRetg, @NetDiscTaken, @InvDate, @NewTrans, 1)
 		       end
 		       commit transaction
         GetNextCustomer:
 	  select @Customer = min(m.Customer) from bARCM m where m.Customer >= @BeginningCustomer and m.Customer <= @EndingCustomer
 		and m.CustGroup = @CustGroup and m.Customer > @Customer
 	  if @@rowcount = 0 select @Customer = NULL
       end
 GetNextGroup:
 select @CustGroup = min(bARCM.CustGroup) from bARCM where bARCM.CustGroup > @CustGroup
 if @@rowcount = 0 select @CustGroup = null
 end
 bspexit:
 if @rcode<>0 select @errmsg=@errmsg	--+ char(13) + char(13) + '[bspARPurgeBalanceForward]'
 return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARPurgeBalanceForward] TO [public]
GO
