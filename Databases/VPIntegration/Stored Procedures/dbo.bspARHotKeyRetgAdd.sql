SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARHotKeyRetgAdd    Script Date: 5/28/02 9:36:41 AM ******/
   
   CREATE   proc [dbo].[bspARHotKeyRetgAdd]
   
   @arco bCompany=null, @batchmth bMonth=null, @batchid bBatchID=null, @batchseq int=null,
   @applymth bMonth=null, @applytrans bTrans=null, @action char(1), @retgpct bPct,
   @newbatchid int output, @newretg bDollar output, @errmsg varchar(255) output
   
   as
   
   /*******************************************************************************
   * CREATED BY:	TJL 05/28/02 - Issue #5212
   * MODIFIED BY:	DANF 02/14/03 - Issue #20127, Pass restricted batch default to bspHQBCInsert
   *		TJL 07/26/04 - Issue #25142, Update Cash Receipts with new Retg values, add with (nolock)
   *		TJL 08/05/04 - Issue #25296, Retainage Calculations should NOT include Tax
   *		DANF 12/21/04 - Issue #26577: Changed reference on table DDUP 
   *		TJL 07/19/07 - Issue #27720, 6x Rewrite.  Change DDUP to use vDDUP
   *		GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
   *
   * USAGE:
   * 	Generate a Retainage Adjustment batch via a HotKey 'Cntrl-R' from ARCashReceipts
   *	while on a Cash Receipts grid record.
   *
   * INPUT PARAMETERS:
   * 	@arco
   *	@batchmth, @batchid, @batchseq	-	From this ARCashReceipts batch
   *	@applymth, @applymth	-	Input transaction to apply retainage adjustment
   *	@action		-	Header Action type.  This adjustment not allowed if 'C' or 'D'
   *	@retgpct	-	Retainage percentage.
   *  	
   *
   * OUTPUT PARAMETERS:
   *	New BatchId number
   *	Error message
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *******************************************************************************/
   
/**************************************************************************************
*		NOTE:  NOT CURRENTLY USED!!  IF RE-INSTATED, WILL NEED TO MODIFY			  *
*		TO INCORPORORATE "Retainage Tax" AMOUNTS INTO THE OVERALL PROCESS!!!		  *
*       WILL NEED TO CONSIDER SM Invoice SOURCE                                       *
***************************************************************************************/

   /* Working Variables */
   declare @rcode int, @nextseq int, @todaydate bDate, @arline smallint,
   	@nextARLine smallint, @rectype int, 
   	@lineamt bDollar, @batchlineamt bDollar, @linetaxamt bDollar, @batchlinetaxamt bDollar,
   	@postretgamt bDollar, @RestrictedBatches bYN
   
   set nocount on
   
   select @rcode = 0, @newretg = 0
   ----#141031
   set @todaydate = dbo.vfDateOnly()
      
   if @arco is null
     	begin
     	select @errmsg='ARCo is missing!',@rcode=1
     	goto bspexit
     	end
   if @batchmth is null or @batchid is null or @batchseq is null
     	begin
     	select @errmsg='BatchMth, BatchId, or BatchSeq is missing!',@rcode=1
     	goto bspexit
     	end
   if @applymth is null
     	begin
     	select @errmsg='Invoice ApplyMth is missing!',@rcode=1
     	goto bspexit
     	end
   if @applytrans is null
     	begin
     	select @errmsg='Invoice ApplyTrans is missing!',@rcode=1
     	goto bspexit
     	end
   if @action <> 'A'
   	begin
   	select @errmsg='An automatic Retainage adjustment may not be generated on a transaction '
   	select @errmsg=@errmsg + 'currently being Changed or Deleted!',@rcode=1
   	goto bspexit
   	end
   
   /* Find an existing Open Batch created by this user to add records to if it exists. */
   select @newbatchid = max(BatchId)
   from bHQBC
   where Co = @arco and Mth = @batchmth and Source = 'AR Invoice' and InUseBy is Null
   	and Status = 0 and CreatedBy = SUSER_SNAME()
   if @@rowcount = 1
   	begin
   	/* Validate and Lock existing batch to be used */
   	exec @rcode = bspHQBCUseExisting @arco, @batchmth, @newbatchid, 'AR Invoice', 'ARBH',
   		@errmsg output
   	if @rcode = 1 goto GETNEW
   	end
   else
   	begin
   GETNEW:
   	/* Get Restricted batch default from vDDUP */
   	select @RestrictedBatches = isnull(RestrictedBatches,'N')
   	from dbo.vDDUP with (nolock)
   	where VPUserName = SUSER_SNAME()
   	if @@rowcount <> 1
   	 	begin
   		select @rcode = 1, @errmsg = 'Missing :' + SUSER_SNAME() + ' from vDDUP.'
   		goto bspexit
   		end
   	/* Open New Batch */
   	exec @newbatchid=bspHQBCInsert @arco, @batchmth, 'AR Invoice', 'ARBH', @RestrictedBatches, 'N', Null, Null,
   		@errmsg output
   	if @newbatchid = 0
   		begin
   		select @rcode = 1
   		goto bspexit
   		end
   	end
   
   /* Insert 'AR Invoice - Adjustment' header record into new Batch */
   
   /* Get next Batch Seq number */
   select @nextseq = isnull(max(BatchSeq),0)+1
   from bARBH
   where Co = @arco and Mth = @batchmth and BatchId = @newbatchid
   
   /* Enter Header entry for this WriteOff Transaction */
   insert into bARBH(Co, Mth, BatchId, BatchSeq, TransType, Source, ARTransType, CustGroup, 
   	Customer, JCCo, Contract, AppliedMth, AppliedTrans, RecType, Invoice, Description, 
   	TransDate, DueDate, PayTerms)
   select @arco, @batchmth, @newbatchid, @nextseq, 'A', 'AR Invoice', 'A', CustGroup, 
   	Customer, JCCo, Contract, @applymth, @applytrans, RecType, Invoice, 'Auto Retainage Adjust', 
   	@todaydate, null, PayTerms
   from bARTH with (nolock)
   where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans
   if @@rowcount <> 1
    	begin
    	select @errmsg = 'Unable to add header record to ARInvoice Entry Batch!', @rcode = 1
    	goto bspexit
    	end
   
   /* Begin Line Loop - Process Retainage Adjustment */
   select @arline = min(ARLine)
   from bARTL with (nolock)
   where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans
   
   while @arline is not null
   	begin	/* Begin Line Loop */
   	select @postretgamt = 0
   
   	/* Get Line Amount. We will exclude payments and Finance Charges from consideration
   	   however other adjustments, credits or writeoffs will be factored in. */
   	select @lineamt = IsNull(sum(l.Amount),0),
   		@linetaxamt = IsNull(sum(l.TaxAmount),0)
      	from bARTL l with (nolock)
   	join bARTH h with (nolock) on h.ARCo=l.ARCo and h.Mth=l.Mth and h.ARTrans=l.ARTrans
   	where l.ARCo = @arco and l.ApplyMth = @applymth and l.ApplyTrans = @applytrans 
   		and l.ApplyLine = @arline
   		and l.LineType <> 'F' and h.ARTransType <> 'P'
   
   	select @batchlineamt=sum(case ARBL.TransType when 'D'
            			then case when ARBH.ARTransType in ('I','A','F','R')
                 		then -ARBL.oldAmount else ARBL.oldAmount
                		end
   
           			else
   
                		case when ARBH.ARTransType in ('I','A','F','R')
                 		then IsNull(ARBL.Amount,0)-IsNull(ARBL.oldAmount,0)
                 		else -IsNull(ARBL.Amount,0)+IsNull(ARBL.oldAmount,0)
                		end
            			end),
   
   		@batchlinetaxamt=sum(case ARBL.TransType when 'D'
            			then case when ARBH.ARTransType in ('I','A','F','R')
                 		then -ARBL.oldTaxAmount else ARBL.oldTaxAmount
                		end
   
           			else
   
                		case when ARBH.ARTransType in ('I','A','F','R')
                 		then IsNull(ARBL.TaxAmount,0)-IsNull(ARBL.oldTaxAmount,0)
                 		else -IsNull(ARBL.TaxAmount,0)+IsNull(ARBL.oldTaxAmount,0)
                		end
            			end)
   	from bARBL ARBL with (nolock)
   	join bARBH ARBH with (nolock) on ARBH.Co=ARBL.Co and ARBH.Mth=ARBL.Mth and ARBH.BatchId=ARBL.BatchId and ARBH.BatchSeq=ARBL.BatchSeq
   	where ARBL.Co=@arco and ARBL.ApplyMth=@applymth and ARBL.ApplyTrans=@applytrans
   		and ARBL.ApplyLine=@arline
   		and ARBL.LineType <> 'F' and ARBH.ARTransType <> 'P'
   		/* This sequence does not matter. It will always be 0.00 at this time. Form restrictions will enforce this */
   		--and ARBL.BatchSeq <> (case when ARBL.Mth = @batchmth and ARBL.BatchId = @batchid  then @batchseq else 0 end)
   
   	/* Calculate Retainage Amount for this line. */
   	select @postretgamt = ((isnull(@lineamt, 0) + isnull(@batchlineamt, 0)) - (isnull(@linetaxamt, 0) + isnull(@batchlinetaxamt, 0))) * @retgpct
   
   	/* Insert into Batch table bARBL */
   	if isnull(@postretgamt,0) <> 0
        	begin
        	select @nextARLine = Max(ARLine) + 1  /* This is a new Batch line, Different than @arline to which we are applying */
        	from bARBL
        	where Co = @arco and Mth = @batchmth and BatchId = @newbatchid and BatchSeq = @nextseq
    
        	insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType,
                			LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
                          	Amount, TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered, DiscTaken,
                          	FinanceChg, ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, 
   						ContractUnits, Job, PhaseGroup, Phase, CostType, UM, JobUnits, JobHours,
   						ActDate, INCo, Loc, MatlGroup, Material, UnitPrice, ECM, MatlUnits,
   						CustJob)
        	select bARTL.ARCo, @batchmth, @newbatchid, @nextseq, IsNull(@nextARLine,1), 'A', null, bARTL.RecType,
               		bARTL.LineType, bARTL.Description, bARTL.GLCo, bARTL.GLAcct, bARTL.TaxGroup, bARTL.TaxCode,
               		0, 0, 0, @retgpct, @postretgamt, 0, 0, 0, @applymth, @applytrans, bARTL.ApplyLine,
               		bARTL.JCCo, bARTL.Contract, bARTL.Item, 0, bARTL.Job,
   					bARTL.PhaseGroup, bARTL.Phase, bARTL.CostType, bARTL.UM, bARTL.JobUnits, bARTL.JobHours,
   					bARTL.ActDate, bARTL.INCo, bARTL.Loc, bARTL.MatlGroup, bARTL.Material, bARTL.UnitPrice,
   					bARTL.ECM, bARTL.MatlUnits,	bARTL.CustJob
        	from bARTL with (nolock)
        	where bARTL.ARCo = @arco and bARTL.Mth = @applymth and bARTL.ARTrans = @applytrans and bARTL.ARLine = @arline
        	end
   
   	/* Return the New retainage values to form for updating form grid and related labels */
   	select @newretg = @newretg + isnull(@postretgamt, 0)
   
   GetNextLine:
   	select @arline = min(ARLine)
   	from bARTL with (nolock)
   	where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans
   		and ARLine > @arline
   	end		/* End Line Loop */
   
   /* Reset HQBC status to Open */
   exec @rcode = bspHQBCExitCheck @arco, @batchmth, @newbatchid, 'AR Invoice', 'ARBH', 
   	@errmsg output
   
   bspexit:
   if @rcode <> 0 select @errmsg = @errmsg	--+ char(13) + char(10) + '[bspARHotKeyRetgAdd]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARHotKeyRetgAdd] TO [public]
GO
