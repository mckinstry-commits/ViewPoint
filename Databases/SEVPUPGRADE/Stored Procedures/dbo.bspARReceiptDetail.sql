SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARReceiptDetail    Script Date: 8/28/99 9:34:14 AM ******/
CREATE proc [dbo].[bspARReceiptDetail]
/***********************************************************
* CREATED BY: JRE 7/7/97
* MODIFIED By:  JM 9/25/97 - Added return of ARBL.DiscOffered
*		JRE 11/20/98	- Added temp file to include other batches
*		JM 12/14/98 - Changed select from bARTL from ARLine->
*					ApplyLine, Mth->ApplyMth, and ARTrans->ApplyTrans.
*  		TJL 10/03/01 - Issue #14498:  Correct and allow posting to same invoice using 2 sequences, same batch\
*		TJL 12/21/01 - Issue #14170:  Add new amount to grid for (Amtdue - FCAmt) for each line.
*		TJL 03/28/02 - Issue #16734:  Add Finance Chg UnpaidFC column and ApplyFC Column to grid.
*		TJL 04/04/02 - Issue #16280:  Do not include/sum bARTL amounts for payments added back into batch for change.
*		TJL 05/13/02 - Issue #17421:  Add UnPaid Tax column and Apply Tax column to grid.
*		TJL 07/30/02 - Issue #11219:  Add Avail TaxDisc and Apply TaxDisc to grid.
*		TJL 08/07/03 - Issue #22087:  Performance mods,  add NoLocks
*		TJL 09/01/04 - Issue #21060:  Add StdItem to grid and add UnitsBilled Label
*		TJL 02/28/08 - Issue #125289:  Include unposted batch values for ONLY unposted ARCashReceipts (P) batches. (Not A, C, W, F)
*		TJL 06/05/08 - Issue #128457:  ARCashReceipts International Sales Tax
*
* USAGE:
*	Fills grid in AR Pmt Detail
*
* INPUT PARAMETERS
*	ARCo, BatchMth, BatchId, BatchSeq, ApplyMth, ApplyTrans
*
*
* OUTPUT PARAMETERS
*   @msg      Description or error message
* RETURN VALUE
*   0         success
*   1         msg & failure
*****************************************************/
(@ARCo bCompany,@BatchMth bMonth,@BatchId bBatchID,@BatchSeq int, @ApplyMth bMonth,
@ApplyTrans bTrans) /*, @msg varchar(255) output)*/
as
set nocount on

declare @rcode integer, @paytrans int

select @rcode = 0
   
/* Get Payment transaction number for a transaction that has been added back
  into the batch. */
select @paytrans = min(ARTrans)
from bARBL with (nolock)
where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
   
begin

create table #PmtDetailGrid
	(ARLine int null,
	Amount numeric(12,2) null,
 	ApplyAmt numeric(12,2) null,
 	DiscTaken numeric(12,2) null,
 	TaxDue numeric(12,2) null,
 	ApplyTax numeric(12,2) null,
 	OpenRetg numeric(12,2) null,
 	ApplyRetg numeric(12,2) null,
 	OrigRetg numeric(12,2) null,
 	DiscOffered numeric(12,2) null,
 	PrevDiscTaken numeric(12,2) null,
 	FCAmtDue numeric(12,2) null,
	ApplyFC numeric(12,2) null,
 	AvailTaxDisc numeric(12,2) null,
	ApplyTaxDisc numeric(12,2) null,
	ContractUnits numeric(12,3) null,
   	OpenRetgTax numeric(12,2) null,
	ApplyRetgTax numeric(12,2) null)
/**********************/
/* get invoice totals */
/**********************/
insert into #PmtDetailGrid
select ARTL.ApplyLine,
	AmountDue=IsNull(sum(ARTL.Amount),0),
	ApplyAmt=0,
	DiscTaken=0,
	TaxDue=IsNull(sum(ARTL.TaxAmount),0),
	ApplyTax=0,
	OpenRetg=IsNull(sum(ARTL.Retainage),0),
	ApplyRetg=0,
	OrigRetg=case when ARTH.ARTransType in ('I','C','W','A') then IsNull(sum(ARTL.Retainage),0) else 0 end,
	DiscOffered=IsNull(sum(ARTL.DiscOffered),0),
	PrevDiscTaken=IsNull(sum(ARTL.DiscTaken),0),
	FCAmtDue=IsNull(sum(ARTL.FinanceChg),0),
	ApplyFC=0,
	AvailTaxDisc=IsNull(sum(ARTL.TaxDisc),0),
	ApplyTaxDisc=0,
	ContractUnits = IsNull(sum(ARTL.ContractUnits),0),
	OpenRetgTax=IsNull(sum(ARTL.RetgTax),0),
	ApplyRetgTax=0
from bARTL ARTL with (nolock)
join bARTH ARTH with (nolock) on ARTL.ARCo = ARTH.ARCo	and ARTL.Mth = ARTH.Mth and ARTL.ARTrans = ARTH.ARTrans
where ARTL.ARCo = @ARCo and ARTL.ApplyMth = @ApplyMth and ARTL.ApplyTrans = @ApplyTrans
	and (isnull(ARTH.InUseBatchID,0) <> @BatchId 
	or (isnull(ARTH.InUseBatchID,0) = @BatchId and ARTH.Mth <> @BatchMth)
	or (isnull(ARTH.InUseBatchID,0) = @BatchId and ARTH.Mth = @BatchMth and ARTH.ARTrans <> isnull(@paytrans,0)))
group by ARTL.ApplyLine, ARTH.ARTransType

/**************************************************************/
/* get totals from other batches except for the current check */
/* 'IAFR' are normally positive so add them up - later we will */
/* subtract non 'IAFR' */
/**************************************************************/
insert into #PmtDetailGrid
select ARBL.ApplyLine,
	AmountDue=sum(case ARBL.TransType
 	      	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	         	then -ARBL.oldAmount else ARBL.oldAmount
	           	end
	    	else
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.Amount,0)-IsNull(ARBL.oldAmount,0)
	            else -IsNull(ARBL.Amount,0)+IsNull(ARBL.oldAmount,0)
	           	end
	       	end),
	ApplyAmt=0,
	DiscTaken=0,
	TaxDue=sum(case ARBL.TransType
	       	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then -ARBL.oldTaxAmount else ARBL.oldTaxAmount
	           	end
	       	else
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.TaxAmount,0)-IsNull(ARBL.oldTaxAmount,0)
	            else -IsNull(ARBL.TaxAmount,0)+IsNull(ARBL.oldTaxAmount,0)
	           	end
	       	end),
	ApplyTax=0,
	OpenRetg=sum(case ARBL.TransType
	       	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then -ARBL.oldRetainage else ARBL.oldRetainage
	           	end
	       	else
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.Retainage,0)-IsNull(ARBL.oldRetainage,0)
	            else -IsNull(ARBL.Retainage,0)+IsNull(ARBL.oldRetainage,0)
	           	end
	       	end),
	ApplyRetg=0,
	OrigRetg=0,
	DiscOffered=sum(case ARBL.TransType
	       	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then -ARBL.oldDiscOffered else ARBL.oldDiscOffered
	           	end
	  		else
	     		case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.DiscOffered,0)-IsNull(ARBL.oldDiscOffered,0)
	            else -IsNull(ARBL.DiscOffered,0)+IsNull(ARBL.oldDiscOffered,0)
	           	end
	       	end),
	PrevDiscTaken=sum(case ARBL.TransType
	       	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then -ARBL.oldDiscTaken else ARBL.oldDiscTaken
	           	end
	       	else
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.DiscTaken,0)-IsNull(ARBL.oldDiscTaken,0)
	            else -IsNull(ARBL.DiscTaken,0)+IsNull(ARBL.oldDiscTaken,0)
	           	end
	       	end),
	FCAmtDue=sum(case ARBL.TransType
	       	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then -ARBL.oldFinanceChg else ARBL.oldFinanceChg
	           	end
	       	else
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.FinanceChg,0)-IsNull(ARBL.oldFinanceChg,0)
	            else -IsNull(ARBL.FinanceChg,0)+IsNull(ARBL.oldFinanceChg,0)
	           	end
	       	end),
	ApplyFC=0,
	AvailTaxDisc=sum(case ARBL.TransType
	       	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then -ARBL.oldTaxDisc else ARBL.oldTaxDisc
	           	end
	       	else
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.TaxDisc,0)-IsNull(ARBL.oldTaxDisc,0)
	            else -IsNull(ARBL.TaxDisc,0)+IsNull(ARBL.oldTaxDisc,0)
	           	end
	       	end),
	ApplyTaxDisc=0,
	ContractUnits=sum(case ARBL.TransType
	       	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then -ARBL.oldContractUnits else ARBL.oldContractUnits
	           	end
	       	else
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.ContractUnits,0)-IsNull(ARBL.oldContractUnits,0)
	            else -IsNull(ARBL.ContractUnits,0)+IsNull(ARBL.oldContractUnits,0)
	           	end
	       	end),
	OpenRetgTax=sum(case ARBL.TransType
	       	when 'D' then
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then -ARBL.oldRetgTax else ARBL.oldRetgTax
	           	end
	       	else
	           	case when ARBH.ARTransType in ('I','A','F','R')
	            then IsNull(ARBL.RetgTax,0)-IsNull(ARBL.oldRetgTax,0)
	            else -IsNull(ARBL.RetgTax,0)+IsNull(ARBL.oldRetgTax,0)
	           	end
	       	end),
	ApplyRetgTax=0
from bARBL ARBL with (nolock)
join bARBH ARBH with (nolock) on ARBL.Co=ARBH.Co and ARBL.Mth=ARBH.Mth and
	ARBL.BatchId=ARBH.BatchId and ARBL.BatchSeq=ARBH.BatchSeq
where ARBL.Co=@ARCo and ARBL.ApplyMth=@ApplyMth and ARBL.ApplyTrans=@ApplyTrans
	and ARBH.ARTransType = 'P'
	and ARBL.BatchSeq <> (case when (ARBL.Mth = @BatchMth and ARBL.BatchId = @BatchId) then @BatchSeq else 0 end)
group by ARBL.ApplyLine
   
/************************************/
/* get totals for the current check */
/************************************/
insert into #PmtDetailGrid
select ARBL.ApplyLine,
	AmountDue=0,
	ApplyAmt=sum(ARBL.Amount),
	DiscTaken=sum(ARBL.DiscTaken),
	TaxDue=0,
	ApplyTax=sum(ARBL.TaxAmount),
	OpenRetg=0,
	ApplyRetg=sum(ARBL.Retainage),
	OrigRetg=0,
	DiscOffered=0,
	PrevDiscTaken=0,
	FCAmtDue=0,
	ApplyFC=sum(ARBL.FinanceChg),
	AvailTaxDisc=0,
	ApplyTaxDisc=sum(ARBL.TaxDisc),
	ContractUnits = 0,
	OpenRetgTax=0,
	ApplyRetgTax=sum(ARBL.RetgTax)
from bARBL ARBL with (nolock)
join bARBH ARBH with (nolock) on ARBL.Co = ARBH.Co and ARBL.Mth = ARBH.Mth and ARBL.BatchId = ARBH.BatchId
	and ARBL.BatchSeq = ARBH.BatchSeq
where ARBL.Co = @ARCo
	and ARBL.ApplyMth = @ApplyMth
	and ARBL.ApplyTrans = @ApplyTrans
	and ARBL.Mth = @BatchMth
	and ARBL.BatchId = @BatchId
	and ARBL.BatchSeq = @BatchSeq
	and (isnull(ARBL.ARTrans,0) <> ARBL.ApplyTrans
		or (ARBL.Mth <> ARBL.ApplyMth
			and isnull(ARBL.ARTrans,0) = ARBL.ApplyTrans))
group by ARBL.ApplyMth, ARBL.ApplyTrans, ARBL.ApplyLine
   
/********************************************************************************************/
/* get old amounts in case it is an added transaction in this current Seq. 	    */
/* all other batch amounts have been considered previously.                            */
/********************************************************************************************/

/* TJL notes 12/26/01:  I am unsure about the value of the following code for the following reasons!
1)  This same code does not appear in 'bspARCashReceiptsGridFill' which essentially does exactly the same thing.
2)  This code seems incomplete!  The code should more closely resemble the code for summing all other batches and Seq above.
3)  What is displayed to user represents all posted and unposted batches and Seq, not including this batch/Seq.  If user is 
     changing this transaction (After adding back into batch) then results of the change will show up when moving onto
     next Seq or batch.  
  For the moment, I have rem'd this code pending further review.  If anyone disagrees, please see me immediately and be prepared with
  an example of a customer transaction causing the problem.   Do not panic, this is only displayed information, not calculated data. */
     
/* insert into #PmtDetailGrid
select ARBL.ApplyLine,AmountDue=sum(ARBL.oldAmount),
	ApplyAmt=0, DiscTaken=0, TaxDue=0, OpenRetg=0, ApplyRetg=0, OrigRetg=0, DiscOffered=0,
	PrevDiscTaken=0, FCAmt=?

from bARBH ARBH
join bARBL ARBL on ARBL.Co=ARBH.Co
	and ARBL.Mth=ARBH.Mth
	and ARBL.BatchId=ARBH.BatchId
	and ARBL.BatchSeq=ARBH.BatchSeq
where ARBH.Co = @ARCo
	and ARBH.AppliedMth=@ApplyMth
	and ARBH.AppliedTrans=@ApplyTrans
	and ARBH.Mth = @BatchMth
	and ARBH.BatchId = @BatchId
	and ARBH.BatchSeq = @BatchSeq
	and (isnull(ARBL.ARTrans,0) <> ARBL.ApplyTrans
	or (ARBL.Mth <> ARBL.ApplyMth and isnull(ARBL.ARTrans,0) = ARBL.ApplyTrans))
group by ARBL.ApplyMth, ARBL.ApplyTrans, ARBL.ApplyLine
   */
   
/* select the results */
select ARLine = ARTL.ARLine,
	Item = ARTL.Item,
	StdItem = JCCI.SICode,
	CustJob = ARTL.CustJob,
	AmountDue = IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0),
	AmtDueLessFC = IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0)-IsNull(sum(t.FCAmtDue),0),
 	ApplyAmount = IsNull(sum(t.ApplyAmt),0)-IsNull(sum(t.ApplyRetg),0),
	DiscTaken = IsNull(sum(t.DiscTaken),0),
	Balance = (IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0))-(IsNull(sum(t.ApplyAmt),0)-IsNull(sum(t.ApplyRetg),0)),
	TaxDue = IsNull(sum(t.TaxDue),0),
	ApplyTax = IsNull(sum(t.ApplyTax),0),   	
	OpenRetg = IsNull(sum(t.OpenRetg),0),
	ApplyRetg = IsNull(sum(t.ApplyRetg),0),
	FCAmtDue = IsNull(sum(t.FCAmtDue),0),
	ApplyFC = IsNull(sum(t.ApplyFC),0),
	AvailTaxDisc = IsNull(sum(t.AvailTaxDisc),0),
	ApplyTaxDisc = IsNull(sum(t.ApplyTaxDisc),0),
	Invoice = ARTH.Invoice,
	ContractItem = JCCI.Description,
	ARLine = min(ARBL.ARLine),
	DiscAvail = IsNull(sum(t.DiscOffered),0)+IsNull(sum(t.PrevDiscTaken),0),
	BilledUnits = IsNull(sum(t.ContractUnits),0),
	OpenRetgTax = IsNull(sum(t.OpenRetgTax),0),
	ApplyRetgTax = IsNull(sum(t.ApplyRetgTax),0)
from bARTL ARTL with (nolock)
join bARTH ARTH with (nolock) on ARTL.ARCo=ARTH.ARCo and ARTL.Mth=ARTH.Mth and ARTL.ARTrans=ARTH.ARTrans
left join bARBL ARBL with (nolock) on 
	ARBL.Co=ARTL.ARCo and	
	ARBL.ApplyTrans=ARTL.ARTrans and
	ARBL.ApplyMth=ARTL.Mth and
	ARBL.ApplyLine=ARTL.ARLine and
	ARBL.Co=@ARCo and
	ARBL.Mth=@BatchMth and
	ARBL.BatchId=@BatchId and
	ARBL.BatchSeq=@BatchSeq
join #PmtDetailGrid t on t.ARLine=ARTL.ARLine
left join bJCCI JCCI with (nolock) on JCCI.JCCo=ARTL.JCCo and
      JCCI.Contract=ARTL.Contract and JCCI.Item=ARTL.Item
where ARTL.ARCo=@ARCo and ARTL.Mth=@ApplyMth and ARTL.ARTrans=@ApplyTrans
group by ARTL.ARLine, ARTL.Item, JCCI.SICode, ARTL.CustJob, ARTH.Invoice, JCCI.Description
end

bspexit:
/* if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspARReceiptDetail]' */
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARReceiptDetail] TO [public]
GO
