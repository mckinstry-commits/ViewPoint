SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARAutoApply    Script Date: 8/28/99 9:36:41 AM ******/
   CREATE proc [dbo].[bspARAutoApply]
   /********************************************************
   * CREATED BY: 	JRE 5/25/97
   * MODIFIED BY:  JRE 6/22/97 - Added check for other batches.
   *		JM 1/21/98 - Added @GLCo input to prevent error in ARBL insert trigger
   *					on @Option = 'A' which requires insert of GLCo in HQCC.
   *		CJW 2/19/98 - Changed On Account amount to a + instead of -.
   *		JM 8/12/98 - Added begin transaction
   *		JM 8/17/98 - Changed On Acct LineType from 'M' to 'A' (Issue 2729)
   *		JM 2/14/99 - Added option 'N' to not apply balance (Issue 3568) - added
   *				 	'if @Option='N'' section.
   *		JM 2/14/99 - Added option 'S' to apply balance to a specified starting
   *				 	Invoice (Issue 3568).
   *		JM 5/12/99 - Added 'stuff(@StartingInvoice ,1,0,space(10-datalength(@StartingInvoice )))'
   *				 	to where clause for @Option = 'S' in insert statement into #ARInitCash (Issue 3957).
   *   	GR 09/27/00  - Corrected the ApplyAmount calculation when retainage option is checked - issue 10459
   *		TJL 05/01/01 - Reviewed and corrected numerous issues regarding end result calculations.  Almost
   *				 	everyone was related to Batch Calculations for DiscTaken.  Most were a result of an
   *				 	incorrect + or - value which has a cascading effect down the line.
   *		TJL 05/04/01 - Added option 'J' to apply balance to a specified Customer
   *				   	Job Number (Issue 11540).  This required using a permanent processing
   *				   	table 'bARAA'  rather than the temporary table as before.
   *		TJL 07/05/01 - Correct ApplyAllYN flag to NOT set to 'Y' when Check Amt = 0.00 and Cust total Invoice Bal = 0.00 (rare condition)
   *		TJL 07/25/01 - Correct variable declare 'aInvoice int', change to 'aInvoice varchar(10)'
   *		TJL 09/11/01 - Correct RecType for 'On Account' Apply Option.  Use from ARCM first and from ARCO second.
   *		TJL 10/03/01 - Issue #14498:  Correct and allow posting to same invoice using 2 sequences, same batch
   *				   	Exclude Invoices whose InUseBatchID is not null.
   *		TJL 10/29/01 - Issue #15075:  Remove unnecessary 'BEGIN TRANSACTION, ROLLBACK, COMMIT TRANS' code.
   *		TJL 11/12/01 - Issue #15154:  When AutoInitializing by 'On Account', TaxGroup is not set on PmtOnAcct form as it should.
   *		TJL 12/18/01 - Issue #14170:  Exclude Finance Charge option, better Retainage handling, better ApplyAllYN handling.
   *		TJL 03/26/02 - Issue #16734:  Update new FinanceChg column in bARTL when receiving cash
   *		TJL 04/04/02 - Issue #16280:  Do not include/sum bARTL amounts for payments added back into batch for change.
   *		TJL 05/14/02 - Issue #17421:  Add 'Tax Applied' to grid for user input. 
   *		TJL 07/31/02 - Issue #11219:  Add 'TaxDisc Applied' to grid for user input. 
   *		TJL 08/07/03 - Issue #22087:  Performance mods, add NoLocks
   *		TJL 11/07/03 - Issue #22972:  Do Not even process when Invoice Amount = 0.00.  (Helps w/old FinanceChg col when not 0.00)
   *		******************************** TOTAL REWRITE AFTER THIS POINT ***************************************
   *		TJL 11/13/03 - Issue #23005:  Improve how cash gets applied to Negative Lines (Opposite Lines)
   *		TJL 11/19/03 - Issue #23054:  Related to #23005, however also requires associated form mods
   *		TJL 08/03/05 - Issue #29474:  Applied line amounts from Adjustments & FinChgs not included when applying by CustJob
   *		TJL 02/28/08 - Issue #125289:  Include unposted batch values for ONLY unposted ARCashReceipts (P) batches. (Not A, C, W, F)
   *
   * CAUTION:
   *	As with so many backend procedures, seemingly minor modifications can have major
   *	implications.  This procedure works closely with bspARAutoApplyLine and bspARAutoApplyLineRev
   *	as well as with form ARInitialize.
   *	If it seems too easy it probably is. Unless you understand how all these procedures
   *	function together you should not be making changes.
   *
   * USAGE:
   * 	Auto Apply a Check to a Customer's Invoices - called from ARInitializeReceipt
   *
   * INPUT PARAMETERS:
   *    	@Option - On (A)ccount, by (D)ate, by (I)nvoice, (S)tart at Invoice, or Do(N)t Apply
   *    	@ARCo,@BatchMth,@BatchId,@BatchSeq,@RetgYN (pay retainage or not),@DiscYN,@ExcludeFCYN
   *    	@GLCo (for @Option = 'A')
   *   	@StartingInvoice (for @Option = 'S')
   *		@CustJob (for @Option = 'J')
   *
   * OUTPUT PARAMETERS:
   *	Error message
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   @Option char(1)= null, @ARCo bCompany = null, @BatchMth bMonth = null,
   @BatchId bBatchID = null, @BatchSeq int = null, @RetgYN bYN = null, @DiscYN bYN = null, @ExcludeFCYN bYN = null,
   @GLCo bCompany = null, @StartingInvoice varchar(10) = null, @CustJob varchar(20) = null,
   @msg varchar(255) output
   
   as
   
   declare @AmtLeft bDollar,@ApplyAmt bDollar, @ApplyRetg bDollar,@ApplyDisc bDollar,
   	@ApplyTaxDisc bDollar, @ApplyFC bDollar, @ApplyTax bDollar, @XAmount bDollar, 
   	@TaxAmount bDollar, @Retainage bDollar, @FinanceChg bDollar, @CheckAmt bDollar, 
   	@DiscOffered bDollar, @DiscTaken bDollar, @TaxDisc bDollar, 
   	@ARTransDate bDate, @DiscDate bDate, @Mth bMonth, @ARTrans bTrans, @ARLine smallint,
    	@NextARLine smallint, @rcode int, @CustGroup bGroup, @Customer bCustomer,
   	@PayTransDate bDate, @OpenCursor tinyint, @rectypeA int, @TaxGroup bGroup, @Source char(10), 
   	@JBFlag int, @paytrans int
   
   /* Declare Processing Table / Cursor Variables */
   declare	@aTransDate bDate, @aInvoice varchar(10), @aARCo bCompany, @aMth bMonth, 
   	@aARTrans bTrans
   
   set nocount on
   
   select @rcode = 0, @OpenCursor = 0, @JBFlag = 0
   
   if @Option not in ('A','D','I','N', 'S', 'J')
     	BEGIN
     	select @msg='Option must be one of: On (A)ccount by (D)ate by (I)nvoice by (S)tart at Invoice by Cust(J)ob or Do(N)t Apply',@rcode=1
     	goto bspexit
     	END
   
   if @Option = 'S' and @StartingInvoice is null
     	begin
     	select @msg = 'Must specify a starting Invoice No for this Apply Option.', @rcode=1
     	goto bspexit
     	end
   
   if @Option = 'J' and @CustJob is null
     	begin
     	select @msg = 'Must specify a Customer Job No for this Apply Option.', @rcode=1
     	goto bspexit
     	end
   
   select @CustGroup = CustGroup, @Customer = Customer, @CheckAmt = CreditAmt, @PayTransDate = TransDate
   from bARBH with (nolock)
   where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
   
   if @@rowcount<>1
     	BEGIN
     	select @msg = 'BatchSeq not found in ARBH', @rcode = 1
     	goto bspexit
     	END
   
   if (select count(*) from bARCM where CustGroup = @CustGroup and Customer = @Customer) <> 1
     	BEGIN
     	select @msg = 'Customer not found', @rcode = 1
     	goto bspexit
     	END
   
   if @CheckAmt is null
     	BEGIN
     	select @msg = 'Check Amount may not be null', @rcode = 1
     	goto bspexit
     	END
   
   if @RetgYN <> 'Y' and @RetgYN <> 'N'
     	BEGIN
     	select @msg = 'Apply to Retainage must be Y or N', @rcode = 1
     	goto bspexit
     	END
   
   if @DiscYN <> 'Y' and @DiscYN <> 'N'
     	BEGIN
     	select @msg = 'Use Discount must be Y or N', @rcode = 1
     	goto bspexit
     	END
   
   if @ExcludeFCYN <> 'Y' and @ExcludeFCYN <> 'N'
     	BEGIN
     	select @msg = 'Exclude Finance Charge must be set to Y or N', @rcode = 1
     	goto bspexit
     	END
   
   if @PayTransDate is null
     	BEGIN
     	select @msg = 'Transaction date of payment may not be null', @rcode = 1
     	goto bspexit
     	END
   
   /* Cant apply if batch lines are being edited */
   if (select count(*) from bARBL with (nolock)
   	where Co=@ARCo and Mth=@BatchMth and BatchId=@BatchId and BatchSeq=@BatchSeq
     		and TransType <> 'A') <> 0
     	BEGIN
     	select @msg = 'This check already has been applied', @rcode = 1
     	goto bspexit
     	END
   
   /* Delete batch lines for a restart */
   delete from bARBL
   where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
                and TransType = 'A'
   
   /* @AmtLeft begins with the full check amount.  As cash is applied, @AmtLeft is 
      reduced by the applied amount. */
   select @AmtLeft = @CheckAmt
   
   if @Option = 'A' /* on Account */
     	begin
     	/* Get the next line number */
     	select @NextARLine = Max(ARLine) + 1 
   	from bARBL with (nolock)
     	where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
   
   	/* Get RecType, first from ARCM and if null, then get from ARCO */
   	/* Issue #15154,  also get TaxGroup */
   	select @rectypeA = RecType, @TaxGroup = TaxGroup
   	from bARCM with (nolock)
   	where CustGroup = @CustGroup and Customer = @Customer
   
   	if isnull(@rectypeA, -1) = -1
   		begin
   		select @rectypeA = RecType
   		from bARCO with (nolock)
   		where ARCo = @ARCo
   		end 
   
   	/* Insert into batch */
     	insert into bARBL(Co,Mth,BatchId,BatchSeq,ARLine,TransType,ARTrans,RecType,
           		LineType,Description,GLCo,GLAcct,TaxGroup,TaxCode,Amount,
           		TaxBasis,TaxAmount,RetgPct,Retainage,DiscOffered,TaxDisc,DiscTaken,
           		ApplyMth,ApplyTrans,ApplyLine)
     	values (@ARCo,@BatchMth,@BatchId,@BatchSeq,IsNull(@NextARLine,1),'A',null,
          		@rectypeA,'A','On Account',@GLCo,null,@TaxGroup,null,@AmtLeft,
           	0,0,0,0,0,0,0,@BatchMth,null,null)
    	goto bspexit
     	end
   
   if @Option = 'N' /* Dont Apply */
     	begin
     	delete bARBL
     	where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
     	goto bspexit
     	end
   
   /* Fill processing table bARAA with transactions that meet the filtering
      options as sent from the frmARInitializeReceipt form.
      If NOT by CustJob, Processing table bARAA must get populated here
      when option Apply by Date or Starting Invoice is selected. */
   
   if @Option <> 'J'
   	begin
   	/* Clear out Processing Table bARAA for this user */
   	delete bARAA where VPUserName = SUSER_SNAME()
   
   	insert into bARAA(VPUserName,TransDate,Invoice,ARCo,Mth,ARTrans)
     	select distinct SUSER_SNAME(),
   		case when @Option='D' then bARTH.TransDate else null end,
     		bARTH.Invoice,
     		bARTH.ARCo,
   		bARTH.Mth,
     	  	bARTH.ARTrans
     	from bARTH  with (nolock)
     	where bARTH.CustGroup = @CustGroup
     		and bARTH.Customer = @Customer
     		and bARTH.ARCo = @ARCo
   		and bARTH.Mth = bARTH.AppliedMth
     		and bARTH.ARTrans = bARTH.AppliedTrans
     		and bARTH.Mth <= @BatchMth 
     		and isnull(bARTH.Invoice,'') >= case when @Option = 'S'
   					then stuff(@StartingInvoice,1,0,space(10-datalength(@StartingInvoice )))
     					else isnull(bARTH.Invoice,'')
     					end
   		and bARTH.InUseBatchID is null
     	order by case when @Option='D' then bARTH.TransDate else null end,
     	  	bARTH.Invoice,
     	 	bARTH.Mth,
     	   	bARTH.ARTrans
   
   	end
   
   /* Table bARAA gets the record set by CustJob from frmARInitializeReceiptJob
      in VB.  From this point forward, processing by CustJob or Invoice is identical */
   
   /* Now process total amounts for each line/transaction in bARAA, one transaction at a time */
   /*  Cursor sets the order in which each transaction will be processed. */
   declare bcProcAA cursor local fast_forward for
   select TransDate, Invoice, ARCo, Mth, ARTrans 
   from bARAA a with (nolock)
   where a. VPUserName =  SUSER_SNAME()
   order by case when @Option='D' then a.TransDate else null end,
     	     	a.Invoice,
     	      	a.Mth,
     	      	a.ARTrans
   
   open bcProcAA
   select @OpenCursor = 1
   
   /* These invoice transactions have been selected to automatically apply
      cash to.  They will be processed one transaction at a time. */
   fetch next from bcProcAA into @aTransDate, @aInvoice, @aARCo, @aMth, @aARTrans
   while @@fetch_status = 0 
   	Begin	/* Begin Invoice Process loop */
   
   	/* @AmtLeft begins with the full check amount.  As cash is applied, @AmtLeft is 
          reduce by the applied amount. */
   	if @AmtLeft <= 0 
   		begin
   		goto bspexit
   		end
   
   	/* Set Defaults as each transaction begin to be processed */
   	select @ApplyAmt = 0, @ApplyRetg = 0, @ApplyDisc = 0, @ApplyFC = 0, @ApplyTax = 0, @ApplyTaxDisc = 0
   
   	/* Get Payment transaction number for a transaction that has been added back
      	   into the batch. */
   	select @paytrans = min(ARTrans)
   	from bARBL with (nolock)
   	where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
   
   	/* Get values from ARTL for this transaction. */
   	select @XAmount = IsNull(sum(bARTL.Amount),0),
   			@TaxAmount = IsNull(sum(bARTL.TaxAmount),0),
   			@Retainage = IsNull(sum(bARTL.Retainage),0),
   	  		@DiscOffered = IsNull(sum(bARTL.DiscOffered),0),
   			@TaxDisc = IsNull(sum(bARTL.TaxDisc),0),
   			@DiscTaken = IsNull(sum(bARTL.DiscTaken),0),
   			@FinanceChg = IsNull(sum(bARTL.FinanceChg),0),
   	  		@Mth = Min(bARTL.ApplyMth), @ARTrans = Min(bARTL.ApplyTrans), 
   			@ARLine = Min(bARTL.ApplyLine), @ARTransDate = Min(bARTH.TransDate),
   			@DiscDate = Min(bARTH.DiscDate)
   	from bARTL with (nolock)
   	join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.ApplyMth and bARTH.ARTrans=bARTL.ApplyTrans
   	join bARTH hd with (nolock) on hd.ARCo=bARTL.ARCo and hd.Mth=bARTL.Mth and hd.ARTrans=bARTL.ARTrans
   	where  bARTL.ARCo = @aARCo and bARTL.ApplyMth = @aMth and bARTL.ApplyTrans = @aARTrans
   			--and isnull(bARTL.CustJob,'') = case when @Option='J' then @CustJob else isnull(bARTL.CustJob, '') end
   	        and(isnull(hd.InUseBatchID,0) <> @BatchId 
   			or (isnull(hd.InUseBatchID,0) = @BatchId and hd.Mth <> @BatchMth)
   			or (isnull(hd.InUseBatchID,0) = @BatchId and hd.Mth = @BatchMth and hd.ARTrans <> isnull(@paytrans,0)))
   
   	if @@rowcount <> 1 goto GetNextTrans /*invoice is no longer on file - probably shouldnt happen*/
   
   	/* Now combine open/unposted batch amounts. */
   	select @XAmount = @XAmount + isnull(sum(case ARBL.TransType when 'D'
   	         			then case when ARBH.ARTransType in ('I','A','F','R')
   	              		then -ARBL.oldAmount else ARBL.oldAmount
   	             		end
   	
   	         			else
   	
   						case when ARBH.ARTransType in ('I','A','F','R')
   	              		then IsNull(ARBL.Amount,0)-IsNull(ARBL.oldAmount,0)
   	              		else -IsNull(ARBL.Amount,0)+IsNull(ARBL.oldAmount,0)
   	             		end
   	         			end),0),
   	
   	         @TaxAmount = @TaxAmount + isnull(sum(case ARBL.TransType when 'D'
   	         			then case when ARBH.ARTransType in ('I','A','F','R')
   	              		then -ARBL.oldTaxAmount else ARBL.oldTaxAmount
   	             		end
   	
   	        			else
   	
   	             		case when ARBH.ARTransType in ('I','A','F','R')
   	              		then IsNull(ARBL.TaxAmount,0)-IsNull(ARBL.oldTaxAmount,0)
   	              		else -IsNull(ARBL.TaxAmount,0)+IsNull(ARBL.oldTaxAmount,0)
   	             		end
   	         			end),0),
   	
   	         @Retainage = @Retainage + isnull(sum(case ARBL.TransType when 'D'
   	         			then case when ARBH.ARTransType in ('I','A','F','R')
   	              		then -ARBL.oldRetainage else ARBL.oldRetainage
   	             		end
   	
   	        			else
   	
   	             		case when ARBH.ARTransType in ('I','A','F','R')
   	              		then IsNull(ARBL.Retainage,0)-IsNull(ARBL.oldRetainage,0)
   	              		else -IsNull(ARBL.Retainage,0)+IsNull(ARBL.oldRetainage,0)
   	             		end
   	         			end),0),
   	
   	         @FinanceChg = @FinanceChg + isnull(sum(case ARBL.TransType when 'D'
   	         			then case when ARBH.ARTransType in ('I','A','F','R')
   	              		then -ARBL.oldFinanceChg else ARBL.oldFinanceChg
   	             		end
   	
   	        			else
   	
   	             		case when ARBH.ARTransType in ('I','A','F','R')
   	              		then IsNull(ARBL.FinanceChg,0)-IsNull(ARBL.oldFinanceChg,0)
   	              		else -IsNull(ARBL.FinanceChg,0)+IsNull(ARBL.oldFinanceChg,0)
   	             		end
   	         			end),0),
   	
   	  		@DiscTaken = @DiscTaken + isnull(sum(case ARBL.TransType when 'D'
   	         			then case when ARBH.ARTransType in ('I','A','F','R')
   	              		then -ARBL.oldDiscTaken else ARBL.oldDiscTaken
   	             		end
   	
   	         			else
   	
   	             		case when ARBH.ARTransType in ('I','A','F','R')
   	              		then IsNull(ARBL.DiscTaken,0)-IsNull(ARBL.oldDiscTaken,0)
   	              		else -IsNull(ARBL.DiscTaken,0)+IsNull(ARBL.oldDiscTaken,0)
   	             		end
   	         			end),0),
   	
   
   	  		@DiscOffered = @DiscOffered + isnull(sum(case ARBL.TransType when 'D'
   	         			then case when ARBH.ARTransType in ('I','A','F','R')
   	              		then -ARBL.oldDiscOffered else ARBL.oldDiscOffered
   	             		end
   	
   	         			else
   	
   	             		case when ARBH.ARTransType in ('I','A','F','R')
   	              		then IsNull(ARBL.DiscOffered,0)-IsNull(ARBL.oldDiscOffered,0)
   	              		else -IsNull(ARBL.DiscOffered,0)+IsNull(ARBL.oldDiscOffered,0)
   	             		end
   	         			end),0),
   	
   	  		@TaxDisc = @TaxDisc + isnull(sum(case ARBL.TransType when 'D'
   	         			then case when ARBH.ARTransType in ('I','A','F','R')
   	              		then -ARBL.oldTaxDisc else ARBL.oldTaxDisc
   	
   	             		end
   	
   	         			else
   	
   	             		case when ARBH.ARTransType in ('I','A','F','R')
   	              		then IsNull(ARBL.TaxDisc,0)-IsNull(ARBL.oldTaxDisc,0)
   	              		else -IsNull(ARBL.TaxDisc,0)+IsNull(ARBL.oldTaxDisc,0)
   	             		end
   	         			end),0)
   	
   	from bARBL ARBL with (nolock)
   	join bARBH ARBH with (nolock) on ARBH.Co = ARBL.Co and ARBH.Mth = ARBL.Mth and ARBH.BatchId = ARBL.BatchId and ARBH.BatchSeq = ARBL.BatchSeq
   	where ARBL.Co = @aARCo and ARBL.ApplyMth = @aMth and ARBL.ApplyTrans = @aARTrans
			and ARBH.ARTransType = 'P'
   			--and isnull(ARBL.CustJob,'') = case when @Option='J' then @CustJob else isnull(ARBL.CustJob, '') end 
   			and ARBL.BatchSeq <> (case when ARBL.Mth = @BatchMth and ARBL.BatchId = @BatchId  then @BatchSeq else 0 end)	
   
   	/* Skip entirely when overall amount of invoice = 0.00 */
   	if @XAmount = 0 goto GetNextTrans
   
   	/************** ATTEMPT TO CATCH BAD COLUMN DATA AND SKIP ********************/
   	/* If either Tax, Finance charges, or Retainage columns have not remained
   	   correctly balanced over time, (ie: FC column missing orig positive amounts 
   	   resulting in a negative column value) then this may catch SOME of them and skip 
   	   processing.  It helps, but is far from full proof.  It all depends on Values. 
   	   (Any one column, either Tax or FC or Retg is opposite polarity of the amount on 
   	   this invoice. */
   	if (@XAmount < 0 and (@TaxAmount > 0 or @FinanceChg > 0 or @Retainage > 0)) or
   		(@XAmount > 0 and (@TaxAmount < 0 or @FinanceChg < 0 or @Retainage < 0)) goto GetNextTrans
   
   /************************* ESTABLISH OVERALL INVOICES AMOUNTS FOR APPLICATION ************************/
   
   	/* If discounts are used then calculate what is available. This gets added to AmtLeft
   	   upfront since it goes to the amount of cash made available to apply. */
   	/***** Evaluate Discount Amounts Available *****/
   	if @DiscYN = 'Y'
   		begin
     		select @ApplyDisc = case when @PayTransDate <= @DiscDate then (@DiscOffered + @DiscTaken) else 0 end
   		select @ApplyTaxDisc = case when @PayTransDate <= @DiscDate then @TaxDisc else 0 end
     		--if @ApplyDisc < 0 select @ApplyDisc = 0
   		--if @ApplyDisc = 0 or @ApplyTaxDisc < 0 select @ApplyTaxDisc = 0
   		if @ApplyDisc = 0 select @ApplyTaxDisc = 0
   		end
   	else
     		begin
   		select @ApplyDisc = 0
   		select @ApplyTaxDisc = 0
     		end
   
   	/* Start with Base amounts */
   	select @ApplyAmt = @XAmount - (@TaxAmount + @FinanceChg + @Retainage)
   	select @AmtLeft = @AmtLeft + @ApplyDisc + @ApplyTaxDisc
   
   	/************** ATTEMPT TO CATCH BAD COLUMN DATA AND SKIP ********************/
   	/* If either Tax, Finance charges, or Retainage columns have not remained
   	   correctly balanced over time, (ie: FC column missing credit amounts and is
   	   greater than it should be) then this may catch SOME of them and skip processing.
   	   It helps, but is far from full proof.  It all depends on Values. (The combined 
   	   Tax, FC and Retg buckets are greater than the Total amount on this invoice) */
   	if (@ApplyAmt < 0 and @XAmount > 0) or (@ApplyAmt > 0 and @XAmount < 0) goto GetNextTrans
   
   	/* Set Apply Amounts, assuming we have enough to include them. */
   	select @ApplyTax = @TaxAmount, @ApplyAmt = @ApplyAmt + @TaxAmount
   	if @RetgYN = 'Y' select @ApplyRetg = @Retainage, @ApplyAmt = @ApplyAmt + @Retainage
   	if @ExcludeFCYN = 'N' select @ApplyFC = @FinanceChg, @ApplyAmt = @ApplyAmt + @FinanceChg
   
   	/* Adjust the Apply Amounts based on the @AmtLeft (which includes Discounts at this 
   	   point but may be adjusted later after considering Retainage).  This section only 
   	   comes into play on the last invoice where there is not enough cash left to apply
   	   total amounts.  In this case, we apply in the following order of priority:
   	   		Tax, Principle, Finance Charges, and Retg.
   
   	   This is a tricky section of code.  Small/quick changes here have large, and sometimes
   	   not so obvious consequences!! Think it though carefully!  I took days to keep this
   	   simple and still incorporate all of the rules when applying cash.
   
   	   @AmtLeft is NOT a consideration on negative invoices since all negative amounts
   	   replenish or add to the overall @AmtLeft available to process. */
   	if @XAmount > 0 and @AmtLeft < @ApplyAmt		--@AmtLeft already includes Discounts if available
   		begin
   		/* If here, there is not enough to pay all Tax, Principle, FC's if included, 
   		   and Retg if included.  Discounts are allowed even when paying only partial Retg. */
   		if @AmtLeft > (@ApplyAmt - @ApplyRetg)
   			begin
   			/* Pay Principle, Tax, FC's and any remaining to Retg */
   			select @ApplyRetg = @AmtLeft - (@ApplyAmt - @ApplyRetg)
   			select @ApplyAmt = @AmtLeft
   			goto KeepGoing	--Discounts still valid 
   			end				
   
   		/* From this point on, Discounts are only allowed if the entire invoice (Retg excluded)
   		   can be paid in Full.  Otherwise remove this Invoices discount amounts and reset (reduce)
   		   the AmtLeft that can be applied overall. */
   		if @AmtLeft < (@ApplyAmt - @ApplyRetg) 
   			begin
   			/* Not enough to pay last Invoice in FULL, Cancel Discounts. */
   			select @AmtLeft = @AmtLeft - (@ApplyDisc + @ApplyTaxDisc)
   			select @ApplyDisc = 0, @ApplyTaxDisc = 0
   			end
   
   		/* Continue on with evaluation using adjusted AmtLeft (Possibly reduced) */
   		if @AmtLeft > (@ApplyAmt - (@ApplyFC + @ApplyRetg))
   			begin
   			/* Pay Principle, Tax and any remaining to FC's */
   			select @ApplyFC = @AmtLeft - (@ApplyAmt - (@ApplyFC + @ApplyRetg))
   			select @ApplyRetg = 0
   			select @ApplyAmt = @AmtLeft
   			goto KeepGoing	
   			end				
   
   		/***************** PRIORITIZE TAX AFTER PRINCIPLE OPTION ***********************/
   		--if @AmtLeft > @ApplyAmt - (@ApplyTax + @ApplyFC + @ApplyRetg)
   		--	begin
   			/* Pay Principle and any remaining to Tax */
   		--	select @ApplyTax = @AmtLeft - (@ApplyAmt - (@ApplyTax + @ApplyFC + @ApplyRetg))
   		--	select @ApplyRetg = 0, @ApplyFC = 0
   		--	select @ApplyAmt = @AmtLeft
   		--	goto KeepGoing
   		--	end
   
   		--select @ApplyRetg = 0, @ApplyFC = 0, @ApplyTax = 0, @ApplyAmt = @AmtLeft
   		/***************** END PRIORITIZE TAX AFTER PRINCIPLE OPTION *******************/
   
   		/************************** PRIORITIZE TAX FIRST OPTION ************************/		
   		select @ApplyRetg = 0, @ApplyFC = 0
   		select @ApplyAmt = @AmtLeft
   		select @ApplyTax = case when @ApplyTax > @AmtLeft then @AmtLeft else @ApplyTax end
   		/************************ END PRIORITIZE TAX FIRST OPTION **********************/
   		end
   
   /* All Apply amounts have been determined. */
   KeepGoing:
   	/* if retainage is to be paid then we need to check the invoice source. */
   	if @ApplyRetg <> 0 and @JBFlag = 0
   		begin
   		select @Source = Source
   		from bARTH h with (nolock)
   		where h.ARCo = @aARCo and h.CustGroup = @CustGroup and h.Customer = @Customer and h.Mth = @aMth 
   			and h.ARTrans = @aARTrans
   
   		if @Source = 'JB' select @JBFlag = 1
   		end
   
   	/* Process Invoice amounts to be applied to the Invoice lines */	
   	exec @rcode = bspARAutoApplyLine @ARCo, @BatchMth, @BatchId, @BatchSeq,
   	  	@Mth, @ARTrans, @ApplyAmt, @ApplyTax, @ApplyRetg, @ApplyDisc, @ApplyTaxDisc,
   		@ApplyFC, @CustJob, @Option, @msg output
   
   	/* Exit immediately when applying cash to a transaction fails.  Display message
   	   to User.  All previous transactions will have cash applied correctly.  User may
   	   Post what is applied or start over.  */
   	if @rcode = 1 goto bspexit
   
   	/* If continuing, reduce AmtLeft by that Applied to last invoice. (Discounts
   	   have already been incorporated earlier for this invoice) */
   	select @AmtLeft = @AmtLeft - @ApplyAmt
   
   GetNextTrans:
   	/* get the next invoice Trans */
   	fetch next from bcProcAA into @aTransDate, @aInvoice, @aARCo, @aMth, @aARTrans
   	end		/* End Invoice Process loop */
   
   bspexit:
   
   /* Close and deallocate Cursor */
   if @OpenCursor = 1
   	begin
   	close bcProcAA
   	deallocate bcProcAA
   	select @OpenCursor = 0
   	end
   
   /* Clear out Processing Table bARAA for this user */
   delete bARAA where VPUserName = SUSER_SNAME()
   
   /* Single error to user if any retainage was paid on an Invoice from JB */
   if @JBFlag = 1
   	begin
   	select @msg = 'JBYes', @JBFlag = 0
   	end
   
   if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[bspARAutoApply]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARAutoApply] TO [public]
GO
