SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspARInvEntryLinesOtherInfo]
   
   /****************************************************************************
   * CREATED BY: TJL - 04/11/02
   * MODIFIED BY: TJL 09/29/03 - Issue #22393, Warn if Crediting more than Line AmtDue, Add with (nolock)
   *
   * USAGE:
   * 	Fills Other Info tab in ARInvoiceEntryLines
   *
   * INPUT PARAMETERS:
   *	@ARCo
   * 	@BatchMth, @BatchId, @BatchSeq      	
   *	@ApplyMth, @ApplyTrans, @ApplyLine		
   *
   * OUTPUT PARAMETERS:
   *	Line amounts and Line amounts due
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   @ARCo bCompany = null, @BatchMth bMonth = null, @BatchId bBatchID = null, @BatchSeq int = null,
     	@ApplyMth bMonth = null, @ApplyTrans bTrans = null, @ApplyLine smallint = null, 
     	@lineamt bDollar output, @linetax bDollar output, @lineretg bDollar output, @lineFC bDollar output,
   	@lineamtdue bDollar output, @linetaxdue bDollar output,  @lineretgdue bDollar output, @lineFCdue bDollar output,
   	@origlineamt bDollar output
   
   as
    
   set nocount on
    
   declare @invtrans int, @rcode int
   
   select @rcode = 0
   
   if @ARCo is null or @BatchMth is null or @BatchId is null or @BatchSeq is null or 
   	@ApplyMth is null or @ApplyTrans is null or @ApplyLine is null 
   	begin
   	select @rcode = 1	
   	goto bspexit
   	end
   
   select @origlineamt = Amount
   from bARTL with (nolock)
   where ARCo = @ARCo and Mth = @ApplyMth and ARTrans = @ApplyTrans and ARLine = @ApplyLine
   
   /* Get Invoice transaction number for a transaction that has been added back
      into the batch. */
   select @invtrans = min(ARTrans)
   from bARBL with (nolock)
   where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
   
   /* Get the amount totals for each Line */
   select @lineamt = IsNull(sum(bARTL.Amount),0),
   	@linetax = IsNull(sum(bARTL.TaxAmount),0),
   	@lineretg = IsNull(sum(bARTL.Retainage),0),
   	@lineFC = IsNull(sum(bARTL.FinanceChg),0)
   from bARTL with (nolock)
   join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
   where bARTL.ARCo = @ARCo and bARTL.ApplyMth = @ApplyMth and bARTL.ApplyTrans = @ApplyTrans and bARTL.ApplyLine = @ApplyLine
   	and bARTH.ARTransType <> 'P'
   	and(isnull(bARTH.InUseBatchID,0) <> @BatchId 
   	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth <> @BatchMth)
   	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth = @BatchMth and bARTH.ARTrans <> isnull(@invtrans,0)))
   
   /* Add in any amounts from another batch */
   select @lineamt = @lineamt + IsNull(sum(case bARBL.TransType when 'D'
              						then case when bARBH.ARTransType in ('I','A','F','R')
                					then -bARBL.oldAmount else bARBL.oldAmount
                					end
    
    			else
    
    								case when bARBH.ARTransType in ('I','A','F','R')
                					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
                					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
    								end
    			end),0),
    
    		@linetax = @linetax + IsNull(sum(case bARBL.TransType when 'D' then
                 					case when bARBH.ARTransType in ('I','A','F','R')
                 					then -bARBL.oldTaxAmount else bARBL.oldTaxAmount
                 					end
   	 
   	  		else
    
     								case when bARBH.ARTransType in ('I','A','F','R') 
                 					then IsNull(bARBL.TaxAmount,0) - IsNull(bARBL.oldTaxAmount,0)
                 					else -IsNull(bARBL.TaxAmount,0) + IsNull(bARBL.oldTaxAmount,0)
     								end
     			end),0), 
    
         	@lineretg = @lineretg + IsNull(sum(case bARBL.TransType when 'D'
    								then case when bARBH.ARTransType in ('I','A','F','R')
    								then -bARBL.oldRetainage else bARBL.oldRetainage
    								end
    
    			else
    	 
    								case when bARBH.ARTransType in ('I','A','F','R')
    								then IsNull(bARBL.Retainage,0) - IsNull(bARBL.oldRetainage,0)
    								else -IsNull(bARBL.Retainage,0) + IsNull(bARBL.oldRetainage,0)
     								end
    			end),0),
   
      		@lineFC = @lineFC + IsNull(sum(case bARBL.TransType when 'D'
    								then case when bARBH.ARTransType in ('I','A','F','R')
    								then -bARBL.oldFinanceChg else bARBL.oldFinanceChg
    								end
    
    			else
    	 
    								case when bARBH.ARTransType in ('I','A','F','R')
    								then IsNull(bARBL.FinanceChg,0) - IsNull(bARBL.oldFinanceChg,0)
    								else -IsNull(bARBL.FinanceChg,0) + IsNull(bARBL.oldFinanceChg,0)
     								end
    			end),0)
   
   from bARBL with (nolock)
   join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
   where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans and bARBL.ApplyLine = @ApplyLine
   		and bARBH.ARTransType <> 'P'
    		and bARBL.BatchSeq <> (case when bARBL.Mth = @BatchMth and bARBL.BatchId = @BatchId  then @BatchSeq else 0 end)	/* dont include this seq */
   
   /* Get the current amount due for each ARLine */
   select @lineamtdue = IsNull(sum(bARTL.Amount),0),
   	@linetaxdue = IsNull(sum(bARTL.TaxAmount),0),
   	@lineretgdue = IsNull(sum(bARTL.Retainage),0),
   	@lineFCdue = IsNull(sum(bARTL.FinanceChg),0)
   from bARTL with (nolock)
   join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
   where bARTL.ARCo = @ARCo and bARTL.ApplyMth = @ApplyMth and bARTL.ApplyTrans = @ApplyTrans and bARTL.ApplyLine = @ApplyLine
   	and(isnull(bARTH.InUseBatchID,0) <> @BatchId 
   	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth <> @BatchMth)
   	or (isnull(bARTH.InUseBatchID,0) = @BatchId and bARTH.Mth = @BatchMth and bARTH.ARTrans <> isnull(@invtrans,0)))
   
    
   /* Add in any amounts from another batch */
   select @lineamtdue = @lineamtdue + IsNull(sum(case bARBL.TransType when 'D'
              						then case when bARBH.ARTransType in ('I','A','F','R')
                					then -bARBL.oldAmount else bARBL.oldAmount
                					end
    
    			else
    
    								case when bARBH.ARTransType in ('I','A','F','R')
                					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
                					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
    								end
    			end),0),
    
    		@linetaxdue = @linetaxdue + IsNull(sum(case bARBL.TransType when 'D' then
                 					case when bARBH.ARTransType in ('I','A','F','R')
                 					then -bARBL.oldTaxAmount else bARBL.oldTaxAmount
                 					end
   	 
   	  		else
    
     								case when bARBH.ARTransType in ('I','A','F','R') 
                 					then IsNull(bARBL.TaxAmount,0) - IsNull(bARBL.oldTaxAmount,0)
                 					else -IsNull(bARBL.TaxAmount,0) + IsNull(bARBL.oldTaxAmount,0)
     								end
     			end),0), 
    
         	@lineretgdue = @lineretgdue + IsNull(sum(case bARBL.TransType when 'D'
    								then case when bARBH.ARTransType in ('I','A','F','R')
    								then -bARBL.oldRetainage else bARBL.oldRetainage
    								end
    
    			else
    	 
    								case when bARBH.ARTransType in ('I','A','F','R')
    								then IsNull(bARBL.Retainage,0) - IsNull(bARBL.oldRetainage,0)
    								else -IsNull(bARBL.Retainage,0) + IsNull(bARBL.oldRetainage,0)
     								end
    			end),0),
   
      		@lineFCdue = @lineFCdue + IsNull(sum(case bARBL.TransType when 'D'
    								then case when bARBH.ARTransType in ('I','A','F','R')
    								then -bARBL.oldFinanceChg else bARBL.oldFinanceChg
    								end
    
    			else
    	 
    								case when bARBH.ARTransType in ('I','A','F','R')
    								then IsNull(bARBL.FinanceChg,0) - IsNull(bARBL.oldFinanceChg,0)
    								else -IsNull(bARBL.FinanceChg,0) + IsNull(bARBL.oldFinanceChg,0)
     								end
    			end),0)
   
   from bARBL with (nolock)
   join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
   where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans and bARBL.ApplyLine = @ApplyLine
    		and bARBL.BatchSeq <> (case when bARBL.Mth = @BatchMth and bARBL.BatchId = @BatchId  then @BatchSeq else 0 end)	/* dont include this seq */
   
   bspexit:

GO
GRANT EXECUTE ON  [dbo].[bspARInvEntryLinesOtherInfo] TO [public]
GO
