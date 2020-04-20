SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspARCustomerBalance]
   
   /****************************************************************************
   * CREATED BY: TJL 10/23/03 - Issue #20401, Over CreditLimit check
   * MODIFIED BY: 
   *
   * USAGE:
   * 	Fills Balance lblData on ARInvoiceEntry Form
   *
   * INPUT PARAMETERS:
   *	@ARCo
   * 	@BatchMth, @BatchId, @BatchSeq      	
   *			
   *
   * OUTPUT PARAMETERS:
   *	Line amounts and Line amounts due
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   @arco bCompany = null, @batchmth bMonth = null, @batchid bBatchID = null, @batchseq int = null,
     	@custgroup bGroup, @customer bCustomer, @amtdue bDollar output, @calcamtdue bDollar output
   
   as
    
   set nocount on
    
   declare @rcode int, @artrans bTrans
   
   select @rcode = 0
   
   if @arco is null or @batchmth is null or @batchid is null or @batchseq is null or 
   	@custgroup is null or @customer is null
   	begin
   	select @rcode = 1	
   	goto bspexit
   	end
   
   /* Get AR transaction number for a transaction that has been added back
      into the batch. */
   select @artrans = min(ARTrans)
   from bARBL with (nolock)
   where Co = @arco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq
   
   /* Get the amount totals for this custgroup and customer from ARMT for speed. 
      It would be far too slow to do a calculated amount from ARTL.  Retainage is not
      excluded since it is still an amount ultimately owed by the customer. */
   select @amtdue =(isnull(sum(Invoiced),0) - isnull(sum(Paid),0))
   from bARMT with (nolock)
   where ARCo = @arco and CustGroup = @custgroup and Customer = @customer
   group by ARCo, CustGroup, Customer
   
   /* Exclude values for this transaction if it has been added
      back into a batch for change or delete. */
   select @amtdue = isnull(@amtdue,0) - IsNull(sum(bARTL.Amount),0)
   from bARTL with (nolock)
   join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
   where bARTL.ARCo = @arco and bARTH.CustGroup = @custgroup and bARTH.Customer = @customer
   	and (isnull(bARTH.InUseBatchID,0) = @batchid and bARTH.Mth = @batchmth and bARTH.ARTrans = isnull(@artrans,0))
   
   /* Add in any amounts from other batches not including this batchseq */
   select @amtdue = isnull(@amtdue,0) + IsNull(sum(case bARBL.TransType when 'D'
              						then case when bARBH.ARTransType in ('I','A','F','R')
                					then -bARBL.oldAmount else bARBL.oldAmount
                					end
     			else
    								case when bARBH.ARTransType in ('I','A','F','R')
                					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
                					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
    								end
    			end),0)
   from bARBL with (nolock)
   join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
   where bARBL.Co = @arco and bARBH.CustGroup = @custgroup and bARBH.Customer = @customer
    		and bARBL.BatchSeq <> (case when bARBL.Mth = @batchmth and bARBL.BatchId = @batchid  then @batchseq else 0 end)	/* dont include this seq */
   
   ---------------For Testing only-------------
   /* Get the Calculated amount totals for this custgroup and customer. Exclude values for any transaction added
      back into a batch for change or delete. */
   /*
   select @calcamtdue = IsNull(sum(bARTL.Amount),0)
   from bARTL with (nolock)
   join bARTH with (nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
   where bARTL.ARCo = @arco and bARTH.CustGroup = @custgroup and bARTH.Customer = @customer
   	and(isnull(bARTH.InUseBatchID,0) <> @batchid 
   	or (isnull(bARTH.InUseBatchID,0) = @batchid and bARTH.Mth <> @batchmth)
   	or (isnull(bARTH.InUseBatchID,0) = @batchid and bARTH.Mth = @batchmth and bARTH.ARTrans <> isnull(@artrans,0)))
   */
   /* Add in any amounts from other batches not including this batchseq */
   /*
   select @calcamtdue = isnull(@calcamtdue,0) + IsNull(sum(case bARBL.TransType when 'D'
              						then case when bARBH.ARTransType in ('I','A','F','R')
                					then -bARBL.oldAmount else bARBL.oldAmount
                					end
     			else
    								case when bARBH.ARTransType in ('I','A','F','R')
                					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
                					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
    								end
    			end),0)
   from bARBL with (nolock)
   join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
   where bARBL.Co = @arco and bARBH.CustGroup = @custgroup and bARBH.Customer = @customer
    		and bARBL.BatchSeq <> (case when bARBL.Mth = @batchmth and bARBL.BatchId = @batchid  then @batchseq else 0 end)
   */
   select @calcamtdue = 0	--Leave here, remove for Testing
   -----------------End Testing-----------------
   
   bspexit:

GO
GRANT EXECUTE ON  [dbo].[bspARCustomerBalance] TO [public]
GO
