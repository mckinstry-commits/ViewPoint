SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARBLLinesMarkDeleted    Script Date: 03/05/2004 9:34:08 AM ******/
CREATE procedure [dbo].[vspARBLLinesMarkDeleted]
/*************************************************************************************************
* CREATED BY:	TJL 02/07/05 - Issue #26556, Set ARBL Batch Lines for Delete
* MODIFIED By:	TJL 10/26/07 - Issue #123134, Set ARBM Batch Lines for Delete	
*
* USAGE:
* 	Currently used to set the ARBL Transaction Type to 'D'elete
*	when the Invoice Header gets set for 'D'elete by the user.
*
* INPUT PARAMETERS
*   @co			AR Co
*   @mth		Month of batch
*   @batchid	Batch ID 
*	@batchseq	Batch Sequence
*	@source		Source 
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/
  
(@arco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @source char(10),
	@errmsg varchar(255) output)
as

set nocount on

declare @rcode int, @reccount int, @headertranstype char(1)

select @rcode = 0, @reccount = 0

if @source not in ('AR Invoice', 'AR Receipt', 'ARFinanceC')
	begin
	select @errmsg = 'Not a valid Source.', @rcode = 1
	goto vspexit
	end

/* Mark bARBL Lines for 'D'elete for this batchid and batchseq. */
select @reccount = count(*), @headertranstype = h.TransType
from bARBL l with (nolock) 
join bARBH h with (nolock) on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
where l.Co = @arco and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @batchseq 
group by h.TransType

if isnull(@reccount, 0) > 0
   	begin
   	update bARBL 
	set TransType = case when @headertranstype = 'D' then 'D' else 'C' end
	where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
  
	if @@rowcount <> @reccount
		begin
		select @errmsg = 'Not all Batch Lines have been Marked for Deletion or Change. User must do so manually.', @rcode = 1
		goto vspexit
		end
   	end

/* Mark bARBM Lines for 'D'elete for this batchid and batchseq. */
select @reccount = 0
select @reccount = count(*)
from bARBM with (nolock) 
where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq 

if isnull(@reccount, 0) > 0
   	begin
   	update bARBM 
	set TransType = case when @headertranstype = 'D' then 'D' else 'C' end
	where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
  
	if @@rowcount <> @reccount
		begin
		select @errmsg = 'Not all Misc Distributions have been Marked for Deletion or Change. User must do so manually.', @rcode = 1
		goto vspexit
		end
   	end

vspexit:
if @rcode <> 0 select @errmsg=@errmsg	--+ char(13) + char(10) + '[vspARBLLinesMarkDeleted]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARBLLinesMarkDeleted] TO [public]
GO
