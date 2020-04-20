SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBHTotalGet    Script Date: 8/28/99 9:34:07 AM ******/
CREATE  proc [dbo].[bspARBHTotalGet]
/**********************************************************************************************
* CREATED BY: 	CJW 5/30/97
* MODIFIED BY:	bc 8/26/98
*		TJL 06/18/04:  Issue #24636, Rewrite. Correct various bad values
*		TJL 06/13/08 - Issue #128286, ARInvoiceEntry International Sales Tax
*
* USAGE:
*	Used by forms: ,  and ARCashReceipts
*		ARInvoiceEntry:		Sets lblData(LBL_TRANSTOTAL), lblData(LBL_BATCHTOTAL)
*		ARMiscRec:			Sets lblData(LBL_TOTAL), lblData(LBL_TOT_MISC_REC), lblData(LBL_TAX)
*		ARCashReceipts:		Not Used - Similar values already available on form	
*
* INPUT PARAMETERS:
*	ARCO
*	Month
*	BatchId
* 	BatchSeq
*	ARTranstype  	Optional.  Originally inserted for Misc Rec batches.  Type = 'M'
*
* OUTPUT PARAMETERS:
*	@transamount:	Total amount for the specific sequence
*	@batchamount:	Total amount for the batch (all sequences)
*	@retgamount:	Total retainage amount for the specific sequence
*	@discamount:	Total discount amount for the specific sequence
*	@taxamount:		Total tax amount for specific sequence
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
************************************************************************************************/
(@arco  bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @ar_transtype varchar(3) = null,
	@transamount bDollar output, @batchamount bDollar output, @retgamount bDollar output,
	@discamount bDollar output, @taxamount bDollar output, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @transamount = 0, @batchamount = 0, @retgamount = 0, @discamount = 0,
   	@taxamount = 0
   
if @arco is null
	begin
	select @msg = 'Missing AR Company', @rcode = 1
	goto bspexit
	end
   
/* ARCashReceipts:  Come directly from ARCashReceipts Form. */
--if @ar_transtype = 'P'
--	begin
--	--Do something
--	goto bspexit
--	end
   
/* ARMiscReceipts:  Display amounts specific to ARMiscReceipts.  Polarity is not an Issue 
  in ARMiscReceipts. */
if @ar_transtype = 'M'
   	begin
   	/* Get Total batch amount for Misc Receipts only. */
   	select @batchamount = isnull(sum(l.Amount),0)
   	from bARBL l with (nolock)
   	join bARBH h with (nolock) on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId 
   		and h.BatchSeq = l.BatchSeq
   	where l.Co = @arco and l.Mth = @mth and l.BatchId = @batchid and l.TransType <> 'D'
   	  	and h.ARTransType = 'M'
   
   	/* Misc Distributions are stored in bARBM by sequence.  All values displayed on MiscDist
      	   form therefore are by sequence. */
   	select @transamount =isnull(sum(Amount),0), @taxamount = isnull(sum(TaxAmount),0)
   	from bARBL l with (nolock)
   	where l.Co = @arco and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @batchseq and l.TransType <> 'D'
   	goto bspexit
   	end
   
/* ARInvoiceEntry  (ARTransType may be I, A, C, W):  Display amounts specific to ARInvoiceEntry.  Batch 
  typically holds Positive values regardless of the ARTransType (Posting takes care of this later).
  However to display the sum of the batch on the entry form, (All sequences - Some may be Invoice/Adjustments (pos)
  and some may  be Credits/Writeoffs (neg), we need to make the polarity adjustment at this time.  */
select @batchamount = sum(case when h.ARTransType in ('I','A') then IsNull(l.Amount,0) else -(IsNull(l.Amount,0)) end)
from bARBL l with (nolock)
join bARBH h with (nolock) on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
where h.Co = @arco and h.Mth = @mth and h.BatchId = @batchid and l.TransType <> 'D'

/* Misc Distributions are stored in bARBM by sequence.  All values displayed on MiscDist
  form therefore are by sequence. */
select @transamount = sum(case when h.ARTransType in ('I','A') then IsNull(l.Amount,0) else -(IsNull(l.Amount,0)) end),
@taxamount = sum(case when h.ARTransType in ('I','A') then IsNull(l.TaxAmount,0) else -(IsNull(l.TaxAmount,0)) end)
	+ sum(case when h.ARTransType in ('I','A') then IsNull(l.RetgTax,0) else -(IsNull(l.RetgTax,0)) end),
@retgamount = sum(case when h.ARTransType in ('I','A') then IsNull(l.Retainage,0) else -(IsNull(l.Retainage,0)) end), 
@discamount = sum(case when h.ARTransType in ('I','A') then IsNull(l.DiscOffered,0) else -(IsNull(l.DiscOffered,0)) end)
from bARBL l with (nolock)
join bARBH h with (nolock) on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
where l.Co = @arco and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @batchseq and l.TransType <> 'D'
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBHTotalGet] TO [public]
GO
