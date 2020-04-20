SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMMLLinesMarkDeleted    Script Date: 04/04/2004 9:34:08 AM ******/
CREATE procedure [dbo].[vspEMMLLinesMarkDeleted]
/*************************************************************************************************
* CREATED BY: 		TJL 04/04/07 - Issue #27992, Set EMML Batch Lines for Delete
* MODIFIED By :
*
* USAGE:
* 	Currently used to set the EMML Transaction Type to 'D'elete
*	when the Header gets set for 'D'elete by the user.
*
* INPUT PARAMETERS
*   @co			EM Co
*   @mth		Month of batch
*   @batchid	Batch ID 
*	@batchseq	Batch Sequence
*	@source		Source		(NA at this time)
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/
  
(@emco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @errmsg varchar(255) output)	--@source char(10),
as

set nocount on

declare @rcode int, @reccount int, @transtype char(1)

select @rcode = 0, @reccount = 0

--if @source not in ('EMMiles')
--	begin
--	select @errmsg = 'Not a valid Source.', @rcode = 1
--	goto vspexit
--	end

/* Mark bEMML Lines for 'D'elete for this batchid and batchseq. */
select @reccount = count(*), @transtype = h.BatchTransType
from bEMML l with (nolock) 
join bEMMH h with (nolock) on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
where l.Co = @emco and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @batchseq 
group by h.BatchTransType

if isnull(@reccount, 0) > 0
   	begin
   	update bEMML 
	set BatchTransType = case when @transtype = 'D' then 'D' else 'C' end
	where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
  
	if @@rowcount <> @reccount
		begin
		select @errmsg = 'Not all Batch Lines TransType have been Marked for Deletion or Change. User must do so manually.', @rcode = 1
		goto vspexit
		end
   	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMMLLinesMarkDeleted] TO [public]
GO
