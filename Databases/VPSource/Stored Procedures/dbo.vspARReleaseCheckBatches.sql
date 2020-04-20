SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARReleaseCheckBatches]
/*********************************************************************************
*  Created:	TJL  06/10/05:  Issue #27716, 6X rewrite
*  Modified: GG 02/25/08 - #120107 - separate sub ledger close, use last mth AR closed
*		
*  Currently used by 'ARRelease' form and 'bspARRelease' procedure.
*  Will retrieve proper GLCo for this ARCo then retrieve GL Sub Ledger Closed date.
*  It then Checks all bARBH batches for transactions later than this date and relative
*  to a specific customer or customer and contract.  If they exist, it will then further check bHQBC for 
*  unfinished status and if it is in the process of posting or open, an error message
*  will be sent to user.
*  
*
* Inputs:
*	@arco			-	AR Company
*	@custgroup		-	Customer Group
*	@customer		-	Customer Range to evaluate
*	@jcco			-	JCCo
*	@contract		-	Contract
*
* Outputs:
*	@msg			-	error message
*   @rcode	
*
*************************************************************************************/
(@arco bCompany = null, @batchmth bMonth, @batchid bBatchID, @batchseq int, 
	@custgroup bGroup, @customer bCustomer, @jcco bCompany, @contract bContract,
	@errmsg varchar(375) output)
as
set nocount on
  
declare @rcode int, @count int, @glco bCompany, @lastsubclosedmth bMonth, @duplicateseq int
  
select @rcode = 0

if @arco is null
	begin
	select @errmsg = 'Missing AR Company', @rcode = 1
	goto vspexit
	end
  
/*  Since Releasing retainage depends on accurate Open Retainage information,
	and since open batches can lead to changes that can effect Open Retainage that
	is evaluated, all transactions that exist in batches that may affect
	the Open Retainage of that transaction should first be posted before user 
	begins the Release Retainage process.  We do not evaluate batch records in Release
	Retainage processing.  User is warned to post open batches before proceeding. */
  
/* Get GLCo for this ARCo */
select @glco = GLCo
from bARCO with (nolock)
where ARCo = @arco
  
/* Get the SubLedger last closed month for this GLCo.  We do not care about transactions
   in batches if the month has been closed.  */
select @lastsubclosedmth = LastMthARClsd	-- #120017 - use AR close month
from bGLCO with (nolock)
where GLCo = @glco

/* Begin by checking to see if this BatchId already contains a Header record relative
   to this Customer, JCCo/Contract.  Due to the way the grid refreshes, duplicate use of Customer 
   or Customer/Contract is not allowed. */
select @duplicateseq = h.BatchSeq
from bARBH h with (nolock)
where h.Co = @arco and h.Mth = @batchmth and h.BatchId = @batchid	--Duplicates exist in this BatchId
	and h.CustGroup = @custgroup and h.Customer = @customer			--This customer only
	and isnull(h.JCCo, 0) = isnull(@jcco, 0)
	and isnull(h.Contract, '') = isnull(@contract, '')				--This contract or all non-contract invoices
	and h.BatchSeq <> (case when h.Mth = @batchmth and h.BatchId = @batchid  then @batchseq else 0 end)	--Not this BatchSeq
if @duplicateseq is not null
	begin
	select @errmsg = 'An entry already exists in this batch relative to this exact Customer or '
	select @errmsg = @errmsg + 'Customer/Contract value.  This combination will not be allowed twice in the same Batchid.  '
	select @errmsg = @errmsg + 'It is recommended that you return to BatchSeq #' + Convert(varchar(10), @duplicateseq) 
	select @errmsg = @errmsg + ' and either delete or post this BatchSeq before proceeding.'
	select @rcode = 1
	goto vspexit
	end

/* Check unposted batches for any transactions with retainage that may affect the 
   accuracy of this process.  Duplication based Strictly upon Customer and JCCo/Contract has
   already been caught above so this next check can look to any batch based upon Customer
   and JCCo/Contract for any unposted retainage values that could effect the outcome of this
   release action.  Duplicate entries in this batch based upon Customer and JCCo/Contract
   will not exist if we have reached this point. */
select 1
from bARBL l with (nolock)
join bARBH h with (nolock) on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId
join bHQBC c with (nolock) on c.Co = h.Co and c.Mth = h.Mth and c.BatchId = h.BatchId
where h.Co = @arco and h.ARTransType in ('F','I','P','R', 'C', 'A', 'W')
	and h.Mth > @lastsubclosedmth 									--Don't care about batches left in Months closed
	and h.CustGroup = @custgroup and h.Customer = @customer			--This customer only
	and isnull(h.JCCo, 0) = isnull(@jcco, 0)
	and isnull(h.Contract, '') = isnull(@contract, '')				--This contract or all non-contract invoices
	and c.Status < 5												--Open batches or those currently in process
	and l.Retainage <> 0											--Retainage not 0.00
	and h.BatchId <> @batchid										--Not this BatchId
if @@rowcount > 0
	begin
	/* A related record, containing retainage, has been found in a valid batch, Warn User 
	   but allow user to continue. */
	select @errmsg = 'Entries exist in unposted batches that contain retainage relative to this '
	select @errmsg = @errmsg + 'Customer or Customer/Contract and could effect this Release process.  '
	select @errmsg = @errmsg + 'This routine does not evaluate open batch values!  It is recommended that all batches ' 
	select @errmsg = @errmsg + 'containing related transactions with retainage amounts be posted.'
	select @rcode = 7
	goto vspexit
	end
  
vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '  [vspARReleaseCheckBatches]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARReleaseCheckBatches] TO [public]
GO
