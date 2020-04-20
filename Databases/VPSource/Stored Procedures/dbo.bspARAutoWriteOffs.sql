SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARAutoWriteOffs    Script Date: 01/29/02 11:36:41 AM ******/
   
   CREATE proc [dbo].[bspARAutoWriteOffs]
   
   /********************************************************
   * CREATED BY: 	TJL 1/29/02
   * MODIFIED BY:	TJL 04/08/02	Changes due to New FinanceChg column. 
   *		TJL 07/21/03 - Issue #21890, Performance Mods - Add (with (nolocks)
   *		TJL 09/11/03 - Issue #22435, Add write offs by Invoice Number
   *		TJL 10/31/03 - Issue #22898, Allow for Partial Finance Charge WriteOffs
   *		TJL 12/29/04 - Issue #26044, Use Line RecType for On-Account WriteOff RecType
   *		TJL 06/27/05 - Issue #29151, Correct Issue #26044
   *		TJL 08/31/06 - Issue #30635, Replace Table Variable with Temporary Table for speed.
   *		TJL 01/11/07 - Issue #28307, 6x Recode.  Give indication if at least one Write-Off record was generated.
   *		TJL 02/28/08 - Issue #125289:  Remove unposted batch values from consideration
   *		GF 09/05/2010 - issue #141031 changed to use function vfDateOnly
   *
   *
   * USAGE:
   * 	Automatically create writeoff entries for transactions older
   *	than a given date.  WriteOff amount can be based on Finance
   *	Charge amounts, or Invoice balances, or Account balances.
   *	This stored procedure is called from ARWriteOffAuto from within
   *	ARInvoiceEntry.
   *
   * INPUT PARAMETERS:
   *   @ARCo,@BatchMth,@BatchId
   *   @OlderThanDate - Transactions involved will be older than this date
   *	@CustGroup
   *   @BeginCust and @EndCust
   *	@BeginInvoice and @EndInvoice
   *   @WrtOffOpt - Either by Finance Charge, Min Invoice Bal or Min Acct Bal
   *	@MinBal - Min Invoice or Acct Balance to use. (By Invoice, By Account)
   *	@MinBal - Partial FC Amount or Percent to writeoff. (By FinChg)
   *
   * OUTPUT PARAMETERS:
   *	Error message
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@ARCo bCompany= null, @BatchMth bMonth= null, @BatchId bBatchID= null,
   @OlderThanDate bMonth= null, @CustGroup bGroup= null, @BeginCust bCustomer,
   @EndCust bCustomer, @BeginInvoice varchar(10) = null, @EndInvoice varchar(10) = null,
   @WrtOffOpt varchar(10) = null, @fcpctYN_all bYN, @fcpctYN_amt bYN, @MinBal bDollar, 
   @AtLeastOneRecAddedYN bYN output, @msg varchar(255) output)
   
   AS
   
   set nocount on
   
   /* Variables related to bARTH */
   declare @applymth bMonth, @applytrans bTrans, @customer bCustomer,
   	@rectype int, @acctrectype int, @postrectype int,@JCCo bCompany,  
   	@contract bContract, @invoicenum varchar(10), @payterms bPayTerms,
   	@lrectype int, @artranstype char(1)
   
   /* Variables related to RecType */
   declare @GLCo bCompany, @acctGLCo bCompany, @GLWriteOffAcct bGLAcct, 
   	@acctGLWriteOffAcct bGLAcct, @postGLWriteOffAcct bGLAcct
   	--@GLFCWriteOffAcct bGLAcct,
   
   /* Variables Misc */
   declare @rcode int, @amtleft bDollar, @acctamount bDollar, @nextseq int,
   	@applyallYN char(1), @todaydate bDate, @translistcursor int, @acctlistcursor int,
   	@fcpct bPct, @invflag char(1)
   
   /* Variables related to the sum of bARTL amounts */
   declare @invamount bDollar, @invretgdue bDollar, @invFCamtdue bDollar
   --	@invamtdue bDollar, @invpaid bDollar, @invinvoiced bDollar, @invdisctaken bDollar
   
   IF @ARCo is null
   	begin
   	select @rcode=1,@msg='AR Company is missing'
   	goto bspexit
   	end
   IF @BatchMth is null
   	begin
   	select @rcode=1,@msg='AR Batch Month is missing'
   	goto bspexit
   	end
   IF @BatchId is null
   	begin
   	select @rcode=1,@msg='AR Batch ID is missing'
   	goto bspexit
   	end
   IF @OlderThanDate is null
   	begin
   	select @rcode=1,@msg='The -Older Than- date is missing'
   	goto bspexit
   	end
   IF @CustGroup is null
   	begin
   	select @rcode=1,@msg='AR Customer Group is missing'
   	goto bspexit
   	end
   IF @WrtOffOpt is null
   	begin
   	select @rcode=1,@msg='The WriteOff option has not been set'
   	goto bspexit
   	end
   
   select @MinBal = isnull(@MinBal, 0), @applyallYN = 'N', @fcpct = 0, @invflag = 'O'
   select @rcode = 0, @AtLeastOneRecAddedYN = 'N', @translistcursor = 0, @acctlistcursor = 0
   ----#141031
   set @todaydate = dbo.vfDateOnly()
   
   /************************************************************************
   *
   *              BY FINANCE CHARGE OR INVOICE BALANCE
   *
   ************************************************************************/
   
   /* Option to write-off by FinChg or by InvBal.
      Since processing by FinChg or by InvBal are dealing with individual
      invoice/transactions, much of the initial filtering may be combined at this point. */
   if @WrtOffOpt = 'FinChg' or @WrtOffOpt = 'InvBal'
   	begin	/* Begin FinChg or InvBal Write-offs */
   
   	/* Declare Cursor to get ARCo, Mth and ARTrans representing All Original 
   	   'I', 'F', 'R' transactions:
   			with TransDate older than user input date; 
   	   		for all customers in a range or single customer;
   			for all invoices in a range or single invoice; */
   	declare bcTransList cursor local fast_forward for 
   	select h.Mth, h.ARTrans
   	from bARTH h with (nolock)
   	join bARCM m with (nolock) on h.CustGroup = m.CustGroup and h.Customer = m.Customer
   	where h.ARCo = @ARCo
   		and h.ARTransType in ('I','F','R')
   		-- This assures that we do not cycle on transactions for Applied Invoice Finance Charges or Release Retainage.
   		-- Does not effect the actual invoices created by Account Finance Charges or Released Retainage.
   		and h.Mth = isnull(h.AppliedMth, '2079-06-06') and h.ARTrans = isnull(h.AppliedTrans, 0)
   		and h.TransDate < @OlderThanDate
   		and h.Customer >= isnull(@BeginCust, h.Customer)
   		and h.Customer <= isnull(@EndCust, h.Customer)
   		and h.Invoice >= isnull(@BeginInvoice, h.Invoice)
   		and h.Invoice <= isnull(@EndInvoice, h.Invoice)
   
    	/* Open TransList cursor */
   	open bcTransList
   	select @translistcursor = 1
   
   	fetch next from bcTransList into @applymth, @applytrans
   	/* Spin through Transactions - At this point, these transactions meet the 
   	   'Older Than Date', the 'Customer Range', the invoice range,
   		and the 'WriteOff type' filter requirements. */
   	while @@fetch_status = 0
   	    	Begin  /* Begin by FinChg or Invoice Transaction loop */
   
   			/*   We need to retrieve some data for each original transaction. */
   	       	select @CustGroup = h.CustGroup, @customer = h.Customer, @rectype = h.RecType,
   					@JCCo = h.JCCo, @contract = h.Contract, @invoicenum = h.Invoice,
   					@payterms = h.PayTerms, @GLCo = r.GLCo, @GLWriteOffAcct = r.GLWriteOffAcct
   					--@GLFCWriteOffAcct = r.GLFCWriteOffAcct
   			from bARTH h with (nolock)
   			join bARRT r with (nolock) on h.ARCo = r.ARCo and h.RecType = r.RecType
   	       	where h.ARCo = @ARCo and h.Mth = @applymth and h.ARTrans = @applytrans
   		
   			/* Get total Invoice Amounts. Sum the Line Amounts of all applied transactions for each 
   			   original transaction. */
   			select @invamount = isnull(sum(l.Amount), 0),
   				@invretgdue = isnull(sum(l.Retainage), 0),
   				@invFCamtdue = isnull(sum(l.FinanceChg), 0)	--,
   				--@invdisctaken = -(isnull(sum(l.DiscTaken), 0)),
   				--@invamtdue = isnull(sum(l.Amount), 0) - isnull(sum(l.Retainage), 0),
   				--@invpaid = -(isnull(sum(case when h.ARTransType = 'P' then l.Amount else 0 end), 0)),
   				--@invinvoiced = isnull((sum(l.Amount)
   				--	-(sum(case when h.ARTransType = 'P' then l.Amount else 0 end))), 0)				
   			from bARTL l with (nolock)
   			join bARTH h with (nolock) on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans
   			where l.ARCo = @ARCo and l.ApplyMth = @applymth and l.ApplyTrans = @applytrans
   
--   			/* Add in any relative amounts from unposted batches */
--   			select @invamount = @invamount + IsNull(sum(case bARBL.TransType when 'D'
--              						then case when bARBH.ARTransType in ('I','A','F','R')
--                					then -IsNull(bARBL.oldAmount,0) else IsNull(bARBL.oldAmount,0)
--                					end
--    
--    			else
--    
--    								case when bARBH.ARTransType in ('I','A','F','R')
--                					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
--                					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
--    								end
--    			end),0),
--    
--         		@invretgdue = @invretgdue + IsNull(sum(case bARBL.TransType when 'D'
--    								then case when bARBH.ARTransType in ('I','A','F','R')
--    								then -IsNull(bARBL.oldRetainage,0) else IsNull(bARBL.oldRetainage,0)
--    								end
--    
--    			else
--    	 
--    								case when bARBH.ARTransType in ('I','A','F','R')
--    								then IsNull(bARBL.Retainage,0) - IsNull(bARBL.oldRetainage,0)
--    								else -IsNull(bARBL.Retainage,0) + IsNull(bARBL.oldRetainage,0)
--     								end
--    			end),0),
--   
--      			@invFCamtdue = @invFCamtdue + IsNull(sum(case bARBL.TransType when 'D'
--    								then case when bARBH.ARTransType in ('I','A','F','R')
--    								then -IsNull(bARBL.oldFinanceChg,0) else IsNull(bARBL.oldFinanceChg,0)
--    								end
--    
--    			else
--    	 
--    								case when bARBH.ARTransType in ('I','A','F','R')
--    								then IsNull(bARBL.FinanceChg,0) - IsNull(bARBL.oldFinanceChg,0)
--    								else -IsNull(bARBL.FinanceChg,0) + IsNull(bARBL.oldFinanceChg,0)
--     								end
--    			end),0)
--   
--   			from bARBL with (nolock)
--   			join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
--   			where bARBL.Co = @ARCo and bARBL.ApplyMth = @applymth and bARBL.ApplyTrans = @applytrans
   
   			if @invamount = 0 goto GetNextTrans
   
   			/* FINANCE CHARGE WRITE-OFFS - All transactions meeting the filters above
   			   must now be looked at closer depending on the Write-Off option. */
   			If @WrtOffOpt = 'FinChg'	
   				begin	/* Begin FinChg setup */
   				if @fcpctYN_all = 'N' and @fcpctYN_amt = 'N'
   					begin	/* Begin FinChg Full or Partial Amount */
   					select @invflag = 'P'
   
   					/* Invoice amounts and FinanceChg amounts must be of the same polarity
   					   to continue with processing, otherwise skip this Invoice. */
   					if (@invFCamtdue > 0 and (@invamount - @invretgdue) > 0 and @MinBal >= 0)		
   						or (@invFCamtdue < 0 and (@invamount - @invretgdue) < 0 and @MinBal >= 0)
   						begin
   
   						/* If this is a Negative invoice, the input amount is changed to negative */
   						if (@invFCamtdue < 0 and (@invamount - @invretgdue) < 0 and @MinBal <> 0)
   							begin
   							select @MinBal = -(@MinBal)
   							select @invflag = 'N'
   							end
   
   						/* Get next Batch Seq number */
   						select @nextseq = isnull(max(BatchSeq),0)+1
   						from bARBH 
   						where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId
   	
   						/* When writing off Finance Charges, we compare Invoice AmtDue with FCAmt
   		   				because we never want to writeoff more than has been left unpaid. 
   		   				(Otherwise an unwanted credit results).  Invoice AmtDue should not include retainage.*/
   						if @MinBal = 0
   							begin
   							select @amtleft = case when abs((@invamount - @invretgdue)) < abs(@invFCamtdue) then (@invamount - @invretgdue) 
   												else @invFCamtdue end
   							end
   						else
   							begin
   							if abs(@MinBal) <= abs((@invamount - @invretgdue))
   								begin
   								select @amtleft = case when abs(@MinBal) < abs(@invFCamtdue) then @MinBal else @invFCamtdue end
   								end
   							else
   								begin
   								select @amtleft = case when abs((@invamount - @invretgdue)) < abs(@invFCamtdue) then (@invamount - @invretgdue) 
   												else @invFCamtdue end
   								end
   							end
   
   						/* If the entire invoice Finance Charge amount cannot be written off as determined
   						   above, then we will process until the @amtleft is gone. */
   						select @applyallYN = case when abs(@amtleft) < abs(@invFCamtdue) then 'N' else 'Y' end
   						end
   					else
   						begin
   						/* Invoice amounts and Finance Charge amounts are not same polarity. */
   						goto GetNextTrans
   						end
   					end		/* End FinChg Full or Partial Amount */
   
   				if @fcpctYN_all = 'N' and @fcpctYN_amt = 'Y'
   					begin	/* Begin Finchg Percent Start Line #1 */
   					select @invflag = 'P'
   
   					if (@invFCamtdue > 0 and (@invamount - @invretgdue) > 0 and @MinBal > 0)		
   						or (@invFCamtdue < 0 and (@invamount - @invretgdue) < 0 and @MinBal > 0)
   						begin
   						/* If this is a Negative invoice, the invoice polarity flag must be set to 'N'egative */
   						if (@invFCamtdue < 0 and (@invamount - @invretgdue) < 0 and @MinBal <> 0)
   							begin
   							select @invflag = 'N'
   							end
   
   						/* 100 percent is maximum allowed.  Should have been caught by form */
   						if @MinBal > 100
   							begin 
   							select @MinBal = 100
   							end
   
   						/* Get next Batch Seq number */
   						select @nextseq = isnull(max(BatchSeq),0)+1
   						from bARBH 
   						where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId
   
   						select @amtleft = case when abs((@invamount - @invretgdue)) < abs(@invFCamtdue * (@MinBal/100)) then (@invamount - @invretgdue) 
   										else (@invFCamtdue * (@MinBal/100)) end
   
   						/* If the entire invoice Finance Charge amount cannot be written off as determined
   						   above, then we will process until the @amtleft is gone. */
   						select @applyallYN = case when abs(@amtleft) < abs(@invFCamtdue) then 'N' else 'Y' end
   						end
   					else
   						begin
   						/* Invoice amounts and Finance Charge amounts are not same polarity. */
   						goto GetNextTrans
   						end
   					end 	/* End Finchg Percent Start Line #1 */
   
   				if @fcpctYN_all = 'Y' and @fcpctYN_amt = 'N'
   					begin	/* Begin Finchg Percent All Lines */
   					if (@invFCamtdue > 0 and (@invamount - @invretgdue) > 0 and @MinBal > 0)		
   						or (@invFCamtdue < 0 and (@invamount - @invretgdue) < 0 and @MinBal > 0)
   						begin
   
   						/* 100 percent is maximum allowed.  Should have been caught by form */
   						if @MinBal > 100
   							begin 
   							select @MinBal = 100
   							end
   
   						/* Get next Batch Seq number */
   						select @nextseq = isnull(max(BatchSeq),0)+1
   						from bARBH
   						where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId
   
   						select @amtleft = 0, @fcpct = @MinBal/100
   						select @applyallYN = 'P'
   						end
   					else
   						begin
   						/* Invoice amounts and Finance Charge amounts are not same polarity. */
   						goto GetNextTrans
   						end
   					end 	/* End Finchg Percent All Lines */
   
   				select @postGLWriteOffAcct = @GLWriteOffAcct  --@GLFCWriteOffAcct
   				end		/* End FinChg Setup */
   
   			/* INVOICE BALANCE WRITE-OFFS - All transactions meeting the filters above
   			   must now be looked at closer depending on the Write-Off option. */
   			If @WrtOffOpt = 'InvBal'
   				begin
   				/* Determine if this Transaction has a balance less then MinBal input
   				   by the user to be written off.  This is relative to both Positive
   				   and negative invoices. */
   				if @invamount < ABS(@MinBal) and @invamount > -(ABS(@MinBal)) and @invamount <> 0
   					begin
   					/* Get next Batch Seq number */
   					select @nextseq = isnull(max(BatchSeq),0)+1
   					from bARBH
   					where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId
   					
   					/* At this time, Set @amtleft as a place holder only.  Not used when
   					   processing the lines amounts.  */
   					select @amtleft = @invamount, @applyallYN = 'Y'
   
   					select @postGLWriteOffAcct = @GLWriteOffAcct
   					end
   				else
   					begin
   					/* Skip if Invoice balance is greater than the Minimum Balance input */
   					goto GetNextTrans
   					end
   				end
   
			/* Enter Header entry for this WriteOff Transaction */
			insert into bARBH(Co, Mth, BatchId, BatchSeq, TransType, Source, ARTransType, CustGroup, Customer, JCCo, Contract,
					AppliedMth, AppliedTrans, RecType, Invoice, Description, TransDate, DueDate, PayTerms)
				values (@ARCo, @BatchMth, @BatchId, @nextseq, 'A', 'AR Invoice', 'W', @CustGroup, @customer , @JCCo, @contract,
					@applymth, @applytrans, @rectype, @invoicenum, 'Auto WriteOff', @todaydate, null, @payterms)
			if @@rowcount = 1
				begin
				select @AtLeastOneRecAddedYN = 'Y'
				end

   			/* Go to separate routine to process the writeoff lines */
   			exec bspARAutoWriteOffByLine  @ARCo, @BatchMth, @BatchId, @nextseq,
   				@applymth, @applytrans, @amtleft, @applyallYN, @rectype,
   				@GLCo, @postGLWriteOffAcct, @WrtOffOpt, @fcpct, @invflag, @msg output
   
   			GetNextTrans:
   			fetch next from bcTransList into @applymth, @applytrans
   
   			End		/* End by FinChg or Invoice Transaction loop */
   	END		/* End FinChg or InvBal Write-offs */
   
   /************************************************************************
   *
   *                         ACCOUNT BALANCE
   *
   ************************************************************************/
   
   /* Option to Write Off by Account balances */
   if @WrtOffOpt = 'AcctBal'
   	BEGIN	-- Begin AcctBal Write-offs
   	
   	/* Create a local temporary table. - Could not find any other way to do it. This feature will
      	rarely be used and this inefficiency will rarely be a factor. (Temporary tables are much
		faster than table variables because table variables cannot be indexed) */
   	create table #CustTotals
   	(Mth smalldatetime null,
    	ARTrans int null,
   		ARTransType char(1) null,
    	Customer int null,
    	RetgDue numeric(12,2) null,
    	InvAmount numeric(12,2) null) 
     create nonclustered index biCustTotalsCustomer on #CustTotals(Customer)

   	/* This record set returns values for all Original Invoice/Transactions as well as
      	for original (As in not applied to another On-Account original) 'On-Account' payment 
      	transactions that meet the User Input filters for 'Older Than Date' and 'Customer
      	Range'. Checking the sum against the MinBal input occurs in the next step. */
   	insert #CustTotals
   	select  distinct h.Mth, h.ARTrans, h.ARTransType, h.Customer, h.Retainage, h.AmountDue
   	from bARTH h with (nolock)
   	join bARCM m with (nolock) on h.CustGroup = m.CustGroup and h.Customer = m.Customer
   	join bARTL l with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
   	where h.ARCo = @ARCo and h.CustGroup = @CustGroup 
   		and ((h.ARTransType in ('I', 'F', 'R') and h.Mth = isnull(h.AppliedMth, '2079-06-06') and h.ARTrans = isnull(h.AppliedTrans, 0)) or
   			(h.ARTransType = 'P' and l.LineType = 'A' and l.ApplyMth = l.Mth and l.ApplyTrans = l.ARTrans))
   		and h.TransDate < @OlderThanDate
   		and h.Customer >= isnull(@BeginCust, h.Customer)
   		and h.Customer <= isnull(@EndCust, h.Customer)
   	Group by h.Customer, h.Mth, h.ARTrans, h.ARTransType, h.Retainage, h.AmountDue
   	order by h.Customer, h.Mth, h.ARTrans
   
   	/* Spin through temporary table.  First spin through all transactions
   	   in the temporary table by customer, sum the line amounts for each transaction
   	   and add them to the next for this customer.  Before moving onto the next customer
   	   check to see if the line amount total for this customers transactions is less
   	   than the MinBal input by the user.  If so, spin through the temporary table again
   	   for same customer but this time process each transaction for a write-off.  Otherwise
   	   move to the next customer. */
   	select @customer = min(c.Customer) 
   	from #CustTotals c
   	select @acctamount = 0	-- Reset Account amount for each customer 
   
   	while @customer is not null
   		Begin  -- Begin Customer while
   
   		/* Declare a cursor for use the first time to total account values */
   		declare bcAcctList cursor local fast_forward for
   		select c.Mth, c.ARTrans
   		from #CustTotals c
   		where c.Customer = @customer
   
   		/* Open bcAcctList Cursor */
   		open bcAcctList
   		select @acctlistcursor = 1
   
   		/* Spin through the Acct Transaction list for the first time */
   		fetch next from bcAcctList into @applymth, @applytrans
   		while @@fetch_status = 0
   			begin	-- Begin transaction while
   
   			/* Sum the Line Amounts for each transaction in order to determine
   		   	   the account total for this customer. */
   			select @invamount = isnull(sum(l.Amount), 0)	--,
   				--@invretgdue = isnull(sum(l.Retainage), 0),
   				--@invdisctaken = -(isnull(sum(l.DiscTaken), 0)),
   				--@invamtdue = isnull(sum(l.Amount), 0) - isnull(sum(l.Retainage), 0),
   				--@invpaid = -(isnull(sum(case when h.ARTransType = 'P' then l.Amount else 0 end), 0)),
   				--@invinvoiced = isnull((sum(l.Amount)
   				--	-(sum(case when h.ARTransType = 'P' then l.Amount else 0 end))), 0),
   				--@invFCamtdue = isnull(sum((case when l.LineType = 'F' then l.Amount else 0 end)), 0)
   			from bARTL l with (nolock)
   			join bARTH h with (nolock) on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans
   			where l.ARCo = @ARCo and l.ApplyMth = @applymth and l.ApplyTrans = @applytrans
   
--   			/* Add in any relative amounts from unposted batches */
--   			select @invamount = @invamount + IsNull(sum(case bARBL.TransType when 'D'
--              						then case when bARBH.ARTransType in ('I','A','F','R')
--                					then -IsNull(bARBL.oldAmount,0) else IsNull(bARBL.oldAmount,0)
--                					end
--    
--    			else
--    
--    								case when bARBH.ARTransType in ('I','A','F','R')
--                					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
--                					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
--    								end
--    			end),0)
--   			from bARBL with (nolock)
--   			join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
--   			where bARBL.Co = @ARCo and bARBL.ApplyMth = @applymth and bARBL.ApplyTrans = @applytrans
   
   			/* Set this particular transaction Invoice Amount into the table variable for use later */
   			update #CustTotals
   			set InvAmount = @invamount
   			where Mth = @applymth and ARTrans = @applytrans and Customer = @customer
   
   			/* Accumulate Customer Balance amount. */
   			select @acctamount = @acctamount + @invamount
   
   			GetNextAcctTrans:
   			fetch next from bcAcctList into @applymth, @applytrans
   			end		-- End Transaction while
   
   		if @acctlistcursor = 1
   			begin
   			close bcAcctList
   			deallocate bcAcctList
   			select @acctlistcursor = 0
   			end		
   
   		/* Before getting next customer we will check the Acct Amount for this customer
   			if less than the MinBal input by the user we will begin processing 
   			writeoffs for this customers transactions */
   		if @acctamount < ABS(@MinBal) and @acctamount > -(ABS(@MinBal)) and @acctamount <> 0
   			begin	-- Begin Processing Account Write-Offs
   
   			/* When Account Write-Offs, you must look for the usual transactions but
   	   		in addition, you must check the ON-ACCOUNT payments.  ON-ACCOUNT
   	   		payments do not have an associated RecType in the Header and therefore we must retrieve
   	   		RecType either from the original On-Acct Line in ARTL or from ARCM or ARCO table to use 
   			with these transactions. */
   			select @acctrectype = bARCM.RecType
   			from bARCM with (nolock) 
   			where bARCM.CustGroup = @CustGroup and bARCM.Customer = @customer
   			if isnull(@acctrectype, -1) < 0
   				begin
   				select @acctrectype = bARCO.RecType
   				from bARCO with (nolock)
   				where bARCO.ARCo = @ARCo
   				end
   
   			/* Declare the Cursor for use a second time to process writeoffs */
   			declare bcAcctList cursor local fast_forward for
   			select c.Mth, c.ARTrans, c.ARTransType, c.InvAmount
   			from #CustTotals c
   			where c.Customer = @customer
   
   			/* Open AcctList Cursor */
   			open bcAcctList
   			select @acctlistcursor = 1
   
   			/* Spin through this Customers transactions again and process them
   				for write-offs, one at a time. */
   			fetch next from bcAcctList into @applymth, @applytrans, @artranstype, @invamount
   			while @@fetch_status = 0
   				begin	-- Begin transaction while loop 2
   				/* If the Invoice Amount is 0.00, no need to process it, skip to next for this customer */
   				if @invamount = 0 goto GetNextAcctTrans2
   
   				/* Begin processing this transaction, Clear variables. */
   				select @rectype = null, @lrectype = null, @acctrectype = null, @postrectype = null
   
   				/* We need some values for this transaction. */      				
   				select @CustGroup = h.CustGroup, @customer = h.Customer, @rectype = h.RecType,
   						@JCCo = h.JCCo, @contract = h.Contract, @invoicenum = h.Invoice,
   						@payterms = h.PayTerms, @GLCo = r.GLCo, @GLWriteOffAcct = r.GLWriteOffAcct
   						--@GLFCWriteOffAcct = r.GLFCWriteOffAcct
   				from bARTH h with (nolock)
   				left join bARRT r with (nolock) on h.ARCo = r.ARCo and h.RecType = r.RecType		--RecType missing on On-Acct transactions
   	       		where h.ARCo = @ARCo and h.Mth = @applymth and h.ARTrans = @applytrans
   
   				/* If the current transaction is an On-Account payment then the RecType value from the above
   				   select will be NULL since it does not exist in the ARTH record.  We must Get from ARTL */
   				if @artranstype = 'P'					-- Can only be P when dealing with an On-Account original Transaction
   					begin
   					select @lrectype = RecType			-- Returns last if multiple lines exist, all lines should be the same
   					from bARTL with (nolock)
   					where ARCo = @ARCo and Mth = @applymth and ARTrans = @applytrans
   						and Mth = ApplyMth and ARTrans = ApplyTrans
   					end
   
   				/* On-Account RecType value will be the LineRecType unless it is NULL, in which case, we will use
   				   The RecType from ARCustomer, followed by from ARCompany */
   				select @acctrectype = isnull(@lrectype, @acctrectype)
   
   				/* Now that the On-Account RecType has been established, we can now retrieve the Write-Off Acct
   				   relative to this RecType value */
   				select @acctGLCo = bARRT.GLCo, @acctGLWriteOffAcct = bARRT.GLWriteOffAcct
   				from bARRT with (nolock)
   				where bARRT.ARCo = @ARCo and bARRT.RecType = @acctrectype
   
   				/* If this transaction is an On-Account payment transaction then the ARTH.RecType will be NULL, 
   				   therefore we will use Account RecType and relative GLWrite-Off Account that came from either
   				   the original On-Account payment line or, if null, then from ARCM or ARCO as determined above. */
   				select @postrectype = case when (isnull(@rectype, -1) >= 0) then @rectype else @acctrectype end
   				select @GLCo = case when isnull(@rectype, -1) >= 0 then @GLCo else @acctGLCo end
   				select @postGLWriteOffAcct = case when isnull(@rectype, -1) >= 0 then @GLWriteOffAcct else @acctGLWriteOffAcct end
   
   				/* Get next Batch Seq number */
   				select @nextseq = isnull(max(BatchSeq),0)+1
   				from bARBH
   				where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId
   					
   				/* At this time, Set @amtleft as a place holder only.  Not used when
   				   processing the lines amounts.  */
   				select @amtleft = @acctamount, @applyallYN = 'Y'
   
				/* Enter Header entry for this WriteOff Transaction */
				insert into bARBH(Co, Mth, BatchId, BatchSeq, TransType, Source, ARTransType, CustGroup, Customer, JCCo, Contract,
							AppliedMth, AppliedTrans, RecType, Invoice, Description, TransDate, DueDate, PayTerms)
					values (@ARCo, @BatchMth, @BatchId, @nextseq, 'A', 'AR Invoice', 'W', @CustGroup, @customer , @JCCo, @contract,
							@applymth, @applytrans, @postrectype, @invoicenum, 'Auto WriteOff', @todaydate, null, @payterms)
				if @@rowcount = 1
					begin
					select @AtLeastOneRecAddedYN = 'Y'
					end

   				/* Go to separate routine to process the writeoff lines */
   				exec bspARAutoWriteOffByLine  @ARCo, @BatchMth, @BatchId, @nextseq,
   						@applymth, @applytrans, @amtleft, @applyallYN, @postrectype,
   						@GLCo, @postGLWriteOffAcct, @WrtOffOpt, @fcpct, @invflag, @msg output
   
   				GetNextAcctTrans2:
   				fetch next from bcAcctList into @applymth, @applytrans, @artranstype, @invamount
   				end		-- End Transaction while loop 2		
   			if @acctlistcursor = 1
   				begin
   				close bcAcctList
   				deallocate bcAcctList
   				select @acctlistcursor = 0
   				end		
   
   			end		-- End Processing Account Write-Offs
   
   		GetNextAcctCustomer:
   		select @customer = min(c.Customer) 
   		from #CustTotals c 
   		where c.Customer > @customer
   		select @acctamount = 0	-- Reset Account amount for each customer
   
   		End		-- End Customer while
   
   	drop table #CustTotals
   	END	-- End AcctBal Write-Offs
   
   bspexit:
   if @translistcursor = 1
   	begin
   	close bcTransList
   	deallocate bcTransList
   	end
   if @acctlistcursor = 1
   	begin
   	close bcAcctList
   	deallocate bcAcctList
   	end
   
   if @rcode<>0 select @msg=@msg		--+ char(13) + char(10) + '[bspARAutoWriteOffs]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARAutoWriteOffs] TO [public]
GO
