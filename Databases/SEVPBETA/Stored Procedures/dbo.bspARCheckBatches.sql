SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCheckBatches    Script Date: 6/6/02 9:34:18 AM ******/
   CREATE proc [dbo].[bspARCheckBatches]
   /*********************************************************************************
   *  Created:	TJL  06/06/02
   *  Modified:	TJL  07/06/05:  Issue #29224, 6x recoding required.
   *			GG 02/22/08 - #120107 - separate sub ledger close - use AR close month		
   *		
   *  Currently used only by 'PurgeByPaidInv' programs.
   *  Will retrieve proper GLCo for this ARCo then retrieve GL Sub Ledger Closed date.
   *  It then Checks all bARBH batches for transactions later than this date and within
   *  a specified customer range.  If they exist, it will then further check bHQBC for 
   *  unfinished status and if it is in the process of posting or open, an error message
   *  will be sent to user.
   *  
   *
   * Inputs:
   *	@arco					-	AR Company
   *	@custgroup				-	Customer Group
   *	@begincust, @endcust	-	Customer Range to evaluate
   *	@purgeby				-	Purge By selection
   *	@begincontract, endcontract		- Contract Range to evaluate
   *
   * Outputs:
   *	@msg			-	error message
   *   @rcode	
   *
   *************************************************************************************/
   (@arco bCompany = null, @custgroup bGroup, @begincust bCustomer, @endcust bCustomer,
   	@purgeby varchar(8), @jcco bCompany, @begincontract bContract, @endcontract bContract, @msg varchar(375) output)
   as
   set nocount on
   
   declare @rcode int, @count int, @glco bCompany, @batchid bBatchID, @mth bMonth, 
   	@source varchar(20), @lastsubclosedmth bMonth, @batchlistcursor int
   
   select @rcode = 0, @batchlistcursor = 0
   
   if @arco is null
   	begin
   	select @msg = 'Missing AR Company', @rcode = 1
   	goto bspexit
   	end
   
   /*  Since Invoice Purges depend on accurate balances,
   	and since open batches can lead to changes that can effect the balances that
   	are evaluated, all transactions that exist in batches that may affect
       the balance of that transaction should first be posted before user 
   	begins these processes. We do not evaluate batch records in these processes
   	because changes in open batches would effect the accuracy of the calculations
   	anyway.  User is warned to post open batches before proceeding and in the 
   	case of Invoice Purges, the user is actually prevented from proceeding. */
   
   /* Get GLCo for this ARCo */
   select @glco = GLCo
   from bARCO with (nolock)
   where ARCo = @arco
   
   /* Get the SubLedger last closed month for this GLCo.  We do not care about transactions
      in batches if the month has been closed.  */
   select @lastsubclosedmth = LastMthARClsd	-- #120107 - use AR closed month
   from bGLCO with (nolock)
   where GLCo = @glco
   
   if @purgeby = 'Customer'
   	begin
   	/* Create a list of batches within this customer range, containing records that exist 
   	   and whose Mth is greater than the Subledger closed date. */
   	declare bcBatchList cursor for
   	select distinct BatchId, Mth, Source 
   	from bARBH with (nolock)
   	where Co = @arco and ARTransType in ('F','I','P','R', 'C', 'A', 'W')
   		and Mth > @lastsubclosedmth and CustGroup = @custgroup
   		and Customer >= isnull(@begincust, Customer)
   		and Customer <= isnull(@endcust, Customer)
   	
   	open bcBatchList
   	select @batchlistcursor = 1
   	
   	fetch next from bcBatchList into @batchid, @mth, @source
   	while @@fetch_status = 0
   		begin  /* Begin Customer BatchList loop */
   		/* Since these batches exist and are later than the Subledger closed date
   		   we will check the Batch control status for each batch.
   		   	If not present in bHQBC, then not valid so may be skipped/ignored.
   			If present in bHQBC and in process or open, give error to user */
   		select Mth, BatchId
   		from bHQBC with (nolock)
   		where Co = @arco and Mth = @mth and BatchId = @batchid and Status < 5
   	
   		/* This record has been found to be in a valid batch, Warn User and exit */
   		if @@rowcount > 0
   			begin
   			select @msg = 'Entries exist, for this Customer range, in AR batch: ' + convert(varchar(10),@batchid)
   			select @msg = @msg + ' for month ' + convert(varchar(8), @mth, 1) 
   			select @msg = @msg + ': in source ' + convert(varchar(20), @source) + '.  '
   			select @msg = @msg + char(13) + char(10)
   			select @msg = @msg + 'This routine does not evaluate open batch values!  ' 
   			select @msg = @msg + 'To proceed, it is recommended that all Invoice, Payment, Release Retainage, and Finance Charge batches be posted.'
   			select @rcode = 1
   			goto bspexit
   			end
   	
   	
   		/* No warning to this point so get next BatchId and evaluate */
   		fetch next from bcBatchList into @batchid, @mth, @source
   		end  /* End Customer BatchList loop */
   	end
   
   if @purgeby = 'Contract'
   	begin
   	/* Create a list of batches within this contract range, containing records that exist 
   	   and whose Mth is greater than the Subledger closed date. */
   	declare bcBatchList cursor for
   	select distinct h.BatchId, h.Mth, h.Source 
   	from bARBH h with (nolock)
   	join bARBL l with (nolock) on l.Co = h.Co and l.Mth = h.Mth and l.BatchId = h.BatchId
   	where h.Co = @arco and h.ARTransType in ('F','I','P','R', 'C', 'A', 'W')
   		and h.Mth > @lastsubclosedmth and l.JCCo = @jcco
   		and l.Contract >= isnull(@begincontract, l.Contract)
   		and l.Contract <= isnull(@endcontract, l.Contract)
   	
   	open bcBatchList
   	select @batchlistcursor = 1
   	
   	fetch next from bcBatchList into @batchid, @mth, @source
   	while @@fetch_status = 0
   		begin  /* Begin Contract BatchList loop */
   		/* Since these batches exist and are later than the Subledger closed date
   		   we will check the Batch control status for each batch.
   		   	If not present in bHQBC, then not valid so may be skipped/ignored.
   			If present in bHQBC and in process or open, give error to user */
   		select Mth, BatchId
   		from bHQBC with (nolock)
   		where Co = @arco and Mth = @mth and BatchId = @batchid and Status < 5
   	
   		/* This record has been found to be in a valid batch, Warn User and exit */
   		if @@rowcount > 0
   			begin
   			select @msg = 'Entries exist, for this Contract range, in AR batch: ' + convert(varchar(10),@batchid)
   			select @msg = @msg + ' for month ' + convert(varchar(8), @mth, 1) 
   			select @msg = @msg + ': in source ' + convert(varchar(20), @source) + '.  '
   			select @msg = @msg + char(13) + char(10)
   			select @msg = @msg + 'This routine does not evaluate open batch values!  ' 
   			select @msg = @msg + 'To proceed, it is recommended that all Invoice, Payment, Release Retainage, and Finance Charge batches be posted.'
   			select @rcode = 1
   			goto bspexit
   			end
   		
   		/* No warning to this point so get next BatchId and evaluate */
   		fetch next from bcBatchList into @batchid, @mth, @source
   		end  /* End Contract BatchList loop */
   	end
   
   bspexit:
   if @batchlistcursor = 1
   	begin
   	close bcBatchList
   	deallocate bcBatchList
   	end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARCheckBatches] TO [public]
GO
