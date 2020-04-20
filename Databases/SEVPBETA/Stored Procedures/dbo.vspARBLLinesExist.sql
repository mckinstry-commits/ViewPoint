SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARBLLinesMarkDeleted    Script Date: 03/05/2004 9:34:08 AM ******/
CREATE procedure [dbo].[vspARBLLinesExist]
/*************************************************************************************************
* CREATED BY: 		TJL 06/20/05 - Issue #27715, 6x rewrite ARRelease.  Check for presence of ARBL records by Invoice
* MODIFIED By :
*
* USAGE:
* 	Currently used only by 'ARRelease'.  It determines if Detail records have been placed into
*	the ARBL batch table relative to a single Invoice.  If so, user is allowed to the Release Detail form.  
*	If no records exist for a particular BatchMth, BatchSeq, ApplyMth and ApplyTrans then access to Release Detail
*	form is disabled for this Invoice.
*
*   ARCashReceipts currently has code in place but Rem'd out that would also use this routine.  
*   If put into play it would be used only to check for the existence of lines in ARBL (relative to a 
*   single Invoice) that are ALL set to 0.00 value.  If so, these invoice lines would ultimately be
*   removed from the Batch table bARBL by another routine.
*
* INPUT PARAMETERS
*   @co				AR Co
*   @mth			Month of batch
*   @batchid		Batch ID 
*	@batchseq		Batch Sequence
*	@source			Source 
*	@invapplymth	Invoice Transaction Month
*	@invapplytrans	Invoice Transaction number
*
* OUTPUT PARAMETERS
*	@allzeroyn	if Detail records exist, are they all zero value or not
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/
  
(@arco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @source char(10),
	@invapplymth bMonth, @invapplytrans bTrans, @allzeroyn bYN output, @errmsg varchar(255) output)
as

set nocount on

declare @rcode int, @amount bDollar

select @rcode = 0

if @source not in ('ARRelease', 'AR Receipt')
	begin
	select @errmsg = 'Not a valid Source.', @rcode = 1
	goto vspexit
	end
  
/* Check for existence of Batch Lines for this Invoice. */
if not exists (select 1 
	from bARBL with (nolock) 
	where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq 
		and ApplyMth = @invapplymth and ApplyTrans = @invapplytrans)
	begin
	/* No detail records exist.  Form will not allow user into Release Detail Form. */
	select @allzeroyn = 'Y', @rcode = 1
	goto vspexit
	end
else
	begin
	/* Detail records do exists.  Determine if all detail records are Zero value or if
	   one or more contains a Release amount. 
	   (If the count of all detail records for this Invoice that have some values = 0 (No detail contains value) then ALLZero = 'Y')*/
	if (select count(*)
		from bARBL with (nolock)
		where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq 
			and ApplyMth = @invapplymth and ApplyTrans = @invapplytrans
			and (isnull(Amount, 0) <> 0 or isnull(TaxAmount, 0) <> 0 or isnull(Retainage, 0) <> 0 
				or isnull(DiscTaken, 0) <> 0 or isnull(TaxDisc, 0) <> 0 or isnull(FinanceChg, 0) <> 0
				or isnull(oldAmount, 0) <> 0 or isnull(oldTaxAmount, 0) <> 0 or isnull(oldRetainage, 0) <> 0 
				or isnull(oldDiscTaken, 0) <> 0 or isnull(oldTaxDisc, 0) <> 0 or isnull(oldFinanceChg, 0) <> 0)) = 0
		begin
		select @allzeroyn = 'Y'
		goto vspexit
		end
	else
		begin
		select @allzeroyn = 'N'
		goto vspexit
		end
	end

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[vspARBLLinesExist]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARBLLinesExist] TO [public]
GO
