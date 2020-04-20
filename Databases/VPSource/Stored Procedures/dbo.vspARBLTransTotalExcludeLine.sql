SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARBLTransTotalExcludeLine    Script Date: 03/05/2004 9:34:08 AM ******/
CREATE procedure [dbo].[vspARBLTransTotalExcludeLine]
/*************************************************************************************************
* CREATED BY: 		TJL 02/07/05 - Issue #26556, Get Transaction Total excluding current Line.
* MODIFIED By :
*
* USAGE:
* 	Currently used only by 'ARInvoiceEntry' to return the ARBL Transaction Lines Total
*	excluding the amount of the current line.  Its used before the Line record gets updated
*	to warn the user when CreditLimit has been exceeded, or when an inputted amount is
*	inconsistent with other line values.
*
* INPUT PARAMETERS
*   @co			AR Co
*   @mth		Month of batch
*   @batchid	Batch ID 
*	@batchseq	Batch Sequence
*	@currentline	Batch Line number
*	@source		 
*
* OUTPUT PARAMETERS
*	@amount		Transaction amount minus current line value
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/
  
(@arco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @currentline int,
	@source bSource, @amount bDollar output, @errmsg varchar(255) output)
as

set nocount on

declare @rcode int

select @rcode = 0, @amount = 0

if @source not in ('AR Invoice', 'AR Receipt')
	begin
	select @errmsg = 'Not a valid Source.', @rcode = 1
	goto vspexit
	end
  
/* Get Transaction amount excluding current line value. */
select @amount = isnull(sum(Amount), 0)
from bARBL with (nolock) 
where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq 
	and ARLine <> @currentline

vspexit:

if @rcode <> 0 select @errmsg=@errmsg	--+ char(13) + char(10) + '[vspARBLTransTotalExcludeLine]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARBLTransTotalExcludeLine] TO [public]
GO
