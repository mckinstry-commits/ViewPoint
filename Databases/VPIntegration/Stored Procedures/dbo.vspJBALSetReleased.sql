SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBALSetReleased    Script Date: ******/
CREATE procedure [dbo].[vspJBALSetReleased]
/*******************************************************************************************
* CREATED BY:   	TJL 08/18/08 - Issue #128370, JB Release International Sales Tax
* MODIFIED By :   	
*
*
* USAGE:
* Called from bspJBARReleaseVal to generate the NEW 'Released' invoice lines
*
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
***************************************************************************************************/
@jbco bCompany, @batchmth bMonth, @batchid bBatchID, @seq int, @jbcontractitem bContractItem,
	@batchtranstype char(1), @JCGLCo bCompany, @itemglrevacct bGLAcct, @taxgroup bGroup, @taxcode bTaxCode,
	@um bUM, @revrelretgYN bYN, @retgrel bDollar, @retgtaxrel bDollar, @itemnotes varchar(8000),
	@errmsg varchar(255) output

as
set nocount on
declare @rcode int

select @rcode = 0

/******************************************************************************************/
/* Begin processing 'R'eleased lines  (New 'R' type invoice lines).  This is the new      */
/* invoice that gets created as a result of releasing retainage from earlier invoices.	  */
/*																						  */
/******************************************************************************************/

update bJBAL
set RetgRel = RetgRel + @retgrel, RetgTaxRel = RetgTaxRel + @retgtaxrel
where Co = @jbco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @seq and Item = @jbcontractitem
	and ARLine = 10000

if @@rowcount = 0
	begin
	insert into bJBAL(Co, Mth, BatchId, BatchSeq, Item, ARLine, BatchTransType,
		GLCo, GLAcct, Description, TaxGroup, TaxCode, UM, Amount, Units, TaxBasis, TaxAmount,
		RetgPct, Retainage, RetgRel, RetgTaxRel, Notes)
	values(@jbco, @batchmth, @batchid, @seq, @jbcontractitem, 10000, @batchtranstype,
		@JCGLCo, @itemglrevacct, 'Released Retainage', @taxgroup, @taxcode, @um, 0, 0, 0, 0,
		0, 0, @retgrel, @retgtaxrel, @itemnotes)

	if @@rowcount = 0
		begin
		select @errmsg = 'Unable to add "Released" retainage line into batch.', @rcode = 1
		goto vspexit
		end
	end

vspexit:

if @rcode <> 0 select @errmsg = @errmsg	
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBALSetReleased] TO [public]
GO
