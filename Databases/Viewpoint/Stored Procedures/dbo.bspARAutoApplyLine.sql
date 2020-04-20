SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARAutoApplyLine    Script Date: 8/28/99 9:36:03 AM ******/
CREATE proc [dbo].[bspARAutoApplyLine]
/********************************************************
* CREATED BY: 	JRE 5/24/97
* MODIFIED BY:	JRE 7/10/97
*		JM 6/26/98  - corrected assignment of @AmtLeft in two places
* 		AE 10/1/98  - added code to handle TransType 'C' in frmCashReciepts
*             		when adding transaction to a batch
*	  	JM 3/26/99  - Changed sign for @PostRetg in @AmtLeft definition from	+ to - (approx line 257).
*	  	GR 8/27/99  - corrected assignment of @AmtLeft not to substract @PostRetg (issue 3108)
*   	GR 6/14/00  - corrected the calculation of @PostAmt
*     	GR 6/23/00  - corrected the @PostDisc calculation if there is no discount offered - issue 7075
*     	bc 02/27/01 - issue 12315.  tax update to ARBL.
*   	bc 02/28/01 - adjusted calculation of @AmtLeft although i suspect that the abs()
*		TJL 05/01/01 - Reviewed and corrected an error in Batch calculations for DiscTaken
*					It was a result of an incorrect + or - value which has a cascading effect down the line.		
*		TJL 05/04/01 - Added code to handle @Option 'J' and process only lines for a 
*			       	CustJob.
*		TJL 07/03/01 - Issue #13905.  
*					Use ABS() function when comparing values to determine tax amounts to be posted.  This is necessary
*					because Cash Receipts was applying an incorrect negative TaxAmount when Applied Amt is negative.
*		TJL 07/05/01 - Correct UPDATE ARBL statements to correctly update 'Amount' field.
*					Correct @TaxAmtDue for correct amount when Retainage is applied at the grid.
*					Correct Proper handling of Retainage when user Adjust Applied Amount at the grid.
*		TJL 07/25/01 - Send 'INCo' and 'Loc' to bARBL to be used in 'bspARBH1_ValCashLines' to determine ARDiscountGLAcct.
*		TJL 09/13/01 - Issue #14499: Test if ApplyMth > BatchMth, If so error and exit.
*		TJL 09/14/01 - Issue #14596: Allow overpayment to a 0.00 value Invoice.
*		TJL 10/03/01 - Issue #14498:  Correct and allow posting to same invoice using 2 sequences, same batch
*				  	Exclude Invoices whose InUseBatchID is not null	
*		TJL 10/17/01 - Issue #14805:
*					Modfied, removed some unnecessary ABS() functions when determining @Post values.
*					Modified to capture and warn user if Invoice being applied to (manually) is IN USE by another batch.
*		TJL 12/18/01 - Issue #14170:  Exclude Finance Charge option, better Retainage handling, better ApplyAllYN handling.
*		TJL 03/26/02 - Issue #16734:  Update new FinanceChg column in bARTL when receiving cash
*		TJL 04/04/02 - Issue #16280:  Do not include/sum bARTL amounts for payments added back into batch for change.
*		TJL 05/14/02 - Issue #17421:  Add 'Tax Applied' to grid for user input.  Improve how cash is applied to Negative
*									  Invoices.  Reverse Payments now call separate procedure. Improve cash applied to FC's
*		TJL 07/31/02 - Issue #11219:  Add 'TaxDisc Applied' to grid for user input.
*		TJL 08/07/03 - Issue #22087:  Performance mods, add NoLocks
*		***************************************** TOTAL REWRITE AFTER THIS POINT ****************************************
*		TJL 11/13/03 - Issue #23005:  Improve how cash gets applied to Negative Lines (Opposite Lines), remove psuedo cursor
*		TJL 11/19/03 - Issue #23054:  Related to #23005, however also requires associated form mods
*		TJL 01/06/05 - Issue #26713:  Removed unused code that was causing 100,000 unnecessary reads
*		TJL 08/03/05 - Issue #29474:  Applied line amounts from Adjustments & FinChgs not included when applying by CustJob
*		TJL 08/26/05 - Issue #29677:  6x Rewrite.  Modify ConditionalSuccess messages, use ConditionalSuccess rcode = (7) designation	
*		TJL 02/28/08 - Issue #125289:  Include unposted batch values for ONLY unposted ARCashReceipts (P) batches. (Not A, C, W, F)
*		TJL 06/05/08 - Issue #128457:  ARCashReceipts International Sales Tax
*
*
* CAUTION:
*	As with so many backend procedures, seemingly minor modifications can have major
*	implications.  This procedure works closely with bspARAutoApply and bspARAutoApplyLineRev
*	as well as with form ARCashReceipts.
*	If it seems too easy it probably is. Unless you understand how all these procedures
*	function together you should not be making changes.
*
* USAGE:
* 	This procedure applies payment amounts to each line of an invoice.
*	If any money is left over, the amounts will be applied to the first
*	line of the invoice
*
*	Run from either:

*		1. VB Code in frmCashReciepts when applying cash directly at the grid
*		2. Called in bspARAutoApply
*
* INPUT PARAMETERS:
* 	ARCo, BatchMth, BatchId, BatchSeq
*   	ApplyMth, ApplyTrans, ApplyAmt, ApplyTax, ApplyRetg  
*    	DiscTaken, ApplyTaxDisc, ApplyFC, CustJob, Option (Rev)
*
* OUTPUT PARAMETERS:
*	Error message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
@ARCo bCompany, @BatchMth bMonth, @BatchId bBatchID,
   @BatchSeq int, @ApplyMth bMonth, @ApplyTrans bTrans, @ApplyAmt bDollar = 0,
   @ApplyTax bDollar = 0, @ApplyRetg bDollar = 0, @DiscTaken bDollar = 0, @ApplyTaxDisc bDollar = 0, 
   @ApplyFC bDollar = 0, @CustJob varchar(20)=null, @Option char(1) = null, @errmsg varchar(512) output
as

set nocount on

declare @AmtDue bDollar,  @DiscAvail bDollar, @DiscLeft bDollar,
	@DiscOffer bDollar, @TaxDiscAvail bDollar, @TaxDiscLeft bDollar, @RetgDue bDollar, 
	@RetgLeft bDollar, @TaxAmtDue bDollar, @TaxLeft bDollar, @FCDue bDollar, @FCLeft bDollar,
	@PostAmt bDollar, @PostDisc bDollar, @PostTaxDisc bDollar, @PostRetg bDollar, 
	@PostTaxAmt bDollar, @PostFC bDollar, @TotAmtLeft bDollar, @Amount bDollar, @InvAmtDue bDollar,
	@ARLine smallint, @paytrans int, @FirstLine int, @NextARLine int,
	@openarlinecursor tinyint, @passes tinyint, @RevValueFlag tinyint, @InvType char(1),
	@RetgTaxDue bDollar, @PostRetgTax bDollar, @RetgTaxLeft bDollar, @NegAppliedRetgYN bYN,
	@ApplyRetgPct numeric(5,2)

declare @rcode int

select @rcode = 0, @openarlinecursor = 0, @passes = 0, @RevValueFlag = 0, @InvAmtDue = 0, @NegAppliedRetgYN = 'N' 

/* Very odd input by user (Rare if at all).  They have applied a negative payment to Retainage only.  The rest of the invoice
   applied values are positive as they should be.  Special handling required for RetgTax.  The end result of this entry is
   that Retainage on the first line of the invoice will be increased rather than paid down.  Because of the increase on first
   line, Retainage tax will not be paid on the first line. (See OverPay at end of procedure) */
if (@ApplyAmt > 0 and @ApplyRetg < 0) or (@ApplyAmt < 0 and @ApplyRetg > 0) select @NegAppliedRetgYN = 'Y'
   
if @ARCo is null
	begin
	select @errmsg='Must supply an AR Company', @rcode=1
	goto bspexit
	end

if @BatchMth is null
	begin
	select @errmsg='Must supply a batch month', @rcode=1
	goto bspexit
	end

if @BatchId is null
	begin
	select @errmsg='Must supply a batchid', @rcode=1
	goto bspexit
	end

if @BatchSeq is null
	begin
	select @errmsg='Must supply a batch sequence', @rcode=1
	goto bspexit
	end

if @ApplyMth > @BatchMth
	begin
	select @errmsg='User may NOT apply Payment to an Invoice in a future month!', @rcode=1
	goto bspexit
	end
   
/********************* Check for and perform Payment Reversals ********************************/

/* Reverse Payments are very different from normal payment application.  A separate procedure is used to 
  handle this.  Reverse payments are identified by the fact that all the inputs will be opposite
  in polarity to the original invoice.  

  The procedure will Reverse amounts based upon amounts already paid on the line rather than on amounts 
  due, as when making the payment in the first place. */

if isnull(@Option, '') = 'R'	--Reversal
	begin	/* Begin Payment Reversals */

	/* Execute a Normal Payment Reversal. */
	if (@ApplyAmt < 0 and @ApplyTax <= 0 and @ApplyRetg <= 0 and @DiscTaken <= 0 and @ApplyTaxDisc <= 0 
		and @ApplyFC <= 0) or (@ApplyAmt > 0 and @ApplyTax >= 0 and @ApplyRetg >= 0 and @DiscTaken >= 0 
		and @ApplyTaxDisc >= 0 and @ApplyFC >= 0)
		begin

		exec @rcode = bspARAutoApplyLineRev  @ARCo, @BatchMth, @BatchId, @BatchSeq,
			@ApplyMth, @ApplyTrans, @ApplyAmt, @ApplyTax, @ApplyRetg, @DiscTaken, @ApplyTaxDisc,
			@ApplyFC, @errmsg output

		/* Exit immediately on success or error */
		goto bspexit
		end

	/* It should be noted that Reversing an overpaid invoice while at the SAME TIME applying normal
	   payment to another column, such as Retainage, will skip the above Reversal routine and apply
	   in the normal manner.  This is a strange beast.  It works well enough when a user is moving
	   a previous payment amount off one invoice and at the same time pays the retainage on that
	   same invoice.  (It is kind of like doing a payment On Account).  However results at the line
	   level can become confusing if users attempts to do too much with Tax or Finance Charges while
	   in the process of trying to reverse an overpaid invoice. */

	end		/* End Payment Reversals */

/************************** Begin Normal Payment application by Line **********************************/
   
/* Get Payment transaction number for a transaction that has been added back
into the batch. */
select @paytrans = min(ARTrans)
from bARBL with (nolock)
where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq

/* Keep a running amounts of how much cash is left to apply in each bucket.  
  Rules enforced by Form:
  1) User input @ApplyAmt can never be less than (@ApplyTax + @ApplyRetg + @ApplyFC)
  2) User inputs @ApplyTax,  @ApplyRetg,  @ApplyFC may never be more than available on the invoice.
  Another words, users may never over apply these values.
  3) User may over credit the overall Invoice but never Tax, Retg or Finance Chgs.
  4) @DiscTaken is an arbitrary value.  It is not required, cannot be credited off invoice and
  for this reason does not affect the bottom line (Amount) of the invoice when applying cash.
  Its affect is to make more cash available (Cash credit) for applying elsewhere.  It has
  more of an affect in bspARAutoApply when determining AmtLeft to apply to next invoice.
*/
   
select @TotAmtLeft = @ApplyAmt, @TaxLeft = @ApplyTax, @DiscLeft = @DiscTaken, @TaxDiscLeft = @ApplyTaxDisc,
	@RetgLeft = @ApplyRetg, @FCLeft = @ApplyFC

/* Setting @RetgTaxLeft is a special process. */
	/* Get the current Retainage/RetgTax amounts for the Invoice. */
 	select @RetgDue = IsNull(sum(bARTL.Retainage),0),
		@RetgTaxDue = IsNull(sum(bARTL.RetgTax),0)
 	from bARTL with (nolock)
 	left join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
 	where bARTL.ARCo = @ARCo and bARTL.ApplyMth = @ApplyMth and bARTL.ApplyTrans = @ApplyTrans
	/* If this previously posted transaction is being changed, then ignore its current values
	   in bARTL since they are about to be modified.  (Treat as if this trans doesn't exist) */
       and(isnull(bARTH.InUseBatchID,0) <> @BatchId 
	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth <> @BatchMth)
	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth = @BatchMth and bARTH.ARTrans <> isnull(@paytrans,0)))
    
	/* Add in any amounts from other unposted batches. */
	select @RetgDue = @RetgDue + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldRetainage else bARBL.oldRetainage
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.Retainage,0) - IsNull(bARBL.oldRetainage,0)
								else -IsNull(bARBL.Retainage,0) + IsNull(bARBL.oldRetainage,0)
 								end
					end),0),

       	@RetgTaxDue = @RetgTaxDue + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldRetgTax else bARBL.oldRetgTax
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.RetgTax,0) - IsNull(bARBL.oldRetgTax,0)
								else -IsNull(bARBL.RetgTax,0) + IsNull(bARBL.oldRetgTax,0)
 								end
					end),0)
  	from bARBL with (nolock)
 	join bARBH with (nolock)on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
  	where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans 
		and bARBH.ARTransType = 'P'
		and bARBL.BatchSeq <> (case when bARBL.Mth = @BatchMth and bARBL.BatchId = @BatchId  then @BatchSeq else 0 end)

/* Generate a @RetgTaxLeft value. */
select @RetgTaxLeft = case when @RetgDue <> 0 then (@ApplyRetg/@RetgDue) * @RetgTaxDue else 0 end, 
	@ApplyRetgPct = case when @RetgDue <> 0 then (@ApplyRetg/@RetgDue) * 100 else 0 end

select @AmtDue = 0, @TaxAmtDue = 0, @RetgDue = 0, @DiscAvail = 0, @DiscOffer = 0, @FCDue = 0,
   	@TaxDiscAvail = 0, @RetgTaxDue = 0
   
CycleThruLines:
 
declare bcARLine cursor local fast_forward for
select ARLine
from bARTL with (nolock)
where ARCo = @ARCo and Mth = @ApplyMth and ARTrans = @ApplyTrans
		 --and isnull(bARTL.CustJob, '') = case when @Option = 'J' then @CustJob else isnull(bARTL.CustJob, '') end
   
open bcARLine
select @openarlinecursor = 1
select @passes = @passes + 1	--For Neg/Rev Polarity lines/column handling

fetch next from bcARLine into @ARLine
while @@fetch_status = 0
	Begin	/* Begin Line Loop */
 	select @PostAmt=0, @PostRetg=0, @PostDisc=0, @PostTaxAmt=0, @PostFC=0, @PostRetgTax=0
   
	/* Get the current amount due for each ARLine. */
 	select @AmtDue = IsNull(sum(bARTL.Amount),0),
		@TaxAmtDue = IsNull(sum(bARTL.TaxAmount),0),
   		@RetgDue = IsNull(sum(bARTL.Retainage),0),
		@FCDue = IsNull(sum(bARTL.FinanceChg),0),
	  	@DiscAvail = IsNull(sum(bARTL.DiscOffered),0) + IsNull(sum(bARTL.DiscTaken),0),
    	@DiscOffer = IsNull(sum(bARTL.DiscOffered),0),
		@TaxDiscAvail = IsNull(sum(bARTL.TaxDisc),0),
		@RetgTaxDue = IsNull(sum(bARTL.RetgTax),0)
 	from bARTL with (nolock)
 	left join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
 	where bARTL.ARCo = @ARCo and bARTL.ApplyMth = @ApplyMth and bARTL.ApplyTrans = @ApplyTrans and bARTL.ApplyLine = @ARLine
	/* If this previously posted transaction is being changed, then ignore its current values
	   in bARTL since they are about to be modified.  (Treat as if this trans doesn't exist) */
       and(isnull(bARTH.InUseBatchID,0) <> @BatchId 
	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth <> @BatchMth)
	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth = @BatchMth and bARTH.ARTrans <> isnull(@paytrans,0)))
    
	/* Add in any amounts from other unposted batches. */
	select @AmtDue = @AmtDue + IsNull(sum(case bARBL.TransType when 'D'
          						then case when bARBH.ARTransType in ('I','A','F','R')
            					then -bARBL.oldAmount else bARBL.oldAmount
            					end

					else

								case when bARBH.ARTransType in ('I','A','F','R')
            					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
            					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
								end
					end),0),

       	@TaxAmtDue = @TaxAmtDue + IsNull(sum(case bARBL.TransType when 'D' then
             					case when bARBH.ARTransType in ('I','A','F','R')
             					then -bARBL.oldTaxAmount else bARBL.oldTaxAmount
             					end

 					else

 								case when bARBH.ARTransType in ('I','A','F','R') 
             					then IsNull(bARBL.TaxAmount,0) - IsNull(bARBL.oldTaxAmount,0)
             					else -IsNull(bARBL.TaxAmount,0) + IsNull(bARBL.oldTaxAmount,0)
 								end
 					end),0), 

       	@RetgDue = @RetgDue + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldRetainage else bARBL.oldRetainage
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.Retainage,0) - IsNull(bARBL.oldRetainage,0)
								else -IsNull(bARBL.Retainage,0) + IsNull(bARBL.oldRetainage,0)
 								end
					end),0),

		@FCDue = @FCDue + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldFinanceChg else bARBL.oldFinanceChg
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.FinanceChg,0) - IsNull(bARBL.oldFinanceChg,0)
								else -IsNull(bARBL.FinanceChg,0) + IsNull(bARBL.oldFinanceChg,0)
 								end
					end),0),

		@DiscAvail = @DiscAvail + IsNull(sum(case bARBL.TransType when 'D'
 								then
 			 					case when bARBH.ARTransType in ('I','A','F','R')
 								then -bARBL.oldDiscOffered else bARBL.oldDiscOffered
 								end

 					else
  								case when bARBH.ARTransType in ('I','A','F','R')
 								then IsNull(bARBL.DiscOffered,0) - IsNull(bARBL.oldDiscOffered,0)
 								else -IsNull(bARBL.DiscOffered,0) + IsNull(bARBL.oldDiscOffered,0)  
 								end
 					end),0) - IsNull(sum(case bARBL.TransType when 'D'
 								then 
 								case when bARBH.ARTransType in ('I','A','F','R')
 								then -bARBL.oldDiscTaken else bARBL.oldDiscTaken
 								end

 					else
 								case when bARBH.ARTransType in ('I','A','F','R')
 								then IsNull(bARBL.DiscTaken,0) - IsNull(bARBL.oldDiscTaken,0)
 								else IsNull(bARBL.DiscTaken,0) - IsNull(bARBL.oldDiscTaken,0)
 								end
 					end),0),
		 
		@DiscOffer = @DiscOffer + IsNull(sum(case bARBL.TransType when 'D' 
								then                  	      					
								case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldDiscOffered else bARBL.oldDiscOffered
								end

					else

								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.DiscOffered,0) - IsNull(bARBL.oldDiscOffered,0)
								else -IsNull(bARBL.DiscOffered,0) + IsNull(bARBL.oldDiscOffered,0)
								end
					end),0),

       	@TaxDiscAvail = @TaxDiscAvail + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldTaxDisc else bARBL.oldTaxDisc
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.TaxDisc,0) - IsNull(bARBL.oldTaxDisc,0)
								else -IsNull(bARBL.TaxDisc,0) + IsNull(bARBL.oldTaxDisc,0)
 								end
					end),0),

       	@RetgTaxDue = @RetgTaxDue + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldRetgTax else bARBL.oldRetgTax
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.RetgTax,0) - IsNull(bARBL.oldRetgTax,0)
								else -IsNull(bARBL.RetgTax,0) + IsNull(bARBL.oldRetgTax,0)
 								end
					end),0)
  	from bARBL with (nolock)
 	join bARBH with (nolock)on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
  	where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans and bARBL.ApplyLine = @ARLine
		and bARBH.ARTransType = 'P'
		and bARBL.BatchSeq <> (case when bARBL.Mth = @BatchMth and bARBL.BatchId = @BatchId  then @BatchSeq else 0 end)	/* dont include this seq */
   
   /**************************** NEGATIVE/REVERSE POLARITY LINE OR COLUMN HANDLING ONLY *******************************/
   	/* Combine with This BatchSeq values to be posted.  The combined values below will be 0.00 during this pass!
   	   They are ONLY considered when a Reverse Polarity value (Usually Neg column Or Neg Line) has been
   	   encountered.  In which case, we are cycling thru the Lines of this invoice a 2nd
   	   time to distribute the extra cash generated by posting negative values across lines with
   	   amounts still due.  This is a very real situation and a second pass cannot be avoided. 
   
   	   ***IMPORTANT*** Old values DO NOT need to be considered here because we ignored existing
   	   values in bARTL initially for this specific Invoice transaction.  (See above) */
   	if @RevValueFlag = 1 and @passes = 2
   		begin	/* Begin Reverse Polarity handling */
   	 	select @AmtDue = @AmtDue - IsNull(sum(bARBL.Amount),0),
   	        	@TaxAmtDue = @TaxAmtDue - IsNull(sum(bARBL.TaxAmount),0), 
   	        	@RetgDue = @RetgDue - IsNull(sum(bARBL.Retainage),0),
   	         	@FCDue = @FCDue - IsNull(sum(bARBL.FinanceChg),0),
   	  			@DiscAvail = @DiscAvail - IsNull(sum(bARBL.DiscTaken),0),
   	 			@DiscOffer = @DiscOffer - IsNull(sum(bARBL.DiscOffered),0),		--Always 0
   	        	@TaxDiscAvail = @TaxDiscAvail - IsNull(sum(bARBL.TaxDisc),0),
				@RetgTaxDue = @RetgTaxDue - IsNull(sum(bARBL.RetgTax),0)
   	   	from bARBL with (nolock)
   	   	where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans and bARBL.ApplyLine = @ARLine
   			and bARBL.Mth = @BatchMth and bARBL.BatchId = @BatchId and bARBL.BatchSeq = @BatchSeq	/* Include this seq */
   		end		/* End Reverse Polarity Handling */
   /**************************** END NEGATIVE/REVERSE LINE OR COLUMN HANDLING ONLY *******************************/
   
   /********************** EVALUATE AND SET POST AMOUNTS BASED ON INPUTTED APPLY AMOUNTS *******************/
   
   	/* Accumulate Invoice AmtDue totals during the 1st pass of all lines.  It may
   	   be used later to determine if Overpayment of this invoice is allowed. */
   	if @passes = 1 select @InvAmtDue = @InvAmtDue + @AmtDue

   	/* Reduce the Line to individual bucket values.  @Amount represents whatever is remaining
   	   when Tax, Retg and Finance Chg values are removed. */
   	select @Amount = @AmtDue - (@TaxAmtDue + @FCDue + @RetgDue)
   	
   	/* Set post amounts. */
   	select @PostRetg = case
   			when @RetgDue = 0 then 0
   			when (@ApplyRetg > 0 and @RetgDue < 0) or (@ApplyRetg < 0 and @RetgDue > 0) then @RetgDue --Neg/Rev column handling
   			when abs(@RetgDue) <= abs(@RetgLeft) and @RetgLeft <> 0 then @RetgDue
   	 		when abs(@RetgDue) > abs(@RetgLeft) and @RetgLeft <> 0 then @RetgLeft
   	     	else 0
   	 		end,
		/* RetgTax requires special handling.  There is no exposed "Applied" input for the user on the CashReceipt grid.  
		   RetgTax paid amount is determined automatically for the user behind the scenes. */
		@PostRetgTax = case
   			when @PostRetg = 0 then 0
   			when (@ApplyRetg > 0 and @RetgDue < 0) or (@ApplyRetg < 0 and @RetgDue > 0) then @RetgTaxDue --Neg/Rev column handling
   			when abs(@RetgTaxDue) <= abs(@RetgTaxLeft) and abs(@RetgTaxDue) <= abs(@PostRetg) and @RetgTaxLeft <> 0 then @RetgTaxDue
			when abs(@RetgTaxDue) <= abs(@RetgTaxLeft) and abs(@RetgTaxDue) > abs(@PostRetg) and @RetgTaxLeft <> 0 then @PostRetg
   	 		when abs(@RetgTaxDue) > abs(@RetgTaxLeft) and abs(@RetgTaxLeft) <= abs(@PostRetg) and @RetgTaxLeft <> 0 then @RetgTaxLeft
			when abs(@RetgTaxDue) > abs(@RetgTaxLeft) and abs(@RetgTaxLeft) > abs(@PostRetg) and @RetgTaxLeft <> 0 then @PostRetg
   	     	else 0
   	 		end,
   	 	@PostDisc = case
   	    	when @DiscAvail = 0 then 0  
   			when (@DiscTaken > 0 and @DiscAvail < 0) or (@DiscTaken < 0 and @DiscAvail > 0) then @DiscAvail	--Neg/Rev column handling
   	     	when abs(@DiscAvail) <= abs(@DiscLeft) and @DiscLeft <> 0 then @DiscAvail
   	 	 	when abs(@DiscAvail) > abs(@DiscLeft) and @DiscLeft <> 0 then @DiscLeft
   	 	 	else 0
   	 	 	end,
   	 	@PostTaxDisc = case
   	    	when @TaxDiscAvail = 0 then 0
   			when (@ApplyTaxDisc > 0 and @TaxDiscAvail < 0) or (@ApplyTaxDisc < 0 and @TaxDiscAvail > 0) then @TaxDiscAvail	--Neg/Rev column handling
   	     	when abs(@TaxDiscAvail) <= abs(@TaxDiscLeft) and @TaxDiscLeft <> 0 then @TaxDiscAvail
   	 	 	when abs(@TaxDiscAvail) > abs(@TaxDiscLeft) and @TaxDiscLeft <> 0 then @TaxDiscLeft
   	 	 	else 0
   	 	 	end,
   		@PostTaxAmt = case
   			when @TaxAmtDue = 0 then 0
   			when (@ApplyTax > 0 and @TaxAmtDue < 0) or (@ApplyTax < 0 and @TaxAmtDue > 0) then @TaxAmtDue	--Neg/Rev column handling
   			when abs(@TaxAmtDue) <= abs(@TaxLeft) and @TaxLeft <> 0 then @TaxAmtDue
   			when abs(@TaxAmtDue) > abs(@TaxLeft) and @TaxLeft <> 0 then @TaxLeft
   			else 0
   			end,
   		@PostFC = case
   			when @FCDue = 0 then 0
   			when (@ApplyFC > 0 and @FCDue < 0) or (@ApplyFC < 0 and @FCDue > 0) then @FCDue		--Neg/Rev column handling
   			when abs(@FCDue) <= abs(@FCLeft) and @FCLeft <> 0 then @FCDue
   			when abs(@FCDue) > abs(@FCLeft) and @FCLeft <> 0 then @FCLeft
   			else 0
   			end
   
   	/* @PostAmt is dependent upon all other posted values and must be determined last.  Amounts
   	   left (TaxLeft, FCLeft and RetgLeft) are very important and must be considered in order
   	   to reserve enough in TotAmtLeft to cover these values for lines yet to be posted.
   	   Rules are:
   		1) Later, overall Amount posted = (@PostAmt + @PostTax + @PostRetg + @PostFC)
   		2) @PostDisc does not affect the Amount column at all! It only represents more available
   		   cash after posting against this invoice.
   		3) @PostAmt may never exceed (@TotAmtLeft, at this moment, minus (@TaxLeft + @FCLeft + @RetgLeft, representing
   		   the amounts needed to be held back for posting Tax, Retg, & FC on this line and future lines. )
   	*/
   	select @PostAmt = case
   	      	when @Amount = 0 then 0
   			when (@ApplyAmt > 0 and @AmtDue < 0) or (@ApplyAmt < 0 and @AmtDue > 0) then @Amount 	--Neg/Rev column handling
   			when abs(@Amount) <= abs(@TotAmtLeft - (@TaxLeft + @FCLeft + @RetgLeft)) then @Amount
   			when abs(@Amount) > abs(@TotAmtLeft - (@TaxLeft + @FCLeft + @RetgLeft)) then @TotAmtLeft - (@TaxLeft + @FCLeft + @RetgLeft)
   	 	 	else 0
   	 	 	end

	/* PostRetgTax value is determined by the PostRetg value BUT after both have been calculated we need to evaluate,
	   one more time, to ensure that once these values get posted for the line, there remains enough in the RetgLeft bucket to 
	   cover any remaining amounts in the RetgTaxLeft bucket.  Without this check you can end up with 0.00 in the RetgLeft bucket
	   and some value in the RetgTaxLeft bucket that never gets posted to RetgTax.  In effect, your payment on RetgTax
	   is not the same Percent ratio as that of your retainage payment.  This check helps eliminate this problem.
	   Posted Retainage Value for the Line is:
		MAX Value:  Will be the PostRetg value minus the RetgTaxLeft value after posting.  Leaving enough for remaining RetgTaxLeft.
		MIN Value:  Will be the value of the PostRetgTax.  PostRetg can never be less then the PostRetgTax value on a line. */
	if abs(@RetgLeft - @PostRetg) < abs(@RetgTaxLeft - @PostRetgTax)  --Do we still have more Retainage then RetgTax left to post?
		begin
		select @PostRetg = case when abs(@PostRetg - (@RetgTaxLeft - @PostRetgTax)) > abs(@PostRetgTax) then
			@PostRetg - (@RetgTaxLeft - @PostRetgTax) else @PostRetgTax end
		end
   
   	/* Negative/Reverse Polarity Line/Column handling.  Will later be used to determine of a 2nd
   	   Pass is required to distribute extra cash generated by zeroing out these values. */
   	if ((@ApplyRetg > 0 and @RetgDue < 0) or (@ApplyRetg < 0 and @RetgDue > 0)) or
   		((@DiscTaken > 0 and @DiscAvail < 0) or (@DiscTaken < 0 and @DiscAvail > 0)) or
   		((@ApplyTaxDisc > 0 and @TaxDiscAvail < 0) or (@ApplyTaxDisc < 0 and @TaxDiscAvail > 0)) or
   		((@ApplyTax > 0 and @TaxAmtDue < 0) or (@ApplyTax < 0 and @TaxAmtDue > 0)) or
   		((@ApplyFC > 0 and @FCDue < 0) or (@ApplyFC < 0 and @FCDue > 0)) or
   		((@ApplyAmt > 0 and @AmtDue < 0) or (@ApplyAmt < 0 and @AmtDue > 0))
   	select @RevValueFlag = 1
   
   PostRoutine:
	if @passes = 1
   		begin	/* Begin Pass One batch insert */
   		/* Clear values out and start over or insert into batch for the first time. */
   		update bARBL
   		set Amount = @PostAmt + @PostTaxAmt + @PostFC + @PostRetg, 
   		 	TaxAmount = @PostTaxAmt,     
   		 	Retainage = @PostRetg, 
   			DiscTaken = @PostDisc,
   			TaxDisc = @PostTaxDisc,
   			FinanceChg = @PostFC,
			RetgTax = @PostRetgTax 
   		where Co=@ARCo and Mth=@BatchMth and BatchId=@BatchId and BatchSeq=@BatchSeq and
   		 	ApplyMth=@ApplyMth and ApplyTrans=@ApplyTrans and ApplyLine=@ARLine
   	 
   		if isnull(@@rowcount,0) = 0 and (isnull(@PostAmt,0) <> 0 or isnull(@PostTaxAmt,0) <> 0 or isnull(@PostFC,0) <> 0 or isnull(@PostRetg,0) <> 0 
   				or isnull(@PostDisc,0) <> 0 or isnull(@PostTaxDisc,0) <> 0)
   			begin
   		  	select @NextARLine = Max(ARLine) + 1  /* This is a new Batch line, Different than @ARline to which we are applying */
   		  	from bARBL with (nolock)
   		  	where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
   	 
   		 	insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType,
   		           	LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, 
   					Amount,
   		        	TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, TaxDisc, FinanceChg, DiscOffered, DiscTaken,
   		          	ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, INCo, Loc, CustJob)
   		  	select bARTL.ARCo, @BatchMth, @BatchId, @BatchSeq, IsNull(@NextARLine,1), 'A', null, bARTL.RecType,
   		          	bARTL.LineType, bARTL.Description, bARCO.GLCo, null, bARTL.TaxGroup, bARTL.TaxCode,
   		         	@PostAmt + @PostTaxAmt + @PostFC + @PostRetg,
   		 			0, @PostTaxAmt, 0, @PostRetg, @PostRetgTax, @PostTaxDisc, @PostFC, 0, @PostDisc, 
   					bARTL.Mth, bARTL.ARTrans, bARTL.ARLine, bARTL.JCCo, bARTL.Contract, bARTL.Item, bARTL.INCo, bARTL.Loc, bARTL.CustJob
   		 	from bARTL with (nolock)
   		  	join bARCO  with (nolock) on bARCO.ARCo=bARTL.ARCo
   		   	where bARTL.ARCo = @ARCo and bARTL.Mth = @ApplyMth and bARTL.ARTrans = @ApplyTrans and bARTL.ARLine = @ARLine
   	
   
   			/* If the update or insert has failed, exit immediately. */
   			if isnull(@@rowcount,0) = 0
   			  	begin
   			  	select @errmsg = 'Updating Batch Detail Table has failed on'
   				select @errmsg = @errmsg + ' Mth: ' + isnull(convert(varchar(8),@ApplyMth,1),'') 
   				select @errmsg = @errmsg + ' ARTrans: ' + isnull(convert(varchar(6),@ApplyTrans), ''), @rcode=1
   			  	goto bspexit
   			  	end
   	 		end
   		end		/* End Pass One batch insert */
   
   	if @passes = 2
   		begin	/* Begin Pass two batch update for Reverse/Negative Polariyt Line/Column handling. */
   		/* DO NOT clear out values, we are adding to what already exists from the first pass. */
   		update bARBL
   		set Amount = Amount + (@PostAmt + @PostTaxAmt + @PostFC + @PostRetg), 
   		 	TaxAmount = TaxAmount + @PostTaxAmt,     
   		 	Retainage = Retainage + @PostRetg, 
   			DiscTaken = DiscTaken + @PostDisc,
   			TaxDisc = TaxDisc + @PostTaxDisc,
   			FinanceChg = FinanceChg + @PostFC,
			RetgTax = RetgTax + @PostRetgTax
   		where Co=@ARCo and Mth=@BatchMth and BatchId=@BatchId and BatchSeq=@BatchSeq and
   		 	ApplyMth=@ApplyMth and ApplyTrans=@ApplyTrans and ApplyLine=@ARLine
   
   		/* A new line may actually need to be inserted on the 2nd pass. */
   		if isnull(@@rowcount,0) = 0 and (isnull(@PostAmt,0) <> 0 or isnull(@PostTaxAmt,0) <> 0 or isnull(@PostFC,0) <> 0 or isnull(@PostRetg,0) <> 0 
   				or isnull(@PostDisc,0) <> 0 or isnull(@PostTaxDisc,0) <> 0)
   			begin
   		  	select @NextARLine = Max(ARLine) + 1  /* This is a new Batch line, Different than @ARline to which we are applying */
   		  	from bARBL with (nolock)
   		  	where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
   	 
   		 	insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType,
   		           	LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, 
   					Amount,
   		        	TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, TaxDisc, FinanceChg, DiscOffered, DiscTaken,
   		          	ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, INCo, Loc, CustJob)
   		  	select bARTL.ARCo, @BatchMth, @BatchId, @BatchSeq, IsNull(@NextARLine,1), 'A', null, bARTL.RecType,
   		          	bARTL.LineType, bARTL.Description, bARCO.GLCo, null, bARTL.TaxGroup, bARTL.TaxCode,
   		         	@PostAmt + @PostTaxAmt + @PostFC + @PostRetg,
   		 			0, @PostTaxAmt, 0, @PostRetg, @PostRetgTax, @PostTaxDisc, @PostFC, 0, @PostDisc, 
   					bARTL.Mth, bARTL.ARTrans, bARTL.ARLine, bARTL.JCCo, bARTL.Contract, bARTL.Item, bARTL.INCo, bARTL.Loc, bARTL.CustJob
   		 	from bARTL with (nolock)
   		  	join bARCO  with (nolock) on bARCO.ARCo=bARTL.ARCo
   		   	where bARTL.ARCo = @ARCo and bARTL.Mth = @ApplyMth and bARTL.ARTrans = @ApplyTrans and bARTL.ARLine = @ARLine
   	
   			/* If the update or insert has failed, exit immediately. */
   			if isnull(@@rowcount,0) = 0
   			  	begin
   			  	select @errmsg = 'Updating Batch Detail Table has failed on'
   				select @errmsg = @errmsg + ' Mth: ' + isnull(convert(varchar(8),@ApplyMth,1),'') 
   				select @errmsg = @errmsg + ' ARTrans: ' + isnull(convert(varchar(6),@ApplyTrans),''), @rcode=1
   			  	goto bspexit
   			  	end
   	 		end
   		end		/* End Pass two batch update for Reverse/Negative Line/Column handling. */
    
   	/* Update the running totals. */
   	select @TotAmtLeft = @TotAmtLeft - (@PostAmt + @PostTaxAmt + @PostFC + @PostRetg),
   	  	@TaxLeft = @TaxLeft - @PostTaxAmt,
		@RetgLeft = @RetgLeft - @PostRetg,
   	  	@FCLeft = @FCLeft - @PostFC,
		@DiscLeft = @DiscLeft - @PostDisc,
   	  	@TaxDiscLeft = @TaxDiscLeft - @PostTaxDisc,
		@RetgTaxLeft = @RetgTaxLeft - @PostRetgTax
   
   	/* If any Leftover amounts exist (Invoice is overpaid), the overpaid amount will be placed
          on first line. */
   	if @FirstLine is null select @FirstLine = @ARLine
    
   	/* Get next line. */
   	fetch next from bcARLine into @ARLine
   
   	End   /* End Line Loop */
   
/* Cleanup after each pass as is appropriate */
if @openarlinecursor = 1
   	begin
   	close bcARLine
   	deallocate bcARLine
   	select @openarlinecursor = 0
   	end
   
if @passes = 2 select @RevValueFlag = 0
   
ReversePolarity_Line:
	/* Can ONLY occur once and ONLY if Negative/Reverse polarity values have been encountered on 1st pass. */
	if @RevValueFlag = 1 and (@TotAmtLeft <> 0 or @TaxLeft <> 0 or @RetgLeft <> 0 or @DiscLeft <> 0 
		or @TaxDiscLeft <> 0 or @FCLeft <> 0)
   		begin
   		goto CycleThruLines		--Cannot avoid a 2nd pass under this condition
   		end
   
OverPay: 
   /* @TotAmtLeft can only be greater than 0.00 if an Amount is applied manually directly to the Cash Receipts 
      grid by the user.  The bspAutoApply procedure is used during Auto Initializing ONLY and automatically 
      limits @TotAmtLeft to the exact amount of each invoice. 
   
      Overcrediting an Invoice will only affect the Amount column.  Form restrictions do not allow the
      user to overcredit Tax, Retainage or Finance Chgs unless user does so from within the Payment
      Detail form.  (*** The @___Left <> 0 checks below are just in case something slips by ***) */
   if @FirstLine is not null and (@TotAmtLeft <> 0 or @TaxLeft <> 0 or @RetgLeft <> 0 or @DiscLeft <> 0 
   		or @TaxDiscLeft <> 0 or @FCLeft <> 0)
    	begin	/* Begin OverPayment Processing */
   		/* When over paying an Invoice, user should be warned if any Taxes, Finance Charges,
   		   or retainage are still due on the invoice!  *** IMPORTANT *** A @TotAmtLeft at this point 
   		   means that having processed all lines, any money left over may be intended as an overpayment.
   		   However, if any portion of Tax, Finance Charges, or Retainage was left unpaid then the 
   		   check below will result in a balance due. (Meaning how can you overpay if not paid in full
   		   in the first place.)  We will allow the overpayment but the user will be warned about
   		   this condition.
	   
   		   ***IMPORTANT*** Old values DO NOT need to be considered here because we ignored existing
   		   values in bARTL initially for this specific Invoice transaction.  (See above) */
   		if @TotAmtLeft <> 0
   			begin
   	 		select @InvAmtDue = @InvAmtDue - IsNull(sum(bARBL.Amount),0)
   			from bARBL
   			where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq and
       			ApplyMth = @ApplyMth and ApplyTrans = @ApplyTrans
	   
   			if @InvAmtDue <> 0
   		  		begin
     		  		select @errmsg = 'This will overpay the invoice where there still remains open tax, '
     				select @errmsg = @errmsg + 'finance charges, or retainage!'
     				select @errmsg = @errmsg + char(13) + char(10) + char(13) + char(10)
     				select @errmsg = @errmsg + 'Reapply or use Payment Detail form, click the "Remove Input Restrictions" box,'
     				select @errmsg = @errmsg + ' to apply the overpayment differently.'
     				select @errmsg = @errmsg + char(13) + char(10) + char(13) + char(10) + ' Mth: ' + isnull(convert(varchar(8),@ApplyMth,1),'') 
     				select @errmsg = @errmsg + ' ARTrans: ' + isnull(convert(varchar(6),@ApplyTrans),''), @rcode = 2
   		  		end
   			end
   
   		/* Invoice might be a 'F' (Finance Chg, By Rectype or On Account type) in which case we will
   		   need to place a value in the FinanceChg column as well as the Amount column.  Check
   		   Invoice type! */
   		select @InvType = ARTransType
   		from bARTH
   		where ARCo = @ARCo and Mth = @ApplyMth and ARTrans = @ApplyTrans
   
   		/* Invoice has 0.00 balance, begin overpayment */
		update bARBL
		set Amount = Amount + @TotAmtLeft, 
   			TaxAmount = TaxAmount + @TaxLeft, 
   			Retainage = Retainage + @RetgLeft,
   			TaxDisc = TaxDisc + @TaxDiscLeft, 
   			FinanceChg = case when @InvType = 'F' then FinanceChg + @TotAmtLeft else FinanceChg + @FCLeft end, 
   			DiscTaken = DiscTaken + @DiscLeft,
			RetgTax = case when @NegAppliedRetgYN = 'Y' then 0 else RetgTax end			--Net increase in Retg on this line, no payment on RetgTax
   		where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq and
       		ApplyMth = @ApplyMth and ApplyTrans = @ApplyTrans and ApplyLine = @FirstLine
   
		/* The ONLY time that bARBL will NOT contain a record, at this point, is when cash is applied
		against 0.00 balance (Fully Paid) invoices.  A line must therefore be inserted. 
		All previous updates and inserts are skipped because all PostAmts = 0.00 for all lines.  
		This leaves a @TotAmtLeft > 0 and therefore must be applied somewhere. It will be Applied to Line #1 
		of this invoice. 

		Again @TaxLeft, @RetgLeft, @TaxDiscLeft, @FCLeft, @DiscLeft are not likely to have a value
		unless the column has not been kept correctly updated (Bad Data). */
    	if isnull(@@rowcount,0) = 0
    		begin
       		select @NextARLine = Max(ARLine) + 1  /* This is a new Batch line, Different than @ARline to which we are applying */
       		from bARBL with (nolock)
        	where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
    
       		insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType,
           		LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
           		Amount, TaxBasis, TaxAmount, RetgPct, Retainage, TaxDisc, 
   				FinanceChg, 
   				DiscOffered, DiscTaken,
           		ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, INCo, Loc, CustJob)
        	select bARTL.ARCo, @BatchMth, @BatchId, @BatchSeq, IsNull(@NextARLine,1), 'A', null, bARTL.RecType,
				bARTL.LineType, bARTL.Description, bARCO.GLCo, null, bARTL.TaxGroup, bARTL.TaxCode,
				@TotAmtLeft, 0, @TaxLeft, 0, @RetgLeft, @TaxDiscLeft, 
   				case when @InvType = 'F' then @TotAmtLeft else @FCLeft end, 
   				0, @DiscLeft,
				bARTL.Mth, bARTL.ARTrans, bARTL.ARLine, bARTL.JCCo, bARTL.Contract, bARTL.Item, bARTL.INCo, bARTL.Loc, bARTL.CustJob
       		from bARTL with (nolock)
        	join bARCO with (nolock) on bARCO.ARCo=bARTL.ARCo 
        	where bARTL.ARCo = @ARCo and bARTL.Mth = @ApplyMth and bARTL.ARTrans = @ApplyTrans and bARTL.ARLine = @FirstLine
	   
   			/* If the update or insert has failed, exit immediately. */
   			if isnull(@@rowcount,0) = 0
   		  		begin
   		  		select @errmsg = 'Updating Batch Detail Table has failed on'
   				select @errmsg = @errmsg + ' Mth: ' + isnull(convert(varchar(8),@ApplyMth,1),'') 
   				select @errmsg = @errmsg + ' ARTrans: ' + isnull(convert(varchar(6),@ApplyTrans),''), @rcode=1
   		  		goto bspexit
   		  		end
			end
   
   			if @rcode = 2
   				begin
   				/* Payment has been applied, use Warning message established earlier. */
   				select @rcode = 7
   				goto bspexit
   				end
   			else
   				begin
   				/* At this point, the additional amount can only be intended to be straight overpayment of
   				   the invoice. (There is no outstanding Tax, FinanceChgs, or Retainage that this might apply
   				   against.)  Therefore Payment has been applied, use this Warning message to notify user. */
     	  			select @errmsg = 'This will overpay the invoice and will be applied to Line #1. '
     				select @errmsg = @errmsg + char(13) + char(10) + char(13) + char(10)
     				select @errmsg = @errmsg + 'Use Payment Detail form, click the "Remove Input Restrictions" box,'
     				select @errmsg = @errmsg + ' to apply the overpayment differently.', @rcode = 7
   	  			goto bspexit
   				end
    	end		/* End OverPayment Processing */
    
bspexit:

if isnull(@RetgTaxLeft, 0) <> 0
	begin 
	if @errmsg is not null select @errmsg = @errmsg + char(13) + char(10) + char(13) + char(10)
	select @errmsg = isnull(@errmsg, '') + 'Cash was not applied to the full ' + convert(varchar(6), @ApplyRetgPct) + '% of Retainage Tax.  '
	select @errmsg = @errmsg + 'Use the Payment Detail form to verify or change the cash applied directly to Retainage Tax on this invoice.'
	select @rcode = 7
	end

if @openarlinecursor = 1
   	begin
   	close bcARLine
   	deallocate bcARLine
   	select @openarlinecursor = 0
   	end
   
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + char(13) + char(10) + '[bspARAutoApplyLine]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARAutoApplyLine] TO [public]
GO
