SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCashReceiptsGridFill    Script Date: 8/28/99 9:34:10 AM ******/
CREATE proc [dbo].[bspARCashReceiptsGridFill]
/****************************************************************************
* CREATED BY: JRE 06/25/97
* MODIFIED BY: JRE 7/10/97 - Added BatchId & BatchMth input parameters
*		JM 7/11/97 - Added UnPaidRetg return value
*		JM 9/21/97 - Added SortOption input to change sort of recordset
*		JM 6/27/98 - Correted math for Balance in each Sort's select stmt
*						as noted below
*		JM 10/6/98 - Corrected WHERE clauses in 'get totals for the current check',
*						'get old amounts', and 'select the results based on SortOption'
*						sections per Jim to correct display of On Acct receipts recalled
*						to a batch.
*		JRE 11/21/98 - don't add the oldAmount into the amount due calculation
*		GH 03/09/99 - If an invoice has been fully applied in a batch that has not been
*                     posted the invoice should still show up in a new sequence as
*                     amount due=$0.00.  I removed the join on bARBL.BatchSeq = @BatchSeq
*                     in the 'Sort by' routines.
*     	JM 12/6/99 - Added Order By's to each 'Sort By' routine.
*      	JM 12/7/99 - Added ARTH.Mth as first member in ARTrans sort by clause (per JE).
*		GR 6/10/00 - Added  Invoice Amt, Contract#, Prev Applied, CustRef, CustPO columns
*		GR 8/31/00 - Added to display zero amount invoices in the grid issue# 9433
*      	JE 12/02/00 - Changed display of zero invoices correcting issue #9433  - issue # 11490
*      	TJL 04/24/01 - Changed to always display  original Invoice Amount in grid 'Invoice Amount' column and
*     	TJL 10/03/01 - Issue #14498:  Correct and allow posting to same invoice using 2 sequences, same batch
*		TJL 11/27/01 - Issue #15087:  Return ARTH.ARTransType back to ARCashReceipts Grid
*		TJL 12/20/01 - Issue #14170:  Add new amount to grid for (Amtdue - FCAmt), fix displayed 'Invoiced' amount, fix displayed 'PrevApplied' amount
*		TJL 02/19/02 - Issue #16316 & 16338:  Display Mth in grid as mm/yy, display RecType in grid. 
*		TJL 03/28/02 - Issue #16734:  Add Finance Chg Amount Due lable and FC Applied Column to grid.
*		TJL 04/04/02 - Issue #16280:  Do not include/sum bARTL amounts for payments added back into batch for change. 
*		TJL 05/10/02 - Issue #17179:  Fix @ShowOption code.  Supercedes Issues #9433 & #11490.  See Toml & rem'd statements at end if in doubt. 
*		TJL 05/13/02 - Issue #17421:  Add new grid column called 'Tax Applied'.
*		TJL 05/29/02 - Issue #5212:  Fix 'OrigRetg' to include open batch amounts.
*		TJL 07/30/02 - Issue #11219: Add new grid column caleed 'Tax Disc'.
*		TJL 08/07/03 - Issue #22087: Performance updates, No Locks added
*		TJL 09/02/04 - Issue #21058: Add new SortBy Option for Contract
*		TJL 10/09/07 - Issue #125715:  Use Views (not tables) in selects statements to fill grid.  Allows DataType security to work.
*		TJL 02/28/08 - Issue #125289:  Include unposted batch values for ONLY unposted ARCashReceipts (P) batches. (Not A, C, W, F)
*
* USAGE:
* 	Fills grid in AR Receipts
*
* INPUT PARAMETERS:
*	Company, CustGrp, Customer, Option (A=All, O=Open Invoices, R=Open Retg)
*       	BatchId, BatchMth, BatchSeq, SortOption (I=Invoice, C=CustRef,
*			T=Transaction, D=TransDate, U=DueDate)
*
* OUTPUT PARAMETERS:
*	See Select statement below
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@ARCo bCompany = null,@CustGrp bGroup = null,@Customer bCustomer=null,
@ShowOption char(1)=null, @BatchId bBatchID, @BatchMth bMonth, @BatchSeq int,
@SortOption char(1)=null)
as
set nocount on
declare @rcode integer, @paytrans int

select @rcode = 0

/* Get Payment transaction number for a transaction that has been added back
into the batch. */
select @paytrans = min(ARTrans)
from ARBL with (nolock)
where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq

begin
   
create table #CashRecGrid
(Mth smalldatetime null,
ARTrans int null,
Amount numeric(12,2) null,
PrevApplied numeric(12,2) null,
ApplyAmt numeric(12,2) null,
ApplyTax numeric(12,2) null,
DiscTaken numeric(12,2) null,
TaxDiscTaken numeric(12,2) null,
OpenRetg numeric(12,2) null,
ApplyRetg numeric(12,2) null,
OrigRetg numeric(12,2) null,
DiscOffered numeric(12,2) null,
PrevDiscTaken numeric(12,2) null,
TaxAmt numeric(12,2) null,
FCAmtDue numeric(12,2) null,
ApplyFC numeric(12,2) null,
TaxDiscAvail numeric(12,2) null)
   
/**********************/
/* get invoice totals */
/**********************/
insert into #CashRecGrid
select ARTL.ApplyMth, ARTL.ApplyTrans,
	Amount=IsNull(sum(ARTL.Amount),0),
	PrevApplied=sum(case when ARTH.ARTransType = 'P' then IsNull(ARTL.Amount,0) else 0 end),
	ApplyAmt=0, ApplyTax=0, DiscTaken=0, TaxDiscTaken=0, OpenRetg=IsNull(sum(ARTL.Retainage),0), ApplyRetg=0,
	OrigRetg=sum(case when ARTH.ARTransType in ('I','C','W','A') then IsNull(ARTL.Retainage,0) else 0 end),
	DiscOffered=IsNull(sum(ARTL.DiscOffered),0),
	PrevDiscTaken=IsNull(sum(ARTL.DiscTaken),0),
	TaxAmt=IsNull(sum(ARTL.TaxAmount),0), 
	FCAmtDue=IsNull(sum(ARTL.FinanceChg),0),
	ApplyFC = 0,
	TaxDiscAvail=IsNull(sum(ARTL.TaxDisc),0)
from ARTH ARTH with (nolock)
join ARTL ARTL with (nolock) on ARTL.ARCo = ARTH.ARCo and ARTL.Mth = ARTH.Mth and ARTL.ARTrans = ARTH.ARTrans
where ARTH.ARCo = @ARCo and ARTH.CustGroup = @CustGrp and ARTH.Customer = @Customer 
   and(isnull(ARTH.InUseBatchID,0) <> @BatchId 
		or (isnull(ARTH.InUseBatchID,0) = @BatchId and ARTH.Mth <> @BatchMth)
		or (isnull(ARTH.InUseBatchID,0) = @BatchId and ARTH.Mth = @BatchMth and ARTH.ARTrans <> isnull(@paytrans,0)))
group by ARTL.ApplyMth, ARTL.ApplyTrans
   
/**************************************************************/
/* get totals from other batches except for the current check */
/* 'IAFR' are normally positive so add them up - later we will */
/* subtract non 'IAFR' */
/**************************************************************/
insert into #CashRecGrid
select ARBL.ApplyMth, ARBL.ApplyTrans,
	Amount=sum(case ARBL.TransType when 'D' then
				case when ARBH.ARTransType in ('I','A','F','R') then -ARBL.oldAmount else ARBL.oldAmount end
			else
   				case when ARBH.ARTransType in ('I','A','F','R') then IsNull(ARBL.Amount,0)-IsNull(ARBL.oldAmount,0)
				else -IsNull(ARBL.Amount,0)+IsNull(ARBL.oldAmount,0) end
			end),
	PrevApplied=sum(case ARBL.TransType when 'D' then
				case when ARBH.ARTransType in ('P') then ARBL.oldAmount else 0 end
			else
				case when ARBH.ARTransType in ('P') then -IsNull(ARBL.Amount,0)+IsNull(ARBL.oldAmount,0) else 0 end
         	end),
	ApplyAmt=0,
	ApplyTax=0,
	DiscTaken=0,
	TaxDiscTaken=0,
	OpenRetg=sum(case ARBL.TransType when 'D' then
               	case when ARBH.ARTransType in ('I','A','F','R') then -ARBL.oldRetainage else ARBL.oldRetainage end
         	else
               	case when ARBH.ARTransType in ('I','A','F','R') then IsNull(ARBL.Retainage,0)-IsNull(ARBL.oldRetainage,0)
          		else -IsNull(ARBL.Retainage,0)+IsNull(ARBL.oldRetainage,0) end
			end),
	ApplyRetg=0,
	OrigRetg=sum(case ARBL.TransType when 'D' then
               	case when ARBH.ARTransType in ('I','A','F','R') then 
				case when ARBH.ARTransType in ('I', 'A') then -ARBL.oldRetainage else 0 end else -- exclude FinChg & Release Retg Amts, Reduces Original values!
				case when ARBH.ARTransType in ('C', 'W') then ARBL.oldRetainage else 0 end end	-- exclude Payment Amts, Reduces Original values!
         	else
               	case when ARBH.ARTransType in ('I','A','F','R') then 
				case when ARBH.ARTransType in ('I', 'A') then IsNull(ARBL.Retainage,0)-IsNull(ARBL.oldRetainage,0) else 0 end else
          		case when ARBH.ARTransType in ('C', 'W') then -IsNull(ARBL.Retainage,0)+IsNull(ARBL.oldRetainage,0)else 0 end end
			end),
	DiscOffered=sum(case ARBL.TransType when 'D' then
             	case when ARBH.ARTransType in ('I','A','F','R') then -ARBL.oldDiscOffered else ARBL.oldDiscOffered end
         	else
              	case when ARBH.ARTransType in ('I','A','F','R') then IsNull(ARBL.DiscOffered,0)-IsNull(ARBL.oldDiscOffered,0)
          		else -IsNull(ARBL.DiscOffered,0)+IsNull(ARBL.oldDiscOffered,0) end
			end),
	PrevDiscTaken=sum(case ARBL.TransType when 'D' then
               	case when ARBH.ARTransType in ('I','A','F','R') then -ARBL.oldDiscTaken else ARBL.oldDiscTaken end
          	else
              	case when ARBH.ARTransType in ('I','A','F','R') then IsNull(ARBL.DiscTaken,0)-IsNull(ARBL.oldDiscTaken,0)
           		else -IsNull(ARBL.DiscTaken,0)+IsNull(ARBL.oldDiscTaken,0) end
			end),
	TaxAmt=sum(case ARBL.TransType when 'D' then
             	case when ARBH.ARTransType in ('I','A','F','R') then -ARBL.oldTaxAmount else ARBL.oldTaxAmount end
           	else
             	case when ARBH.ARTransType in ('I','A','F','R') then IsNull(ARBL.TaxAmount,0)-IsNull(ARBL.oldTaxAmount,0)
           		else -IsNull(ARBL.TaxAmount,0)+IsNull(ARBL.oldTaxAmount,0) end
			end),
	FCAmtDue=sum(case ARBL.TransType when 'D' then
           		case when ARBH.ARTransType in ('I','A','F','R') then -ARBL.oldFinanceChg else ARBL.oldFinanceChg end
     		else
           		case when ARBH.ARTransType in ('I','A','F','R') then IsNull(ARBL.FinanceChg,0)-IsNull(ARBL.oldFinanceChg,0)
      			else -IsNull(ARBL.FinanceChg,0)+IsNull(ARBL.oldFinanceChg,0) end
			end),
	ApplyFC=0,
	TaxDiscAvail=sum(case ARBL.TransType when 'D' then
               	case when ARBH.ARTransType in ('I','A','F','R') then -ARBL.oldTaxDisc else ARBL.oldTaxDisc end
         	else
               	case when ARBH.ARTransType in ('I','A','F','R') then IsNull(ARBL.TaxDisc,0)-IsNull(ARBL.oldTaxDisc,0)
          		else -IsNull(ARBL.TaxDisc,0)+IsNull(ARBL.oldTaxDisc,0) end
			end)
from ARBH ARBH with (nolock)
join ARBL ARBL with (nolock) on ARBL.Co=ARBH.Co   and ARBL.Mth=ARBH.Mth  and ARBL.BatchId=ARBH.BatchId and ARBL.BatchSeq=ARBH.BatchSeq
where ARBH.Co=@ARCo  and ARBH.CustGroup=@CustGrp and ARBH.Customer=@Customer
and ARBH.ARTransType = 'P'
and ARBL.BatchSeq <> case when (ARBL.Mth = @BatchMth and ARBL.BatchId = @BatchId) then @BatchSeq else 0 end
group by ARBL.ApplyMth, ARBL.ApplyTrans
   
/************************************/
/* get totals for the current check */
/************************************/
insert into #CashRecGrid
select ARBL.ApplyMth, ARBL.ApplyTrans,  Amount=0, PrevApplied=0,
	ApplyAmt=sum(ARBL.Amount),
	ApplyTax=sum(ARBL.TaxAmount),
	DiscTaken=sum(ARBL.DiscTaken),
	TaxDiscTaken=sum(ARBL.TaxDisc),
	OpenRetg=0,
	ApplyRetg=sum(ARBL.Retainage),
	OrigRetg=0, DiscOffered=0, PrevDiscTaken=0, TaxAmt=0, FCAmtDue=0,
	ApplyFC=sum(ARBL.FinanceChg),
	TaxDiscAvail=0
from ARBH ARBH with (nolock)
join ARBL ARBL with (nolock) on ARBL.Co = ARBH.Co and ARBL.Mth = ARBH.Mth and ARBL.BatchId = ARBH.BatchId and ARBL.BatchSeq = ARBH.BatchSeq
where ARBH.Co = @ARCo and ARBH.CustGroup = @CustGrp and ARBH.Customer = @Customer and
   	ARBH.Mth = @BatchMth and ARBH.BatchId = @BatchId and ARBH.BatchSeq = @BatchSeq and
   	(isnull(ARBL.ARTrans,0) <> ARBL.ApplyTrans or (ARBL.Mth <> ARBL.ApplyMth and isnull(ARBL.ARTrans,0) = ARBL.ApplyTrans))
group by ARBL.ApplyMth,  ARBL.ApplyTrans
   
/* select the results */
select ARTH.Invoice,
	ARTH.Mth,	-- This 1st is a hidden column, passed into stored procedures unformatted mm/dd/yyyy
	ARTH.Mth,	-- This 2nd is formatted specifically as mm/yy to be displayed in the grid
	ARTH.ARTrans,
	ARTH.TransDate,
	ARTH.DueDate,
	ARTH.ARTransType,
	ARTH.RecType, 
	ARTH.CustRef, 
	ARTH.CustPO, 
	JCCo=MIN(ARTH.JCCo), 
	Contract=MIN(ARTH.Contract), 
	Description=MIN(JCCM.Description),
	InvoiceAmt = IsNull(sum(t.Amount),0)-IsNull(sum(t.PrevApplied),0),
	AmountDue = IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0),
	AmtDueLessFC = IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0)-IsNull(sum(t.FCAmtDue),0),
	PrevApplied = -IsNull(sum(t.PrevApplied),0),
	ApplyAmount = IsNull(sum(t.ApplyAmt),0),
	ApplyTax = IsNull(sum(t.ApplyTax),0),
 	DiscTaken = IsNull(sum(t.DiscTaken),0),
	TaxDiscTaken = IsNull(sum(t.TaxDiscTaken),0),
 	ApplyRetg = IsNull(sum(t.ApplyRetg),0),
 	ApplyFC = IsNull(sum(t.ApplyFC),0),	
	Balance = (IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0))-(IsNull(sum(t.ApplyAmt),0)-IsNull(sum(t.ApplyRetg),0)),
 	DiscDate = MIN(ARTH.DiscDate),
  	OrigRetg = IsNull(sum(t.OrigRetg),0),
 	UnPaidRetg = IsNull(sum(t.OpenRetg),0),
 	UnPaidFC = IsNull(sum(t.FCAmtDue),0),
 	DiscOffered = IsNull(sum(t.DiscOffered),0),
 	PrevDiscTaken = -IsNull(sum(t.PrevDiscTaken),0),
 	TaxAmt = IsNull(sum(t.TaxAmt),0),
	TaxDiscAvail = IsNull(sum(t.TaxDiscAvail),0)
from ARTH ARTH with (nolock)
JOIN #CashRecGrid t on t.Mth=ARTH.Mth  and t.ARTrans=ARTH.ARTrans
LEFT JOIN JCCM JCCM with (nolock) on ARTH.JCCo=JCCM.JCCo and ARTH.Contract=JCCM.Contract
where ARTH.ARCo = @ARCo and ARTH.CustGroup = @CustGrp	and ARTH.Customer = @Customer
group by ARTH.ARCo, ARTH.Invoice, ARTH.ARTransType, ARTH.CustRef, ARTH.CustPO, ARTH.Mth, ARTH.ARTrans,
 	ARTH.TransDate, ARTH.DueDate, ARTH.Invoiced, ARTH.RecType
having @ShowOption='A' 																		-- 'A', Show all invoices even if fully paid.
	or (@ShowOption='O' and ((IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0))<>0))		--'O', Show open invoices with amount due > $0.00.
	or (@ShowOption='R' and (((IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0))<>0) 		--'R', Show open invoices with amount due > $0.00 or 
	or ((IsNull(sum(t.Amount),0)-IsNull(sum(t.OpenRetg),0))=0 and sum(t.OpenRetg)<>0)))		--with amount due = $0.00 but Retgdue > &0.00.
order by /* results can be order by several different ways depending on the Sort Option */
    case  @SortOption
   		when 'I' then ARTH.Invoice
   		when '' then ARTH.Invoice 
   		when 'C' then ARTH.CustRef 
   		when 'T' then  convert(varchar(8), ARTH.Mth, 112) 
   		when 'D' then convert(varchar(8), ARTH.TransDate, 112)
   		when 'U' then convert(varchar(8), ARTH.DueDate, 112)
   		when 'Y' then ARTH.ARTransType 
   		when 'R' then convert(varchar(3), ARTH.RecType)
   		when 'J' then MIN(ARTH.Contract)
	else ARTH.Invoice end,
    case  @SortOption
   		when  'I'  then ARTH.CustRef
   		when  '' then ARTH.CustRef
   		when 'C' then ARTH.Invoice
   		when 'T' then convert(varchar(9),ARTH.ARTrans)
   		when 'D' then  ARTH.Invoice
   		when 'U' then  ARTH.Invoice
   		when 'Y' then ARTH.Invoice
   		when 'R' then ARTH.Invoice
   		when 'J' then ARTH.Invoice
	else ARTH.Invoice end,
    case  @SortOption
   		when 'I' then convert(varchar(8), ARTH.TransDate, 112)
   		when '' then convert(varchar(8), ARTH.TransDate, 112)
   		when 'C' then convert(varchar(8), ARTH.TransDate, 112)
   		when 'T' then ARTH.Invoice 
   		when 'Y' then convert(varchar(8), ARTH.TransDate, 112)
   		when 'R' then convert(varchar(8), ARTH.TransDate, 112)
   		when 'J' then convert(varchar(8), ARTH.TransDate, 112)
	else ARTH.Invoice end		--Invoice is in twice just to show that 'T' must always be by invoice JRE
    
bspexit:
return @rcode

end

GO
GRANT EXECUTE ON  [dbo].[bspARCashReceiptsGridFill] TO [public]
GO
