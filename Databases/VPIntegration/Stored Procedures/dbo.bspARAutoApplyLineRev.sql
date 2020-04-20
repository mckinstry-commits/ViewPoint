SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARAutoApplyLineRev    Script Date: 8/20/02 9:36:03 AM ******/
CREATE  proc [dbo].[bspARAutoApplyLineRev]
/********************************************************
* CREATED BY: 	TJL 05/20/02 - Issue #17421,  Breakout Reverse Payment processing to its own procedure
* MODIFIED BY:	TJL 07/31/02 - Issue #11219,  Add 'TaxDisc Applied' column to grid for user input. 
*		TJL 08/07/03 - Issue #22087, Performance mods, add NoLocks
*		***************************************** TOTAL REWRITE AFTER THIS POINT ****************************************
*		TJL 11/13/03 - Issue #23005:  To be consistent with rewrite of bspARAutoApply and bspARAutoApplyLine
*		TJL 01/06/05 - Issue #26713, Removed unused code that was causing 100,000 unnecessary reads
*		TJL 06/05/08 - Issue #128457:  ARCashReceipts International Sales Tax
*
* USAGE:
* 	This procedure Reverses payment amounts to each line of an invoice.
*	This Apply procedure will only reverse payment amounts up to the total amount
*	having been previously paid in each column.
*	
*
*	This functionality was previously performed by 'bspARAutoApplyLine' however, had to be
*	separated to allow for proper negative Invoice processing which utilizes 'ABS()' and
*	was problematic for Reversing payments.
*
*
* CAUTION:
*	As with so many backend procedures, seemingly minor modifications can have major
*	implications.  This procedure works closely with bspARAutoApply and bspARAutoApplyLine
*	as well as with form ARCashReceipts.
*	If it seems too easy it probably is. Unless you understand how all these procedures
*	function together you should not be making changes.
*
*
*	Run from:
*		1. Called by bspARAutoApplyLine
*
* INPUT PARAMETERS:
*		ARCo, BatchMth, BatchId, BatchSeq
*   	ApplyMth, ApplyTrans, ApplyAmt, ApplyTax, ApplyRetg
*    	DiscReturn, ApplyFC
*
* OUTPUT PARAMETERS:
*	Error message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/

@ARCo bCompany, @BatchMth bMonth, @BatchId bBatchID,
@BatchSeq int, @ApplyMth bMonth, @ApplyTrans bTrans, @ApplyAmt bDollar,
@ApplyTax bDollar, @ApplyRetg bDollar, @DiscReturn bDollar, @ApplyTaxDisc bDollar,
@ApplyFC bDollar, @errmsg varchar(255) output
as
   
set nocount on
   
/* Line declarations */
declare @AmtPaid bDollar, @TotAmtLeft bDollar, @DiscTaken bDollar, @DiscLeft bDollar,
   	@TaxDiscTaken bDollar, @TaxDiscLeft bDollar, @RetgPaid bDollar, @RetgLeft bDollar, 
   	@TaxAmtPaid bDollar, @TaxLeft bDollar, @FCPaid bDollar, @FCLeft bDollar,
   	@PostAmt bDollar, @PostDisc bDollar, @PostTaxDisc bDollar, @PostRetg bDollar, 
   	@PostTaxAmt bDollar, @PostFC bDollar, @Amountpd bDollar,
	@RetgTaxPaid bDollar, @RetgTaxLeft bDollar, @PostRetgTax bDollar
   
/* Invoice declarations */
declare @InvAmtPaid bDollar, @InvDiscTaken bDollar, @InvTaxDiscTaken bDollar, @InvRetgPaid bDollar,
   	@InvTaxAmtPaid bDollar, @InvFCPaid bDollar, @InvRetgTaxPaid bDollar, @InvApplyRetgPct numeric(5,2)
   
/* General declarations */
declare @ARLine smallint, @paytrans int, @NextARLine int,
   	@openarlinecursor int, @passes tinyint, @RevValueFlag tinyint,
   	@rcode int
   
select @rcode = 0, @openarlinecursor = 0, @passes = 0, @RevValueFlag = 0
   
/* Get Payment transaction number for a transaction that has been added back
   into the batch. */
select @paytrans = min(ARTrans)
from bARBL with (nolock)
where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
   
/******************************** INVOICE PAYMENT AMOUNTS **********************************/
/* There are no user input restrictions on the form preventing users from Reversing more
  than what was paid on a given invoice.  (This would be difficult to do since there are already
  extensive restrictions when applying cash normally and not all the information is readily
  available on the form regarding payments for ALL columns.)

  Therefore it is necessary to do an extra and slightly time consuming check to get Invoice
  amounts paid before proceeding.  These will be used later to override users inputs
  that exceed total payment amounts for the invoice.  The inefficiency of this should be 
  acceptible since users should rarely be reversing payments. */
   
/* Get the paid amounts already posted for this Invoice.  */
select @InvAmtPaid = IsNull(sum(bARTL.Amount),0),
   	@InvTaxAmtPaid = IsNull(sum(bARTL.TaxAmount),0),
   	@InvRetgPaid = IsNull(sum(bARTL.Retainage),0),
   	@InvFCPaid = IsNull(sum(bARTL.FinanceChg),0),
   	@InvDiscTaken = IsNull(sum(bARTL.DiscTaken),0),
   	@InvTaxDiscTaken = IsNull(sum(bARTL.TaxDisc),0),
	@InvRetgTaxPaid = IsNull(sum(bARTL.RetgTax),0)
from bARTL with (nolock)
left join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
where bARTL.ARCo = @ARCo and bARTL.ApplyMth = @ApplyMth and bARTL.ApplyTrans = @ApplyTrans
   	and bARTH.ARTransType = 'P'
   	/* If this previously posted transaction is being changed, then ignore its current values
   	   in bARTL since they are about to be modified.  (Treat as if this trans doesn't exist) */
   	and(isnull(bARTH.InUseBatchID,0) <> @BatchId 
   	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth <> @BatchMth)
   	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth = @BatchMth and bARTH.ARTrans <> isnull(@paytrans,0)))
    
/* Add in any amounts from other unposted batches. */
select @InvAmtPaid = @InvAmtPaid + IsNull(sum(case bARBL.TransType when 'D'
      						then case when bARBH.ARTransType in ('I','A','F','R')
        					then -bARBL.oldAmount else bARBL.oldAmount
        					end
    
   				else
   
   						case when bARBH.ARTransType in ('I','A','F','R')
        					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
        					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
   						end
   				end),0),
    
   		@InvTaxAmtPaid = @InvTaxAmtPaid + IsNull(sum(case bARBL.TransType when 'D' then
         					case when bARBH.ARTransType in ('I','A','F','R')
         					then -bARBL.oldTaxAmount else bARBL.oldTaxAmount
         					end
    
     				else
    
   						case when bARBH.ARTransType in ('I','A','F','R') 
     						then IsNull(bARBL.TaxAmount,0) - IsNull(bARBL.oldTaxAmount,0)
     						else -IsNull(bARBL.TaxAmount,0) + IsNull(bARBL.oldTaxAmount,0)
   						end
     				end),0), 
    
   		@InvRetgPaid = @InvRetgPaid + IsNull(sum(case bARBL.TransType when 'D'
   						then case when bARBH.ARTransType in ('I','A','F','R')
   						then -bARBL.oldRetainage else bARBL.oldRetainage
   						end
    
    				else
    	 
   						case when bARBH.ARTransType in ('I','A','F','R')
   						then IsNull(bARBL.Retainage,0) - IsNull(bARBL.oldRetainage,0)
   						else -IsNull(bARBL.Retainage,0) + IsNull(bARBL.oldRetainage,0)
   						end
    				end),0),
   
		@InvFCPaid = @InvFCPaid + IsNull(sum(case bARBL.TransType when 'D'
   						then case when bARBH.ARTransType in ('I','A','F','R')
   						then -bARBL.oldFinanceChg else bARBL.oldFinanceChg
   						end
    
    				else
    	 
   						case when bARBH.ARTransType in ('I','A','F','R')
   						then IsNull(bARBL.FinanceChg,0) - IsNull(bARBL.oldFinanceChg,0)
   						else -IsNull(bARBL.FinanceChg,0) + IsNull(bARBL.oldFinanceChg,0)
   						end
    				end),0),
   
   		@InvDiscTaken = @InvDiscTaken + IsNull(sum(case bARBL.TransType when 'D'
   						then case when bARBH.ARTransType in ('I','A','F','R')
   						then -bARBL.oldDiscTaken else bARBL.oldDiscTaken
   						end
    
    				else
    	 
   						case when bARBH.ARTransType in ('I','A','F','R')
   						then IsNull(bARBL.DiscTaken,0) - IsNull(bARBL.oldDiscTaken,0)
   						else -IsNull(bARBL.DiscTaken,0) + IsNull(bARBL.oldDiscTaken,0)
   						end
    				end),0),
   
		@InvTaxDiscTaken = @InvTaxDiscTaken + IsNull(sum(case bARBL.TransType when 'D'
   						then case when bARBH.ARTransType in ('I','A','F','R')
   						then -bARBL.oldTaxDisc else bARBL.oldTaxDisc
   						end
    
    				else
    	 
   						case when bARBH.ARTransType in ('I','A','F','R')
   						then IsNull(bARBL.TaxDisc,0) - IsNull(bARBL.oldTaxDisc,0)
   						else -IsNull(bARBL.TaxDisc,0) + IsNull(bARBL.oldTaxDisc,0)
   						end
    				end),0),

   		@InvRetgTaxPaid = @InvRetgTaxPaid + IsNull(sum(case bARBL.TransType when 'D'
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
join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans
and bARBH.ARTransType = 'P'
and bARBL.BatchSeq <> (case when bARBL.Mth = @BatchMth and bARBL.BatchId = @BatchId  then @BatchSeq else 0 end)	/* dont include this seq */
/****************************** END INVOICE PAYMENT AMOUNTS ********************************/

/*************************** BEGIN PROCESSING PAYMENT ON THIS INVOICE *******************/ 
    
/* Keep a running amount of how much cash is left to reverse.  Restrict user from reversing 
  more than has been paid for any one column value. */
select @TotAmtLeft = case when abs(@ApplyAmt) > abs(@InvAmtPaid) then @InvAmtPaid else @ApplyAmt end, 
@RetgLeft = case when abs(@ApplyRetg) > abs(@InvRetgPaid) then @InvRetgPaid else @ApplyRetg end, 
@DiscLeft = case when abs(@DiscReturn) > abs(@InvDiscTaken) then @InvDiscTaken else @DiscReturn end, 
@FCLeft = case when abs(@ApplyFC) > abs(@InvFCPaid) then @InvFCPaid else @ApplyFC end, 
@TaxLeft = case when abs(@ApplyTax) > abs(@InvTaxAmtPaid) then @InvTaxAmtPaid else @ApplyTax end, 
@TaxDiscLeft = case when abs(@ApplyTaxDisc) > abs(@InvTaxDiscTaken) then @InvTaxDiscTaken else @ApplyTaxDisc end,
@RetgTaxLeft = case when @InvRetgPaid <> 0 then (@RetgLeft/@InvRetgPaid) * @InvRetgTaxPaid else 0 end,
@InvApplyRetgPct = case when @InvRetgPaid <> 0 then (@RetgLeft/@InvRetgPaid) * 100 else 0 end
  
select @AmtPaid = 0, @TaxAmtPaid = 0, @RetgPaid = 0, @FCPaid = 0, @DiscTaken = 0,
   	@TaxDiscTaken = 0, @RetgTaxPaid = 0
   
CycleThruLines:
declare bcARLine cursor local fast_forward for
select ARLine
from bARTL with (nolock)
where ARCo = @ARCo and Mth = @ApplyMth and ARTrans = @ApplyTrans
   
open bcARLine
select @openarlinecursor = 1
select @passes = @passes + 1	--For Neg/Rev Polarity lines/column handling

fetch next from bcARLine into @ARLine
while @@fetch_status = 0
	begin	/* Begin Line Loop */
	select @PostAmt=0, @PostRetg=0, @PostDisc=0, @PostTaxAmt=0, @PostFC=0, @PostTaxDisc=0, @PostRetgTax=0
    
	/* Get the amount already paid for each ARLine */
 	select @AmtPaid = IsNull(sum(bARTL.Amount),0),
		@TaxAmtPaid = IsNull(sum(bARTL.TaxAmount),0),
   		@RetgPaid = IsNull(sum(bARTL.Retainage),0),
		@FCPaid = IsNull(sum(bARTL.FinanceChg),0),
		@DiscTaken = IsNull(sum(bARTL.DiscTaken),0),
		@TaxDiscTaken = IsNull(sum(bARTL.TaxDisc),0),
		@RetgTaxPaid = IsNull(sum(bARTL.RetgTax),0)
 	from bARTL with (nolock)
 	left join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
 	where bARTL.ARCo = @ARCo and bARTL.ApplyMth = @ApplyMth and bARTL.ApplyTrans = @ApplyTrans and bARTL.ApplyLine = @ARLine
		and bARTH.ARTransType = 'P'
		/* If this previously posted transaction is being changed, then ignore its current values
		   in bARTL since they are about to be modified.  (Treat as if this trans doesn't exist) */
		   and(isnull(bARTH.InUseBatchID,0) <> @BatchId 
		or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth <> @BatchMth)
		or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth = @BatchMth and bARTH.ARTrans <> isnull(@paytrans,0)))
    
	/* Add in any amounts from other unposted batches */
	select @AmtPaid = @AmtPaid + IsNull(sum(case bARBL.TransType when 'D'
          						then case when bARBH.ARTransType in ('I','A','F','R')
            					then -bARBL.oldAmount else bARBL.oldAmount
            					end

					else

								case when bARBH.ARTransType in ('I','A','F','R')
            					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
            					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
								end
					end),0),
    
       	@TaxAmtPaid = @TaxAmtPaid + IsNull(sum(case bARBL.TransType when 'D' then
             					case when bARBH.ARTransType in ('I','A','F','R')
             					then -bARBL.oldTaxAmount else bARBL.oldTaxAmount
             					end

 					else

 								case when bARBH.ARTransType in ('I','A','F','R') 
             					then IsNull(bARBL.TaxAmount,0) - IsNull(bARBL.oldTaxAmount,0)
             					else -IsNull(bARBL.TaxAmount,0) + IsNull(bARBL.oldTaxAmount,0)
 								end
 					end),0), 
    
       	@RetgPaid = @RetgPaid + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldRetainage else bARBL.oldRetainage
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.Retainage,0) - IsNull(bARBL.oldRetainage,0)
								else -IsNull(bARBL.Retainage,0) + IsNull(bARBL.oldRetainage,0)
 								end
					end),0),
   
		@FCPaid = @FCPaid + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldFinanceChg else bARBL.oldFinanceChg
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.FinanceChg,0) - IsNull(bARBL.oldFinanceChg,0)
								else -IsNull(bARBL.FinanceChg,0) + IsNull(bARBL.oldFinanceChg,0)
 								end
					end),0),
   
		@DiscTaken = @DiscTaken + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldDiscTaken else bARBL.oldDiscTaken
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.DiscTaken,0) - IsNull(bARBL.oldDiscTaken,0)
								else -IsNull(bARBL.DiscTaken,0) + IsNull(bARBL.oldDiscTaken,0)
 								end
					end),0),
   
		@TaxDiscTaken = @TaxDiscTaken + IsNull(sum(case bARBL.TransType when 'D'
								then case when bARBH.ARTransType in ('I','A','F','R')
								then -bARBL.oldTaxDisc else bARBL.oldTaxDisc
								end

					else
	 
								case when bARBH.ARTransType in ('I','A','F','R')
								then IsNull(bARBL.TaxDisc,0) - IsNull(bARBL.oldTaxDisc,0)
								else -IsNull(bARBL.TaxDisc,0) + IsNull(bARBL.oldTaxDisc,0)
 								end
					end),0),

       	@RetgTaxPaid = @RetgTaxPaid + IsNull(sum(case bARBL.TransType when 'D'
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
	join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
	where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans and bARBL.ApplyLine = @ARLine
	and bARBH.ARTransType = 'P'
		and bARBL.BatchSeq <> (case when bARBL.Mth = @BatchMth and bARBL.BatchId = @BatchId  then @BatchSeq else 0 end)	/* dont include this seq */
   
/**************************** NEGATIVE/REVERSE POLARITY LINE OR COLUMN HANDLING ONLY *******************************/
/* Combine with This BatchSeq values to be posted.  These will be 0.00 initially!
   They are ONLY considered when a Reverse Polarity value (Usually Neg column Or Neg Line) has been
   encountered.  In which case, we are cycling thru the Lines of this invoice a 2nd
   time to distribute the extra cash generated by posting negative values across lines with
   amounts still due.  This is a very real situation and a second pass cannot be avoided. 

   ***IMPORTANT*** Old values DO NOT need to be considered here because we ignored existing
   values in bARTL initially for this specific Invoice transaction.  (See above) */
if @RevValueFlag = 1 and @passes = 2
	begin	/* Begin Reverse Polarity handling */
 	select @AmtPaid = @AmtPaid - IsNull(sum(bARBL.Amount),0),
        	@TaxAmtPaid = @TaxAmtPaid - IsNull(sum(bARBL.TaxAmount),0), 
        	@RetgPaid = @RetgPaid - IsNull(sum(bARBL.Retainage),0),
         	@FCPaid = @FCPaid - IsNull(sum(bARBL.FinanceChg),0),
  			@DiscTaken = @DiscTaken - IsNull(sum(bARBL.DiscTaken),0),
        	@TaxDiscTaken = @TaxDiscTaken - IsNull(sum(bARBL.TaxDisc),0),
			@RetgTaxPaid = @RetgTaxPaid - IsNull(sum(bARBL.RetgTax),0)
   	from bARBL with (nolock)
   	where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans and bARBL.ApplyLine = @ARLine
		and bARBL.Mth = @BatchMth and bARBL.BatchId = @BatchId and bARBL.BatchSeq = @BatchSeq	/* Include this seq */
	end		/* End Reverse Polarity Handling */
/**************************** END NEGATIVE/REVERSE LINE OR COLUMN HANDLING ONLY *******************************/

/********************** EVALUATE AND SET POST AMOUNTS BASED ON INPUTTED REVERSAL AMOUNTS *******************/
    
/* Retainage Amount removed for proper comparisons that follow */
select @Amountpd = @AmtPaid - (@TaxAmtPaid + @FCPaid + @RetgPaid)
    
/* Set post amounts */
select @PostRetg=case
		when @RetgPaid = 0 then 0
		when (@ApplyRetg > 0 and @RetgPaid < 0) or (@ApplyRetg < 0 and @RetgPaid > 0) then @RetgPaid --Neg/Rev column handling
		when abs(@RetgPaid) <= abs(@RetgLeft) and @RetgLeft <> 0 then @RetgPaid
 		when abs(@RetgPaid) > abs(@RetgLeft) and @RetgLeft <> 0 then @RetgLeft
     	else 0
 		end,
	/* RetgTax requires special handling.  There is no exposed "Applied" input for the user on the CashReceipt grid.  
	   RetgTax paid amount is determined automatically for the user behind the scenes. */
	@PostRetgTax = case
   		when @PostRetg = 0 then 0
		when (@ApplyRetg > 0 and @RetgPaid < 0) or (@ApplyRetg < 0 and @RetgPaid > 0) then @RetgTaxPaid --Neg/Rev column handling
   		when abs(@RetgTaxPaid) <= abs(@RetgTaxLeft) and abs(@RetgTaxPaid) <= abs(@PostRetg) and @RetgTaxLeft <> 0 then @RetgTaxPaid
		when abs(@RetgTaxPaid) <= abs(@RetgTaxLeft) and abs(@RetgTaxPaid) > abs(@PostRetg) and @RetgTaxLeft <> 0 then @PostRetg
   		when abs(@RetgTaxPaid) > abs(@RetgTaxLeft) and abs(@RetgTaxLeft) <= abs(@PostRetg) and @RetgTaxLeft <> 0 then @RetgTaxLeft
		when abs(@RetgTaxPaid) > abs(@RetgTaxLeft) and abs(@RetgTaxLeft) > abs(@PostRetg) and @RetgTaxLeft <> 0 then @PostRetg
		else 0
   		end,
	@PostDisc=case
		when @DiscTaken = 0 then 0
		when (@DiscReturn > 0 and @DiscTaken < 0) or (@DiscReturn < 0 and @DiscTaken > 0) then @DiscTaken	--Neg/Rev column handling
     	when abs(@DiscTaken) <= abs(@DiscLeft) and @DiscLeft <> 0 then @DiscTaken
 	 	when abs(@DiscTaken) > abs(@DiscLeft) and @DiscLeft <> 0 then @DiscLeft
 	 	else 0
 	 	end,
 	@PostTaxDisc=case
		when @TaxDiscTaken = 0 then 0
		when (@ApplyTaxDisc > 0 and @TaxDiscTaken < 0) or (@ApplyTaxDisc < 0 and @TaxDiscTaken > 0) then @TaxDiscTaken	--Neg/Rev column handling
     	when abs(@TaxDiscTaken) <= abs(@TaxDiscLeft) and @TaxDiscLeft <> 0 then @TaxDiscTaken
 	 	when abs(@TaxDiscTaken) > abs(@TaxDiscLeft) and @TaxDiscLeft <> 0 then @TaxDiscLeft
 	 	else 0
 	 	end,
	@PostTaxAmt=case
		when @TaxAmtPaid = 0 then 0
		when (@ApplyTax > 0 and @TaxAmtPaid < 0) or (@ApplyTax < 0 and @TaxAmtPaid > 0) then @TaxAmtPaid	--Neg/Rev column handling
		when abs(@TaxAmtPaid) <= abs(@TaxLeft) and @TaxLeft <> 0 then @TaxAmtPaid
		when abs(@TaxAmtPaid) > abs(@TaxLeft) and @TaxLeft <> 0 then @TaxLeft
		else 0
		end,
	@PostFC=case
		when @FCPaid = 0 then 0
		when (@ApplyFC > 0 and @FCPaid < 0) or (@ApplyFC < 0 and @FCPaid > 0) then @FCPaid 	--Neg/Rev column handling
		when abs(@FCPaid) <= abs(@FCLeft) and @FCLeft <> 0 then @FCPaid
		when abs(@FCPaid) > abs(@FCLeft) and @FCLeft <> 0 then @FCLeft
		else 0
		end
   
/* @PostAmt is dependent upon all other posted values and must be determined last.  Amounts
   left (@TaxLeft, @FCLeft and @RetgLeft) are very important and must be considered in order
   to reserve enough in @TotAmtLeft to cover these values for lines yet to be posted.  The 
   difference when reversing payments is that there are NO input restrictions preventing the
   user from trying to reverse more than that paid already.  We prevent this earlier in this
   procedure by summing Total Amounts for the invoice. 
   Rules are:
	1) Later, overall Amount posted = (@PostAmt + @PostTax + @PostRetg + @PostFC)
	2) @PostDisc does not affect the Amount column at all! It only represents more available
	   cash after posting against this invoice.
	3) @PostAmt may never exceed (@TotAmtLeft, at this moment, minus (@TaxLeft + @FCLeft + @RetgLeft, representing
	   the amounts needed to be held back for posting Tax, Retg, & FC on this line and future lines. )
*/
select @PostAmt = case
  	when @Amountpd = 0 then 0
	when (@ApplyAmt > 0 and @AmtPaid < 0) or (@ApplyAmt < 0 and @AmtPaid > 0) then @Amountpd 	--Neg/Rev column handling
	when abs(@Amountpd) <= abs(@TotAmtLeft - (@TaxLeft + @FCLeft + @RetgLeft)) then @Amountpd
	when abs(@Amountpd) > abs(@TotAmtLeft - (@TaxLeft + @FCLeft + @RetgLeft)) then @TotAmtLeft - (@TaxLeft + @FCLeft + @RetgLeft)
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
if abs(@RetgLeft - @PostRetg) < abs(@RetgTaxLeft - @PostRetgTax)
	begin
	select @PostRetg = case when abs(@PostRetg - (@RetgTaxLeft - @PostRetgTax)) > abs(@PostRetgTax) then
		@PostRetg - (@RetgTaxLeft - @PostRetgTax) else @PostRetgTax end
	end

/* Negative/Reverse Polarity Line/Column handling.  Will later be used to determine of a 2nd
   Pass is required to distribute extra cash generated by zeroing out these values. */
If ((@ApplyRetg > 0 and @RetgPaid < 0) or (@ApplyRetg < 0 and @RetgPaid > 0)) or
	((@DiscReturn > 0 and @DiscTaken < 0) or (@DiscReturn < 0 and @DiscTaken > 0)) or
	((@ApplyTaxDisc > 0 and @TaxDiscTaken < 0) or (@ApplyTaxDisc < 0 and @TaxDiscTaken > 0)) or
	((@ApplyTax > 0 and @TaxAmtPaid < 0) or (@ApplyTax < 0 and @TaxAmtPaid > 0)) or
	((@ApplyFC > 0 and @FCPaid < 0) or (@ApplyFC < 0 and @FCPaid > 0)) or
	((@ApplyAmt > 0 and @AmtPaid < 0) or (@ApplyAmt < 0 and @AmtPaid > 0)) 
select @RevValueFlag = 1
   
PostRoutine:
   	if @passes = 1
   		begin	/* Begin Pass One batch insert */
   		/* Clear values out and start over or insert into batch for the first time. */
   		update bARBL
   		set Amount = @PostAmt + @PostTaxAmt + @PostFC + @PostRetg,   
   		 	Retainage = @PostRetg, 
   			TaxDisc = @PostTaxDisc,
   			FinanceChg = @PostFC, 
   			DiscTaken = @PostDisc,
   		 	TaxAmount = @PostTaxAmt,
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
   			  	select @errmsg = 'Reversing Payment error. - Updating Batch Detail Table has failed on'
   				select @errmsg = @errmsg + ' Mth: ' + isnull(convert(varchar(8),@ApplyMth,1),'') 
   				select @errmsg = @errmsg + ' ARTrans: ' + isnull(convert(varchar(6),@ApplyTrans),''), @rcode=1
   			  	goto bspexit
   			  	end
   		 	end
   		end		/* End Pass One batch insert */
   
   	if @passes = 2
   		begin	/* Begin Pass two batch update for Reverse/Negative Polarity Line/Column handling. */
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
   
   	/* Get next line. */
   	fetch next from bcARLine into @ARLine
   
   	end   /* End Line Loop */
   
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
   
/********* AT THIS TIME, Users should not want to Reverse more than has been paid ******** 
********* in any one column.  Any amounts greater than true amounts paid have    ********
********* already been dropped. */
    
bspexit:

if isnull(@RetgTaxLeft, 0) <> 0
	begin 
	if @errmsg is not null select @errmsg = @errmsg + char(13) + char(10) + char(13) + char(10)
	select @errmsg = isnull(@errmsg, '') + 'Cash was not reversed for the full ' + convert(varchar(6), @InvApplyRetgPct) + '% of Retainage Tax.  '
	select @errmsg = @errmsg + 'Use the Payment Detail form to verify or change the cash reversal directly to Retainage Tax on this invoice.'
	select @rcode = 7
	end

if @openarlinecursor = 1
	begin
	close bcARLine
	deallocate bcARLine
	select @openarlinecursor = 0
	end
    
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARAutoApplyLineRev]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARAutoApplyLineRev] TO [public]
GO
