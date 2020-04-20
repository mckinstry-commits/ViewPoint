SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARBLSetReleased    Script Date: 8/28/99 9:36:06 AM ******/
CREATE procedure [dbo].[vspARBLSetReleased]
/*******************************************************************************************
* CREATED BY:   	TJL 07/03/08 - Issue #128371, AR Release International Sales Tax
* MODIFIED By :   	
*
*
* USAGE:
* Called from bspARBHReleaseVal to generate the NEW 'Released' invoice lines
*
*
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
***************************************************************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @seq int, @jcco bCompany = null, @contract bContract = null, @contractitem bContractItem = null,
	@amount bDollar = 0, @taxamount bDollar = 0, @retainage bDollar = 0, @retgtax bDollar = 0, 
	@artrans bTrans, @rectype TinyInt, @taxgroup bGroup, @taxcode bTaxCode = null, @errmsg varchar(255) output
as
set nocount on
declare @rcode int, @ncglco bCompany, @ncglrevacct bGLAcct, @retg_apply_line int, @contractstatus int,
	@itemglco bCompany, @itemglrevacct bGLAcct

select @rcode = 0

	/******************************************************************************************/
  	/* Begin processing 'R'eleased lines  (New 'R' type invoice lines).  This is the new      */
	/* invoice that gets created as a result of releasing retainage from earlier invoices.	  */
	/* The grouping of Lines relative to Non-Contract invoices and Contract invoices differs  */
	/* here.																				  */
	/******************************************************************************************/

if @jcco is null or @contract is null or @contractitem is null
	begin
	/* Non-Contract 'Released' invoice line.  One Line for ALL non-contract invoice lines. */
  	/* Get initial GLCo, GLRevAcct values for non-contract lines. */
  	select @ncglco = GLCo, @ncglrevacct = GLRevAcct
  	from bARRT with (nolock)
  	where ARCo = @co and RecType = @rectype

	select @retg_apply_line = 10000

	update bARBL
	set Amount = isnull(Amount,0) + @amount, TaxAmount = isnull(TaxAmount,0) + @taxamount,
		Retainage = isnull(Retainage,0) + @retainage, RetgTax = isnull(RetgTax,0) + @retgtax
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and ARLine = @retg_apply_line

	if @@rowcount = 0   /* If record is not already there then lets try to insert it */
		begin
		/*Insert one Line for ALL non-contract invoice lines. */
		insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType, LineType, Description,
  			GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxAmount, Retainage, RetgTax, ApplyMth, ApplyTrans, ApplyLine)
		values(@co, @mth, @batchid, @seq, @retg_apply_line, 'A', @artrans, @rectype, 'R', 'Released Retainage',
			@ncglco ,@ncglrevacct, @taxgroup, @taxcode, @amount, @taxamount, @retainage, @retgtax, @mth,
      		@artrans, @retg_apply_line)
		if @@rowcount = 0
			begin
			select @errmsg = 'Unable to add "Released" retainage line into batch.', @rcode = 1
			goto vspexit
			end
		end
	end
else
	begin
	/* Contract 'Released' invoice line.  One Line for each Contract Item. */
	exec @rcode = bspJCContractVal @jcco, @contract, @contractstatus output, null, null, null, null, @errmsg output
	if @rcode <> 0
 		begin
		/* Contract is Missing or invalid in some way. */
 		select @contractstatus = null
		select @rcode = 0
 		end	

	/* Get initial GLCo, GLRevAcct values for each contract item line. */
	if @contractstatus is null
		begin
		select @itemglco = null, @itemglrevacct = null
		end
	else
		begin
		select @itemglco = d.GLCo, 
			@itemglrevacct = case when @contractstatus = 3 then d.ClosedRevAcct else d.OpenRevAcct end 
		from bJCCM m with (nolock)
		join bJCCI i with (nolock) on i.JCCo = m.JCCo and i.Contract = m.Contract
		join bJCDM d with (nolock) on d.JCCo = i.JCCo and d.Department = i.Department
		where i.JCCo = @jcco and i.Contract = @contract and i.Item = @contractitem
		end

	update bARBL
	set Amount = isnull(Amount,0) + @amount, TaxAmount = isnull(TaxAmount,0) + @taxamount,
		Retainage = isnull(Retainage,0) + @retainage, RetgTax = isnull(RetgTax,0) + @retgtax
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq 
		and JCCo = @jcco and Contract = @contract and Item = @contractitem and ARLine >= 10000

	if @@rowcount = 0   /* If record is not already there then lets try to insert it */
		begin
		select @retg_apply_line = max(ARLine)
		from bARBL
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq 
		if @retg_apply_line > 9999 select @retg_apply_line = @retg_apply_line + 1 else select @retg_apply_line = 10000

		/*Insert one Line for each Contract Item. */
		insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType, LineType, Description,
  			GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxAmount, Retainage, RetgTax, ApplyMth, ApplyTrans, ApplyLine,
			JCCo, Contract, Item)
		values(@co, @mth, @batchid, @seq, @retg_apply_line, 'A', @artrans, @rectype, 'R', 'Released Retainage',
			@itemglco, @itemglrevacct, @taxgroup, @taxcode, @amount, @taxamount, @retainage, @retgtax, @mth,
      		@artrans, @retg_apply_line, @jcco, @contract, @contractitem)
		if @@rowcount = 0
			begin
			select @errmsg = 'Unable to add "Released" retainage line into batch.', @rcode = 1
			goto vspexit
			end
		end
	end

vspexit:

if @rcode <> 0 select @errmsg = @errmsg	
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARBLSetReleased] TO [public]
GO
