SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARHotKeyTaxWriteOff    Script Date: 5/23/02 9:36:41 AM ******/

CREATE   proc [dbo].[bspARHotKeyTaxWriteOff]

@arco bCompany=null, @batchmth bMonth=null, @batchid bBatchID=null, @batchseq int=null,
@applymth bMonth=null, @applytrans bTrans=null, @action char(1),
@newbatchid int output, @errmsg varchar(255) output

as
   
/*******************************************************************************
* CREATED BY:	TJL 05/23/02 - Issue #5212
* MODIFIED BY:	TJL 01/09/03 - Issue #19673:  Change from Tax 'W' WriteOff to 'A' Adjustment Like Vision
*		DANF 02/14/03 - Issue #20127: Pass restricted batch default to bspHQBCInsert
*		TJL 07/26/04 - Issue #25142:  Reverse TaxDisc Offered as well, Add "with (nolocks)"
*		DANF 12/21/04 - Issue #26577: Changed reference on table DDUP 
*		TJL 07/19/07 - Issue #27720, 6x Rewrite.  Change DDUP to use vDDUP
*		TJL 06/05/08 - Issue #128457:  ARCashReceipts International Sales Tax
*		GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
*
*
* USAGE:
* 	Generate a Tax Adjustment batch via a HotKey 'Cntrl-T' from ARCashReceipts
*	while on a Cash Receipts grid record.
*
* INPUT PARAMETERS:
* 	@arco
*	@batchmth, @batchid, @batchseq	-	From this ARCashReceipts batch
*	@applymth, @applymth	-	Input transaction to apply adjustment
*	@action		-	Header Action type.  This adjustment not allowed if 'C' or 'D'
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
   
/* Working Variables */
declare @rcode int, @nextseq int, @todaydate bDate, @arline smallint,
	@nextARLine smallint, @rectype int, @glwriteoffacct bGLAcct,
   	@OrigTaxAmt bDollar, @BatchOrigTaxAmt bDollar, @TaxAmtDue bDollar,
   	@BatchTaxAmtDue bDollar, @TaxDisc bDollar, @BatchTaxDisc bDollar, 
   	@postamt bDollar, @posttax bDollar,	@posttaxdisc bDollar, @RestrictedBatches bYN,
	--International Tax
	@OrigRetgTaxAmt bDollar, @BatchOrigRetgTaxAmt bDollar, @RetgTaxAmtDue bDollar,
   	@BatchRetgTaxAmtDue bDollar, @postretgtax bDollar
   
set nocount on
   
select @rcode = 0
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
   	select @errmsg='An automatic Tax Reversal may not be generated on a transaction '
   	select @errmsg=@errmsg + 'currently being Changed or Deleted!',@rcode=1
   	goto bspexit
   	end
   
/* Check to see if any payments have been applied directly to 'TaxAmount' on this Invoice. */
/* Get bARTL amounts */
select @TaxAmtDue = isnull(sum(l.TaxAmount),0),
	@OrigTaxAmt = sum(case when h.ARTransType <> 'P' then IsNull(l.TaxAmount,0) else 0 end),
	@TaxDisc = isnull(sum(l.TaxDisc),0),
	@RetgTaxAmtDue = isnull(sum(l.RetgTax),0),
	@OrigRetgTaxAmt = sum(case when h.ARTransType <> 'P' then IsNull(l.RetgTax,0) else 0 end)
from bARTL l with (nolock)
join bARTH h with (nolock) on h.ARCo=l.ARCo and h.Mth=l.Mth and h.ARTrans=l.ARTrans
where l.ARCo=@arco and l.ApplyMth=@applymth and l.ApplyTrans=@applytrans
   
/* Get bARBL amounts */
select @BatchTaxAmtDue = sum(case ARBL.TransType when 'D'
        			then case when ARBH.ARTransType in ('I','A','F','R')
             		then -ARBL.oldTaxAmount else ARBL.oldTaxAmount
            		end

       			else

            		case when ARBH.ARTransType in ('I','A','F','R')
             		then IsNull(ARBL.TaxAmount,0)-IsNull(ARBL.oldTaxAmount,0)
             		else -IsNull(ARBL.TaxAmount,0)+IsNull(ARBL.oldTaxAmount,0)
            		end
        			end),

        @BatchOrigTaxAmt = sum(case ARBL.TransType when 'D'
        			then case when ARBH.ARTransType in ('I','A','F','R')
             		then -ARBL.oldTaxAmount 
				else case when ARBH.ARTransType in ('C','W') then ARBL.oldTaxAmount else 0 end
            		end

       			else

            		case when ARBH.ARTransType in ('I','A','F','R')
             		then IsNull(ARBL.TaxAmount,0)-IsNull(ARBL.oldTaxAmount,0)
             		else case when ARBH.ARTransType in ('C','W') then -IsNull(ARBL.TaxAmount,0)+IsNull(ARBL.oldTaxAmount,0) else 0 end
            		end
        			end),

		@BatchTaxDisc = sum(case ARBL.TransType when 'D'
        			then case when ARBH.ARTransType in ('I','A','F','R')
             		then -ARBL.oldTaxDisc else ARBL.oldTaxDisc
            		end

       			else

            		case when ARBH.ARTransType in ('I','A','F','R')
             		then IsNull(ARBL.TaxDisc,0)-IsNull(ARBL.oldTaxDisc,0)
             		else -IsNull(ARBL.TaxDisc,0)+IsNull(ARBL.oldTaxDisc,0)
            		end
        			end),

		@BatchRetgTaxAmtDue = sum(case ARBL.TransType when 'D'
        			then case when ARBH.ARTransType in ('I','A','F','R')
             		then -ARBL.oldRetgTax else ARBL.oldRetgTax
            		end

       			else

            		case when ARBH.ARTransType in ('I','A','F','R')
             		then IsNull(ARBL.RetgTax,0)-IsNull(ARBL.oldRetgTax,0)
             		else -IsNull(ARBL.RetgTax,0)+IsNull(ARBL.oldRetgTax,0)
            		end
        			end),

	@BatchOrigRetgTaxAmt = sum(case ARBL.TransType when 'D'
        			then case when ARBH.ARTransType in ('I','A','F','R')
             		then -ARBL.oldRetgTax 
					else case when ARBH.ARTransType in ('C','W') then ARBL.oldRetgTax else 0 end
            		end

       			else

            		case when ARBH.ARTransType in ('I','A','F','R')
             		then IsNull(ARBL.RetgTax,0)-IsNull(ARBL.oldRetgTax,0)
             		else case when ARBH.ARTransType in ('C','W') then -IsNull(ARBL.RetgTax,0)+IsNull(ARBL.oldRetgTax,0) else 0 end
            		end
        			end)
from bARBL ARBL with (nolock)
join bARBH ARBH with (nolock) on ARBH.Co=ARBL.Co and ARBH.Mth=ARBL.Mth and ARBH.BatchId=ARBL.BatchId and ARBH.BatchSeq=ARBL.BatchSeq
where ARBL.Co=@arco and ARBL.ApplyMth=@applymth and ARBL.ApplyTrans=@applytrans
--and ARBL.BatchSeq <> (case when ARBL.Mth = @batchmth and ARBL.BatchId = @batchid  then @batchseq else 0 end)
   
/* Combine and compare amounts - An unequal comparison means a Payment has been applied to
  tax and we may not proceed.	@OrigTaxAmt = No Payments, @TaxAmtDue = With Payments */
if (isnull(@OrigTaxAmt, 0) + isnull(@BatchOrigTaxAmt, 0) + isnull(@OrigRetgTaxAmt, 0) + isnull(@BatchOrigRetgTaxAmt, 0)) <> 
	(isnull(@TaxAmtDue, 0) + isnull(@BatchTaxAmtDue, 0) + isnull(@RetgTaxAmtDue, 0) + isnull(@BatchRetgTaxAmtDue, 0))
	begin
	select @errmsg = 'Tax has been paid on this invoice.  You may not generate a'
	select @errmsg = @errmsg + ' Tax Reversal until partial tax payment is deleted or reversed!', @rcode=1
	goto bspexit
	end
else	-- If comparison is equal, then do not proceed if value is 0.00
	begin
	if isnull(@OrigTaxAmt, 0) + isnull(@BatchOrigTaxAmt, 0) + isnull(@OrigRetgTaxAmt, 0) + isnull(@BatchOrigRetgTaxAmt, 0) = 0
		begin
		select @errmsg = 'There is no Tax to be reversed!', @rcode=1
		goto bspexit
		end
	end
   
/* We are going to proceed so we need a RecType from this invoice and a GLWriteOffAcct
  from the RecType */
/*
select @rectype = h.RecType, @glwriteoffacct = r.GLWriteOffAcct
from bARTH h with (nolock)
join bARRT r with (nolock) on r.ARCo = h.ARCo and r.RecType = h.RecType
where h.ARCo = @arco and h.Mth = @applymth and h.ARTrans = @applytrans
if @@rowcount = 0
	begin
	select @errmsg = 'Invoice contains an invalid RecType!', @rcode=1
	goto bspexit
	end
*/
   
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
   		select @rcode = 1, @errmsg = 'Missing :' +SUSER_SNAME() + ' from vDDUP.'
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
   
/* Enter Header entry for this Adjustment Transaction */
insert into bARBH(Co, Mth, BatchId, BatchSeq, TransType, Source, ARTransType, CustGroup, 
	Customer, JCCo, Contract, AppliedMth, AppliedTrans, RecType, Invoice, Description, 
	TransDate, DueDate, PayTerms)
select @arco, @batchmth, @newbatchid, @nextseq, 'A', 'AR Invoice', 'A', CustGroup, 
	Customer, JCCo, Contract, @applymth, @applytrans, RecType, Invoice, 'Auto Tax Adjustment', 
	@todaydate, null, PayTerms
from bARTH with (nolock)
where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add header record to ARInvoice Entry Batch!', @rcode = 1
	goto bspexit
	end
   
/* Begin Line Loop - Process Adjustment as total Tax Amount on each line */
select @arline = min(ARLine)
from bARTL with (nolock)
where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans
   
while @arline is not null
   	begin	/* Begin Line Loop */
   	select @postamt = 0, @posttax = 0, @posttaxdisc = 0, @postretgtax = 0
   
   	/* Get Line Tax Amount Due. At this point we have already concluded that no
   	   payments exist, therefore, TaxAmtDue will equal the full TaxAmt for the line. */
   	select @TaxAmtDue = IsNull(sum(bARTL.TaxAmount),0),
   		@TaxDisc = IsNull(sum(bARTL.TaxDisc),0),
		@RetgTaxAmtDue = IsNull(sum(bARTL.RetgTax),0)
	from bARTL with (nolock)
   	where ARCo = @arco and ApplyMth = @applymth and ApplyTrans = @applytrans 
   		and ApplyLine = @arline
   
   	select @BatchTaxAmtDue = sum(case ARBL.TransType when 'D'
            			then case when ARBH.ARTransType in ('I','A','F','R')
                 		then -ARBL.oldTaxAmount else ARBL.oldTaxAmount
                		end
   
           			else
   
                		case when ARBH.ARTransType in ('I','A','F','R')
                 		then IsNull(ARBL.TaxAmount,0)-IsNull(ARBL.oldTaxAmount,0)
                 		else -IsNull(ARBL.TaxAmount,0)+IsNull(ARBL.oldTaxAmount,0)
                		end
            			end),
   
   		@BatchTaxDisc = sum(case ARBL.TransType when 'D'
            			then case when ARBH.ARTransType in ('I','A','F','R')
                 		then -ARBL.oldTaxDisc else ARBL.oldTaxDisc
                		end
   
           			else
   
                		case when ARBH.ARTransType in ('I','A','F','R')
                 		then IsNull(ARBL.TaxDisc,0)-IsNull(ARBL.oldTaxDisc,0)
                 		else -IsNull(ARBL.TaxDisc,0)+IsNull(ARBL.oldTaxDisc,0)
                		end
            			end),

		@BatchRetgTaxAmtDue = sum(case ARBL.TransType when 'D'
            			then case when ARBH.ARTransType in ('I','A','F','R')
                 		then -ARBL.oldRetgTax else ARBL.oldRetgTax
                		end
   
           			else
   
                		case when ARBH.ARTransType in ('I','A','F','R')
                 		then IsNull(ARBL.RetgTax,0)-IsNull(ARBL.oldRetgTax,0)
                 		else -IsNull(ARBL.RetgTax,0)+IsNull(ARBL.oldRetgTax,0)
                		end
            			end)
   	from bARBL ARBL with (nolock)
   	join bARBH ARBH with (nolock) on ARBH.Co=ARBL.Co and ARBH.Mth=ARBL.Mth and ARBH.BatchId=ARBL.BatchId and ARBH.BatchSeq=ARBL.BatchSeq
   	where ARBL.Co=@arco and ARBL.ApplyMth=@applymth and ARBL.ApplyTrans=@applytrans
   		and ARBL.ApplyLine=@arline
   		--and ARBL.BatchSeq <> (case when ARBL.Mth = @batchmth and ARBL.BatchId = @batchid  then @batchseq else 0 end)
   
   	select @posttax = isnull(@TaxAmtDue, 0) + isnull(@BatchTaxAmtDue, 0), @postamt = @posttax,
   		@posttaxdisc = isnull(@TaxDisc, 0) + isnull(@BatchTaxDisc, 0),
		@postretgtax = isnull(@RetgTaxAmtDue, 0) + isnull(@BatchRetgTaxAmtDue, 0)
   
   	/* Insert into Batch table bARBL */
   	if isnull(@postamt,0) <> 0
        	begin
        	select @nextARLine = Max(ARLine) + 1  /* This is a new Batch line, Different than @arline to which we are applying */
        	from bARBL
        	where Co = @arco and Mth = @batchmth and BatchId = @newbatchid and BatchSeq = @nextseq
    
        	insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType,
				LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
				Amount, TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, DiscOffered, TaxDisc, DiscTaken,
				FinanceChg, ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, 
   				ContractUnits, Job, PhaseGroup, Phase, CostType, UM, JobUnits, JobHours,
   				ActDate, INCo, Loc, MatlGroup, Material, UnitPrice, ECM, MatlUnits,
   				CustJob)
        	select bARTL.ARCo, @batchmth, @newbatchid, @nextseq, IsNull(@nextARLine,1), 'A', null, bARTL.RecType,
           		bARTL.LineType, bARTL.Description, bARTL.GLCo, bARTL.GLAcct, bARTL.TaxGroup, bARTL.TaxCode,
           		-(@postamt + @postretgtax), -bARTL.TaxBasis, -@posttax, 0, -@postretgtax, -@postretgtax, 0, -@posttaxdisc, 0, 
				0, @applymth, @applytrans, bARTL.ApplyLine,	bARTL.JCCo, bARTL.Contract, bARTL.Item, 
				0, bARTL.Job, bARTL.PhaseGroup, bARTL.Phase, bARTL.CostType, bARTL.UM, null, null,
				bARTL.ActDate, bARTL.INCo, bARTL.Loc, bARTL.MatlGroup, bARTL.Material, 0, bARTL.ECM, 0, 
				bARTL.CustJob
        	from bARTL with (nolock)
        	where bARTL.ARCo = @arco and bARTL.Mth = @applymth and bARTL.ARTrans = @applytrans and bARTL.ARLine = @arline
        	end
   
GetNextLine:
   	select @arline = min(ARLine)
   	from bARTL
   	where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans
   		and ARLine > @arline
   	end		/* End Line Loop */
   
/* Reset HQBC status to Open */
exec @rcode = bspHQBCExitCheck @arco, @batchmth, @newbatchid, 'AR Invoice', 'ARBH', 
@errmsg output
   
bspexit:
if @rcode <> 0 select @errmsg = @errmsg	--+ char(13) + char(10) + '[bspARHotKeyTaxWriteOff]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARHotKeyTaxWriteOff] TO [public]
GO
